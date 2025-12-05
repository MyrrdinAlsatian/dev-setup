#!/usr/bin/env bash

################################################################################
# Utilities Library
# Common utility functions
################################################################################

################################################################################
# Check if a command exists
# Arguments:
#   $1 - Command name
# Returns:
#   0 if command exists, 1 otherwise
################################################################################
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

################################################################################
# Check if running as root
# Returns:
#   0 if root, 1 otherwise
################################################################################
is_root() {
    [[ "${EUID}" -eq 0 ]]
}

################################################################################
# Ensure running as root (exit if not)
################################################################################
require_root() {
    if ! is_root; then
        die "This script must be run as root or with sudo"
    fi
}

################################################################################
# Run a command with sudo if not root
# Arguments:
#   $@ - Command and arguments
################################################################################
run_as_root() {
    if is_root; then
        "$@"
    else
        sudo "$@"
    fi
}

################################################################################
# Ask for user confirmation
# Arguments:
#   $1 - Question to ask
# Returns:
#   0 if yes, 1 if no
################################################################################
confirm() {
    local question="$1"
    local response
    
    read -r -p "${question} [y/N] " response
    case "${response}" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

################################################################################
# Create directory if it doesn't exist
# Arguments:
#   $1 - Directory path
################################################################################
ensure_directory() {
    local dir="$1"
    
    if [[ ! -d "${dir}" ]]; then
        log_step "Creating directory: ${dir}"
        mkdir -p "${dir}"
    fi
}

################################################################################
# Backup a file or directory
# Arguments:
#   $1 - Path to backup
################################################################################
backup_file() {
    local file="$1"
    
    if [[ -e "${file}" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        log_step "Backing up ${file} to ${backup}"
        cp -r "${file}" "${backup}"
    fi
}

################################################################################
# Download a file
# Arguments:
#   $1 - URL
#   $2 - Output path
################################################################################
download_file() {
    local url="$1"
    local output="$2"
    
    log_step "Downloading ${url}"
    
    if command_exists curl; then
        curl -fsSL -o "${output}" "${url}"
    elif command_exists wget; then
        wget -q -O "${output}" "${url}"
    else
        die "Neither curl nor wget is available"
    fi
}

################################################################################
# Add a line to a file if it doesn't exist
# Arguments:
#   $1 - Line to add
#   $2 - File path
################################################################################
add_line_to_file() {
    local line="$1"
    local file="$2"
    
    if ! grep -qF "${line}" "${file}" 2>/dev/null; then
        echo "${line}" >> "${file}"
        log_step "Added line to ${file}"
    fi
}

################################################################################
# Get the default shell
################################################################################
get_default_shell() {
    basename "${SHELL}"
}

################################################################################
# Detect shell configuration file
################################################################################
get_shell_rc() {
    local shell
    shell="$(get_default_shell)"
    
    case "${shell}" in
        bash)
            echo "${HOME}/.bashrc"
            ;;
        zsh)
            echo "${HOME}/.zshrc"
            ;;
        fish)
            echo "${HOME}/.config/fish/config.fish"
            ;;
        *)
            echo "${HOME}/.profile"
            ;;
    esac
}

################################################################################
# Install package using system package manager
# Arguments:
#   $1 - Package name
################################################################################
install_package() {
    local package="$1"
    
    log_step "Installing package: ${package}"
    
    case "${PACKAGE_MANAGER}" in
        apt)
            run_as_root apt-get update -qq
            run_as_root apt-get install -y "${package}"
            ;;
        dnf)
            run_as_root dnf install -y "${package}"
            ;;
        yum)
            run_as_root yum install -y "${package}"
            ;;
        pacman)
            run_as_root pacman -S --noconfirm "${package}"
            ;;
        zypper)
            run_as_root zypper install -y "${package}"
            ;;
        apk)
            run_as_root apk add "${package}"
            ;;
        brew)
            brew install "${package}"
            ;;
        *)
            die "Unsupported package manager: ${PACKAGE_MANAGER}"
            ;;
    esac
}

################################################################################
# Check if a package is installed
# Arguments:
#   $1 - Package name
# Returns:
#   0 if installed, 1 otherwise
################################################################################
is_package_installed() {
    local package="$1"
    
    case "${PACKAGE_MANAGER}" in
        apt)
            dpkg -l "${package}" 2>/dev/null | grep -q "^ii"
            ;;
        dnf|yum)
            rpm -q "${package}" >/dev/null 2>&1
            ;;
        pacman)
            pacman -Q "${package}" >/dev/null 2>&1
            ;;
        brew)
            brew list "${package}" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}
