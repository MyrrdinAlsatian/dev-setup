#!/usr/bin/env bash

################################################################################
# SSH and GPG Keys Setup Script
# Generates and configures SSH and GPG keys for GitHub/GitLab
################################################################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
if [[ -f "${SCRIPT_DIR}/lib/logger.sh" ]]; then
    # shellcheck source=lib/logger.sh
    source "${SCRIPT_DIR}/lib/logger.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
    # shellcheck source=lib/utils.sh
    source "${SCRIPT_DIR}/lib/utils.sh"
fi

# Fallback logging functions if libraries not available
if ! command -v log_info >/dev/null 2>&1; then
    log_info() { echo "ℹ $1"; }
    log_success() { echo "✓ $1"; }
    log_warning() { echo "⚠ $1"; }
    log_error() { echo "✗ $1" >&2; }
    log_step() { echo "→ $1"; }
    log_section() { echo ""; echo "=== $1 ==="; echo ""; }
    print_banner() { echo ""; echo "=== $1 ==="; echo ""; }
    die() { log_error "$1"; exit "${2:-1}"; }
fi

if ! command -v command_exists >/dev/null 2>&1; then
    command_exists() { command -v "$1" >/dev/null 2>&1; }
fi

################################################################################
# Configuration variables
################################################################################
USER_EMAIL=""
USER_NAME=""
SSH_KEY_PATH=""
SSH_KEY_TYPE="ed25519"
GENERATE_SSH=true
GENERATE_GPG=true
NON_INTERACTIVE=false

################################################################################
# Display help
################################################################################
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

SSH and GPG keys initialization script for GitHub/GitLab.

OPTIONS:
    --email EMAIL          Email address (used for SSH and GPG)
    --name NAME            Full name (used for GPG and Git)
    --ssh-path PATH        SSH key path (default: ~/.ssh/id_ed25519 or id_rsa)
    --ssh-type TYPE        SSH key type: ed25519 (default) or rsa
    --no-ssh               Do not generate SSH key
    --no-gpg               Do not generate GPG key
    --help                 Display this help

EXAMPLES:
    # Interactive mode (default)
    ./setup-keys.sh

    # Non-interactive mode with parameters
    ./setup-keys.sh --email "user@example.com" --name "John Doe" --ssh-type rsa

    # Generate SSH key only
    ./setup-keys.sh --no-gpg --email "user@example.com"

    # Generate GPG key only
    ./setup-keys.sh --no-ssh --email "user@example.com" --name "John Doe"

EOF
    exit 0
}

################################################################################
# Parse command line arguments
################################################################################
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --email)
                if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                    log_error "The --email option requires a value"
                    exit 1
                fi
                USER_EMAIL="$2"
                shift 2
                ;;
            --name)
                if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                    log_error "The --name option requires a value"
                    exit 1
                fi
                USER_NAME="$2"
                shift 2
                ;;
            --ssh-path)
                if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                    log_error "The --ssh-path option requires a value"
                    exit 1
                fi
                SSH_KEY_PATH="$2"
                shift 2
                ;;
            --ssh-type)
                if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                    log_error "The --ssh-type option requires a value"
                    exit 1
                fi
                if [[ "$2" != "ed25519" ]] && [[ "$2" != "rsa" ]]; then
                    log_error "Invalid SSH key type: $2 (accepted values: ed25519, rsa)"
                    exit 1
                fi
                SSH_KEY_TYPE="$2"
                shift 2
                ;;
            --no-ssh)
                GENERATE_SSH=false
                shift
                ;;
            --no-gpg)
                GENERATE_GPG=false
                shift
                ;;
            --help)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help to display help."
                exit 1
                ;;
        esac
    done

    # Check if we're in non-interactive mode
    if [[ -n "${USER_EMAIL}" ]] || [[ -n "${USER_NAME}" ]] || [[ -n "${SSH_KEY_PATH}" ]]; then
        NON_INTERACTIVE=true
    fi
}

################################################################################
# Check required dependencies
################################################################################
check_dependencies() {
    log_section "Checking dependencies"
    
    local missing_deps=()
    
    if [[ "${GENERATE_SSH}" == true ]]; then
        if ! command_exists ssh-keygen; then
            missing_deps+=("ssh-keygen")
        fi
        if ! command_exists ssh-agent; then
            missing_deps+=("ssh-agent")
        fi
        if ! command_exists ssh-add; then
            missing_deps+=("ssh-add")
        fi
    fi
    
    if [[ "${GENERATE_GPG}" == true ]]; then
        if ! command_exists gpg; then
            missing_deps+=("gpg")
        fi
    fi
    
    if ! command_exists git; then
        missing_deps+=("git")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        log_info "Installation instructions:"
        echo ""
        
        if [[ -f /etc/debian_version ]]; then
            echo "  sudo apt-get update"
            echo "  sudo apt-get install -y ${missing_deps[*]}"
        elif [[ -f /etc/redhat-release ]]; then
            echo "  sudo dnf install -y ${missing_deps[*]}"
        elif [[ -f /etc/arch-release ]]; then
            echo "  sudo pacman -S ${missing_deps[*]}"
        elif [[ "$(uname)" == "Darwin" ]]; then
            echo "  brew install ${missing_deps[*]}"
        else
            echo "  Install the following packages: ${missing_deps[*]}"
        fi
        
        exit 1
    fi
    
    log_success "All dependencies are present"
}

################################################################################
# Validate an email address
################################################################################
validate_email() {
    local email="$1"
    
    # Basic email validation pattern
    if [[ ! "${email}" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    
    return 0
}

################################################################################
# Sanitize a string (remove dangerous characters)
################################################################################
sanitize_string() {
    local input="$1"
    
    # Remove dangerous special characters for the shell
    # Keep only letters, numbers, spaces, dashes, underscores, dots, @
    echo "${input}" | sed 's/[^a-zA-Z0-9 @._-]//g'
}

################################################################################
# Sanitize a file path
################################################################################
sanitize_path() {
    local input="$1"
    
    # Remove dangerous characters from paths
    # Keep only letters, numbers, /, _, -, ., ~
    echo "${input}" | sed 's/[^a-zA-Z0-9/_.~-]//g'
}

################################################################################
# Function to ask a yes/no question
################################################################################
ask() {
    local question="$1"
    local response
    
    while true; do
        read -r -p "${question} (y/n): " response
        case "${response}" in
            [oOyY]*)
                return 0
                ;;
            [nN]*)
                return 1
                ;;
            *)
                echo "Invalid response. Please enter y (yes) or n (no)."
                ;;
        esac
    done
}

################################################################################
# Collect user information
################################################################################
collect_user_info() {
    log_section "User information"
    
    # Email
    if [[ -z "${USER_EMAIL}" ]]; then
        while true; do
            read -r -p "Enter your email address: " email_input
            email_input=$(sanitize_string "${email_input}")
            
            if validate_email "${email_input}"; then
                USER_EMAIL="${email_input}"
                break
            else
                log_error "Invalid email address. Please try again."
            fi
        done
    else
        log_info "Email address: ${USER_EMAIL}"
    fi
    
    # Name (required only if GPG is enabled)
    if [[ "${GENERATE_GPG}" == true ]] && [[ -z "${USER_NAME}" ]]; then
        read -r -p "Enter your full name: " name_input
        USER_NAME=$(sanitize_string "${name_input}")
    fi
    
    if [[ -n "${USER_NAME}" ]]; then
        log_info "Name: ${USER_NAME}"
    fi
}

################################################################################
# Setup .ssh directory permissions
################################################################################
setup_ssh_directory() {
    local ssh_dir="${HOME}/.ssh"
    
    if [[ ! -d "${ssh_dir}" ]]; then
        log_step "Creating directory ${ssh_dir}"
        mkdir -p "${ssh_dir}"
    fi
    
    # Set correct permissions
    chmod 700 "${ssh_dir}"
    log_step "Permissions set on ${ssh_dir}: 700"
}

################################################################################
# Generate SSH key
################################################################################
generate_ssh_key() {
    log_section "SSH key generation"
    
    # Determine key path
    if [[ -z "${SSH_KEY_PATH}" ]]; then
        if [[ "${SSH_KEY_TYPE}" == "ed25519" ]]; then
            SSH_KEY_PATH="${HOME}/.ssh/id_ed25519"
        else
            SSH_KEY_PATH="${HOME}/.ssh/id_rsa"
        fi
        
        if [[ "${NON_INTERACTIVE}" == false ]]; then
            read -r -p "SSH key path [${SSH_KEY_PATH}]: " custom_path
            if [[ -n "${custom_path}" ]]; then
                SSH_KEY_PATH=$(sanitize_path "${custom_path}")
                # Expand tilde
                SSH_KEY_PATH="${SSH_KEY_PATH/#\~/$HOME}"
            fi
        fi
    else
        SSH_KEY_PATH=$(sanitize_path "${SSH_KEY_PATH}")
        SSH_KEY_PATH="${SSH_KEY_PATH/#\~/$HOME}"
    fi
    
    # Check if key already exists
    if [[ -f "${SSH_KEY_PATH}" ]]; then
        log_warning "An SSH key already exists at: ${SSH_KEY_PATH}"
        
        if [[ "${NON_INTERACTIVE}" == true ]]; then
            log_info "Non-interactive mode: using existing key"
            return 0
        fi
        
        if ! ask "Do you want to replace it?"; then
            log_info "Using existing key"
            return 0
        fi
    fi
    
    # Setup .ssh directory
    setup_ssh_directory
    
    # Generate the key
    log_step "Generating ${SSH_KEY_TYPE} SSH key..."
    
    if [[ "${SSH_KEY_TYPE}" == "ed25519" ]]; then
        ssh-keygen -t ed25519 -C "${USER_EMAIL}" -f "${SSH_KEY_PATH}" -N ""
    elif [[ "${SSH_KEY_TYPE}" == "rsa" ]]; then
        ssh-keygen -t rsa -b 4096 -C "${USER_EMAIL}" -f "${SSH_KEY_PATH}" -N ""
    else
        log_error "Invalid SSH key type: ${SSH_KEY_TYPE}"
        return 1
    fi
    
    # Set correct permissions
    chmod 600 "${SSH_KEY_PATH}"
    chmod 644 "${SSH_KEY_PATH}.pub"
    log_step "Permissions set: 600 (private key), 644 (public key)"
    
    log_success "SSH key generated: ${SSH_KEY_PATH}"
    
    # Add to SSH agent
    add_to_ssh_agent
    
    # Propose SSH configuration for GitHub/GitLab
    configure_ssh_config
    
    # Display public key
    show_ssh_public_key
}

################################################################################
# Add key to SSH agent
################################################################################
add_to_ssh_agent() {
    log_step "Adding key to SSH agent..."
    
    # Start SSH agent if needed
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
        eval "$(ssh-agent -s)" > /dev/null
    fi
    
    # Add the key
    if ssh-add "${SSH_KEY_PATH}" 2>/dev/null; then
        log_success "Key added to SSH agent"
    else
        log_warning "Unable to add key to SSH agent (may require manual intervention)"
    fi
}

################################################################################
# Configure ~/.ssh/config for GitHub/GitLab
################################################################################
configure_ssh_config() {
    if [[ "${NON_INTERACTIVE}" == true ]]; then
        return 0
    fi
    
    if ! ask "Do you want to add an entry in ~/.ssh/config for GitHub/GitLab?"; then
        return 0
    fi
    
    local ssh_config="${HOME}/.ssh/config"
    
    # Create file if it doesn't exist
    if [[ ! -f "${ssh_config}" ]]; then
        touch "${ssh_config}"
        chmod 600 "${ssh_config}"
    fi
    
    # Add configurations for GitHub and GitLab
    if ! grep -q "Host github.com" "${ssh_config}"; then
        log_step "Adding GitHub configuration..."
        cat >> "${ssh_config}" << EOF

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ${SSH_KEY_PATH}
    IdentitiesOnly yes
EOF
    fi
    
    if ! grep -q "Host gitlab.com" "${ssh_config}"; then
        log_step "Adding GitLab configuration..."
        cat >> "${ssh_config}" << EOF

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ${SSH_KEY_PATH}
    IdentitiesOnly yes
EOF
    fi
    
    log_success "SSH configuration updated: ${ssh_config}"
}

################################################################################
# Display SSH public key
################################################################################
show_ssh_public_key() {
    log_section "SSH public key"
    
    echo ""
    log_info "Here is your SSH public key:"
    echo ""
    cat "${SSH_KEY_PATH}.pub"
    echo ""
    
    log_info "To add this key to GitHub:"
    log_step "1. Go to https://github.com/settings/keys"
    log_step "2. Click 'New SSH key'"
    log_step "3. Paste the key above"
    echo ""
    
    log_info "To add this key to GitLab:"
    log_step "1. Go to https://gitlab.com/-/profile/keys"
    log_step "2. Paste the key above"
    echo ""
}

################################################################################
# Generate GPG key
################################################################################
generate_gpg_key() {
    log_section "GPG key generation"
    
    # Check if a key already exists for this email
    local existing_keys
    existing_keys=$(gpg --list-keys --with-colons "${USER_EMAIL}" 2>/dev/null | grep -c "^uid" || true)
    
    if [[ "${existing_keys}" -gt 0 ]]; then
        log_warning "A GPG key already exists for ${USER_EMAIL}"
        
        if [[ "${NON_INTERACTIVE}" == true ]]; then
            log_info "Non-interactive mode: using existing key"
            return 0
        fi
        
        if ! ask "Do you want to generate a new one?"; then
            log_info "Using existing key"
            return 0
        fi
    fi
    
    log_step "Generating GPG key (this may take a moment)..."
    
    # Create a temporary configuration file for gpg --batch
    local batch_file
    batch_file=$(mktemp)
    
    cat > "${batch_file}" << EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: ${USER_NAME}
Name-Email: ${USER_EMAIL}
Expire-Date: 0
%no-protection
%commit
EOF
    
    # Generate the key
    if gpg --batch --gen-key "${batch_file}" 2>/dev/null; then
        log_success "GPG key generated successfully"
    else
        log_error "Failed to generate GPG key"
        rm -f "${batch_file}"
        return 1
    fi
    
    # Clean up temporary file
    rm -f "${batch_file}"
    
    # Display public key
    show_gpg_public_key
    
    # Propose to configure Git
    configure_git_gpg
}

################################################################################
# Display GPG public key
################################################################################
show_gpg_public_key() {
    log_section "GPG public key"
    
    # Get key ID
    local gpg_key_id
    gpg_key_id=$(gpg --list-keys --with-colons "${USER_EMAIL}" 2>/dev/null | grep "^fpr" | head -n 1 | cut -d ':' -f 10)
    
    if [[ -z "${gpg_key_id}" ]]; then
        log_error "Unable to find GPG key"
        return 1
    fi
    
    echo ""
    log_info "Here is your GPG public key:"
    echo ""
    gpg --armor --export "${gpg_key_id}"
    echo ""
    
    log_info "To add this key to GitHub:"
    log_step "1. Go to https://github.com/settings/keys"
    log_step "2. Click 'New GPG key'"
    log_step "3. Paste the key above"
    echo ""
    
    log_info "To add this key to GitLab:"
    log_step "1. Go to https://gitlab.com/-/profile/gpg_keys"
    log_step "2. Paste the key above"
    echo ""
}

################################################################################
# Configure Git to use GPG
################################################################################
configure_git_gpg() {
    if [[ "${NON_INTERACTIVE}" == false ]]; then
        if ! ask "Do you want to configure Git to sign your commits with GPG?"; then
            return 0
        fi
    fi
    
    log_step "Configuring Git for GPG..."
    
    # Get key ID
    local gpg_key_id
    gpg_key_id=$(gpg --list-keys --with-colons "${USER_EMAIL}" 2>/dev/null | grep "^fpr" | head -n 1 | cut -d ':' -f 10)
    
    if [[ -z "${gpg_key_id}" ]]; then
        log_error "Unable to find GPG key"
        return 1
    fi
    
    # Configure Git
    git config --global user.signingkey "${gpg_key_id}"
    git config --global commit.gpgsign true
    
    log_success "Git configured to sign commits with GPG key"
}

################################################################################
# Configure Git (user.name and user.email)
################################################################################
configure_git_user() {
    log_section "Git configuration"
    
    # Check current configuration
    local current_name
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    
    local current_email
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    
    # Configure name if needed
    if [[ -z "${current_name}" ]] && [[ -n "${USER_NAME}" ]]; then
        git config --global user.name "${USER_NAME}"
        log_success "Git user.name configured: ${USER_NAME}"
    elif [[ -n "${current_name}" ]]; then
        log_info "Git user.name already configured: ${current_name}"
    fi
    
    # Configure email if needed
    if [[ -z "${current_email}" ]] && [[ -n "${USER_EMAIL}" ]]; then
        git config --global user.email "${USER_EMAIL}"
        log_success "Git user.email configured: ${USER_EMAIL}"
    elif [[ -n "${current_email}" ]]; then
        log_info "Git user.email already configured: ${current_email}"
    fi
}

################################################################################
# Main function
################################################################################
main() {
    print_banner "SSH and GPG Keys Setup"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Check dependencies
    check_dependencies
    
    # Collect user information
    collect_user_info
    
    # Generate SSH key
    if [[ "${GENERATE_SSH}" == true ]]; then
        generate_ssh_key
    fi
    
    # Generate GPG key
    if [[ "${GENERATE_GPG}" == true ]]; then
        if [[ -z "${USER_NAME}" ]]; then
            log_warning "Name is required to generate a GPG key"
            if [[ "${NON_INTERACTIVE}" == false ]]; then
                read -r -p "Enter your full name: " name_input
                USER_NAME=$(sanitize_string "${name_input}")
            fi
        fi
        
        if [[ -n "${USER_NAME}" ]]; then
            generate_gpg_key
        else
            log_warning "GPG key generation skipped (missing name)"
        fi
    fi
    
    # Configure Git
    configure_git_user
    
    # Final message
    echo ""
    log_section "Setup complete"
    log_success "Your keys have been generated successfully!"
    echo ""
    log_info "Don't forget to add your public keys to GitHub/GitLab"
    log_info "and test your SSH connection with: ssh -T git@github.com"
    echo ""
}

# Execute the script
main "$@"
