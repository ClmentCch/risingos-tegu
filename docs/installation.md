# Installation — RisingOS 9 tegu (unofficial)

> **No installable build exists yet.** This document describes the procedure for when a ZIP
> and images are produced. Nothing here has been executed on a physical Pixel 9a by this
> project. Flashing an unofficial ROM voids warranties, can brick the device, and wipes all
> data. You proceed at your own risk.

## Prerequisites

1. **Google Pixel 9a (`tegu`)**, bootloader unlockable (carrier-locked units may not be).
2. **Stock Android 17 firmware** at least as new as `CP3A.261005.005` (the fingerprint the
   device tree builds against). Update via Google's factory images/OTA before starting.
3. A computer with `adb` and `fastboot` (platform-tools), a good USB-C cable.
4. The build artifacts: `RisingOS-*.zip`, `boot.img`, `recovery.img`, `vendor_boot.img`,
   `dtbo.img` (from `output/<stamp>/`), with `checksums.sha256` verified:
   ```bash
   sha256sum -c checksums.sha256
   ```
5. A full backup: unlocking/installing wipes user data.

## Unlock the bootloader

```bash
adb reboot bootloader
fastboot flashing unlock          # confirm on the device
```

## Install LineageOS recovery

```bash
fastboot flash boot boot.img
fastboot flash vendor_boot vendor_boot.img
fastboot flash dtbo dtbo.img
fastboot reboot recovery
```

## Sideload the ROM

In recovery: **Factory reset → Format data/factory reset** (required when coming from stock
or another ROM), then:

```bash
adb sideload RisingOS-9-tegu-<date>.zip
```

If the package installs a newer recovery, reboot to recovery once and re-apply the zip.

## First boot

- Expect 5–15 minutes on first boot; the device may reboot once while optimising apps.
- If it loops: re-flash stock firmware, verify you used the correct `tegu` artifacts, and
  check the build log for the failing component.

## Returning to stock

Download the matching Pixel 9a factory image from Google, then:

```bash
fastboot flashall -w
```

## What will not work (expected)

- Google Play Services / Play Store (not bundled; `WITH_GMS := false`).
- Hardware-backed attestation: Play Integrity `MEETS_STRONG_INTEGRITY` will fail; some
  banking, streaming and DRM apps may refuse to run.
- Official RisingOS OTA updates (this is a community build without an OTA server).
- Relocking the bootloader on an unofficial build will brick or refuse to boot; do not
  relock unless you have restored fully signed stock firmware.

## Verification after flashing (when hardware testing is possible)

```bash
adb shell getprop ro.build.version.release     # 17
adb shell getprop ro.build.product             # tegu
adb shell getprop ro.product.device            # tegu
adb shell getprop ro.rising.version            # 9
adb shell getprop ro.rising.chipset            # Google Tensor G4
adb shell getprop ro.rising.maintainer         # ClmentCch
adb shell getprop ro.rising.buildtype          # COMMUNITY
```

Record the actual results in `docs/SESSION_STATUS.md`. Do not claim boot success without it.
