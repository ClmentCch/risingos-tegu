# SESSION STATUS — read this first

Last updated: **2026-11-06** (session 2)

## Current phase

**Phase 3/5 — integration review + build preparation complete; Phase 6 (compilation) still
blocked by host resources.** Session 2 verified deeper upstream facts, corrected two
incorrect session-1 claims, added a CI build workflow and hardened `verify.sh`. No ROM was
compiled and no artifact exists.

## Session 2 (2026-11-06) — completed

| Area | Result |
| --- | --- |
| State check | Branch `risingos-9-tegu` at `ecf96d4`, identical to `origin`; host unchanged (2 vCPU / 3.8 GB RAM / 9.7 GB disk) → build still impossible |
| Board-config layout | Verified tegu's board config is at `device/google/tegu/tegu/BoardConfig.mk`, discovered by `build/make`'s `find -L device -maxdepth 4 -path '*/tegu/BoardConfig.mk'` (identical in LineageOS `lineage-24.0` and Rising `seventeen`); `TARGET_DEVICE_DIR` = `device/google/tegu/tegu`. Recorded in `docs/integration-review.md`. |
| Kernel sourcing | **Session-1 claim corrected**: `tegu-kernels@lineage-24.0` contains only 8 files (module load/blocklist lists + `init.insmod.tegu.cfg`) — no `boot.img`, `dtbo.img`, `Image` or `*.ko`. Board config expects those in `TARGET_KERNEL_DIR`. Vendor blob repo has none either. Added as high-severity risk **R1**. |
| Rising packaging | Verified `bacon` → `RisingOS-9-<date>-VANILLA-COMMUNITY-tegu-ota.zip` + `.sha256sum`, and that it writes an OTA JSON into `vendor/official_devices` (dirty tree expected). |
| Rising composition | Verified `frameworks/base`, `Settings`, `Launcher3` are Rising forks (`android_frameworks_base-new`, etc., remote `rising@seventeen`) — confirms the build is RisingOS, not LineageOS + apps. |
| Tooling | `verify.sh` now checks the nested board config, kernel inputs (warn), 16 KB dir, and Rising packaging identity; `config/device.json` kernel block corrected and extended. |
| CI | Added `.github/workflows/build.yml` for a 64 GB self-hosted runner (audit → setup → sync → verify → build → package → artifacts → tag-only Release). **Never executed.** |
| Docs | Added `docs/integration-review.md` (facts + risk register R1–R7); updated `kernel/README.md`, `docs/source-audit.md`, `docs/known-issues.md`, `docs/build-guide.md`, `README.md`. |

## Session 1 (2026-11-06) — completed

Repository bootstrap, environment audit (2 vCPU / 3.8 GB / 9.7 GB — below Android 17
minimums), full source research and SHA pinning, `rising_tegu` product integration, five
build scripts, four configs, initial documentation. Push `4d80a9c`, handoff `ecf96d4`.

## Not done

1. **No source sync** (~100 GB+ needed; host has 9.7 GB).
2. **No compilation** (needs 64 GB RAM / 400 GB disk).
3. **No artifacts** — no ZIP, `boot.img`, `recovery.img`; no artifact checksums.
4. **No hardware validation** — no Pixel 9a; flashing out of scope.
5. **CI workflow unexecuted** — no self-hosted runner registered.
6. **R1 unresolved** — kernel/boot payload sourcing unproven.

## Repository branches / commits

| Branch | State |
| --- | --- |
| `main` | untouched default branch (`README.md` stub, `Prompt.md`) |
| `freebuff-base` | scaffolding |
| `risingos-9-tegu` | **project branch**; session 1 pushed `4d80a9c` / `ecf96d4`, session 2 adds the integration review, corrections and CI workflow |

Last successful GitHub commit: `c09ddac` (session 2) on `risingos-9-tegu`; session 1
commits were `4d80a9c` and `ecf96d4`. Authoritative tip: `git log -1 --oneline origin/risingos-9-tegu`.

## Source revisions (pinned, unchanged)

| Project | Revision |
| --- | --- |
| `RisingOS-Revived/android` (manifest) | `seventeen` @ `4197174e43f84deaadccfd8b980aeb73fb47d84d` |
| `LineageOS/android_device_google_tegu` | `lineage-24.0` @ `0df2d90b48370375f154ac7cf0bee96d1f372074` |
| `LineageOS/android_device_google_zumapro` | `lineage-24.0` @ `c03df81e8fed84aeb4f2d26e9cef2ea5762d7c3f` |
| `LineageOS/android_device_google_tegu-kernels` | `lineage-24.0` @ `06318d991a4a688cf281d69815143a8370e503b4` |
| `TheMuppets/proprietary_vendor_google_tegu` | `lineage-24.0` @ `6840f69264a3191a3be83816b950ecec4c4d88f1` |
| `RisingOS-Revived/android_vendor_rising` | `seventeen` (tracked) |
| `RisingOS-Revived/android_vendor_lineage` | `refs/heads/seventeen` (tracked) |

## Build status

`NOT STARTED — BLOCKED`. No build log exists. `scripts/setup.sh --check-only` correctly
refuses this host; `scripts/verify.sh` correctly fails without a tree.

## Current errors / blockers

1. **Host capacity** — 3.8 GB RAM / 9.7 GB disk vs 64 GB / 400 GB required. Hard blocker.
2. **No source tree** — cannot sync for the same reason.
3. **R1 (high)** — kernel/boot artifacts absent from pinned repos; unproven that a clean
   sync yields a bootable `boot.img`. Resolve first on a capable host.
4. **R2 (high)** — `rising_tegu` has never been built; expect real first-build errors.
5. **CI unexecuted** — workflow exists but no runner has run it.

## Exact next actions (next session)

1. On a host with **64 GB RAM and ~500 GB free SSD** (or a registered
   `android-builder-64g` self-hosted runner):
   ```bash
   git clone https://github.com/ClmentCch/risingos-tegu -b risingos-9-tegu
   cd risingos-tegu
   ./scripts/setup.sh --check-only     # must pass
   ./scripts/setup.sh
   ./scripts/sync.sh
   ./scripts/verify.sh --lunch
   ```
2. **Resolve R1 first**:
   ```bash
   ls -la device/google/tegu-kernels/6.1
   ls -la out/target/product/tegu/ 2>/dev/null
   ```
   If `boot.img`/`dtbo.img`/`*.ko` are missing, determine the real population step
   (factory-image extraction or another upstream project), document it in
   `docs/integration-review.md` and wire it into `scripts/setup.sh` — do **not** flash or
   publish anything built without a verified kernel.
3. Run `./scripts/build.sh`, keep `logs/*-build.log`, fix real errors only. Update
   `docs/known-issues.md` and the risk register with what actually happened.
4. `./scripts/package.sh`; publish artifacts as GitHub Release assets with
   `checksums.sha256` (never commit them).
5. Record `repo forall -c 'echo "$REPO_PATH $(git rev-parse HEAD)"'` and the build outcome
   here, then update `docs/integration-review.md`.
6. Only with a physical Pixel 9a: `docs/installation.md`, then replace "untested" claims
   with measured `getprop` output.

## Resume protocol

Read this file → `AI_INSTRUCTIONS.md` → `docs/integration-review.md` (risk register) →
`docs/source-audit.md`. Do not redo the research; revisions are pinned and the layout facts
are verified. Verify the environment first; if it still cannot build, continue with
documentation/patch work rather than claiming a build.
