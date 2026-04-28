# Debug Toolbox

This project now includes a local no-root debug toolbox under `tools/`.

Available launchers:

- `tools/bin/gdb-ikemen`
- `tools/bin/gdbserver-ikemen`
- `tools/bin/strace-ikemen`
- `tools/bin/ltrace-ikemen`
- `tools/bin/valgrind-ikemen`
- `tools/bin/glxinfo-local`
- `tools/bin/eglinfo-local`

Typical usage:

```bash
tools/bin/gdb-ikemen
tools/bin/gdb-ikemen -q -ex run -- -log
tools/bin/strace-ikemen
tools/bin/ltrace-ikemen
tools/bin/valgrind-ikemen
tools/bin/glxinfo-local -B
```

Notes:

- Logs are written under `debug/`.
- `GOTRACEBACK=crash` is enabled by default in the wrappers to get richer Go crash data.
- `gdbserver-ikemen` listens on `127.0.0.1:2345` by default.
- `gdb-ikemen` accepts GDB options first and game arguments after `--`.
- The toolbox is local to the repo because system-wide `apt install` requires a sudo password in this environment.
