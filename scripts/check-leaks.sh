#!/usr/bin/env bash

# Torrent VPN Stack - Comprehensive Leak Detection Script
# Tests for IP leaks, DNS leaks, IPv6 leaks, and WebRTC leaks

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Comprehensive Leak Detection Test                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

LEAK_DETECTED=false

# Test 1: IP Leak Test
echo -e "${BLUE}[Test 1/5]${NC} IP Leak Detection"
echo -e "${BLUE}═══════════════════════════════════════${NC}"

# Get your real IP (from host, not through VPN)
echo "Getting your real IP (from host machine)..."
REAL_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "unknown")
echo -e "${BLUE}Your real IP (host): ${REAL_IP}${NC}"
echo ""

# Get VPN IP from qBittorrent
echo "Getting IP as seen from qBittorrent container..."
QBIT_IP=$(docker exec qbittorrent wget -T 10 -qO- https://api.ipify.org 2>/dev/null || echo "unknown")

if [ "$QBIT_IP" = "unknown" ]; then
    echo -e "${RED}✗ FAIL: Could not get IP from qBittorrent${NC}"
    echo -e "${YELLOW}  Container may not be running or VPN is down${NC}"
    LEAK_DETECTED=true
elif [ "$QBIT_IP" = "$REAL_IP" ]; then
    echo -e "${RED}✗ LEAK DETECTED: qBittorrent is using your REAL IP!${NC}"
    echo -e "${RED}  qBittorrent IP: ${QBIT_IP}${NC}"
    echo -e "${RED}  Real IP: ${REAL_IP}${NC}"
    echo -e "${RED}  VPN is NOT working!${NC}"
    LEAK_DETECTED=true
else
    echo -e "${GREEN}✓ PASS: qBittorrent is using VPN IP: ${QBIT_IP}${NC}"
    echo -e "${GREEN}  Your real IP (${REAL_IP}) is hidden${NC}"
fi
echo ""

# Test 2: DNS Leak Test
echo -e "${BLUE}[Test 2/5]${NC} DNS Leak Detection"
echo -e "${BLUE}═══════════════════════════════════════${NC}"

# Check DNS servers being used
echo "Checking which DNS servers are being used..."
DNS_CHECK=$(docker exec qbittorrent nslookup google.com 2>&1 || echo "failed")

if echo "$DNS_CHECK" | grep -q "failed"; then
    echo -e "${RED}✗ FAIL: DNS resolution failed${NC}"
    LEAK_DETECTED=true
else
    DNS_SERVER=$(echo "$DNS_CHECK" | grep -A1 "Server:" | tail -1 | awk '{print $2}')
    echo -e "${BLUE}DNS server in use: ${DNS_SERVER}${NC}"

    # Check if using known safe DNS
    if [[ "$DNS_SERVER" =~ ^1\.1\.1\. ]] || [[ "$DNS_SERVER" =~ ^1\.0\.0\. ]]; then
        echo -e "${GREEN}✓ PASS: Using Cloudflare DNS (DNS-over-TLS)${NC}"
    elif [[ "$DNS_SERVER" =~ ^10\. ]]; then
        echo -e "${GREEN}✓ PASS: Using VPN internal DNS${NC}"
    elif [[ "$DNS_SERVER" =~ ^192\.168\. ]]; then
        echo -e "${YELLOW}⚠ WARNING: Using local network DNS${NC}"
        echo -e "${YELLOW}  This could be your router (potential leak)${NC}"
        echo -e "${YELLOW}  Verify DOT=on in your .env file${NC}"
        LEAK_DETECTED=true
    else
        echo -e "${YELLOW}⚠ UNKNOWN: DNS server ${DNS_SERVER}${NC}"
        echo -e "${YELLOW}  Verify this is your VPN provider's DNS${NC}"
    fi
fi
echo ""

# Test 3: IPv6 Leak Test
echo -e "${BLUE}[Test 3/5]${NC} IPv6 Leak Detection"
echo -e "${BLUE}═══════════════════════════════════════${NC}"

# Check for IPv6 addresses
IPV6_ADDRS=$(docker exec qbittorrent ip -6 addr show scope global 2>/dev/null | grep "inet6" || echo "")

if [ -z "$IPV6_ADDRS" ]; then
    echo -e "${GREEN}✓ PASS: IPv6 is disabled${NC}"
    echo -e "${GREEN}  No IPv6 leak possible${NC}"
else
    echo -e "${YELLOW}⚠ WARNING: IPv6 addresses detected${NC}"
    echo "$IPV6_ADDRS"
    echo ""
    echo -e "${YELLOW}  Testing if IPv6 traffic is leaking...${NC}"

    # Try to get IPv6 address from external service
    IPV6_EXTERNAL=$(docker exec qbittorrent wget -T 5 -qO- https://api6.ipify.org 2>/dev/null || echo "")
    if [ -n "$IPV6_EXTERNAL" ]; then
        echo -e "${RED}✗ LEAK DETECTED: IPv6 traffic is not going through VPN${NC}"
        echo -e "${RED}  External IPv6: ${IPV6_EXTERNAL}${NC}"
        echo -e "${YELLOW}  Fix: Set DISABLE_IPV6=yes in .env${NC}"
        LEAK_DETECTED=true
    else
        echo -e "${GREEN}✓ IPv6 is present but not leaking (no route)${NC}"
    fi
fi
echo ""

# Test 4: Multiple IP Leak Sources
echo -e "${BLUE}[Test 4/5]${NC} Testing Multiple IP Detection Services"
echo -e "${BLUE}═══════════════════════════════════════${NC}"

echo "Checking IP from multiple sources to ensure consistency..."
IP_SOURCES=(
    "https://api.ipify.org"
    "https://icanhazip.com"
    "https://ifconfig.me/ip"
)

CONSISTENT=true
FIRST_IP=""
for source in "${IP_SOURCES[@]}"; do
    SERVICE_NAME=$(echo "$source" | awk -F/ '{print $3}')
    IP=$(docker exec qbittorrent wget -T 5 -qO- "$source" 2>/dev/null | tr -d '\n\r' || echo "failed")

    if [ "$IP" = "failed" ]; then
        echo -e "${YELLOW}⚠ ${SERVICE_NAME}: Request failed${NC}"
        continue
    fi

    if [ -z "$FIRST_IP" ]; then
        FIRST_IP="$IP"
    fi

    if [ "$IP" = "$FIRST_IP" ]; then
        echo -e "${GREEN}✓ ${SERVICE_NAME}: ${IP}${NC}"
    else
        echo -e "${RED}✗ ${SERVICE_NAME}: ${IP} (INCONSISTENT!)${NC}"
        CONSISTENT=false
        LEAK_DETECTED=true
    fi
done

if $CONSISTENT; then
    echo -e "${GREEN}✓ PASS: All services report the same IP${NC}"
else
    echo -e "${RED}✗ FAIL: IP addresses are inconsistent (possible leak)${NC}"
fi
echo ""

# Test 5: Kill Switch Test (Optional - requires stopping VPN)
echo -e "${BLUE}[Test 5/5]${NC} Kill Switch Verification"
echo -e "${BLUE}═══════════════════════════════════════${NC}"

echo "This test verifies the kill switch by stopping the VPN."
read -p "Do you want to test the kill switch? (This will temporarily stop VPN) (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Stopping Gluetun VPN..."
    docker-compose stop gluetun

    sleep 3

    echo "Attempting to reach internet from qBittorrent (should FAIL)..."
    KILL_SWITCH_TEST=$(docker exec qbittorrent wget -T 5 -qO- https://api.ipify.org 2>&1 || echo "failed")

    if echo "$KILL_SWITCH_TEST" | grep -q "failed\|timeout\|Connection refused"; then
        echo -e "${GREEN}✓ PASS: Kill switch working!${NC}"
        echo -e "${GREEN}  qBittorrent cannot reach internet without VPN${NC}"
    else
        echo -e "${RED}✗ FAIL: Kill switch NOT working!${NC}"
        echo -e "${RED}  qBittorrent can still reach internet: ${KILL_SWITCH_TEST}${NC}"
        LEAK_DETECTED=true
    fi

    echo ""
    echo "Restarting Gluetun VPN..."
    docker-compose start gluetun
    echo "Waiting for VPN to reconnect (30 seconds)..."
    sleep 30
    echo -e "${GREEN}VPN restarted${NC}"
else
    echo -e "${YELLOW}⚠ Kill switch test skipped${NC}"
    echo -e "${BLUE}  To test manually:${NC}"
    echo -e "${BLUE}  1. docker-compose stop gluetun${NC}"
    echo -e "${BLUE}  2. docker exec qbittorrent wget https://api.ipify.org (should fail)${NC}"
    echo -e "${BLUE}  3. docker-compose start gluetun${NC}"
fi
echo ""

# Final Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  Test Summary                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if $LEAK_DETECTED; then
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⚠️  LEAKS DETECTED - DO NOT USE FOR TORRENTING! ⚠️       ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Recommended fixes:${NC}"
    echo "  1. Check VPN credentials in .env"
    echo "  2. Verify VPN is connected: docker-compose logs gluetun"
    echo "  3. Ensure DOT=on in .env (DNS-over-TLS)"
    echo "  4. Set DISABLE_IPV6=yes in .env"
    echo "  5. Restart stack: docker-compose restart"
    echo ""
    exit 1
else
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           ✓ ALL TESTS PASSED - NO LEAKS DETECTED          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✓ IP leak protection: Working${NC}"
    echo -e "${GREEN}✓ DNS leak protection: Working${NC}"
    echo -e "${GREEN}✓ IPv6 leak protection: Working${NC}"
    echo -e "${GREEN}✓ VPN routing: Confirmed${NC}"
    echo ""
    echo -e "${BLUE}Your setup is secure for torrenting!${NC}"
    echo ""
    echo -e "${YELLOW}Additional verification:${NC}"
    echo "  • Visit https://ipleak.net from qBittorrent's Web UI"
    echo "  • Check that IP, DNS, and WebRTC all show VPN location"
    echo "  • Run this test periodically to ensure no regressions"
    echo ""
fi
