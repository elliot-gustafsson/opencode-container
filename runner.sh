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

RULES_RO="${SCRIPT_DIR}/state/RULES_RO.md"
RULES_RW="${SCRIPT_DIR}/state/RULES_RW.md"

if [ ! -f "$RULES_RO" ]; then
  cat << 'EOF' > "$RULES_RO"
# SYSTEM RULES
- Environment: You are running inside an isolated Podman container.
- Write access: `/tmp` ONLY. `/workspace` and all other paths are READ-ONLY.
- CRITICAL: `.git` is set to READ-ONLY by the OS. Do not attempt commits, pushes, or writes. Only use read commands.
EOF
fi

if [ ! -f "$RULES_RW" ]; then
  cat << 'EOF' > "$RULES_RW"
# SYSTEM RULES
- Environment: You are running inside an isolated Podman container.
- Write access: `/workspace` and `/tmp` ONLY. All other paths are READ-ONLY.
- CRITICAL: `.git` is set to READ-ONLY by the OS. Do not attempt commits, pushes, or writes. Only use read commands.
EOF
fi

PODMAN_MOUNTS=()
# always mount the current directory to /workspace
PODMAN_MOUNTS+=("-v" "$(pwd):/workspace:${WORKSPACE_MODE},z")

# mount .git as ro always
if [ -e "$(pwd)/.git" ]; then
  PODMAN_MOUNTS+=("-v" "$(pwd)/.git:/workspace/.git:ro,z")
fi

if [ "$WORKSPACE_MODE" = "rw" ]; then
  ACTIVE_RULES="$RULES_RW"
else
  ACTIVE_RULES="$RULES_RO"
fi

PODMAN_MOUNTS+=("-v" "${ACTIVE_RULES}:/tmp/RULES.md:ro,z")

exec podman run -it --rm \
  --name "opencode-sandbox-$$" \
  --cap-drop=ALL \
  --cap-add=CAP_NET_ADMIN \
  --cap-add=CAP_SETPCAP \
  --userns=keep-id:uid=1000,gid=1000 \
  --read-only \
  -v /tmp \
  --pids-limit=200 \
  --memory=4g \
  --cpus=4 \
  --sysctl net.ipv6.conf.all.disable_ipv6=1 \
  --sysctl net.ipv6.conf.default.disable_ipv6=1 \
  -e XDG_STATE_HOME=/home/opencode-user/.local/share/opencode/xdg_state \
  -e XDG_CACHE_HOME=/tmp/cache \
  -e OPENCODE_DISABLE_AUTOUPDATE=1 \
  -e OPENCODE_INSTRUCTIONS='["/tmp/RULES.md"]' \
  -v "${SCRIPT_DIR}/state:/home/opencode-user/.local/share/opencode:Z,U" \
  -v "${SCRIPT_DIR}/opencode.jsonc:/home/opencode-user/.config/opencode/opencode.jsonc:ro,z" \
  -v "${SCRIPT_DIR}/opencode.gitignore:/home/opencode-user/.config/opencode/.gitignore:ro,z" \
  "${PODMAN_MOUNTS[@]}" \
  --env-file="${SCRIPT_DIR}/.env" \
  opencode-sandbox "${ARGS[@]}"
