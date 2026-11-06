# Integration review — verified facts and risk register (session 2)

Second-pass review of the integration against the pinned upstream files, performed on
2026-11-06 without a synced tree. Everything below was read from the pinned revisions, not
assumed. Where a fact could not be resolved without a full tree, it is marked as an open
verification item rather than stated as a conclusion.

## 1. Board configuration layout (corrected understanding)

The tegu device tree does **not** have a top-level `BoardConfig.mk`. The board config lives
one level deeper:

```
device/google/tegu/tegu/BoardConfig.mk
device/google/tegu/tegu/product.prop
device/google/tegu/tegu/vendor.prop
device/google/tegu/tegu/extract-files.py
device/google/tegu/tegu/proprietary-{files,files-vendor,firmware}.txt
device/google/tegu/tegu/{setup-makefiles.py,osaifu-keitai.patch}
device/google/tegu/wifi/BoardConfig-wifi.mk
```

This is valid because `build/make/core/board_config.mk` (both LineageOS `lineage-24.0` and
RisingOS `seventeen`, verified line-for-line identical in the relevant block) discovers the
board config with:

```make
board_config_mk := $(TARGET_DEVICE_DIR)/BoardConfig.mk
...
$(shell test -d device && find -L device -maxdepth 4 -path '*/$(TARGET_DEVICE)/BoardConfig.mk')
```

`device/google/tegu/tegu/BoardConfig.mk` matches `*/tegu/BoardConfig.mk` at depth 4, so
`TARGET_DEVICE_DIR` becomes `device/google/tegu/tegu`. The board config then uses
`DEVICE_PATH` = `device/google/tegu` (set by the product makefile before board config
evaluation) for `board-info.txt`, sepolicy, recovery module lists and the WiFi config.

**Consequence for this project:** `TARGET_DEVICE_DIR` is *not* `device/google/tegu`. Any
script or documentation that assumes `$(TARGET_DEVICE_DIR)/product.prop` is wrong. Our
product makefile does not reference `TARGET_DEVICE_DIR`, so no change is required; the fact
is recorded to prevent future mistakes.

Verified contents of `tegu/BoardConfig.mk`:

- `TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/board-info.txt` (`require board=tegu`)
- `TARGET_BOOTLOADER_BOARD_NAME := tegu`, `TARGET_SCREEN_DENSITY := 420`
- `BOOT_SECURITY_PATCH := 2026-10-05`, `VENDOR_SECURITY_PATCH` same
- `include device/google/zumapro/BoardConfig-common.mk`
- vendor kernel ramdisk module blocklist/load lists from `recovery/`
- sepolicy dirs incl. `hardware/google/pixel-sepolicy/vibrator/{common,cs40l26}`
- `include wifi/BoardConfig-wifi.mk`
- `include $(VENDOR_PATH)/BoardConfigVendor.mk`

## 2. Kernel and boot image sourcing — open verification item

Facts read from the pinned revisions:

| Fact | Source |
| --- | --- |
| `TARGET_NO_KERNEL := true`, `BOARD_USES_GENERIC_KERNEL_IMAGE := true` | `zumapro/BoardConfig-common.mk` |
| `BOARD_PREBUILT_BOOTIMAGE := $(wildcard $(TARGET_KERNEL_DIR)/boot.img)` | `zumapro/BoardConfig-common.mk` |
| `BOARD_PREBUILT_DTBOIMAGE := $(TARGET_KERNEL_DIR)/dtbo.img` | `zumapro/BoardConfig-common.mk` |
| `KERNEL_MODULES := $(wildcard $(TARGET_KERNEL_DIR)/*.ko)` | `zumapro/BoardConfig-common.mk` |
| `TARGET_KERNEL_DIR := device/google/tegu-kernels/6.1` | `tegu/device-tegu.mk` |
| `tegu-kernels/6.1` contains **only** module load/blocklist lists and `init.insmod.tegu.cfg` (8 tracked files total, no `boot.img`, no `dtbo.img`, no `*.ko`) | `git ls-tree` of `LineageOS/android_device_google_tegu-kernels@lineage-24.0` |
| Vendor blob repo contains no `boot.img`/`Image*`/`dtbo.img` either (3074 files, firmware images are bootloader/modem only) | `git ls-tree` of `TheMuppets/proprietary_vendor_google_tegu@lineage-24.0`; `proprietary-firmware.txt` lists `abl/bl1/bl2/bl31/gcf/gsa/ldfw/modem/pbl/tzsw` |
| Extraction is factory-image based (`extract_pixel_factory_image`, `extract_pixel_firmware`), and the wiki requires a device/factory image | `tegu/extract-files.py`, LineageOS wiki |

**Interpretation (not yet proven):** with an empty `TARGET_KERNEL_DIR` kernel payload,
`BOARD_PREBUILT_BOOTIMAGE` and `BOARD_PREBUILT_DTBOIMAGE` resolve to non-existent paths and
`KERNEL_MODULES` is empty. Either (a) the build extracts/produces those artifacts through a
step not visible from the pinned makefiles, or (b) a clean `repo sync` tree is not sufficient
to produce a bootable `boot.img`. This must be settled on a synced tree before any build is
trusted:

```bash
ls -la  device/google/tegu-kernels/6.1
ls -la  device/google/tegu/tegu/
grep -rn "BOOTIMAGE\|DTBOIMAGE" device/google/zumapro/BoardConfig-common.mk
# after a build:
ls -la  out/target/product/tegu/{boot.img,dtbo.img,vendor_boot.img}
```

`scripts/verify.sh` now reports the presence/absence of these kernel inputs explicitly and
fails if the board config layout is not the verified one.

## 3. RisingOS packaging identity (verified)

From `vendor/rising/config/version.mk` and `build/tasks/otapackage.mk`:

- `RISING_VERSION := 9`, `RISING_BUILDTYPE` for tegu = `COMMUNITY`
  (not in `vendor/official_devices/OTA/risingOS.devices`)
- `RISING_PACKAGE_TYPE` = `VANILLA` when `WITH_GMS != true` and `WITH_MICROG != true`
- `RISING_BUILD_VERSION := 9-<YYMMDD-HHMM>-VANILLA-COMMUNITY-tegu`
- `bacon` produces `out/target/product/tegu/RisingOS-9-…-ota.zip`, a `.sha256sum` file,
  and copies an OTA JSON to `vendor/official_devices/OTA/device/VANILLA/tegu.json`

Implications for this project:

1. `scripts/package.sh`'s `RisingOS-*.zip` glob matches the real artifact name. It also
   copies the ZIP's neighbouring `.sha256sum` only if the file matches the image list —
   it does not, so the package script generates its own `checksums.sha256`. That is correct
   and stricter than upstream.
2. `bacon` writes into `vendor/official_devices/...`. The Rising manifest pins that project
   (branch `fifteen`), so the directory exists, but the write dirties a synced project.
   Builders should expect `repo status` to show a modified `vendor/official_devices` after
   packaging. This is upstream behaviour, not a project bug.
3. Our docs must quote `VANILLA-COMMUNITY` as the expected package type, not "unofficial".

## 4. RisingOS layer composition (verified)

`frameworks/base`, `packages/apps/Settings` and `packages/apps/Launcher3` are all replaced by
Rising forks in `snippets/rising.xml` (`android_frameworks_base-new`,
`android_packages_apps_Settings`, `android_packages_apps_Launcher3`, remote `rising`,
revision `seventeen`). This confirms the central claim of the project: the build is RisingOS
software, not LineageOS plus Rising apps.

`vendor/rising/config/packages.mk` adds system_ext packages (OmniStyle, OmniJaws, Updater,
GameSpace, LMOFreeform, AxQuickLook, AxSandbox, AppDataBackup, BatteryStatsViewer, …) and
`LatinIME` when GMS is off. `rising.mk` additionally adds RisingWalls, BtHelper,
ColumbusService, the adblock init script and freeform/SIP permissions.

## 5. Risk register

| # | Risk | Severity | Evidence | Mitigation |
| --- | --- | --- | --- | --- |
| R1 | Kernel/boot artifacts absent from pinned repos | **High** | `tegu-kernels` has 8 files, no `boot.img`/`dtbo.img`/`*.ko`; BoardConfig expects them | Verify on synced tree (`§2`); if absent, document the extraction procedure and add it to `setup.sh`; do not claim a build until `boot.img` is produced and inspected |
| R2 | `rising_tegu` product never built upstream | **High** | tegu not in `official_devices`; no Rising build for this device exists | First build on capable host; fix real errors only |
| R3 | Rising `bacon` dirties `vendor/official_devices` | Low | `otapackage.mk` copies JSON into it | Expect it; do not commit that change |
| R4 | Nested board config surprises scripts | Medium | `TARGET_DEVICE_DIR=device/google/tegu/tegu` | Now checked by `verify.sh`; documented here |
| R5 | Firmware/security patch baseline `2026-10-05` | Medium | `tegu/BoardConfig.mk` | Device must run stock firmware at least that new; documented in install guide |
| R6 | 16 KB page size path | Medium | `BoardConfig-16k-common.mk` uses `TARGET_KERNEL_DIR/16kb` if present; `tegu-kernels` has no `16kb/` | Build uses 4 KB path; document that 16 KB mode is unavailable from pinned sources |
| R7 | GMS-disabled build differs from Rising's default | Low | `WITH_GMS := false` in our product | Intentional (licensing); recorded in `known-issues.md` |

## 6. What changed as a result of this review

- `kernel/README.md` corrected: it no longer claims kernel binaries ship in `tegu-kernels`.
- `config/device.json` kernel block now states what is and is not present in the pinned repos.
- `scripts/verify.sh` gained board-config and kernel-artifact checks.
- CI workflow added (`.github/workflows/build.yml`) for a 64 GB self-hosted runner.
- Risk register above is the authoritative pre-build checklist.
