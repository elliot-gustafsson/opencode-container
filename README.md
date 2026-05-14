# opencode-container

This repository provides a sandboxed environment for running the `opencode` CLI tool inside a Podman container. It is designed to restrict local system and network access while providing a persistent configuration and isolated runtime.

## Features

- **Podman Sandbox:** Runs `opencode` in an AlmaLinux-based container with strict resource limits (CPUs, memory, PIDs) and a read-only root filesystem.
- **Security & Privilege Drop:** Drops all capabilities by default (`--cap-drop=ALL`). The container's `entrypoint.sh` blocks access to local private IPv4 addresses (RFC 1918) via blackhole routing and drops remaining privileges using `setpriv --no-new-privs` before executing the CLI.
- **Workspace Mounting:** Mounts the current working directory of the host into the container's `/workspace`. Defaults to read-only (`ro`) mode, but can be configured as read-write via the `-rw` flag on the runner script.
- **State Persistence:** Maintains `opencode` state and configurations locally using host-mounted volumes (`state/`, `opencode.jsonc`, `opencode.gitignore`) ensuring history and settings persist across container executions.

## Installation

A `Makefile` is provided to build the container image and install the runner script.

```bash
make install
```

This will:
1. Build the Podman image `opencode-sandbox` using the `Containerfile`.
2. Create the necessary `state` directory.
3. Create a system symlink from `runner.sh` to `/usr/local/bin/opencode` (requires sudo).

## Usage

Once installed, you can use the `opencode` command globally. It will execute within the Podman container, mounting your current directory.

```bash
# Run opencode with read-only access to the current directory
opencode

# Run opencode with read-write access to the current directory
opencode -rw [args...]
```
