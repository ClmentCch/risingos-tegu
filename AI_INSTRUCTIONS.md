# AI_INSTRUCTIONS — read this first, then `docs/SESSION_STATUS.md`

Operating rules for any agent continuing **RisingOS 9 tegu**.

## 1. Start of every session

1. Read `docs/SESSION_STATUS.md` (state, blockers, exact next actions).
2. Read `docs/source-audit.md` (verified upstreams + pinned revisions).
3. Audit the environment **before** downloading anything:
   ```bash
   nproc; free -h; df -h .; command -v repo git java python3 ccache
   ```
4. Compare against the hard minimums: **64 GB RAM, 400 GB free disk, 16+ cores**
   (LineageOS requirements for Android 17 / `lineage-21`+). If the host is below that,
   do **not** start a sync or build: continue with configuration, documentation,
   verification and patch work, and record the limitation.

## 2. Never do these

- Never claim a build, package or boot succeeded without the real artifact/log.
- Never fabricate commit SHAs, repository URLs, test results or logs.
- Never use `akita` (Pixel 8a) or another device's tree/vendor files for `tegu`.
- Never commit proprietary blobs, signing keys, tokens or credentials.
- Never flash a physical device; never run `fastboot flash`/`fastboot oem` here.
- Never copy the full Android tree into this repository.
- Never modify unrelated repositories or force-push branches other chats use.

## 3. Source rules

- RisingOS manifest: `https://github.com/RisingOS-Revived/android` branch `seventeen`
  (`repo init -u ... -b seventeen --git-lfs`).
- Device baseline: `LineageOS/android_device_google_tegu@lineage-24.0`.
- Required siblings: `LineageOS/android_device_google_zumapro@lineage-24.0`,
  `LineageOS/android_device_google_tegu-kernels@lineage-24.0`,
  `TheMuppets/proprietary_vendor_google_tegu@lineage-24.0`.
- Any revision change must update **both** `manifest/risingos-9-tegu.xml` and
  `config/sources.json`, and be recorded in `docs/source-audit.md`.
- Verify a repository/branch really exists before pinning it (`git ls-remote`), never guess.

## 4. Integration rules

- The Rising product is `vendor/rising-tegu/rising_tegu.mk`, product name `rising_tegu`.
- Preserve the entire inheritance chain from `device/google/tegu/lineage_tegu.mk`; do not
  reimplement device configuration in this repository.
- Do not fork or patch upstream framework/SystemUI/Settings unless a real build error
  requires it. If a patch is needed: put it in `patches/<area>/`, make it a real
  `git format-patch`-style diff with context, document why, and add it to
  `scripts/verify.sh`/`sync.sh` application logic and to `patches/README.md`.
- Keep `WITH_GMS := false` by default (no Google app redistribution).

## 5. Working method

- Work in small, verifiable increments; run `bash -n` on scripts and JSON/XML lint on
  configs after edits.
- Commit with meaningful messages and push to `risingos-9-tegu` after every completed
  stage (never accumulate a whole session unsaved).
- Update `docs/SESSION_STATUS.md` at the end of every session: phase, done, not done,
  branches, revisions, changed files, last commit, build status, errors, blockers, next
  actions. It must let the next session resume without redoing work.

## 6. Build/package expectations

- Build: `. build/envsetup.sh && lunch rising_tegu-userdebug && mka bacon` (see
  `scripts/build.sh`). RisingOS also ships a `rise`/`riseup` wrapper; `mka` is the
  canonical path used here.
- Artifacts: `out/target/product/tegu/` (ZIP, `boot.img`, `recovery.img`,
  `vendor_boot.img`, `dtbo.img`).
- Package: `scripts/package.sh` copies artifacts to `output/<UTC timestamp>/`, writes
  `checksums.sha256` and `metadata.json`; large artifacts stay out of git.
