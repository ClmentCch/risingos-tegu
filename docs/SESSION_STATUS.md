# SESSION STATUS — read this first

Last updated: **2026-11-06** (session 1)

## Current phase

**Phase 3 — device integration + tooling complete; Phase 6 (compilation) blocked by host
resources.** The repository contains a real, pinned source manifest, a real RisingOS product
integration, working build tooling and complete documentation. No ROM was compiled.

## Completed this session

| Area | Result |
| --- | --- |
| Repository inspection | `ClmentCch/risingos-tegu`, remote `origin`, default branch `main`, empty except `README.md` + `Prompt.md`; branch `risingos-9-tegu` created for this project |
| Environment audit | Ubuntu 24.04.5 x86_64 (KVM), 2 vCPU, 3.8 GB RAM, 9.7 GB free disk; `repo`/`java`/`ccache`/`bc`/`bison`/`flex`/`schedtool` absent → **build impossible** |
| Source research | RisingOS manifest + vendor layer, LineageOS tegu + zumapro + kernel, TheMuppets vendor blobs, all verified with `git ls-remote` and raw file reads (`docs/source-audit.md`) |
| Manifest | `manifest/risingos-9-tegu.xml` — full-SHA pins for tegu, zumapro, tegu-kernels, vendor blobs, `vendor/rising`; branch pin for `vendor/lineage` |
| Device integration | `vendor/rising-tegu/{AndroidProducts.mk,rising_tegu.mk}` — `rising_tegu` product inheriting LineageOS tegu then RisingOS 9 |
| Configuration | `config/{project,device,build,sources}.json` |
| Scripts | `setup.sh`, `sync.sh`, `verify.sh`, `build.sh`, `package.sh` (strict mode, resource guards, logging, checksums) |
| Documentation | `README.md`, `PROJECT_SPEC.md`, `AI_INSTRUCTIONS.md`, `docs/{architecture,source-audit,compatibility,build-guide,installation,known-issues}.md`, `patches/README.md`, `device/README.md`, `kernel/README.md` |
| Patch analysis | Concluded no upstream source patches are required for this layering; documented policy in `patches/README.md` instead of fabricating patches |

## Not done

1. **No source sync** — would require ~100 GB+; host has 9.7 GB.
2. **No compilation** — impossible on this host (needs 64 GB RAM / 400 GB disk).
3. **No artifacts** — no ZIP, no `boot.img`, no `recovery.img`, no checksums of a build.
4. **No hardware validation** — no Pixel 9a available and flashing is out of scope.
5. **No GitHub Release** — nothing large enough exists to warrant one yet.

## Repository branches

| Branch | State |
| --- | --- |
| `main` | untouched upstream/default branch (`README.md` stub, `Prompt.md`) |
| `freebuff-base` | scaffolding |
| `risingos-9-tegu` | **this project** — all files listed above; push succeeded (`4d80a9c`) |

## Source revisions (pinned)

| Project | Revision |
| --- | --- |
| `RisingOS-Revived/android` (manifest) | `seventeen` @ `4197174e43f84deaadccfd8b980aeb73fb47d84d` |
| `LineageOS/android_device_google_tegu` | `lineage-24.0` @ `0df2d90b48370375f154ac7cf0bee96d1f372074` |
| `LineageOS/android_device_google_zumapro` | `lineage-24.0` @ `c03df81e8fed84aeb4f2d26e9cef2ea5762d7c3f` |
| `LineageOS/android_device_google_tegu-kernels` | `lineage-24.0` @ `06318d991a4a688cf281d69815143a8370e503b4` |
| `TheMuppets/proprietary_vendor_google_tegu` | `lineage-24.0` @ `6840f69264a3191a3be83816b950ecec4c4d88f1` |
| `RisingOS-Revived/android_vendor_rising` | `seventeen` (tracked) |
| `RisingOS-Revived/android_vendor_lineage` | `refs/heads/seventeen` (tracked) |

## Files created

```
README.md  PROJECT_SPEC.md  AI_INSTRUCTIONS.md  LICENSE  .gitignore
manifest/risingos-9-tegu.xml  manifest/README.md
vendor/rising-tegu/AndroidProducts.mk  vendor/rising-tegu/rising_tegu.mk  vendor/rising-tegu/README.md
config/{project,device,build,sources}.json
scripts/{setup,sync,verify,build,package}.sh
device/README.md  kernel/README.md  patches/README.md
docs/{architecture,source-audit,compatibility,build-guide,installation,known-issues}.md
docs/SESSION_STATUS.md  output/README.md  logs/README.md
```

## Last successful GitHub commit

`4d80a9c` on `risingos-9-tegu` (pushed 2026-11-06): 31 files, 2338 insertions — project
manifest, `rising_tegu` product, configs, scripts, documentation. If this file and the
branch disagree, the branch is authoritative.

## Build status

`NOT STARTED — BLOCKED`. Host resources are far below the LineageOS requirement. No build
log exists because no build was attempted. `scripts/verify.sh` on this host correctly fails
with "workspace does not exist".

## Current errors / blockers

1. **Host capacity**: 3.8 GB RAM, 9.7 GB disk. Android 17 needs 64 GB RAM and 400 GB disk.
   This is a hard blocker, not a configuration issue.
2. **No source tree**: sync is impossible for the same reason.
3. **First-build risk**: `rising_tegu` is a new product; the first real build may reveal
   genuine conflicts (Rising overlay expectations, package duplication, sepolicy). Those
   must be diagnosed from real logs on a capable host.

## Exact next actions

1. On a host with **64 GB RAM and 500 GB free SSD**:
   ```bash
   git clone https://github.com/ClmentCch/risingos-tegu -b risingos-9-tegu
   cd risingos-tegu
   ./scripts/setup.sh --check-only        # must pass
   ./scripts/setup.sh
   ./scripts/sync.sh
   ./scripts/verify.sh --lunch
   ```
2. Run `./scripts/build.sh` and keep `logs/*-build.log`. Fix real compile errors; if a
   source patch is genuinely needed, follow `patches/README.md` and register it in
   `scripts/sync.sh`.
3. Run `./scripts/package.sh`; publish the ZIP/images as **GitHub Release assets** (never
   commit them) with `checksums.sha256`.
4. Record the resulting commits (`repo forall -c 'echo "$REPO_PATH $(git rev-parse HEAD)"'`)
   and build outcome here.
5. Only with a physical Pixel 9a: follow `docs/installation.md`, then fill in the property
   verification results and remove the "untested" claims.
6. Optional hardening: add a 64 GB CI runner workflow with ccache and artifact upload.

## Resume protocol

Read this file, then `AI_INSTRUCTIONS.md`, then `docs/source-audit.md`. Do not redo the
research: revisions are verified and pinned. Verify the environment first; if it still
cannot build, continue with documentation/patch work rather than claiming a build.
