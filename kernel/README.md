# kernel/ — Tensor G4 kernel integration

## What is used

The Pixel 9a uses a **prebuilt** Linux 6.1 kernel from the LineageOS kernel repository,
not a kernel compiled from this project:

| Item | Value |
| --- | --- |
| Repository | `LineageOS/android_device_google_tegu-kernels` |
| Branch | `lineage-24.0` |
| Pinned SHA | `06318d991a4a688cf281d69815143a8370e503b4` |
| Tree path | `device/google/tegu-kernels` |
| Kernel dir used by build | `device/google/tegu-kernels/6.1` |
| Declared in | `device/google/tegu/device-tegu.mk` |
| Platform kernel source ref | `google/gs-6.1` (`TARGET_KERNEL_PLATFORM_SOURCE`) |
| Linux version | 6.1 (`TARGET_LINUX_KERNEL_VERSION := 6.1`) |
| 16 KB page option | `PRODUCT_16K_DEVELOPER_OPTION := true` when `TARGET_BOOTS_16K != true` |

The prebuilt artifacts (`Image`, `Image.lz4`, DTB/DTBO fragments and the vendor ramdisk
inputs) are consumed by the Android build when generating `boot.img` / `vendor_boot.img`.
The kernel is **not** rebuilt from source in this project, and no kernel patches are
carried here.

## Why no kernel source tree is pinned

- LineageOS ships the tegu kernel as prebuilt binaries in `tegu-kernels`, which is what
  the device tree references. Rebuilding from `google/gs-6.1` would require the proprietary
  Google toolchain and configs and is not part of the LineageOS tegu build path.
- Adding an unpinned kernel source tree would break reproducibility without changing the
  output.

## Kernel-side requirements on the device

- Bootloader must be unlocked (`fastboot flashing unlock`).
- The device must run firmware matching or newer than the LineageOS tegu baseline
  (`CP3A.261005.005`, Android 17) so the prebuilt kernel, DTBO and vendor HALs match.
- Verified boot / AVB: an unofficial build cannot pass Google's hardware-backed attestation.
  Some banking/DRM apps will refuse to run. This is expected and documented in
  `docs/known-issues.md`.

## If a custom kernel is added later

1. Pin the kernel source repo to a full SHA in `manifest/risingos-9-tegu.xml`.
2. Set `TARGET_KERNEL_SOURCE`/`TARGET_KERNEL_CONFIG` in a `patches/device/` patch and
   document the change.
3. Re-run `scripts/verify.sh` and record results in `docs/SESSION_STATUS.md`.
