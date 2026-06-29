# Revebian

Revebian is a small installable CLI for running a lean x64 Linux debugging container.

It is built for dynamic debugging and Frida-based reverse engineering. The default image stays intentionally small: no Radare2, no Ghidra, no compiler toolchain, no pwntools, no rr, no Valgrind, no LLDB, and no network scanning bundles. Wine is available as an optional build variant.

Korean documentation: [README.ko.md](README.ko.md)

## What Is Included

- One host-side CLI: `revebian`
- Frida CLI and matching `frida-server`
- GDB, GEF, and `gdbserver`
- `strace`, `ltrace`, `lsof`, `file`, `binutils`, `xxd`
- Python 3 virtual environment under `/opt/revenv`
- `fish`, `zoxide`, `bat`, `neovim`, `tmux`, `eza`, `jq`, `jaq`, `ripgrep`
- Docker Compose setup with local-only Frida port forwarding
- Optional Wine build with `revebian build --wine`

## Requirements

- Docker
- Docker Compose plugin
- An environment capable of running `linux/amd64` containers

On Apple Silicon, Docker Desktop runs this image through amd64 emulation. That is expected because this environment targets x64 Linux debugging.

## Install The CLI

From this repository:

```bash
./revebian install
```

This creates a symlink at:

```text
~/.local/bin/revebian
```

Make sure `~/.local/bin` is in your `PATH`. You can also choose another target:

```bash
./revebian install --target /usr/local/bin/revebian
```

The installed command is a symlink back to this repository. If you move the repository, reinstall the CLI or set `REVEBIAN_HOME=/path/to/revebian`.

`REVEBIAN_HOME` points to this tool's repository. It is not the workspace that gets mounted into the container.

You can always use the local executable directly:

```bash
./revebian doctor
```

## Quick Start

Build the default slim image:

```bash
revebian build
```

Start the container, start `frida-server`, forward ports, and enter `fish`:

```bash
revebian
```

List processes through the forwarded Frida server:

```bash
revebian ps
```

Stop and clean up the container/network:

```bash
revebian stop
```

## Optional Wine Image

Wine is not included by default because it makes the image much heavier.

Build with Wine only when needed:

```bash
revebian build --wine
```

Then run normally:

```bash
revebian
```

To go back to the slim image:

```bash
revebian build --no-wine --no-cache
```

## Frida Port Forwarding

By default, Compose binds Frida to localhost only:

```text
127.0.0.1:27042 -> container:27042
127.0.0.1:27043 -> container:27043
```

This keeps the Frida server reachable from your machine without exposing it to the network.

From the host:

```bash
frida-ps -H 127.0.0.1:27042
```

From inside the container:

```bash
frida-ps-local
frida-attach-local <pid|process-name> -l hook.js
```

## Commands

```bash
revebian              # default: start container + frida-server, then enter fish
revebian shell        # same as default
revebian up           # start container + frida-server in the background
revebian server       # run the frida-server Compose service in the foreground
revebian ps           # list processes through frida-server
revebian attach ...   # attach through frida-server
revebian exec ...     # run a command inside the container
revebian build        # build the slim image
revebian build --wine # build with Wine included
revebian install      # install CLI symlink
revebian uninstall    # remove CLI symlink
revebian doctor       # print environment status
revebian stop         # stop containers and remove the Compose network
revebian help         # show command help
```

Inside the container, `re-help` prints the common host and container commands.

## Workspace Layout

The directory where you run `revebian` is mounted at:

```text
/workspace
```

For example, if you run `revebian` from `~/targets/foo`, then `~/targets/foo` becomes `/workspace` inside the container.

You can override the mounted workspace explicitly:

```bash
REVEBIAN_WORKSPACE=/path/to/target revebian
```

The Revebian repository is only used for `Dockerfile`, `docker-compose.yml`, and the CLI itself.

## Custom Ports

You can change the host-side Frida ports with environment variables:

```bash
FRIDA_HOST_PORT=37042 FRIDA_CONTROL_PORT=37043 revebian
```

The container still listens on `27042` and `27043`; only the host bindings change.

## Notes

- The default image is intentionally minimal. Build with `--wine` only when you actually need Wine.
- `frida-server` runs inside the container. It is meant for processes running in this same container.
- The default Compose configuration adds ptrace-related capabilities and disables the default seccomp profile so GDB and Frida can work normally.
