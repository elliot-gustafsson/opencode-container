#!/bin/sh
set -e

if [ "$ALLOW_INTERNAL_IPS" != "1" ]; then
    ip route add blackhole 10.0.0.0/8
    ip route add blackhole 172.16.0.0/12
    ip route add blackhole 192.168.0.0/16
    ip route add blackhole 169.254.0.0/16
fi


mkdir -p /tmp/state /tmp/cache /tmp/run /tmp/containers/run /tmp/containers/storage
chmod 700 /tmp/run
chown -R 1000:1000 /tmp/state /tmp/cache /tmp/run /tmp/containers /home/opencode-user/.local/share/opencode

export HOME="/home/opencode-user"
export USER="opencode-user"
export LOGNAME="opencode-user"
export XDG_RUNTIME_DIR="/tmp/run"

exec setpriv \
    --inh-caps=-all \
    --bounding-set=-net_admin,-setpcap \
    -- /opt/opencode/.opencode/bin/opencode "$@"
