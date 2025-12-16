#!/usr/bin/env bash

################################################################################
# Prerequisites Module
# Checks for required tools and system requirements
################################################################################

################################################################################
# Check all prerequisites
################################################################################
check_prerequisites() {
    log_info "Checking system prerequisites..."
    
    local missing_tools=()
    
    # Check for essential tools
    check_tool "curl" "wget" missing_tools
    check_tool "git" "" missing_tools
    
    # OS-specific checks
    if is_linux || is_macos; then
        check_tool "make" "" missing_tools
        check_tool "gcc" "clang" missing_tools
    fi
    
    # Check for sudo (if not root)
    if ! is_root && ! command_exists sudo; then
        missing_tools+=("sudo")
    fi
    
    # Report results
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_warning "Missing required tools:"
        for tool in "${missing_tools[@]}"; do
            log_error "  - ${tool}"
        done
        
        if [[ "${DRY_RUN:-false}" == true ]]; then
            log_dry_run "Would prompt to install missing tools: ${missing_tools[*]}"
            log_dry_run "Would install prerequisites"
        elif confirm "Would you like to install missing tools?"; then
            install_prerequisites "${missing_tools[@]}"
        else
            die "Cannot proceed without required tools"
        fi
    else
        log_success "All prerequisites met"
    fi
}

################################################################################
# Check if a tool exists (with optional alternative)
# Arguments:
#   $1 - Primary tool name
#   $2 - Alternative tool name (optional)
#   $3 - Array name to store missing tools
################################################################################
check_tool() {
    local primary="$1"
    local alternative="$2"
    local -n missing_array="$3"
    
    if ! command_exists "${primary}"; then
        if [[ -n "${alternative}" ]] && command_exists "${alternative}"; then
            log_info "Using ${alternative} as alternative to ${primary}"
        else
            missing_array+=("${primary}")
        fi
    fi
}

################################################################################
# Install prerequisites
# Arguments:
#   $@ - List of tools to install
################################################################################
install_prerequisites() {
    local tools=("$@")
    
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_dry_run "Would install the following prerequisites:"
        for tool in "${tools[@]}"; do
            log_dry_run "  - ${tool}"
        done
        return 0
    fi
    
    log_step "Installing prerequisites..."
    
    for tool in "${tools[@]}"; do
        case "${tool}" in
            curl)
                install_package "curl"
                ;;
            wget)
                install_package "wget"
                ;;
            git)
                install_package "git"
                ;;
            make)
                install_package "make"
                ;;
            gcc)
                if is_distro "ubuntu" || is_distro "debian"; then
                    install_package "build-essential"
                else
                    install_package "gcc"
                fi
                ;;
            sudo)
                log_error "sudo must be installed manually by system administrator"
                ;;
            *)
                install_package "${tool}"
                ;;
        esac
    done
    
    log_success "Prerequisites installed"
}

################################################################################
# Check system resources
################################################################################
check_system_resources() {
    log_info "Checking system resources..."
    
    # Check available disk space (minimum 1GB)
    local available_space
    available_space=$(df -BG "${HOME}" | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [[ ${available_space} -lt 1 ]]; then
        log_warning "Low disk space: ${available_space}GB available"
    else
        log_success "Disk space: ${available_space}GB available"
    fi
    
    # Check available memory
    if is_linux; then
        local available_mem
        available_mem=$(free -g | awk 'NR==2 {print $7}')
        log_info "Available memory: ${available_mem}GB"
    fi
}
