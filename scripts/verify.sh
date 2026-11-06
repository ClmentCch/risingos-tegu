#!/usr/bin/env bash
#
# RisingOS 9 tegu — verify a synced tree and the integration.
#
# Checks (no network, no build):
#   1. required projects exist at the expected paths
#   2. pinned revisions match config/sources.json
#   3. the Rising/Lineage inheritance chain is present
#   4. the product is declared correctly (rising_tegu / tegu / Pixel 9a)
#   5. no forbidden device (akita) hardware sources are present
#   6. with --lunch, resolves the product through the real build system
#
# Usage:
#   ./scripts/verify.sh [--workspace DIR] [--lunch]
#
# Exit code: 0 = all checks passed, 1 = at least one failure.
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
ANDROID_ROOT="${ANDROID_ROOT:-$HOME/android/risingos-9-tegu}"
LUNCH_CHECK=0

while [ $# -gt 0 ]; do
    case "$1" in
        --workspace) ANDROID_ROOT="${2:?--workspace needs a path}"; shift ;;
        --lunch)     LUNCH_CHECK=1 ;;
        -h|--help)   sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) printf '[fail ] unknown argument: %s\n' "$1" >&2; exit 1 ;;
    esac
    shift
done

PASS=0
FAIL=0
WARN=0

ok()   { printf '\033[1;32m[ ok  ]\033[0m %s\n' "$*"; PASS=$((PASS + 1)); }
bad()  { printf '\033[1;31m[FAIL ]\033[0m %s\n' "$*"; FAIL=$((FAIL + 1)); }
note() { printf '\033[1;33m[warn ]\033[0m %s\n' "$*"; WARN=$((WARN + 1)); }

need_path() {
    if [ -e "$ANDROID_ROOT/$1" ]; then ok "present: $1"; else bad "missing: $1"; fi
}

need_file() {
    if [ -f "$ANDROID_ROOT/$1" ]; then ok "present: $1"; else bad "missing: $1"; fi
}

need_grep() {
    local pattern="$1" file="$2" label="$3"
    if [ -f "$ANDROID_ROOT/$file" ] && grep -Eq "$pattern" "$ANDROID_ROOT/$file"; then
        ok "$label"
    else
        bad "$label (pattern '$pattern' not found in $file)"
    fi
}

check_revisions() {
    local sources="$PROJECT_ROOT/config/sources.json"
    [ -f "$sources" ] || { bad "missing config/sources.json"; return; }
    local rows
    rows="$(python3 - "$sources" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
for p in data.get("projects", []):
    if p.get("path") and p.get("verify", True):
        print(f'{p["path"]}\t{p.get("pinned_sha") or ""}\t{p.get("revision") or ""}')
PY
)"
    while IFS=$'\t' read -r path sha revision; do
        [ -n "$path" ] || continue
        local tree="$ANDROID_ROOT/$path"
        if [ ! -d "$tree/.git" ] && [ ! -f "$tree/.git" ]; then
            note "no git metadata at $path (skipping revision check)"
            continue
        fi
        local actual
        actual="$(git -C "$tree" rev-parse HEAD 2>/dev/null || echo unknown)"
        if [ -n "$sha" ] && [ "$actual" = "$sha" ]; then
            ok "revision $path @ ${sha:0:12}"
        elif [ -n "$sha" ]; then
            bad "revision $path is ${actual:0:12}, expected ${sha:0:12}"
        else
            note "revision $path @ ${actual:0:12} (branch $revision, not SHA-pinned)"
        fi
    done <<< "$rows"
}

# ---------------------------------------------------------------------------
printf '\033[1mRisingOS 9 tegu verification\033[0m\n'
printf 'workspace: %s\n' "$ANDROID_ROOT"
printf 'project:   %s\n\n' "$PROJECT_ROOT"

if [ ! -d "$ANDROID_ROOT" ]; then
    bad "workspace does not exist: $ANDROID_ROOT"
    printf '\nResult: %d passed, %d failed, %d warnings\n' "$PASS" "$FAIL" "$WARN"
    echo "Verification FAILED (workspace missing)."
    exit 1
fi

printf '%s\n' '--- required projects ---'
need_path device/google/tegu
need_path device/google/zumapro
need_path device/google/tegu-kernels
need_path vendor/google/tegu
need_path vendor/lineage
need_path vendor/rising
need_path vendor/rising-tegu

printf '\n%s\n' '--- device foundation files ---'
need_file device/google/tegu/lineage_tegu.mk
need_file device/google/tegu/device-tegu.mk
need_file device/google/tegu/AndroidProducts.mk
need_file vendor/google/tegu/tegu-vendor.mk

printf '\n%s\n' '--- RisingOS layer ---'
need_file vendor/rising/config/rising.mk
need_file vendor/rising/config/version.mk
need_file vendor/lineage/config/common_full_phone.mk
need_grep 'RISING_VERSION := 9' vendor/rising/config/version.mk "Rising version is 9"

printf '\n%s\n' '--- product integration ---'
need_file vendor/rising-tegu/AndroidProducts.mk
need_file vendor/rising-tegu/rising_tegu.mk
need_grep 'inherit-product, device/google/tegu/lineage_tegu.mk' vendor/rising-tegu/rising_tegu.mk "inherits LineageOS tegu product"
need_grep 'inherit-product, vendor/rising/config/rising.mk' vendor/rising-tegu/rising_tegu.mk "inherits RisingOS layer"
need_grep '^PRODUCT_NAME := rising_tegu$' vendor/rising-tegu/rising_tegu.mk "PRODUCT_NAME := rising_tegu"
need_grep '^PRODUCT_DEVICE := tegu$' vendor/rising-tegu/rising_tegu.mk "PRODUCT_DEVICE := tegu"
need_grep '^PRODUCT_MODEL := Pixel 9a$' vendor/rising-tegu/rising_tegu.mk "PRODUCT_MODEL := Pixel 9a"
need_grep 'RisingChipset=' vendor/rising-tegu/rising_tegu.mk "RisingChipset build prop set"
need_grep 'RISING_MAINTAINER :=' vendor/rising-tegu/rising_tegu.mk "RISING_MAINTAINER set"
need_grep 'WITH_GMS := false' vendor/rising-tegu/rising_tegu.mk "GMS not bundled (licensing default)"
need_grep 'rising_tegu-userdebug' vendor/rising-tegu/AndroidProducts.mk "lunch target declared"

printf '\n%s\n' '--- forbidden sources ---'
if [ -d "$ANDROID_ROOT/device/google/akita" ]; then
    bad "device/google/akita (Pixel 8a) present: must not be used for tegu"
else
    ok "no akita (Pixel 8a) hardware tree"
fi

printf '\n%s\n' '--- pinned revisions ---'
check_revisions

if [ "$LUNCH_CHECK" -eq 1 ]; then
    printf '\n%s\n' '--- build system product resolution ---'
    if [ -f "$ANDROID_ROOT/build/envsetup.sh" ]; then
        out=""
        if out="$(cd "$ANDROID_ROOT" && bash -c '. build/envsetup.sh >/dev/null 2>&1; lunch rising_tegu-userdebug >/dev/null 2>&1; printf "%s|%s|%s" "$(get_build_var PRODUCT_NAME)" "$(get_build_var TARGET_DEVICE)" "$(get_build_var PRODUCT_MODEL)"' 2>&1)"; then
            if [ "$out" = "rising_tegu|tegu|Pixel 9a" ]; then
                ok "lunch rising_tegu-userdebug resolves to $out"
            else
                bad "product resolution mismatch: got '$out', expected 'rising_tegu|tegu|Pixel 9a'"
            fi
        else
            bad "lunch rising_tegu-userdebug failed"
        fi
    else
        note "build/envsetup.sh absent; skipped lunch check"
    fi
else
    note "lunch check skipped (pass --lunch to enable, requires a synced tree)"
fi

printf '\nResult: %d passed, %d failed, %d warnings\n' "$PASS" "$FAIL" "$WARN"
if [ "$FAIL" -gt 0 ]; then
    echo "Verification FAILED."
    exit 1
fi
echo "Verification PASSED."
