
#!/bin/bash
# Setup script for Injecter - Android Payload Injection Tool


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

BANNER="${RED}
      ██╗███╗   ██╗     ██╗███████╗ ██████╗████████╗███████╗██████╗ 
      ██║████╗  ██║     ██║██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗
      ██║██╔██╗ ██║     ██║█████╗  ██║        ██║   █████╗  ██████╔╝
      ██║██║╚██╗██║██   ██║██╔══╝  ██║        ██║   ██╔══╝  ██╔══██╗
      ██║██║ ╚████║╚█████╔╝███████╗╚██████╗   ██║   ███████╗██║  ██║
      ╚═╝╚═╝  ╚═══╝ ╚════╝ ╚══════╝ ╚═════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
${NC}"

show_message() {
    echo -e "${BLUE}[*]${NC} $1"
}

show_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

show_error() {
    echo -e "${RED}[-]${NC} $1"
}

display_banner() {
    clear
    echo -e "$BANNER"
    echo -e "${GREEN}Android Payload Injection Tool Setup${NC}"
    echo -e "${BLUE}GitHub: https://github.com/zerotrace-hub/Injecter.git${NC}"
    echo ""
}

check_metasploit() {
    if command -v msfvenom &> /dev/null; then
        show_success "Metasploit Framework found"
        return 0
    else
        show_error "Metasploit Framework not found"
        return 1
    fi
}

check_java() {
    if command -v java &> /dev/null; then
        show_success "Java found"
        return 0
    else
        show_error "Java not found"
        return 1
    fi
}

check_keytools() {
    if command -v keytool &> /dev/null && command -v jarsigner &> /dev/null; then
        show_success "Java keytools found"
        return 0
    else
        show_error "Java keytools (keytool/jarsigner) not found"
        return 1
    fi
}

install_metasploit() {
    show_message "Installing Metasploit Framework..."
    
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
        sudo apt-get install metasploit-framework -y
    elif [ -f /etc/redhat-release ]; then
        sudo yum install metasploit-framework -y
    elif [ -f /etc/arch-release ]; then
        sudo pacman -S metasploit --noconfirm
    elif [ -f /data/data/com.termux/files/usr/bin/termux-info ]; then
        pkg install metasploit -y
    else
        show_error "Unsupported OS for auto-install"
        show_message "Please install Metasploit manually from: https://www.metasploit.com/"
        return 1
    fi
}

install_java() {
    show_message "Installing Java JDK..."
    
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
        sudo apt-get install default-jdk -y
    elif [ -f /etc/redhat-release ]; then
        sudo yum install java-11-openjdk-devel -y
    elif [ -f /etc/arch-release ]; then
        sudo pacman -S jdk-openjdk --noconfirm
    elif [ -f /data/data/com.termux/files/usr/bin/termux-info ]; then
        pkg install openjdk-17 -y
    else
        show_error "Unsupported OS for auto-install"
        show_message "Please install Java JDK manually"
        return 1
    fi
}

detect_os() {
    if [ -f /data/data/com.termux/files/usr/bin/termux-info ]; then
        echo "termux"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

main() {
    display_banner
    
    OS=$(detect_os)
    show_message "Detected OS: $OS"
    echo ""
    
    # Check dependencies
    show_message "Checking dependencies..."
    echo ""
    
    check_metasploit
    msf_status=$?
    
    check_java
    java_status=$?
    
    check_keytools
    keytools_status=$?
    
    echo ""
    
    # Ask to install missing dependencies
    if [ $msf_status -eq 1 ]; then
        read -p "$(echo -e ${YELLOW}"[?] Metasploit not found. Install it? (y/n): "${NC})" install_msf
        if [[ $install_msf =~ ^[Yy]$ ]]; then
            install_metasploit
        else
            show_error "Metasploit is required for this tool"
            exit 1
        fi
    fi
    
    if [ $java_status -eq 1 ] || [ $keytools_status -eq 1 ]; then
        read -p "$(echo -e ${YELLOW}"[?] Java/JDK not found. Install it? (y/n): "${NC})" install_java
        if [[ $install_java =~ ^[Yy]$ ]]; then
            install_java
        else
            show_error "Java is required for signing APKs"
            exit 1
        fi
    fi
    
    # Final check
    echo ""
    show_message "Final dependency check..."
    check_metasploit
    check_java
    check_keytools
    
    echo ""
    show_success "Setup completed successfully!"
    echo ""
    show_message "Run ./Inject.sh to start creating payloads"
    show_message "Visit GitHub: https://github.com/yourusername/Injecter"
    echo ""
}

# Run main function
main