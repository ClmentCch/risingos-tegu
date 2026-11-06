# device/ — Pixel 9a device inputs

No device sources are copied into this repository. They are fetched and pinned by
`manifest/risingos-9-tegu.xml`.

## Required projects

| Tree path | Upstream | Branch | Pinned SHA |
| --- | --- | --- | --- |
| `device/google/tegu` | `LineageOS/android_device_google_tegu` | `lineage-24.0` | `0df2d90b48370375f154ac7cf0bee96d1f372074` |
| `device/google/zumapro` | `LineageOS/android_device_google_zumapro` | `lineage-24.0` | `c03df81e8fed84aeb4f2d26e9cef2ea5762d7c3f` |
| `device/google/tegu-kernels` | `LineageOS/android_device_google_tegu-kernels` | `lineage-24.0` | `06318d991a4a688cf281d69815143a8370e503b4` |
| `vendor/google/tegu` | `TheMuppets/proprietary_vendor_google_tegu` | `lineage-24.0` | `6840f69264a3191a3be83816b950ecec4c4d88f1` |

## What the tegu tree provides (verified from `lineage-24.0`)

- `aosp_tegu.mk`, `lineage_tegu.mk`, `AndroidProducts.mk`
- `device-tegu.mk` — kernel wiring, 16 KB page-size developer option, shipping API level
  35, zumapro common include, HIDL services, overlays, preinstalled package sysconfig,
  product/vendor props, recovery init, satellite permission
- `extract-files.py` + `lineage.dependencies` (zumapro, tegu-kernels)
- Display/NFC/DMService/SafetyRegulatory/Settings/SystemUI overlays, `board-info.txt`
- `TARGET_KERNEL_DIR := device/google/tegu-kernels/6.1`
- `TARGET_KERNEL_PLATFORM_SOURCE := google/gs-6.1`
- Build identity from the tree, e.g. fingerprint
  `google/tegu/tegu:17/CP3A.261005.005/16271449:user/release-keys`

## Rules

- Never substitute `akita` (Pixel 8a) or any other device's files. `scripts/verify.sh`
  fails if `device/google/akita` appears in the tree.
- Do not hand-edit synced device sources. If a device-level change is genuinely required,
  add a documented patch under `patches/device/` and apply it in `scripts/sync.sh`.
- Firmware: the device must be on a stock Android 17 build at least as new as the
  fingerprint above before installing; see `docs/installation.md`.
