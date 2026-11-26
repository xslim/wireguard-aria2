# wireguard-aria2

One persistent Docker container running Gluetun WireGuard and aria2. All downloads share the VPN and RPC queue. No RPC port is exposed; the CLI uses docker exec.

## Install / upgrade

```sh
mkdir -p ~/src
cd ~/src
git clone https://github.com/xslim/wireguard-aria2.git
cd wireguard-aria2
bash build.sh
bash install.sh
export PATH="$HOME/.local/bin:$PATH"
```

For existing installations, use git pull instead of clone and rebuild the image. Previous per-download containers are not migrated automatically. Let them finish or stop them explicitly.

## Usage

```sh
export TORRENT_WG_CONFIG="$HOME/.config/wireguard/nordvpn.conf"
cd ~/Downloads
torrent add
torrent add ubuntu.torrent
torrent add 'magnet:?xt=urn:btih:...'
torrent -i add ubuntu.torrent
torrent list
torrent status <gid>
torrent pause <gid>
torrent resume <gid>
torrent stop <gid>
torrent logs
torrent shutdown
torrent start
```

The first add starts the queue container if needed; later adds reuse it. By default one download is active at a time. Set TORRENT_MAX_CONCURRENT before creating the container to change this. The -i flag follows a download; interrupting the viewer is intended not to cancel the download. Logs follows the shared container logs. Stop removes an individual job without deleting its files. Shutdown stops the container, not the individual jobs; start resumes the saved unfinished queue. Session saves occur on submission and every 15 seconds, so abrupt termination can lose recent state. Completed history is in memory, not permanent.

The default download root is your home directory. Current directories under that root are mapped to /downloads; directories outside it are rejected. Set TORRENT_DOWNLOAD_ROOT before first start to restrict or change the root. This is a writable bind mount, so the container can access the whole chosen root. Prefer a dedicated download directory if isolation matters.

Use a Gluetun-compatible WireGuard configuration with an IP endpoint. Keep credentials outside the repository. A single queue uses one VPN configuration. To change the VPN or mount, shut down and remove the stopped queue container, then start again with the new settings:

```sh
torrent shutdown
docker rm "wireguard-aria2-$(id -u)"
torrent start
```

The state directory defaults to ~/.local/state/wireguard-aria2 and contains the session and RPC secret. Do not share it. Docker/OrbStack must remain running. No automatic restart after host reboot is configured.

## Rebuild

```sh
git pull
torrent shutdown
docker rm "wireguard-aria2-$(id -u)"
bash build.sh
bash install.sh
torrent start
```

Skip shutdown/removal if the container does not exist. The moving Gluetun v3 tag can be pinned for reproducible builds.

## Validation

This version is not runtime-tested. Verify with a legal Linux distribution torrent, confirm exit IP and kill-switch behavior, then check queue persistence and download permissions. Docker needs NET_ADMIN and /dev/net/tun. No inbound VPN port forwarding is required, but peer connectivity may be reduced.
