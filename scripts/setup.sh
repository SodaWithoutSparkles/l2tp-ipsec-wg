#!/bin/bash
set -e

echo "==================================="
echo "WireGuard + L2TP/IPsec Setup Script"
echo "==================================="
echo ""

# Check if secrets exist
if [ ! -f secrets/vpn_server_ip.txt ] || \
   [ ! -f secrets/vpn_ipsec_psk.txt ] || \
   [ ! -f secrets/vpn_username.txt ] || \
   [ ! -f secrets/vpn_password.txt ]; then
    echo "Error: Secret files not found!"
    echo "Please create the following files in the secrets/ directory:"
    echo "  - vpn_server_ip.txt"
    echo "  - vpn_ipsec_psk.txt"
    echo "  - vpn_username.txt"
    echo "  - vpn_password.txt"
    echo ""
    echo "You can use the example files as templates:"
    echo "  cp secrets/vpn_server_ip.txt.example secrets/vpn_server_ip.txt"
    echo "  cp secrets/vpn_ipsec_psk.txt.example secrets/vpn_ipsec_psk.txt"
    echo "  cp secrets/vpn_username.txt.example secrets/vpn_username.txt"
    echo "  cp secrets/vpn_password.txt.example secrets/vpn_password.txt"
    echo ""
    echo "Then edit each file to add your actual credentials."
    exit 1
fi

# Check if WireGuard config exists
if [ ! -f config/wg0.conf ]; then
    echo "Error: WireGuard configuration not found!"
    echo "Please create config/wg0.conf based on config/wg0.conf.example"
    echo ""
    echo "Quick start:"
    echo "  1. Generate server keys:"
    echo "     wg genkey | tee config/server_private.key | wg pubkey > config/server_public.key"
    echo ""
    echo "  2. Copy the example config:"
    echo "     cp config/wg0.conf.example config/wg0.conf"
    echo ""
    echo "  3. Edit config/wg0.conf and replace YOUR_SERVER_PRIVATE_KEY with the content from config/server_private.key"
    echo ""
    echo "  4. For each client, generate keys and add a [Peer] section to config/wg0.conf"
    exit 1
fi

echo "✓ All required files found!"
echo ""
echo "Building Docker images..."
docker-compose build

echo ""
echo "Starting services..."
docker-compose up -d

echo ""
echo "Waiting for services to start..."
sleep 5

echo ""
echo "==================================="
echo "Service Status:"
echo "==================================="
docker-compose ps

echo ""
echo "==================================="
echo "Setup Complete!"
echo "==================================="
echo ""
echo "Your WireGuard + L2TP/IPsec VPN chain is now running."
echo ""
echo "WireGuard server is listening on port 51820/udp"
echo "Clients connecting to WireGuard will have their traffic routed through the L2TP/IPsec VPN."
echo ""
echo "To view logs:"
echo "  docker-compose logs -f"
echo ""
echo "To stop:"
echo "  docker-compose down"
