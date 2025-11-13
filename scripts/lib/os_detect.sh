#!/usr/bin/env bash

################################################################################
# OS Detection Library
# Detects operating system, distribution, and architecture
################################################################################

# Global variables for OS information
OS_TYPE=""
OS_DISTRO=""
OS_VERSION=""
OS_ARCH=""
PACKAGE_MANAGER=""

################################################################################
# Detect the operating system
################################################################################
detect_os() {
    # Detect architecture
    OS_ARCH="$(uname -m)"
    
    # Detect OS type
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        detect_linux_distro
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        OS_DISTRO="darwin"
        OS_VERSION="$(sw_vers -productVersion)"
        PACKAGE_MANAGER="brew"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS_TYPE="windows"
        OS_DISTRO="windows"
        PACKAGE_MANAGER="choco"
    else
        OS_TYPE="unknown"
        OS_DISTRO="unknown"
    fi
    
    export OS_TYPE OS_DISTRO OS_VERSION OS_ARCH PACKAGE_MANAGER
}

################################################################################
# Detect Linux distribution
################################################################################
detect_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        # Source the os-release file
        source /etc/os-release
        OS_DISTRO="${ID}"
        OS_VERSION="${VERSION_ID:-unknown}"
        
        # Determine package manager
        case "${OS_DISTRO}" in
            ubuntu|debian)
                PACKAGE_MANAGER="apt"
                ;;
            fedora|rhel|centos|rocky|almalinux)
                PACKAGE_MANAGER="dnf"
                ;;
            arch|manjaro)
                PACKAGE_MANAGER="pacman"
                ;;
            opensuse*|sles)
                PACKAGE_MANAGER="zypper"
                ;;
            alpine)
                PACKAGE_MANAGER="apk"
                ;;
            *)
                PACKAGE_MANAGER="unknown"
                ;;
        esac
    elif [[ -f /etc/redhat-release ]]; then
        OS_DISTRO="rhel"
        PACKAGE_MANAGER="yum"
    elif [[ -f /etc/debian_version ]]; then
        OS_DISTRO="debian"
        PACKAGE_MANAGER="apt"
    else
        OS_DISTRO="unknown"
        PACKAGE_MANAGER="unknown"
    fi
}

################################################################################
# Check if running on Linux
################################################################################
is_linux() {
    [[ "${OS_TYPE}" == "linux" ]]
}

################################################################################
# Check if running on macOS
################################################################################
is_macos() {
    [[ "${OS_TYPE}" == "macos" ]]
}

################################################################################
# Check if running on Windows
################################################################################
is_windows() {
    [[ "${OS_TYPE}" == "windows" ]]
}

################################################################################
# Check if running on a specific distribution
# Arguments:
#   $1 - Distribution name
################################################################################
is_distro() {
    [[ "${OS_DISTRO}" == "$1" ]]
}

################################################################################
# Get package manager command
################################################################################
get_package_manager() {
    echo "${PACKAGE_MANAGER}"
}
