Naruto Ikemen GO for R36S Console

## Development Flow

The repository root is the canonical game tree. Use the x64 Ikemen binary for
local testing:

```bash
tools/run-x64.sh
```

For a quick startup smoke test:

```bash
tools/smoke-x64.sh
```

Build the ARM64 PortMaster zip from the root tree:

```bash
tools/build-portmaster-release.sh
```

The release script stages the PortMaster layout in a temporary folder and
creates `dist/ikemen.zip`. It excludes x64 binaries, editor
tools, logs, temporary files, `Malusardi N4rut0 MUG3N 2022 V5`, and the old
nested `ikemen/` staging folder.
