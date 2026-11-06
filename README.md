# RisingOS 9 tegu

Unofficial **RisingOS Revived 9** build project for the **Google Pixel 9a** (`tegu`, Google Tensor G4, arm64), based on Android 17 / LineageOS `lineage-24.0`.

> **Status: integration + build tooling complete, ROM not compiled yet.**
> The current Cloud build environment has 2 vCPU / 3.8 GB RAM / ~9.7 GB free disk.
> LineageOS requires **64 GB RAM and 400 GB+ storage** for Android 17 (`lineage-21` and newer).
> No ROM, recovery image or installable ZIP has been produced, and nothing has been flashed to a device.
> See [docs/SESSION_STATUS.md](docs/SESSION_STATUS.md) for the exact state and next actions.

This project is **not** an official RisingOS release and is not affiliated with the RisingOS
team, LineageOS, or Google. It is a community/unofficial integration maintained in this
repository.

## What this repository is

This repository is the **project hub**, not a copy of the Android tree. It contains:

| Path | Purpose |
| --- | --- |
| `manifest/` | Repo local manifest pinning every upstream project (RisingOS, LineageOS tegu, kernel, vendor blobs) and this project. |
| `vendor/rising-tegu/` | The device integration itself: `AndroidProducts.mk` + `rising_tegu.mk`. Checked out into the Android tree at `vendor/rising-tegu`, where Soong/product-config auto-discovers it. |
| `config/` | Machine-readable project, device, build and source metadata (JSON). |
| `scripts/` | Reproducible `setup.sh`, `sync.sh`, `verify.sh`, `build.sh`, `package.sh`. |
| `device/`, `kernel/` | Documentation of the upstream device/kernel inputs, pinned revisions and why no files are copied here. |
| `patches/` | Patch policy and any downstream patches (currently none required — see `patches/README.md`). |
| `docs/` | Architecture, source audit, compatibility matrix, build guide, installation, known issues, session status. |
| `output/`, `logs/` | Runtime artifact and log directories (contents are git-ignored). |

The full Android source tree (~100 GB+) is **never** committed here. It is fetched with
`repo` from the pinned upstreams.

## Verified upstreams (checked at project creation)

| Component | Repository | Revision |
| --- | --- | --- |
| RisingOS manifest + fork overlay | `RisingOS-Revived/android` | `seventeen` @ `4197174e43f84deaadccfd8b980aeb73fb47d84d` |
| RisingOS vendor layer | `RisingOS-Revived/android_vendor_rising` | `seventeen` (Rising 9, `CinnamonBun`) |
| Pixel 9a device tree | `LineageOS/android_device_google_tegu` | `lineage-24.0` @ `0df2d90b48370375f154ac7cf0bee96d1f372074` |
| Tensor G4 common platform | `LineageOS/android_device_google_zumapro` | `lineage-24.0` @ `c03df81e8fed84aeb4f2d26e9cef2ea5762d7c3f` |
| Prebuilt kernel 6.1 | `LineageOS/android_device_google_tegu-kernels` | `lineage-24.0` @ `06318d991a4a688cf281d69815143a8370e503b4` |
| Proprietary blobs | `TheMuppets/proprietary_vendor_google_tegu` | `lineage-24.0` @ `6840f69264a3191a3be83816b950ecec4c4d88f1` |

Details and verification method: [docs/source-audit.md](docs/source-audit.md).

## Integration approach

RisingOS is the **software layer** (framework, SystemUI, Settings, customization panels,
Quick Settings, lock screen, themes, system apps). LineageOS `tegu` is the **device
foundation** (device tree, kernel, vendor blobs, HALs, init, recovery).

The device tree is *not* modified: the Rising product inherits
`device/google/tegu/lineage_tegu.mk` (which inherits
`vendor/lineage/config/common_full_phone.mk`) and then inherits
`vendor/rising/config/rising.mk` to pull in the RisingOS component set, then re-declares
the product identity as `rising_tegu`. That is a real RisingOS product, not "LineageOS
plus Rising apps": the framework/SystemUI/Settings/launcher in the build come from the
RisingOS forks pinned by the Rising manifest.

## Quick start (on a machine that meets the requirements)

```bash
git clone https://github.com/ClmentCch/risingos-tegu -b risingos-9-tegu
cd risingos-tegu
./scripts/setup.sh --check-only     # audits RAM/disk/tools; fails clearly if underpowered
./scripts/setup.sh                  # installs repo, initialises RisingOS seventeen, local manifest
./scripts/sync.sh                   # repo sync (~100 GB+)
./scripts/verify.sh                 # verifies tree, product resolution, device identity
./scripts/build.sh                  # lunch rising_tegu-userdebug && mka bacon
./scripts/package.sh                # collects artifacts + SHA-256 checksums in output/
```

Full instructions: [docs/build-guide.md](docs/build-guide.md).

## Licensing and proprietary files

Upstream licenses are respected. This repository contains only original configuration,
scripts and documentation (Apache-2.0, see `LICENSE`). Proprietary Pixel 9a blobs are
**not** redistributed here; they are fetched from `TheMuppets/proprietary_vendor_google_tegu`
(LineageOS's extraction-based mirror). Builders are responsible for complying with the
licenses of any firmware or proprietary component they use.

Google apps are **not** bundled by default (`WITH_GMS := false`), because redistributing
them is not permitted. Builders may opt in locally; that choice is not covered by this
project's licensing.
