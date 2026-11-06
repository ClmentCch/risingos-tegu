#!/usr/bin/env bash
#
# RisingOS 9 tegu — environment audit and source-tree initialisation.
#
# This script never downloads the full tree; it prepares repo and installs the project's
# local manifest. Use scripts/sync.sh for the sync itself.
#
# Usage:
#   ./scripts/setup.sh --check-only          # audit host + resources, change nothing
#   ./scripts/setup.sh                       # audit, install repo launcher, repo init
#   ./scripts/setup.sh --allow-underpowered  # continue on an under-spec host (sync only)
#   ./scripts/setup.sh --install-deps        # apt-get install the LineageOS host packages
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

ANDROID_ROOT="${ANDROID_ROOT:-$HOME/android/risingos-9-tegu}"
MANIFEST_URL="https://github.com/RisingOS-Revived/android"
MANIFEST_BRANCH="seventeen"
REPO_URL="https://storage.googleapis.com/git-repo-downloads/repo"
LOCAL_MANIFEST="$PROJECT_ROOT/manifest/risingos-9-tegu.xml"

# Upstream requirements for Android 17 (LineageOS wiki, lineage-21+):
MIN_RAM_GB=64
MIN_DISK_GB=400
# A full sync is roughly 100-140 GB; refuse to start below this.
MIN_SYNC_DISK_GB=120

CHECK_ONLY=0
ALLOW_UNDERPOWERED=0
INSTALL_DEPS=0

log()  { printf '\033[1;34m[setup]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn ]\033[0m %s\n' "$*" >&2; }
fail() { printf '\033[1;31m[fail ]\033[0m %s\n' "$*" >&2; }
die()  { fail "$*"; exit 1; }

usage() {
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --check-only)         CHECK_ONLY=1 ;;
        --allow-underpowered) ALLOW_UNDERPOWERED=1 ;;
        --install-deps)       INSTALL_DEPS=1 ;;
        -h|--help)            usage ;;
        *) die "unknown argument: $1" ;;
    esac
    shift
done

# ---------------------------------------------------------------------------
# Host audit
# ---------------------------------------------------------------------------
audit_host() {
    local failures=0

    log "host: $(uname -srm)"
    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        log "distro: ${PRETTY_NAME:-unknown}"
    fi

    local cpus ram_gb disk_gb disk_path
    cpus="$(nproc 2>/dev/null || echo 0)"
    ram_gb="$(awk '/^MemTotal:/ {printf "%d", $2/1024/1024}' /proc/meminfo)"
    disk_path="$ANDROID_ROOT"
    while [ ! -d "$disk_path" ]; do disk_path="$(dirname "$disk_path")"; done
    disk_gb="$(df -Pk "$disk_path" | awk 'NR==2 {printf "%d", $4/1024/1024}')"

    log "cpu:   ${cpus} threads"
    log "ram:   ${ram_gb} GB"
    log "disk:  ${disk_gb} GB free at ${disk_path}"

    if [ "$ram_gb" -lt "$MIN_RAM_GB" ]; then
        fail "RAM ${ram_gb} GB < ${MIN_RAM_GB} GB required to build Android 17"
        failures=$((failures + 1))
    fi
    if [ "$disk_gb" -lt "$MIN_DISK_GB" ]; then
        fail "free disk ${disk_gb} GB < ${MIN_DISK_GB} GB required to build Android 17"
        failures=$((failures + 1))
    fi
    if [ "$disk_gb" -lt "$MIN_SYNC_DISK_GB" ]; then
        fail "free disk ${disk_gb} GB < ${MIN_SYNC_DISK_GB} GB needed even for a sync"
        failures=$((failures + 1))
    fi
    if [ "$cpus" -lt 16 ]; then
        warn "only ${cpus} threads: builds will be very slow (32+ recommended)"
    fi

    local missing=()
    local t
    for t in git python3 curl make gcc cc; do
        command -v "$t" >/dev/null 2>&1 || missing+=("$t")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        fail "missing required tools: ${missing[*]}"
        failures=$((failures + 1))
    fi
    for t in repo java ccache rsync unzip zip; do
        command -v "$t" >/dev/null 2>&1 || warn "missing optional tool: $t"
    done

    if [ "$failures" -gt 0 ]; then
        return 1
    fi
    return 0
}

install_deps() {
    command -v apt-get >/dev/null 2>&1 || die "automatic dependency install supports apt-get only"
    log "installing LineageOS host packages (needs sudo)"
    sudo apt-get update
    sudo apt-get install -y \
        bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs \
        gnupg gperf imagemagick lib32readline-dev lib32z1-dev libelf-dev liblz4-tool \
        libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool \
        squashfs-tools xsltproc zip zlib1g-dev python3 python3-pip openjdk-21-jdk
    git lfs install
}

install_repo() {
    local tool_dir="$ANDROID_ROOT/.repo-tool"
    local repo_bin="$tool_dir/repo"
    mkdir -p "$tool_dir"
    if [ ! -x "$repo_bin" ]; then
        log "downloading repo launcher"
        curl -fsSL "$REPO_URL" -o "$repo_bin"
        chmod +x "$repo_bin"
    else
        log "repo launcher already present: $repo_bin"
    fi
    "$repo_bin" --version 2>/dev/null || warn "repo launcher did not report a version"
}

install_local_manifest() {
    [ -f "$LOCAL_MANIFEST" ] || die "missing $LOCAL_MANIFEST"
    mkdir -p "$ANDROID_ROOT/.repo/local_manifests"
    install -m 0644 "$LOCAL_MANIFEST" "$ANDROID_ROOT/.repo/local_manifests/risingos-9-tegu.xml"
    log "installed local manifest -> .repo/local_manifests/risingos-9-tegu.xml"
}

repo_init() {
    mkdir -p "$ANDROID_ROOT"
    cd "$ANDROID_ROOT"
    local repo_bin="$ANDROID_ROOT/.repo-tool/repo"
    if [ -d .repo ]; then
        log "existing .repo found; refreshing local manifest only"
        install_local_manifest
        return 0
    fi
    log "repo init -u $MANIFEST_URL -b $MANIFEST_BRANCH --git-lfs"
    "$repo_bin" init -u "$MANIFEST_URL" -b "$MANIFEST_BRANCH" --git-lfs
    install_local_manifest
}

# ---------------------------------------------------------------------------
main() {
    log "project root: $PROJECT_ROOT"
    log "android root: $ANDROID_ROOT"

    if ! audit_host; then
        if [ "$CHECK_ONLY" -eq 1 ]; then
            die "host does not meet the requirements for an Android 17 build (audit only)"
        fi
        if [ "$ALLOW_UNDERPOWERED" -eq 1 ]; then
            warn "continuing on an under-spec host: a ROM build will not be possible here"
        else
            warn "a ROM build is impossible on this host; use --allow-underpowered for sync/config work only"
            die "aborting (no files changed). Re-run with --check-only or --allow-underpowered."
        fi
    fi

    if [ "$CHECK_ONLY" -eq 1 ]; then
        log "check-only: no changes made"
        exit 0
    fi

    if [ "$INSTALL_DEPS" -eq 1 ]; then
        install_deps
    fi
    install_repo
    repo_init

    log "next: ./scripts/sync.sh   (full tree sync, ~100 GB+)"
}

main "$@"
