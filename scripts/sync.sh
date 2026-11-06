#!/usr/bin/env bash
#
# RisingOS 9 tegu — synchronise the Android source tree.
#
# Installs the project local manifest, runs `repo sync`, then applies any registered
# downstream patches (none at present) and checks that the required projects exist.
#
# Usage:
#   ./scripts/sync.sh [--jobs N] [--force] [--no-verify]
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ANDROID_ROOT="${ANDROID_ROOT:-$HOME/android/risingos-9-tegu}"
LOCAL_MANIFEST="$PROJECT_ROOT/manifest/risingos-9-tegu.xml"

JOBS="$(nproc 2>/dev/null || echo 4)"
FORCE=0
VERIFY=1

# Downstream patches applied after sync: "<project path>:<patch path>".
# Empty by design: the RisingOS layer and the tegu device tree need no source patches.
# See patches/README.md before adding an entry.
PATCHES=()

log()  { printf '\033[1;34m[sync ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn ]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail ]\033[0m %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --jobs)      JOBS="${2:?--jobs needs a number}"; shift ;;
        --force)     FORCE=1 ;;
        --no-verify) VERIFY=0 ;;
        -h|--help)   sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
    shift
done

main() {
    [ -f "$LOCAL_MANIFEST" ] || die "missing $LOCAL_MANIFEST"

    if [ ! -d "$ANDROID_ROOT/.repo" ]; then
        die "no repo checkout at $ANDROID_ROOT — run ./scripts/setup.sh first"
    fi

    mkdir -p "$ANDROID_ROOT/.repo/local_manifests"
    install -m 0644 "$LOCAL_MANIFEST" "$ANDROID_ROOT/.repo/local_manifests/risingos-9-tegu.xml"
    log "local manifest refreshed"

    local repo_bin="$ANDROID_ROOT/.repo-tool/repo"
    [ -x "$repo_bin" ] || repo_bin="$(command -v repo || true)"
    [ -n "$repo_bin" ] || die "repo launcher not found; run ./scripts/setup.sh"

    local args=(-c --no-clone-bundle --optimized-fetch --prune "-j$JOBS")
    if [ "$FORCE" -eq 1 ]; then
        args+=(--force-sync)
    fi

    log "repo sync ${args[*]}"
    mkdir -p "$PROJECT_ROOT/logs"
    local stamp log_file
    stamp="$(date -u +%Y%m%dT%H%MZ)"
    log_file="$PROJECT_ROOT/logs/${stamp}-sync.log"
    ( cd "$ANDROID_ROOT" && timeout 21600 "$repo_bin" sync "${args[@]}" 2>&1 | tee "$log_file" )
    log "sync log: $log_file"

    apply_patches

    if [ "$VERIFY" -eq 1 ]; then
        ANDROID_ROOT="$ANDROID_ROOT" "$SCRIPT_DIR/verify.sh" --workspace "$ANDROID_ROOT" || die "verification failed after sync"
    fi
}

apply_patches() {
    if [ ${#PATCHES[@]} -eq 0 ]; then
        log "no downstream patches registered"
        return 0
    fi
    local entry project patch
    for entry in "${PATCHES[@]}"; do
        project="${entry%%:*}"
        patch="$PROJECT_ROOT/${entry#*:}"
        [ -f "$patch" ] || die "registered patch missing: $patch"
        log "applying $(basename "$patch") to $project"
        if git -C "$ANDROID_ROOT/$project" apply --check "$patch" 2>/dev/null; then
            git -C "$ANDROID_ROOT/$project" apply "$patch"
        elif git -C "$ANDROID_ROOT/$project" apply --reverse --check "$patch" 2>/dev/null; then
            warn "already applied: $(basename "$patch")"
        else
            die "patch does not apply cleanly: $patch (tree drifted from pinned revision?)"
        fi
    done
}

main "$@"
