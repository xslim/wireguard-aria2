#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
IMAGE="${TORRENT_IMAGE:-wireguard-aria2:local}"
docker build --pull --tag "$IMAGE" "$@" .
docker image ls "$IMAGE"
