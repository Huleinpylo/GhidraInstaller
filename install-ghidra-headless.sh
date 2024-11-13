#!/bin/bash

# Ghidra Headless and ThingFinder Installer Script
# Installs Ghidra, ThingFinder, and dependencies for headless analysis on Linux

set -e  # Exit on any error

# Configuration
GHIDRA_VERSION="11.2.1"
GHIDRA_DATE="20241105"
DOWNLOAD_URL="https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/ghidra_${GHIDRA_VERSION}_PUBLIC_${GHIDRA_DATE}.zip"
INSTALL_DIR="/opt/ghidra"
JAVA_VERSION="21"
THINGFINDER_REPO="https://github.com/user1342/ThingFinder.git"
THINGFINDER_DIR="/opt/ThingFinder"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run this script as root or with sudo"
        exit 1
    fi
}

install_dependencies() {
    log_info "Installing system dependencies..."
    
    # Detect package manager
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y wget unzip python3 python3-pip curl git
        apt-get install -y openjdk-21-jdk  # Install OpenJDK 21
    elif command -v dnf &> /dev/null; then
        dnf update -y
        dnf install -y wget unzip python3 python3-pip curl git java-21-openjdk-devel
    elif command -v yum &> /dev/null; then
        yum update -y
        yum install -y wget unzip python3 python3-pip curl git java-21-openjdk-devel
    else
        log_error "Unsupported package manager. Please install dependencies manually."
        exit 1
    fi
}

check_java_version() {
    if ! command -v java &> /dev/null; then
        log_error "Java is not installed"
        exit 1
    fi
    
    java_ver=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [ "$java_ver" -lt "$JAVA_VERSION" ]; then
        log_error "Java ${JAVA_VERSION} or higher is required (found version ${java_ver})"
        exit 1
    fi
}

install_python_packages() {
    log_info "Installing required Python packages..."
    #pip3 install --upgrade pip
    #pip3 install psutil protobuf==3.20.3
}

download_and_install_ghidra() {
    log_info "Creating installation directory for Ghidra..."
    mkdir -p "$INSTALL_DIR"
    
    log_info "Downloading Ghidra..."
    wget "$DOWNLOAD_URL" -O /tmp/ghidra.zip
    
    log_info "Extracting Ghidra..."
    unzip -q /tmp/ghidra.zip -d /tmp
    
    # Move contents to install directory
    mv /tmp/ghidra_${GHIDRA_VERSION}_PUBLIC/* "$INSTALL_DIR"
    
    # Cleanup
    rm /tmp/ghidra.zip
    rmdir /tmp/ghidra_${GHIDRA_VERSION}_PUBLIC
    
    # Set permissions
    chown -R root:root "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
}

install_thingfinder() {
    log_info "Cloning ThingFinder repository..."
    git clone "$THINGFINDER_REPO" "$THINGFINDER_DIR"
    
    log_info "Installing ThingFinder dependencies..."
    pip3 install -r "$THINGFINDER_DIR/requirements.txt"
    
    log_info "Installing ThingFinder package..."
    python3 -m pip install "$THINGFINDER_DIR"
}

create_symlinks() {
    log_info "Setting up analyzeHeadless in PATH..."

    # Check if analyzeHeadless is already accessible
    if command -v ghidra-headless &> /dev/null; then
        log_info "Ghidra headless is already available in PATH as 'ghidra-headless'."
    else
        # Create symlink if not found in PATH
        log_info "Creating symbolic link in /usr/local/bin..."
        ln -sf "$INSTALL_DIR/support/analyzeHeadless" /usr/local/bin/ghidra-headless
        ln -sf "$INSTALL_DIR/support/analyzeHeadless" /usr/local/bin/analyzeHeadless
        # Verify if it worked
        if command -v ghidra-headless &> /dev/null; then
            log_info "Successfully created symlink. You can run Ghidra headless using: ghidra-headless"
        else
            log_warn "Failed to add ghidra-headless to PATH. You can manually add it by adding the following line to your shell profile:"
            echo "export PATH=\"$INSTALL_DIR/support:\$PATH\""
        fi
    fi
}

main() {
    log_info "Starting Ghidra and ThingFinder installation..."
    
    # Check if running as root
    check_root
    
    # Install system dependencies
    install_dependencies
    
    # Verify Java version
    check_java_version
    
    # Install Python packages
    install_python_packages
    
    # Download and install Ghidra
    download_and_install_ghidra
    
    # Install ThingFinder
    install_thingfinder
    
    # Create symbolic links
    create_symlinks
    
    log_info "Installation complete!"
    log_info "Ghidra headless is installed in ${INSTALL_DIR}"
    log_info "ThingFinder is installed in ${THINGFINDER_DIR}"
    log_info "You can run Ghidra headless using: ghidra-headless"
    log_info ""
    log_info "🏃 To use ThingFinder:"
    log_info "For source code analysis:"
    log_info "  ThingFinder --code <path-to-code-folder> [--output <output json file>]"
    log_info "For binary analysis with GhidraBridge:"
    log_info "  ThingFinder --binary <path-to-binary> [--reachable_from_function <function-name>] [--output <output json file>]"
}

# Run main function
main
