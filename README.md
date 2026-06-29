# Revebian

Revebian is a small Docker-based x64 Linux workspace for dynamic debugging and Frida-based reverse engineering.

It is intentionally lean. It does not include Radare2, Ghidra, compiler toolchains, pwntools, rr, Valgrind, LLDB, packet scanners, or other large extras. The image is built around Frida, frida-server, GDB, syscall/library tracing, and a comfortable shell environment.

Korean documentation: [README.ko.md](README.ko.md)

## What Is Included

- Frida CLI and matching `frida-server`
- GDB, GEF, and `gdbserver`
- `strace`, `ltrace`, `lsof`, `file`, `binutils`, `xxd`
- Python 3 virtual environment under `/opt/revenv`
- `fish`, `zoxide`, `bat`, `neovim`, `tmux`, `eza`, `jq`, `jaq`, `ripgrep`
- Docker Compose setup with local Frida port forwarding

## Requirements

- Docker
- Docker Compose plugin
- An environment capable of running `linux/amd64` containers

On Apple Silicon, Docker Desktop runs this image through amd64 emulation. That is expected because this environment targets x64 Linux debugging.

## Quick Start

Build the image:

```bash
./setup.sh
```

Start the container, start `frida-server`, forward ports, and enter `fish`:

```bash
./run.sh
```

List processes through the forwarded Frida server:

```bash
./run.sh ps
```

Stop and clean up the container/network:

```bash
./run.sh stop
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
./run.sh shell      # default: start container + frida-server, then enter fish
./run.sh up         # start container + frida-server in the background
./run.sh server     # run the frida-server Compose service in the foreground
./run.sh ps         # list processes through frida-server
./run.sh attach ... # attach through frida-server
./run.sh stop       # stop containers and remove the Compose network
./run.sh rebuild    # rebuild the image
./run.sh help       # show command help
```

Inside the container, `re-help` prints the common commands again.

## Workspace Layout

The project directory is mounted at:

```text
/workspace
```

Anything you place in this repository on the host is available inside the container.

## Custom Ports

You can change the host-side Frida ports with environment variables:

```bash
FRIDA_HOST_PORT=37042 FRIDA_CONTROL_PORT=37043 ./run.sh
```

The container still listens on `27042` and `27043`; only the host bindings change.

## Rebuild From Scratch

```bash
./run.sh stop
./setup.sh --no-cache
```

## Notes

- The image is intentionally minimal. If you need heavy static analysis tools, install them separately or create a separate image.
- `frida-server` runs inside the container. It is meant for processes running in this same container.
- The default Compose configuration adds ptrace-related capabilities and disables the default seccomp profile so GDB and Frida can work normally.
