#!/bin/bash
# setup.sh -  Installer for INJECTER

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
    ╔═══════════════════════════════════════╗
    ║                                       ║
    ║          INJECTER SETUP               ║
    ║          ---Installer---              ║
    ║                                       ║
    ╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"
echo "GitHub: https://github.com/zerotrace-hub/Injecter.git"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}[!]${NC} This script requires root privileges."
    echo -e "${YELLOW}[!]${NC} Please run: sudo ./setup.sh"
    exit 1
fi

echo -e "${BLUE}[*]${NC} Updating package list..."
apt update -y

echo ""
echo -e "${BLUE}[*]${NC} Installing basic tools..."
apt install -y wget curl git

echo ""
echo -e "${BLUE}[*]${NC} Installing Java JDK..."
apt install -y openjdk-17-jdk default-jdk

echo ""
echo -e "${BLUE}[*]${NC} Installing latest APKTool..."

# Get latest APKTool version
LATEST_VERSION=$(curl -s https://api.github.com/repos/iBotPeaches/Apktool/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_VERSION" ]; then
    LATEST_VERSION="v2.9.0"
    echo -e "${YELLOW}[!]${NC} Using APKTool version: $LATEST_VERSION"
else
    echo -e "${GREEN}[+]${NC} Latest APKTool version: $LATEST_VERSION"
fi

# Download and install APKTool
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

VERSION_NUM=${LATEST_VERSION#v}

# Download wrapper script
curl -L https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool -o apktool

# Download jar file
curl -L "https://github.com/iBotPeaches/Apktool/releases/download/${LATEST_VERSION}/apktool_${VERSION_NUM}.jar" -o apktool.jar

if [ -f "apktool" ] && [ -f "apktool.jar" ]; then
    chmod +x apktool
    chmod +x apktool.jar
    mv apktool /usr/local/bin/
    mv apktool.jar /usr/local/bin/
    echo -e "${GREEN}[+]${NC} APKTool $LATEST_VERSION installed successfully"
else
    echo -e "${RED}[-]${NC} Failed to download APKTool"
fi

cd
rm -rf "$TEMP_DIR"

echo ""
echo -e "${BLUE}[*]${NC} Installing Metasploit Framework..."
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb -o msfinstall
chmod +x msfinstall
./msfinstall
rm msfinstall

# Initialize Metasploit database
echo ""
echo -e "${BLUE}[*]${NC} Initializing Metasploit database..."
msfdb init
msfdb start

echo ""
echo -e "${GREEN}[+]${NC} Creating INJECTER keystore..."
keytool -genkey -v -keystore injecter.keystore \
    -alias injecter_key \
    -keyalg RSA -keysize 2048 \
    -validity 10000 \
    -storepass injecter123 \
    -keypass injecter123 \
    -dname "CN=Injecter, OU=GitHub, O=InjecterTool" 2>/dev/null

echo ""
echo -e "${GREEN}[+]${NC} Verifying installations..."

echo -e "${CYAN}Java:${NC} $(java --version 2>/dev/null | head -1 || echo "Not found")"
echo -e "${CYAN}APKTool:${NC} $(apktool --version 2>/dev/null | head -1 || echo "Not found")"
echo -e "${CYAN}msfvenom:${NC} $(msfvenom --version 2>/dev/null | head -1 || echo "Not found")"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}      $  SETUP COMPLETE!    $                   ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run INJECTER main tool:"
echo "     ./Injecter.sh"
echo ""
echo "  2. For quick exploits:"
echo "     ./exploit.sh"
echo ""
echo -e "${BLUE}GitHub Repository:${NC}"
echo "  https://github.com/yourusername/Injecter"
echo ""