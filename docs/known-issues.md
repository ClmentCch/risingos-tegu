# Known issues

Status legend: **BLOCKED** = cannot proceed in this environment, **UNTESTED** = implemented
but never executed, **OPEN** = known limitation.

## Build-blocking

| # | Issue | Status | Detail / mitigation |
| --- | --- | --- | --- |
| 1 | No ROM has been compiled | **BLOCKED** | Authoring host: 2 vCPU, 3.8 GB RAM, 9.7 GB free disk. Android 17 needs 64 GB RAM and 400 GB disk. `scripts/setup.sh --check-only` reports this and exits non-zero. Use a capable host (bare metal or 64 GB+ CI runner). |
| 2 | RisingOS manifest consumed from a branch | **OPEN** | `repo init -b seventeen` is a moving reference. For byte-reproducible builds, snapshot the manifest at `4197174e43f84deaadccfd8b980aeb73fb47d84d`. |
| 3 | `vendor/lineage` not SHA-pinned | **OPEN** | Defined by the Rising manifest at `refs/heads/seventeen`; a local SHA pin would conflict. Upstream branch movement can change the build. |
| 4 | No verified `rising_tegu` build exists upstream | **OPEN** | tegu is not in RisingOS `official_devices`; this integration is first-of-its-kind and may surface real compile errors (missing overlays, package conflicts) on the first build. Those must be fixed honestly, not papered over. |
| 4b | Kernel/boot artifacts missing from pinned repos (R1) | **OPEN — HIGH** | `tegu-kernels@lineage-24.0` ships only 8 files (module lists + `init.insmod.tegu.cfg`), but `BoardConfig-common.mk` expects `boot.img`, `dtbo.img` and `*.ko` under `TARGET_KERNEL_DIR`; neither it nor the vendor blob repo contains them. Whether a clean sync can produce a bootable `boot.img` is unproven. Resolve before trusting any build; see `docs/integration-review.md` §2. |
| 4c | Board config is not at `device/google/tegu/BoardConfig.mk` | **DOCUMENTED** | It lives at `device/google/tegu/tegu/BoardConfig.mk`; `TARGET_DEVICE_DIR` is therefore `device/google/tegu/tegu`. `verify.sh` now checks this layout. |

## Hardware / functional

| # | Issue | Status | Detail |
| --- | --- | --- | --- |
| 5 | Boot not tested on a Pixel 9a | **UNTESTED** | No physical device access. Do not claim it boots. |
| 6 | Play Integrity / attestation fails | **OPEN** | Unofficial builds cannot pass hardware-backed verification; banking/DRM apps may break. |
| 7 | No Google apps | **OPEN (by design)** | `WITH_GMS := false` because redistribution is not permitted. Builders may opt in locally, at their own legal risk. |
| 8 | OTA updates | **OPEN** | No OTA server, no maintainer keys, `vendor/official_devices` does not list tegu. |
| 9 | Firmware mismatch risk | **OPEN** | The kernel/DTBO/vendor blobs assume firmware ≥ `CP3A.261005.005`. Flashing over older firmware can produce a non-booting device. |
| 10 | 16 KB page-size configuration | **UNTESTED** | Device tree sets `PRODUCT_16K_DEVELOPER_OPTION` when not booting 16 KB kernels; behaviour on tegu is unverified. |
| 11 | Signing | **OPEN** | Test-keys by default. Release builds need a private key set that must never enter this repository. |

## Tooling

| # | Issue | Status | Detail |
| --- | --- | --- | --- |
| 12 | `scripts/verify.sh --lunch` needs a synced tree | **BY DESIGN** | Without the tree it reports missing paths and exits non-zero — this is correct behaviour, not a bug. |
| 13 | `sync.sh` takes hours | **BY DESIGN** | 100 GB+ download; run under `tmux`/`nohup` and keep the log in `logs/`. |
| 14 | No CI pipeline | **OPEN** | A 64 GB/400 GB runner with ccache is required; GitHub-hosted runners are far too small. |

## Reporting a new issue

Add a row above with: symptom, exact command, log excerpt (real, unedited), the pinned
revision in use, and whether it reproduces after `make clobber`. Then update
`docs/SESSION_STATUS.md`.
