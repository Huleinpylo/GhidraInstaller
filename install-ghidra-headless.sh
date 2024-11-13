#!/bin/bash

# Ghidra Headless Installer Script
# This script installs Ghidra and its dependencies for headless analysis on Linux

set -e  # Exit on any error

# Configuration
GHIDRA_VERSION="11.2.1"
GHIDRA_DATE="20241105"
DOWNLOAD_URL="https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/ghidra_${GHIDRA_VERSION}_PUBLIC_${GHIDRA_DATE}.zip"
INSTALL_DIR="/opt/ghidra"
JAVA_VERSION="21"

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
    log_info "Installing dependencies..."
    
    # Detect package manager
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        apt-get update
        apt-get install -y wget unzip python3 python3-pip curl
        # Install OpenJDK 21
        apt-get install -y openjdk-21-jdk
    elif command -v dnf &> /dev/null; then
        # Fedora/RHEL
        dnf update -y
        dnf install -y wget unzip python3 python3-pip curl
        dnf install -y java-21-openjdk-devel
    elif command -v yum &> /dev/null; then
        # CentOS
        yum update -y
        yum install -y wget unzip python3 python3-pip curl
        yum install -y java-21-openjdk-devel
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
    pip3 install --upgrade pip
    pip3 install psutil protobuf==3.20.3
}

download_and_install_ghidra() {
    log_info "Creating installation directory..."
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

create_symlinks() {
    log_info "Creating symbolic links..."
    ln -sf "$INSTALL_DIR/support/analyzeHeadless" /usr/local/bin/ghidra-headless
}

main() {
    log_info "Starting Ghidra ${GHIDRA_VERSION} headless installation..."
    
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
    
    # Create symbolic links
    create_symlinks
    
    log_info "Installation complete! Ghidra headless is installed in ${INSTALL_DIR}"
    log_info "You can run Ghidra headless using: ghidra-headless"
    log_info "Example usage:"
    log_info "ghidra-headless /path/to/project ProjectName -import /path/to/binary -postScript script.py"
}

# Run main function
main
