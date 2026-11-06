#!/usr/bin/env bash
#
# RisingOS 9 tegu — collect and checksum build artifacts.
#
# Copies the installable ZIP and images from out/target/product/tegu into
# output/<UTC timestamp>/ and writes metadata.json + checksums.sha256.
# Large artifacts are never committed to git (see .gitignore).
#
# Usage:
#   ./scripts/package.sh [--workspace DIR] [--input DIR] [--allow-missing-zip]
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
ANDROID_ROOT="${ANDROID_ROOT:-$HOME/android/risingos-9-tegu}"
INPUT_DIR=""
ALLOW_MISSING_ZIP=0

log()  { printf '\033[1;34m[pack ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn ]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail ]\033[0m %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --workspace)        ANDROID_ROOT="${2:?}"; shift ;;
        --input)            INPUT_DIR="${2:?}"; shift ;;
        --allow-missing-zip) ALLOW_MISSING_ZIP=1 ;;
        -h|--help)          sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
    shift
done

[ -n "$INPUT_DIR" ] || INPUT_DIR="$ANDROID_ROOT/out/target/product/tegu"
[ -d "$INPUT_DIR" ] || die "no build output at $INPUT_DIR (run scripts/build.sh first)"

STAMP="$(date -u +%Y%m%dT%H%MZ)"
DEST="$PROJECT_ROOT/output/$STAMP"
mkdir -p "$DEST"

log "source: $INPUT_DIR"
log "destination: $DEST"

copied=0
copy_if_present() {
    local name="$1"
    if [ -f "$INPUT_DIR/$name" ]; then
        cp -f "$INPUT_DIR/$name" "$DEST/$name"
        log "packaged $name ($(du -h "$INPUT_DIR/$name" | cut -f1))"
        copied=$((copied + 1))
        return 0
    fi
    return 1
}

# Installable package: RisingOS names its bacon output RisingOS-*.zip; accept the
# Lineage-style lineage-*.zip as well for a same-tree fallback build.
zip_found=0
while IFS= read -r z; do
    [ -n "$z" ] || continue
    cp -f "$z" "$DEST/"
    log "packaged $(basename "$z") ($(du -h "$z" | cut -f1))"
    zip_found=1
    copied=$((copied + 1))
done < <(find "$INPUT_DIR" -maxdepth 1 -type f \( -name 'RisingOS-*.zip' -o -name 'lineage-*.zip' \) | sort)

if [ "$zip_found" -eq 0 ]; then
    if [ "$ALLOW_MISSING_ZIP" -eq 1 ]; then
        warn "no installable ZIP found (allowed by --allow-missing-zip)"
    else
        die "no RisingOS-*.zip or lineage-*.zip in $INPUT_DIR: the ROM package was not produced"
    fi
fi

for img in boot.img recovery.img vendor_boot.img dtbo.img super_empty.img; do
    copy_if_present "$img" || warn "not produced: $img"
done

# ---------------------------------------------------------------------------
# Metadata
# ---------------------------------------------------------------------------
python3 - "$DEST" "$INPUT_DIR" "$PROJECT_ROOT" "$ANDROID_ROOT" <<'PY'
import json, os, subprocess, sys, datetime

dest, input_dir, project_root, android_root = sys.argv[1:5]

def git(args, cwd):
    try:
        return subprocess.check_output(["git", "-C", cwd] + args, text=True,
                                       stderr=subprocess.DEVNULL).strip()
    except Exception:
        return None

try:
    build_cfg = json.load(open(os.path.join(project_root, "config", "build.json")))
except Exception:
    build_cfg = {}
try:
    device_cfg = json.load(open(os.path.join(project_root, "config", "device.json")))
except Exception:
    device_cfg = {}
try:
    project_cfg = json.load(open(os.path.join(project_root, "config", "project.json")))
except Exception:
    project_cfg = {}

artifacts = sorted(
    f for f in os.listdir(dest) if os.path.isfile(os.path.join(dest, f))
)
meta = {
    "project": project_cfg.get("project_name", "RisingOS 9 tegu"),
    "rom": project_cfg.get("rom_name", "RisingOS Revived 9"),
    "rom_version": project_cfg.get("rising_version"),
    "build_type": project_cfg.get("build_type", "UNOFFICIAL/COMMUNITY"),
    "device": {
        "codename": device_cfg.get("codename", "tegu"),
        "model": device_cfg.get("model", "Pixel 9a"),
        "soc": device_cfg.get("soc", "Google Tensor G4"),
        "architecture": device_cfg.get("architecture", "arm64"),
    },
    "android_version": project_cfg.get("android_version", "17"),
    "lineage_branch": project_cfg.get("lineage_branch", "lineage-24.0"),
    "rising_branch": project_cfg.get("rising_branch", "seventeen"),
    "lunch_target": build_cfg.get("lunch_target", "rising_tegu-userdebug"),
    "built_at_utc": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "host": {
        "platform": os.uname().machine,
        "cpus": os.cpu_count(),
    },
    "project_commit": git(["rev-parse", "HEAD"], project_root),
    "android_tree_commit": git(["rev-parse", "HEAD"], android_root) if os.path.isdir(os.path.join(android_root, ".repo")) else None,
    "source_artifacts": artifacts,
    "artifacts": {},
    "notes": [
        "Unofficial community build; not an official RisingOS release.",
        "Artifacts are not tested on physical hardware by the project agent.",
    ],
}
try:
    meta["host"]["ram_gb"] = int(os.sysconf("SC_PAGE_SIZE") * os.sysconf("SC_PHYS_PAGES") / 1024**3)
except Exception:
    pass

for a in artifacts:
    p = os.path.join(dest, a)
    meta["artifacts"][a] = {"bytes": os.path.getsize(p)}

with open(os.path.join(dest, "metadata.json"), "w") as fh:
    json.dump(meta, fh, indent=2, sort_keys=True)
    fh.write("\n")
print("wrote metadata.json")
PY

# ---------------------------------------------------------------------------
# Checksums
# ---------------------------------------------------------------------------
(
    cd "$DEST"
    find . -maxdepth 1 -type f ! -name checksums.sha256 ! -name metadata.json -print0 \
        | sort -z | xargs -0 -r sha256sum > checksums.sha256
)
log "checksums:"
sed 's/^/    /' "$DEST/checksums.sha256" || true

log "packaged ${copied} artifact(s) into $DEST"
log "artifacts stay out of git; publish them via a GitHub Release"
