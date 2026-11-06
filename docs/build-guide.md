# Build guide — RisingOS 9 tegu

## 1. Host requirements (hard facts, not suggestions)

LineageOS wiki for `tegu` (Android 17 / `lineage-21`+ generation):

- **64 GB RAM** (less RAM ⇒ OOM kills; ZRAM helps but is not a substitute)
- **400 GB free SSD storage**
- x86_64 Linux (Ubuntu 22.04/24.04 recommended), 16+ threads for a sane build time
- 8+ hours for a cold build; ccache reduces subsequent builds dramatically

The Cloud environment used to author this project had 2 vCPU / 3.8 GB RAM / ~9.7 GB free
disk. **It cannot compile Android.** `scripts/setup.sh --check-only` reports exactly that
and exits non-zero.

## 2. Get the project

```bash
git clone https://github.com/ClmentCch/risingos-tegu -b risingos-9-tegu
cd risingos-tegu
```

## 3. Prepare the host

```bash
./scripts/setup.sh --check-only     # audit; expect failure on under-spec hosts
sudo ./scripts/setup.sh --install-deps   # apt packages + git-lfs (optional)
./scripts/setup.sh                  # installs repo launcher, repo init, local manifest
```

What `setup.sh` does on a capable host:

1. audits RAM/disk/tools and refuses an impossible build;
2. downloads the `repo` launcher into `$ANDROID_ROOT/.repo-tool/repo`;
3. `repo init -u https://github.com/RisingOS-Revived/android -b seventeen --git-lfs`;
4. installs `manifest/risingos-9-tegu.xml` into `.repo/local_manifests/`.

Default tree location: `~/android/risingos-9-tegu` (override with `ANDROID_ROOT`).

## 4. Sync

```bash
./scripts/sync.sh                 # ~100 GB+, uses nproc jobs
./scripts/sync.sh --jobs 8        # explicit job count
./scripts/sync.sh --force         # --force-sync when the tree drifted
```

The script refreshes the local manifest first, runs
`repo sync -c --no-clone-bundle --optimized-fetch --prune`, applies registered downstream
patches (none currently), then runs `verify.sh`.

## 5. Verify

```bash
./scripts/verify.sh --lunch
```

Checks required projects, pinned revisions, the inheritance chain, product identity, absence
of `akita` sources, and (with `--lunch`) real product resolution:

```
rising_tegu | tegu | Pixel 9a
```

## 6. Build

```bash
./scripts/build.sh
# equivalent manual path:
#   . build/envsetup.sh
#   lunch rising_tegu-userdebug
#   mka bacon -j$(nproc)
```

- Logs: `logs/<UTC stamp>-build.log` (git-ignored).
- ccache: `USE_CCACHE=1`, 50 GB, compressed by default in the script.
- RisingOS also ships `rise`/`riseup` wrappers and signing helpers
  (`riseup <device> <build-type>`). They require maintainer keys; this project builds with
  test-keys unless you provide your own keys. Never commit keys.
- Output: `out/target/product/tegu/`.

## 7. Package

```bash
./scripts/package.sh
```

Copies the installable ZIP plus `boot.img`, `recovery.img`, `vendor_boot.img`, `dtbo.img`
to `output/<UTC stamp>/`, writes `metadata.json` and `checksums.sha256`, and **fails** if no
ZIP exists. Large artifacts are git-ignored; publish them as GitHub Release assets.

## 7b. Build in CI on a self-hosted runner

GitHub-hosted runners cannot build Android 17 (16 GB RAM / 14 GB disk).
`.github/workflows/build.yml` targets a self-hosted runner labelled
`android-builder-64g` and performs: host audit → setup → sync → verify → build → package →
artifact upload, with a GitHub Release only on `v*` tags.

```bash
# on the build machine
./config.sh --url https://github.com/ClmentCch/risingos-tegu \
            --token <runner-token> \
            --labels self-hosted,linux,x64,android-builder-64g
./run.sh
```

Repository variables `ANDROID_ROOT` and `CCACHE_DIR` are optional (defaults
`/mnt/android/risingos-9-tegu` and `/mnt/ccache`). The workflow has **never been executed** —
no runner exists yet.

## 7c. Kernel/boot artifact caveat (R1)

`tegu-kernels` ships only module load lists; `BoardConfig-common.mk` expects `boot.img`,
`dtbo.img` and `*.ko` in `TARGET_KERNEL_DIR`. Check this immediately after sync (see
`docs/integration-review.md` §2). If the payload is absent, a clean tree is not buildable and
the extraction/population procedure must be added before any build is claimed.

## 8. Reproducing a specific build

- Device/kernel/vendor/Rising-vendor projects: pinned to full SHAs in
  `manifest/risingos-9-tegu.xml`.
- RisingOS manifest itself is consumed from branch `seventeen`. For a byte-level snapshot,
  clone `RisingOS-Revived/android` at `4197174e43f84deaadccfd8b980aeb73fb47d84d`, run
  `repo init` against that snapshot, and keep the same device SHAs.
- Record the final revisions with:
  ```bash
  repo forall -c 'echo "$REPO_PATH $(git rev-parse HEAD)"' > revs.txt
  ```
- Environment: same JDK (OpenJDK 21), same ccache state is *not* required for correctness.

## 9. Common failures and what they mean

| Symptom | Cause / fix |
| --- | --- |
| `error: Cannot remove project ...: uncommitted changes` | Local edits in the tree; revert or re-sync with `--force`. |
| `ninja: fatal: out of memory` | Below 64 GB RAM; reduce `-j`, enable ZRAM, or use a bigger host. |
| `No such file: vendor/google/tegu/tegu-vendor.mk` | Blob project not synced; check TheMuppets repo/branch, re-sync. |
| `lunch: rising_tegu is not a valid target` | `vendor/rising-tegu` missing from the tree; re-run `sync.sh`. |
| `vendor/rising/config/version.mk: No such file` | `vendor/rising` not synced or wrong branch. |
| `cat: vendor/official_devices/OTA/risingOS.devices: No such file` | Upstream `vendor/official_devices` project missing; the build still proceeds and classifies as COMMUNITY, but re-sync to silence it. |
| `boot.img` built but has no kernel / `BOARD_PREBUILT_BOOTIMAGE` empty | Kernel payload missing from `device/google/tegu-kernels/6.1` (risk R1). Do not flash the result. |
| `repo status` shows `vendor/official_devices` modified after `bacon` | Expected: Rising's `otapackage.mk` writes an OTA JSON there. Do not commit it. |
| ZIP absent after a successful `mka bacon` | Check the target used and `out/target/product/tegu/`; `package.sh` refuses to fake it. |

## 10. Clean rebuild

```bash
cd ~/android/risingos-9-tegu
make clean && make clobber
./scripts/build.sh
```
