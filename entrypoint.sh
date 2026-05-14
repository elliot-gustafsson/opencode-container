#!/bin/sh
set -e

ip route add blackhole 10.0.0.0/8
ip route add blackhole 172.16.0.0/12
ip route add blackhole 192.168.0.0/16
ip route add blackhole 169.254.0.0/16

mkdir -p /tmp/state /tmp/cache
chown -R 1000:1000 /tmp/state /tmp/cache /home/opencode-user/.local/share/opencode

export HOME="/home/opencode-user"
export USER="opencode-user"
export LOGNAME="opencode-user"

exec setpriv \
    --inh-caps=-all \
    --bounding-set=-all \
    --no-new-privs \
    -- /opt/opencode/.opencode/bin/opencode "$@"
