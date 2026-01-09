# Examples and Testing

This document provides various examples and testing scenarios for the WireGuard + L2TP/IPsec VPN chain.

## Table of Contents
- [Basic Setup Examples](#basic-setup-examples)
- [Client Configuration Examples](#client-configuration-examples)
- [Testing Procedures](#testing-procedures)
- [Common Scenarios](#common-scenarios)
- [Debugging Examples](#debugging-examples)

## Basic Setup Examples

### Example 1: Single Client Setup

1. **Create secrets:**
```bash
echo "vpn.example.com" > secrets/vpn_server_ip.txt
echo "MySecretPSK123" > secrets/vpn_ipsec_psk.txt
echo "myusername" > secrets/vpn_username.txt
echo "mypassword" > secrets/vpn_password.txt
chmod 600 secrets/*.txt
```

2. **Generate WireGuard keys:**
```bash
wg genkey > config/server_private.key
cat config/server_private.key | wg pubkey > config/server_public.key
wg genkey > config/client1_private.key
cat config/client1_private.key | wg pubkey > config/client1_public.key
```

3. **Create server config:**
```ini
# config/wg0.conf
[Interface]
PrivateKey = <content-of-server_private.key>
Address = 10.13.13.1/24
ListenPort = 51820

PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# Client 1
PublicKey = <content-of-client1_public.key>
AllowedIPs = 10.13.13.2/32
```

4. **Deploy:**
```bash
docker compose up -d
```

### Example 2: Multiple Clients Setup

**Server config with multiple peers:**
```ini
# config/wg0.conf
[Interface]
PrivateKey = <server-private-key>
Address = 10.13.13.1/24
ListenPort = 51820

PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# Mobile phone
PublicKey = <mobile-public-key>
AllowedIPs = 10.13.13.2/32

[Peer]
# Laptop
PublicKey = <laptop-public-key>
AllowedIPs = 10.13.13.3/32

[Peer]
# Desktop
PublicKey = <desktop-public-key>
AllowedIPs = 10.13.13.4/32
```

## Client Configuration Examples

### Linux/macOS Client

**client1.conf:**
```ini
[Interface]
PrivateKey = <client1-private-key>
Address = 10.13.13.2/24
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = <server-public-key>
Endpoint = your-server-ip:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

**Connect:**
```bash
sudo wg-quick up ./client1.conf
```

**Disconnect:**
```bash
sudo wg-quick down ./client1.conf
```

### iOS/Android Client

Use the official WireGuard app and scan this QR code (generate with):

```bash
cat client1.conf | qrencode -t ansiutf8
```

Or manually enter the configuration from the client config above.

### Windows Client

1. Install WireGuard for Windows
2. Import the tunnel:
   - Click "Add Tunnel"
   - Select "Add empty tunnel"
   - Paste configuration
   - Click "Save"
3. Click "Activate"

## Testing Procedures

### 1. Verify Container Status

```bash
# Check if containers are running
docker compose ps

# Expected output:
# NAME                  STATUS              PORTS
# l2tp-ipsec-exit      Up X minutes        
# wireguard-entry      Up X minutes        0.0.0.0:51820->51820/udp
```

### 2. Test L2TP/IPsec Connection

```bash
# Check IPsec status
docker exec l2tp-ipsec-exit ipsec status

# Expected: Should show ESTABLISHED connection

# Check ppp0 interface
docker exec l2tp-ipsec-exit ip addr show ppp0

# Expected: Should show ppp0 interface with IP address

# Test connectivity from L2TP/IPsec container
docker exec l2tp-ipsec-exit ping -c 4 8.8.8.8
```

### 3. Test WireGuard Server

```bash
# Check WireGuard status
docker exec wireguard-entry wg show

# Expected: Should show interface wg0 with peer info

# Check if WireGuard port is listening
docker exec wireguard-entry netstat -uln | grep 51820

# Test from host
nc -u -z -v localhost 51820
```

### 4. Test End-to-End Connection

From a client device:

```bash
# Connect to WireGuard
wg-quick up ./client.conf

# Test connection
ping 10.13.13.1  # Should reach WireGuard server

# Test internet connectivity
curl -4 ifconfig.me  # Should show VPN server's IP

# Test DNS
nslookup google.com

# Trace route to see VPN path
traceroute 8.8.8.8
```

### 5. Performance Testing

```bash
# Test bandwidth (install iperf3 on both ends)
# On server:
docker exec wireguard-entry iperf3 -s

# On client:
iperf3 -c 10.13.13.1

# Test latency
ping -c 100 10.13.13.1 | tail -1

# Test packet loss
ping -c 1000 10.13.13.1 | grep loss
```

## Common Scenarios

### Scenario 1: Road Warrior Setup

**Use Case:** Connect laptop/phone from anywhere

**Client Config:**
```ini
[Interface]
PrivateKey = <your-private-key>
Address = 10.13.13.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <server-public-key>
Endpoint = your-server-ip:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

### Scenario 2: Site-to-Site VPN

**Use Case:** Connect two networks

**Router Config:**
```ini
[Interface]
PrivateKey = <router-private-key>
Address = 10.13.13.10/24

# Route for local network
PostUp = ip route add 192.168.1.0/24 dev wg0

[Peer]
PublicKey = <server-public-key>
Endpoint = your-server-ip:51820
AllowedIPs = 10.13.13.0/24
PersistentKeepalive = 25
```

### Scenario 3: Split Tunnel

**Use Case:** Only route specific traffic through VPN

**Client Config:**
```ini
[Interface]
PrivateKey = <your-private-key>
Address = 10.13.13.2/24
DNS = 8.8.8.8

[Peer]
PublicKey = <server-public-key>
Endpoint = your-server-ip:51820
# Only route these networks through VPN
AllowedIPs = 10.0.0.0/8, 192.168.0.0/16
PersistentKeepalive = 25
```

## Debugging Examples

### Check Logs

```bash
# All logs
docker compose logs

# Follow logs in real-time
docker compose logs -f

# Only WireGuard logs
docker compose logs -f wireguard

# Only L2TP/IPsec logs
docker compose logs -f l2tp-ipsec

# Last 50 lines
docker compose logs --tail=50
```

### Network Debugging

```bash
# Check routing on WireGuard container
docker exec wireguard-entry ip route

# Check routing on L2TP/IPsec container
docker exec l2tp-ipsec-exit ip route

# Check iptables rules
docker exec wireguard-entry iptables -L -n -v
docker exec wireguard-entry iptables -t nat -L -n -v

# Capture packets
docker exec wireguard-entry tcpdump -i wg0 -n
docker exec l2tp-ipsec-exit tcpdump -i ppp0 -n
```

### Connection Debugging

```bash
# Test from WireGuard to L2TP/IPsec
docker exec wireguard-entry ping -c 4 l2tp-ipsec

# Test from WireGuard to internet
docker exec wireguard-entry ping -c 4 8.8.8.8

# Check DNS resolution
docker exec wireguard-entry nslookup google.com

# Test specific port
docker exec wireguard-entry nc -zv google.com 443
```

### IPsec Debugging

```bash
# Verbose IPsec status
docker exec l2tp-ipsec-exit ipsec statusall

# Check IPsec configuration
docker exec l2tp-ipsec-exit cat /etc/ipsec.conf

# Check if IPsec is running
docker exec l2tp-ipsec-exit ps aux | grep ipsec

# Restart IPsec
docker compose restart l2tp-ipsec
```

### WireGuard Debugging

```bash
# Detailed WireGuard info
docker exec wireguard-entry wg show all dump

# Check WireGuard configuration
docker exec wireguard-entry cat /etc/wireguard/wg0.conf

# Check if WireGuard is running
docker exec wireguard-entry wg

# Restart WireGuard
docker compose restart wireguard
```

## Automated Testing Script

Create a test script:

```bash
#!/bin/bash
# test-vpn.sh

echo "Starting VPN tests..."

# Test 1: Containers running
echo "Test 1: Checking container status..."
if docker compose ps | grep -q "Up"; then
    echo "✓ Containers are running"
else
    echo "✗ Containers not running"
    exit 1
fi

# Test 2: IPsec connected
echo "Test 2: Checking IPsec connection..."
if docker exec l2tp-ipsec-exit ipsec status | grep -q "ESTABLISHED"; then
    echo "✓ IPsec connection established"
else
    echo "✗ IPsec not connected"
    exit 1
fi

# Test 3: ppp0 interface exists
echo "Test 3: Checking ppp0 interface..."
if docker exec l2tp-ipsec-exit ip addr show ppp0 > /dev/null 2>&1; then
    echo "✓ ppp0 interface is up"
else
    echo "✗ ppp0 interface not found"
    exit 1
fi

# Test 4: WireGuard running
echo "Test 4: Checking WireGuard..."
if docker exec wireguard-entry wg show | grep -q "wg0"; then
    echo "✓ WireGuard is running"
else
    echo "✗ WireGuard not running"
    exit 1
fi

# Test 5: Connectivity
echo "Test 5: Checking internet connectivity..."
if docker exec wireguard-entry ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    echo "✓ Internet connectivity works"
else
    echo "✗ No internet connectivity"
    exit 1
fi

echo ""
echo "All tests passed! ✓"
```

Make it executable and run:
```bash
chmod +x test-vpn.sh
./test-vpn.sh
```

## Load Testing

For production deployments, test with multiple concurrent clients:

```bash
# Generate 10 client configurations
for i in {1..10}; do
    wg genkey > "client${i}_private.key"
    cat "client${i}_private.key" | wg pubkey > "client${i}_public.key"
done

# Simulate connections
# Use tools like:
# - ab (Apache Bench)
# - wrk
# - iperf3
# - netperf
```

## Monitoring Examples

### Real-time Monitoring

```bash
# Watch container resources
docker stats wireguard-entry l2tp-ipsec-exit

# Watch WireGuard peers
watch -n 5 'docker exec wireguard-entry wg show'

# Watch connection status
watch -n 10 'docker exec l2tp-ipsec-exit ipsec status'
```

### Log Analysis

```bash
# Count errors in logs
docker compose logs | grep -i error | wc -l

# Find connection drops
docker compose logs | grep -i "connection.*failed"

# Monitor bandwidth usage
docker exec wireguard-entry wg show wg0 transfer
```

## Troubleshooting Examples

See README.md Troubleshooting section for detailed troubleshooting procedures.

---

For more examples and scenarios, please open an issue on GitHub!
