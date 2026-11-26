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
torrent ubuntu.torrent
torrent 'magnet:?xt=urn:btih:...'
torrent -i ubuntu.torrent
torrent list
torrent status <gid>
torrent pause <gid>
torrent resume <gid>
torrent remove <gid>
torrent logs
torrent stop
torrent start
```

The first add starts the queue container if needed; later adds reuse it. By default one download is active at a time. Set TORRENT_MAX_CONCURRENT before creating the container to change this. The -i flag follows a download; interrupting the viewer is intended not to cancel the download. Logs follows the shared container logs. Remove removes an individual job without deleting its files. Stop stops the shared container; start resumes the saved unfinished queue. Session saves occur on submission and every 15 seconds, so abrupt termination can lose recent state. Completed history is in memory, not permanent.

Downloads always go to $HOME/Downloads by default, regardless of the current working directory. The installer creates this directory if missing. Set TORRENT_DOWNLOAD_ROOT before first start to choose another existing directory. The CLI never prompts: supply the source as an argument and configure TORRENT_WG_CONFIG if needed. The explicit add subcommand remains supported.

Use a Gluetun-compatible WireGuard configuration with an IP endpoint. Keep credentials outside the repository. A single queue uses one VPN configuration. To change the VPN or mount, shut down and remove the stopped queue container, then start again with the new settings:

```sh
torrent stop
docker rm "wireguard-aria2-$(id -u)"
torrent start
```

The state directory defaults to ~/.local/state/wireguard-aria2 and contains the session and RPC secret. Do not share it. Docker/OrbStack must remain running. No automatic restart after host reboot is configured.

## Rebuild

```sh
git pull
torrent stop
docker rm "wireguard-aria2-$(id -u)"
bash build.sh
bash install.sh
torrent start
```

Skip stop/removal if the container does not exist. The moving Gluetun v3 tag can be pinned for reproducible builds.

## Validation

This version is not runtime-tested. Verify with a legal Linux distribution torrent, confirm exit IP and kill-switch behavior, then check queue persistence and download permissions. Docker needs NET_ADMIN and /dev/net/tun. No inbound VPN port forwarding is required, but peer connectivity may be reduced.

## Migrating from the previous home-directory mount

Before changing the download root, finish or remove unfinished downloads from the old queue. Saved session paths are relative to the old container mount and will otherwise point to different host locations. Stop and remove the old container, then start the new queue. Existing downloaded files are not moved automatically.
