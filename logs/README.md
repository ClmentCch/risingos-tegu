# logs/

Build and verification logs written by `scripts/build.sh`, `scripts/sync.sh` and
`scripts/verify.sh`.

- Naming: `<UTC timestamp>-<stage>.log` (for example `20261106T2140Z-build.log`).
- Contents are git-ignored: logs are large and may contain host paths.
- On failure, preserve the log and copy the first actionable error into
  `docs/SESSION_STATUS.md` ("Current errors").
- Never paste fabricated or truncated logs as proof of a successful build.
