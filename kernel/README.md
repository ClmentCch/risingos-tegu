# kernel/ — Tensor G4 kernel integration

## What is actually in the pinned kernel repository

| Item | Value |
| --- | --- |
| Repository | `LineageOS/android_device_google_tegu-kernels` |
| Branch | `lineage-24.0` |
| Pinned SHA | `06318d991a4a688cf281d69815143a8370e503b4` |
| Tree path | `device/google/tegu-kernels` |
| Kernel dir used by build | `device/google/tegu-kernels/6.1` (`TARGET_KERNEL_DIR`) |
| Declared in | `device/google/tegu/device-tegu.mk` |
| Platform kernel source ref | `google/gs-6.1` (`TARGET_KERNEL_PLATFORM_SOURCE`) |
| Linux version | 6.1 |

The repository contains **8 tracked files, all under `6.1/`**: `init.insmod.tegu.cfg`,
`modules.load`, `system_dlkm.modules.load`, `system_dlkm.modules.blocklist`,
`vendor_dlkm.modules.load`, `vendor_dlkm.modules.blocklist`, `vendor_kernel_boot.modules.load`,
plus `.gitignore`.

It contains **no `boot.img`, no `dtbo.img`, no `Image`/`Image.lz4` and no `*.ko` modules.**
The vendor blob repository does not contain them either (verified: the firmware lists cover
`abl/bl1/bl2/bl31/gcf/gsa/ldfw/modem/pbl/tzsw` only).

## What the build expects

From `device/google/zumapro/BoardConfig-common.mk` (included by tegu's board config):

```make
TARGET_NO_KERNEL := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_PREBUILT_BOOTIMAGE := $(wildcard $(TARGET_KERNEL_DIR)/boot.img)
BOARD_PREBUILT_DTBIMAGE_DIR := $(TARGET_KERNEL_DIR)
BOARD_PREBUILT_DTBOIMAGE := $(BOARD_PREBUILT_DTBIMAGE_DIR)/dtbo.img
KERNEL_MODULES := $(wildcard $(KERNEL_MODULE_DIR)/*.ko)
```

So the Android build consumes a prebuilt boot image, DTBO and kernel modules from
`device/google/tegu-kernels/6.1`. With the pinned repositories as-is, those files are
missing and the wildcards expand to nothing.

## Status: open verification item (high risk)

It is **not yet established** whether a clean `repo sync` of the pinned tree can produce a
bootable `boot.img`. Two possibilities remain:

1. the kernel payload is populated by a step not visible in the pinned makefiles
   (factory-image/device extraction), or
2. a clean sync is insufficient for a bootable build.

The tegu `extract-files.py` is factory-image based (`extract_pixel_factory_image`,
`extract_pixel_firmware`), and the LineageOS wiki instructs running extraction from a device
or factory image. This is exactly what must be checked first on a synced tree:

```bash
ls -la device/google/tegu-kernels/6.1
ls -la device/google/tegu/tegu/          # BoardConfig.mk, product.prop, extract-files.py
grep -n "BOOTIMAGE\|DTBOIMAGE\|KERNEL_MODULES" device/google/zumapro/BoardConfig-common.mk
```

Then after a build:

```bash
ls -la out/target/product/tegu/boot.img out/target/product/tegu/dtbo.img \
       out/target/product/tegu/vendor_boot.img
```

`scripts/verify.sh` now reports missing kernel inputs explicitly. Treat R1 in
`docs/integration-review.md` as the first thing to resolve in the next build session.

## Why no kernel source tree is pinned

- LineageOS's tegu build path is prebuilt-kernel based (`TARGET_NO_KERNEL := true`), not a
  from-source kleaf build; no `TARGET_KERNEL_SOURCE`/`TARGET_KERNEL_CONFIG` is declared.
- Rebuilding the Tensor G4 kernel would require Google's kernel sources, toolchain and
  configs outside the LineageOS tegu build path, and would not improve reproducibility of
  the documented build.

## Device-side requirements

- Bootloader unlocked.
- Stock firmware at least as new as `CP3A.261005.005` / `BOOT_SECURITY_PATCH 2026-10-05`.
- Unofficial builds cannot pass Google hardware-backed attestation (banking/DRM caveat).

## If a custom kernel is added later

1. Pin the kernel source repo to a full SHA in `manifest/risingos-9-tegu.xml`.
2. Set `TARGET_KERNEL_SOURCE`/`TARGET_KERNEL_CONFIG` via a documented patch, and add the
   prebuilt artifacts or build rules to `TARGET_KERNEL_DIR`.
3. Re-run `scripts/verify.sh`, record results in `docs/SESSION_STATUS.md` and update R1.
