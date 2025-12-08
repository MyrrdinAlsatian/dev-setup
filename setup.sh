#!/usr/bin/env bash

################################################################################
# Dev Environment Setup - Main Bootstrap Script
# 
# Purpose: Multi-OS development environment automation
# Supports: Linux, macOS, and remote deployment via SSH
# 
# Usage:
#   ./setup.sh [OPTIONS]
#
# Options:
#   --help              Show this help message
#   --remote HOST       Deploy to remote host via SSH
#   --config FILE       Use custom configuration file
#   --dry-run           Show what would be done without executing
#   --skip-tools        Skip tool installation
#   --skip-dotfiles     Skip dotfiles configuration
################################################################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/scripts/lib"
MODULES_DIR="${SCRIPT_DIR}/scripts/modules"
CONFIG_DIR="${SCRIPT_DIR}/config"

# Default configuration
CONFIG_FILE="${CONFIG_DIR}/default.conf"
DRY_RUN=false
REMOTE_HOST=""
SKIP_TOOLS=false
SKIP_DOTFILES=false

# Source core libraries
source "${LIB_DIR}/logger.sh"
source "${LIB_DIR}/os_detect.sh"
source "${LIB_DIR}/utils.sh"

################################################################################
# Display usage information
################################################################################
usage() {
    cat << EOF
Dev Environment Setup - Multi-OS Automation Tool

Usage: $0 [OPTIONS]

Options:
    --help              Show this help message
    --remote HOST       Deploy to remote host via SSH
    --config FILE       Use custom configuration file
    --dry-run           Show what would be done without executing
    --skip-tools        Skip tool installation
    --skip-dotfiles     Skip dotfiles configuration

Examples:
    # Local installation
    ./setup.sh

    # Remote deployment
    ./setup.sh --remote user@hostname

    # Custom configuration
    ./setup.sh --config my-config.conf

    # Dry run to see what would be done
    ./setup.sh --dry-run

EOF
    exit 0
}

################################################################################
# Parse command line arguments
################################################################################
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                usage
                ;;
            --remote)
                REMOTE_HOST="$2"
                shift 2
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-tools)
                SKIP_TOOLS=true
                shift
                ;;
            --skip-dotfiles)
                SKIP_DOTFILES=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

################################################################################
# Deploy to remote host
################################################################################
deploy_remote() {
    local host="$1"
    
    log_info "Deploying to remote host: ${host}"
    
    # Create temporary directory on remote
    log_step "Creating temporary directory on remote host"
    ssh "${host}" "mkdir -p /tmp/dev-setup"
    
    # Copy scripts to remote
    log_step "Copying setup scripts to remote host"
    scp -r "${SCRIPT_DIR}"/* "${host}:/tmp/dev-setup/"
    
    # Execute setup on remote
    log_step "Executing setup on remote host"
    ssh -t "${host}" "cd /tmp/dev-setup && bash setup.sh"
    
    log_success "Remote deployment completed"
}

################################################################################
# Safely execute a tool installation function
# Arguments:
#   $1 - Function name to execute
#   $2 - Tool name for error reporting
################################################################################
safe_install() {
    local func_name="$1"
    local tool_name="$2"
    
    # Execute the function and capture the exit code
    # Temporarily disable exit on error for this function call
    set +e
    "${func_name}"
    local exit_code=$?
    set -e
    
    # Track failure if the function returned non-zero
    if [[ ${exit_code} -ne 0 ]]; then
        log_warning "${tool_name} installation encountered an error (exit code: ${exit_code})"
        track_failure "${tool_name}"
        return 1
    fi
    
    return 0
}

################################################################################
# Main setup workflow
################################################################################
main() {
    parse_arguments "$@"
    
    # Print banner
    print_banner "Dev Environment Setup"
    
    # Handle remote deployment
    if [[ -n "${REMOTE_HOST}" ]]; then
        deploy_remote "${REMOTE_HOST}"
        exit 0
    fi
    
    # Detect operating system
    log_section "System Detection"
    detect_os
    log_info "Operating System: ${OS_TYPE}"
    log_info "Distribution: ${OS_DISTRO}"
    log_info "Architecture: ${OS_ARCH}"
    if is_wsl; then
        log_info "Environment: WSL (Windows Subsystem for Linux)"
    fi
    
    # Load configuration
    log_section "Configuration"
    if [[ -f "${CONFIG_FILE}" ]]; then
        log_info "Loading configuration from: ${CONFIG_FILE}"
        source "${CONFIG_FILE}"
    else
        log_warning "Configuration file not found: ${CONFIG_FILE}"
        log_info "Using default settings"
    fi
    
    # Check prerequisites
    log_section "Prerequisites Check"
    source "${MODULES_DIR}/prerequisites.sh"
    check_prerequisites
    
    # Install tools
    if [[ "${SKIP_TOOLS}" != true ]]; then
        log_section "Tool Installation"
        
        source "${MODULES_DIR}/git.sh"
        safe_install install_git "Git" || true
        
        source "${MODULES_DIR}/docker.sh"
        safe_install install_docker "Docker" || true
        
        source "${MODULES_DIR}/nvm.sh"
        safe_install install_nvm "NVM (Node Version Manager)" || true
        
        source "${MODULES_DIR}/tmux.sh"
        safe_install install_tmux "Tmux" || true
        
        source "${MODULES_DIR}/starship.sh"
        safe_install install_starship "Starship" || true
        
        # Install optional tools if enabled
        if [[ "${INSTALL_OPTIONAL_TOOLS:-true}" == true ]]; then
            source "${MODULES_DIR}/optional_tools.sh"
            safe_install install_optional_tools "Optional Tools" || true
        fi
        
        # Install UV CLI tools
        source "${MODULES_DIR}/uv_tools.sh"
        safe_install install_uv_cli_tools "UV CLI Tools" || true
    else
        log_info "Skipping tool installation (--skip-tools)"
    fi
    
    # Setup dotfiles
    if [[ "${SKIP_DOTFILES}" != true ]]; then
        log_section "Dotfiles Configuration"
        source "${MODULES_DIR}/dotfiles.sh"
        safe_install setup_dotfiles "Dotfiles" || true
    else
        log_info "Skipping dotfiles configuration (--skip-dotfiles)"
    fi
    
    # Print failure summary if any operations failed
    print_failure_summary
    
    # Final summary
    log_section "Setup Complete"
    if [[ ${#FAILED_OPERATIONS[@]} -eq 0 ]]; then
        log_success "Development environment setup completed successfully!"
    else
        log_warning "Development environment setup completed with some errors."
        log_info "Please review the Installation Summary above."
    fi
    log_info "Please restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
}

# Run main function
main "$@"
