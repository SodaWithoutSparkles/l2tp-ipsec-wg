# Secrets directory
# Create this directory and add your secret files here

# Required secret files:
# - vpn_server_ip.txt: IP address or hostname of your L2TP/IPsec server
# - vpn_ipsec_psk.txt: IPsec pre-shared key
# - vpn_username.txt: VPN username
# - vpn_password.txt: VPN password

# Example commands to create secrets:
# echo "vpn.example.com" > secrets/vpn_server_ip.txt
# echo "your-ipsec-psk" > secrets/vpn_ipsec_psk.txt
# echo "your-username" > secrets/vpn_username.txt
# echo "your-password" > secrets/vpn_password.txt

# Ensure proper permissions:
# chmod 600 secrets/*.txt
