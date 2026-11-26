#!/bin/sh
set -eu
VPN_PID=""
DOWNLOAD_PID=""
cleanup() {
    if [ -n "$DOWNLOAD_PID" ]; then
        kill -TERM "$DOWNLOAD_PID" 2>/dev/null || true
        wait "$DOWNLOAD_PID" 2>/dev/null || true
    fi
    if [ -n "$VPN_PID" ]; then
        kill -TERM "$VPN_PID" 2>/dev/null || true
        wait "$VPN_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
[ -s /gluetun/wireguard/wg0.conf ] || { echo "Missing WireGuard config." >&2; exit 1; }
echo "Starting WireGuard VPN..."
/gluetun-entrypoint &
VPN_PID=$!
elapsed=0
until /gluetun-entrypoint healthcheck >/dev/null 2>&1; do
    kill -0 "$VPN_PID" 2>/dev/null || { echo "VPN exited." >&2; exit 1; }
    [ "$elapsed" -lt "$VPN_START_TIMEOUT" ] || { echo "VPN startup timed out." >&2; exit 1; }
    sleep 2
    elapsed=$((elapsed + 2))
done
echo "VPN connected. Starting aria2 RPC..."
[ -s /state/session ] || touch /state/session
su-exec "${PUID:-1000}:${PGID:-1000}" aria2c \
    --no-conf=true --dir=/downloads --seed-time=0 --continue=true \
    --bt-save-metadata=true --bt-enable-lpd=false --summary-interval=5 \
    --enable-rpc=true --rpc-listen-all=false --rpc-listen-port=6800 \
    --rpc-secret="$(cat /state/rpc-secret)" \
    --input-file=/state/session --save-session=/state/session \
    --save-session-interval=15 --max-concurrent-downloads="${MAX_CONCURRENT:-1}" &
DOWNLOAD_PID=$!
while kill -0 "$DOWNLOAD_PID" 2>/dev/null; do
    kill -0 "$VPN_PID" 2>/dev/null || { echo "VPN exited." >&2; exit 1; }
    sleep 1
done
RESULT=0
wait "$DOWNLOAD_PID" || RESULT=$?
DOWNLOAD_PID=""
exit "$RESULT"
