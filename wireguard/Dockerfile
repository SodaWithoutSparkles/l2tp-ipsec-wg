FROM alpine:3.19

# Install WireGuard and required tools
RUN apk add --no-cache \
    wireguard-tools \
    iptables \
    ip6tables \
    iproute2 \
    bash \
    openresolv

# Create necessary directories
RUN mkdir -p /etc/wireguard

# Copy startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose WireGuard port
EXPOSE 51820/udp

ENTRYPOINT ["/entrypoint.sh"]
