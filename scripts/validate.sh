#!/bin/bash
set -e

echo "==================================="
echo "Configuration Validation Script"
echo "==================================="
echo ""

ERRORS=0

# Check Docker
echo "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "✗ Docker is not installed"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ Docker found: $(docker --version)"
fi

# Check Docker Compose
echo ""
echo "Checking Docker Compose..."
if ! docker compose version &> /dev/null; then
    echo "✗ Docker Compose is not available"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ Docker Compose found: $(docker compose version)"
fi

# Check WireGuard tools
echo ""
echo "Checking WireGuard tools..."
if ! command -v wg &> /dev/null; then
    echo "⚠ WireGuard tools not installed (optional for key generation)"
    echo "  Install with: apt install wireguard-tools (Debian/Ubuntu)"
    echo "             or: brew install wireguard-tools (macOS)"
else
    echo "✓ WireGuard tools found: $(wg --version)"
fi

# Validate docker-compose.yml
echo ""
echo "Validating docker-compose.yml..."
if docker compose config > /dev/null 2>&1; then
    echo "✓ docker-compose.yml is valid"
else
    echo "✗ docker-compose.yml has syntax errors"
    ERRORS=$((ERRORS + 1))
fi

# Check for required directories
echo ""
echo "Checking directory structure..."
for dir in wireguard strongswan config secrets scripts; do
    if [ -d "$dir" ]; then
        echo "✓ Directory exists: $dir"
    else
        echo "✗ Missing directory: $dir"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check for required files
echo ""
echo "Checking required files..."
REQUIRED_FILES=(
    "wireguard/Dockerfile"
    "wireguard/entrypoint.sh"
    "strongswan/Dockerfile"
    "strongswan/entrypoint.sh"
    "strongswan/ipsec.conf"
    "strongswan/xl2tpd.conf"
    "docker-compose.yml"
    "README.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ File exists: $file"
    else
        echo "✗ Missing file: $file"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check executable scripts
echo ""
echo "Checking script permissions..."
for script in scripts/*.sh wireguard/entrypoint.sh strongswan/entrypoint.sh; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo "✓ Executable: $script"
        else
            echo "⚠ Not executable: $script (fixing...)"
            chmod +x "$script"
            echo "  Fixed: $script is now executable"
        fi
    fi
done

# Check for actual secrets (optional at this stage)
echo ""
echo "Checking for secrets..."
SECRET_FILES=(
    "secrets/vpn_server_ip.txt"
    "secrets/vpn_ipsec_psk.txt"
    "secrets/vpn_username.txt"
    "secrets/vpn_password.txt"
)

ALL_SECRETS_EXIST=true
for secret in "${SECRET_FILES[@]}"; do
    if [ -f "$secret" ]; then
        echo "✓ Secret file exists: $secret"
    else
        echo "⚠ Secret file missing: $secret (required for deployment)"
        ALL_SECRETS_EXIST=false
    fi
done

if [ "$ALL_SECRETS_EXIST" = false ]; then
    echo ""
    echo "Note: Secret files are required to deploy the VPN chain."
    echo "Run the following commands to create them from examples:"
    echo "  cp secrets/vpn_server_ip.txt.example secrets/vpn_server_ip.txt"
    echo "  cp secrets/vpn_ipsec_psk.txt.example secrets/vpn_ipsec_psk.txt"
    echo "  cp secrets/vpn_username.txt.example secrets/vpn_username.txt"
    echo "  cp secrets/vpn_password.txt.example secrets/vpn_password.txt"
    echo "Then edit each file with your actual credentials."
fi

# Check for WireGuard config
echo ""
echo "Checking WireGuard configuration..."
if [ -f "config/wg0.conf" ]; then
    echo "✓ WireGuard configuration exists: config/wg0.conf"
else
    echo "⚠ WireGuard configuration missing: config/wg0.conf (required for deployment)"
    echo ""
    echo "Run the key generation script to create keys and config:"
    echo "  ./scripts/generate-keys.sh"
fi

# Check kernel modules (if on Linux)
if [ "$(uname)" = "Linux" ]; then
    echo ""
    echo "Checking kernel modules..."
    
    if lsmod | grep -q wireguard; then
        echo "✓ WireGuard kernel module loaded"
    else
        echo "⚠ WireGuard kernel module not loaded"
        echo "  This is normal if not yet started or using userspace implementation"
    fi
    
    if lsmod | grep -q ppp_generic; then
        echo "✓ PPP kernel module loaded"
    else
        echo "⚠ PPP kernel module not loaded (may need to load manually)"
        echo "  Run: sudo modprobe ppp_generic ppp_async ppp_deflate"
    fi
    
    if [ -c /dev/ppp ]; then
        echo "✓ /dev/ppp device exists"
    else
        echo "⚠ /dev/ppp device not found (may need to create)"
        echo "  Run: sudo mknod /dev/ppp c 108 0"
    fi
fi

# Summary
echo ""
echo "==================================="
echo "Validation Summary"
echo "==================================="
if [ $ERRORS -eq 0 ]; then
    echo "✓ All critical checks passed!"
    echo ""
    echo "Next steps:"
    if [ "$ALL_SECRETS_EXIST" = false ] || [ ! -f "config/wg0.conf" ]; then
        echo "  1. Create secret files with your VPN credentials"
        echo "  2. Generate WireGuard keys and configuration"
        echo "  3. Run ./scripts/setup.sh to deploy"
    else
        echo "  1. Run ./scripts/setup.sh to deploy the VPN chain"
    fi
    exit 0
else
    echo "✗ Found $ERRORS critical error(s)"
    echo "Please fix the errors above before proceeding."
    exit 1
fi
