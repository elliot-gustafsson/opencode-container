#!/usr/bin/env bash

WORKSPACE_MODE="ro"
ARGS=()

for arg in "$@"; do
  if [ "$arg" = "-rw" ]; then
    WORKSPACE_MODE="rw"
    echo "starting opencode in rw mode"
  else
    ARGS+=("$arg")
  fi
done

SCRIPT_DIR=$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")

if [ ! -f "${SCRIPT_DIR}/opencode.jsonc" ]; then
    touch "${SCRIPT_DIR}/opencode.jsonc"
fi

if [ ! -f "${SCRIPT_DIR}/.env" ]; then
    touch "${SCRIPT_DIR}/.env"
fi

exec podman run -it --rm \
  --name "opencode-sandbox-$$" \
  --cap-drop=ALL \
  --cap-add=CAP_NET_ADMIN \
  --cap-add=CAP_SETPCAP \
  --userns=keep-id:uid=1000,gid=1000 \
  --read-only \
  -v /tmp \
  --pids-limit=200 \
  --memory=2g \
  --cpus=4 \
  --sysctl net.ipv6.conf.all.disable_ipv6=1 \
  --sysctl net.ipv6.conf.default.disable_ipv6=1 \
  -e XDG_STATE_HOME=/home/opencode-user/.local/share/opencode/xdg_state \
  -e XDG_CACHE_HOME=/tmp/cache \
  -e OPENCODE_DISABLE_AUTOUPDATE=1 \
  -v "${SCRIPT_DIR}/state:/home/opencode-user/.local/share/opencode:Z,U" \
  -v "${SCRIPT_DIR}/opencode.jsonc:/home/opencode-user/.config/opencode/opencode.jsonc:ro,z" \
  -v "${SCRIPT_DIR}/opencode.gitignore:/home/opencode-user/.config/opencode/.gitignore:ro,z" \
  -v "$(pwd):/workspace:${WORKSPACE_MODE},z" \
  --env-file="${SCRIPT_DIR}/.env" \
  opencode-sandbox "${ARGS[@]}"
