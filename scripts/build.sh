#!/usr/bin/env bash
#
# RisingOS 9 tegu — build the ROM.
#
# Refuses to start unless the host can realistically complete an Android 17 build
# (64 GB RAM / 400 GB free disk by default) and the tree passes verification.
#
# Usage:
#   ./scripts/build.sh [--workspace DIR] [--lunch rising_tegu-userdebug]
#                      [--target bacon] [--jobs N] [--ccache DIR]
#                      [--allow-underpowered] [--skip-verify]
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
ANDROID_ROOT="${ANDROID_ROOT:-$HOME/android/risingos-9-tegu}"

LUNCH_TARGET="rising_tegu-userdebug"
BUILD_TARGET="bacon"
JOBS="$(nproc 2>/dev/null || echo 4)"
CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"
ALLOW_UNDERPOWERED=0
SKIP_VERIFY=0

MIN_RAM_GB=64
MIN_DISK_GB=400
MIN_RAM_GB_HARD=32   # below this the build cannot finish

log()  { printf '\033[1;34m[build]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn ]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail ]\033[0m %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --workspace)          ANDROID_ROOT="${2:?}"; shift ;;
        --lunch)              LUNCH_TARGET="${2:?}"; shift ;;
        --target)             BUILD_TARGET="${2:?}"; shift ;;
        --jobs)               JOBS="${2:?}"; shift ;;
        --ccache)             CCACHE_DIR="${2:?}"; shift ;;
        --allow-underpowered) ALLOW_UNDERPOWERED=1 ;;
        --skip-verify)        SKIP_VERIFY=1 ;;
        -h|--help)            sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
    shift
done

check_resources() {
    local ram_gb disk_gb
    ram_gb="$(awk '/^MemTotal:/ {printf "%d", $2/1024/1024}' /proc/meminfo)"
    disk_gb="$(df -Pk "$ANDROID_ROOT" 2>/dev/null | awk 'NR==2 {printf "%d", $4/1024/1024}')"

    log "resources: ${ram_gb} GB RAM, ${disk_gb} GB free, ${JOBS} jobs"
    if [ "$ram_gb" -lt "$MIN_RAM_GB_HARD" ] || [ "$disk_gb" -lt "$MIN_DISK_GB" ]; then
        if [ "$ALLOW_UNDERPOWERED" -eq 1 ]; then
            warn "host is below the required ${MIN_RAM_GB} GB RAM / ${MIN_DISK_GB} GB disk;"
            warn "the build will almost certainly fail (OOM or ENOSPC)"
        else
            die "host cannot build Android 17: need ${MIN_RAM_GB} GB RAM and ${MIN_DISK_GB} GB free disk (have ${ram_gb} GB / ${disk_gb} GB). Use --allow-underpowered only if you accept failure."
        fi
    elif [ "$ram_gb" -lt "$MIN_RAM_GB" ]; then
        warn "RAM below the recommended ${MIN_RAM_GB} GB; expect OOM kills with -j${JOBS}"
    fi
}

main() {
    [ -d "$ANDROID_ROOT" ] || die "workspace does not exist: $ANDROID_ROOT (run setup.sh + sync.sh)"
    [ -f "$ANDROID_ROOT/build/envsetup.sh" ] || die "no Android tree at $ANDROID_ROOT (build/envsetup.sh missing)"

    check_resources

    if [ "$SKIP_VERIFY" -eq 0 ]; then
        log "running verification"
        ANDROID_ROOT="$ANDROID_ROOT" "$SCRIPT_DIR/verify.sh" --workspace "$ANDROID_ROOT" --lunch \
            || die "verification failed; fix the tree before building"
    fi

    mkdir -p "$PROJECT_ROOT/logs" "$CCACHE_DIR"
    local stamp log_file
    stamp="$(date -u +%Y%m%dT%H%MZ)"
    log_file="$PROJECT_ROOT/logs/${stamp}-build.log"

    export CCACHE_EXEC="$(command -v ccache || true)"
    export USE_CCACHE=1
    export CCACHE_DIR
    export CCACHE_COMPRESS=1
    export LC_ALL=C
    export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation"
    [ -n "$CCACHE_EXEC" ] && ccache -M 50G >/dev/null 2>&1 || warn "ccache not installed; build will be slower"

    log "lunch $LUNCH_TARGET; target: $BUILD_TARGET; log: $log_file"
    (
        cd "$ANDROID_ROOT"
        set -o pipefail
        # shellcheck disable=SC1091
        . build/envsetup.sh
        lunch "$LUNCH_TARGET"
        mka -j"$JOBS" "$BUILD_TARGET"
    ) 2>&1 | tee "$log_file"
    local status=${PIPESTATUS[0]}

    if [ "$status" -ne 0 ]; then
        echo
        warn "build failed with status $status — log: $log_file"
        # Surface the first actionable error for the session handoff.
        grep -nE '^(\*\*\*|[^ ]*error:|FAILED:)' "$log_file" | head -20 || true
        exit "$status"
    fi

    log "build finished successfully: $log_file"
    log "next: ./scripts/package.sh"
}

main "$@"
