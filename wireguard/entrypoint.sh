#!/bin/bash
set -e

echo "Starting WireGuard VPN entry node..."

# Check if configuration exists
if [ ! -f /etc/wireguard/wg0.conf ]; then
    echo "Error: WireGuard configuration not found at /etc/wireguard/wg0.conf"
    exit 1
fi

# Enable IP forwarding
echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

# Set up iptables rules for NAT and forwarding
echo "Setting up iptables rules..."
iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE || echo "Warning: ppp0 not yet available"
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -A FORWARD -o wg0 -j ACCEPT

# Start WireGuard
echo "Starting WireGuard interface wg0..."
wg-quick up wg0

echo "WireGuard is running!"
echo "Interface status:"
wg show

# Keep container running and show logs
tail -f /dev/null
