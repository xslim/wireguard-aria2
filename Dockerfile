FROM qmcgaw/gluetun:v3
RUN apk add --no-cache aria2 su-exec python3
COPY entrypoint.sh /usr/local/bin/download-entrypoint
COPY rpc.py /usr/local/bin/torrent-rpc.py
RUN chmod +x /usr/local/bin/download-entrypoint
ENV VPN_SERVICE_PROVIDER=custom VPN_TYPE=wireguard FIREWALL=on VPN_START_TIMEOUT=120
WORKDIR /downloads
ENTRYPOINT ["/usr/local/bin/download-entrypoint"]
