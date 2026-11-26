# wireguard-aria2

One-shot BitTorrent downloads using aria2 and Gluetun WireGuard in a single temporary Docker container. Intended for Docker on macOS (including OrbStack) and Linux.

## Install

```sh
mkdir -p ~/src
cd ~/src
git clone https://github.com/xslim/wireguard-aria2.git
cd wireguard-aria2
bash build.sh
bash install.sh
export PATH="$HOME/.local/bin:$PATH"
```

Add the export to your shell startup file to make it permanent.

## Usage

Keep your WireGuard configuration outside the repository. Use a standard Gluetun-compatible WireGuard configuration (endpoint IP rather than hostname).

```sh
cd ~/Downloads
torrent ~/.config/wireguard/nordvpn.conf ubuntu.torrent
torrent ~/.config/wireguard/nordvpn.conf 'magnet:?xt=urn:btih:...'
torrent ~/.config/wireguard/nordvpn.conf ubuntu.torrent --max-download-limit=10M
```

The current directory is mounted at /downloads. The configuration and torrent input are read-only mounts. The container waits for Gluetun health, runs aria2 as the host UID/GID, stops seeding after completion and exits. Gluetun's firewall is intended to block non-VPN traffic. No ports are published.

## Background downloads

Use Docker's native detached mode to keep downloading after disconnecting from SSH:

```sh
torrent -d ~/.config/wireguard/nordvpn.conf ubuntu.torrent
torrent --detach ~/.config/wireguard/nordvpn.conf 'magnet:?xt=urn:btih:...'
torrent list
torrent logs <container-id>
torrent status <container-id>
torrent stop <container-id>
```

The detached command prints a container ID immediately, before VPN startup has necessarily completed. Use logs to check VPN readiness and progress. Multiple downloads can run independently; avoid downloading the same files concurrently. Management commands only accept IDs of containers labeled by this tool. Ctrl+C while following logs stops the log viewer, not the detached download.

Containers automatically disappear on completion, failure or stop; their logs and exit status are then unavailable. Partial files remain in the original download directory and can be resumed by running the same download again. Docker/OrbStack must remain running.

To update an existing installation with these CLI-only changes, run git pull and bash install.sh. No image rebuild is required if the existing image is already built.

## Rebuild

```sh
cd ~/src/wireguard-aria2
bash build.sh
# Or rebuild without cache:
bash build.sh --no-cache
```

The base image uses the moving v3 tag; pin a digest if reproducibility is required.

## Troubleshooting and validation

Check Docker with docker info. The Linux container needs NET_ADMIN and /dev/net/tun. Check the VPN startup logs and download-folder permissions. A VPN without port forwarding may have fewer reachable peers.

This initial implementation is not yet runtime-tested. Before trusting the firewall, test with a legal Linux distribution torrent, compare the container exit IP with the host IP, and verify that connectivity fails when the VPN tunnel is interrupted. Never commit credentials. Ignore rules are a precaution, not a secret scanner.
