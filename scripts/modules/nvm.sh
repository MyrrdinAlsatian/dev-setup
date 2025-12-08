#!/usr/bin/env bash

################################################################################
# NVM (Node Version Manager) Installation Module
################################################################################

NVM_VERSION="v0.39.7"
NVM_DIR="${HOME}/.nvm"

################################################################################
# Install NVM
################################################################################
install_nvm() {
    # Unset NPM_CONFIG_PREFIX to avoid nvm incompatibility
    # Reference: nvm is not compatible with the NPM_CONFIG_PREFIX environment variable
    if [ -n "$NPM_CONFIG_PREFIX" ]; then
        unset NPM_CONFIG_PREFIX
        log_info "Unset NPM_CONFIG_PREFIX to allow nvm to work correctly"
    fi
    
    if [[ -d "${NVM_DIR}" ]] && [[ -s "${NVM_DIR}/nvm.sh" ]]; then
        log_success "NVM is already installed"
        source "${NVM_DIR}/nvm.sh"
        local nvm_version
        nvm_version=$(nvm --version)
        log_info "NVM version: ${nvm_version}"
        
        if confirm "Would you like to install the latest LTS version of Node.js?"; then
            install_node_lts
        fi
        return 0
    fi
    
    log_step "Installing NVM..."
    
    # Download and install NVM
    download_file "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" "/tmp/nvm-install.sh"
    bash /tmp/nvm-install.sh
    rm -f /tmp/nvm-install.sh
    
    # Load NVM
    export NVM_DIR="${HOME}/.nvm"
    [ -s "${NVM_DIR}/nvm.sh" ] && source "${NVM_DIR}/nvm.sh"
    
    if command -v nvm >/dev/null 2>&1; then
        log_success "NVM installed successfully"
        
        # Install Node.js LTS
        install_node_lts
        
        # Add NVM to shell configuration
        configure_nvm_shell
    else
        log_error "Failed to install NVM"
        return 1
    fi
}

################################################################################
# Install Node.js LTS version
################################################################################
install_node_lts() {
    log_step "Installing Node.js LTS version..."
    
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    
    local node_version
    node_version=$(node --version)
    log_success "Node.js ${node_version} installed"
    
    local npm_version
    npm_version=$(npm --version)
    log_info "npm version: ${npm_version}"
    
    # Install pnpm for better package management
    install_pnpm
}

################################################################################
# Install pnpm package manager
################################################################################
install_pnpm() {
    log_step "Installing pnpm package manager..."
    
    # Try corepack first (preferred method for pnpm installation)
    if command -v corepack >/dev/null 2>&1; then
        log_info "Using corepack to install pnpm"
        if corepack enable 2>/dev/null; then
            if corepack prepare pnpm@latest --activate 2>/dev/null; then
                local pnpm_version
                pnpm_version=$(pnpm --version 2>/dev/null || echo "unknown")
                log_success "pnpm ${pnpm_version} installed via corepack"
                return 0
            fi
        fi
        log_warning "corepack failed, falling back to npm installation"
    fi
    
    # Fallback to npm install -g pnpm
    log_info "Installing pnpm via npm"
    if npm install -g pnpm 2>/dev/null; then
        local pnpm_version
        pnpm_version=$(pnpm --version 2>/dev/null || echo "unknown")
        log_success "pnpm ${pnpm_version} installed via npm"
    else
        log_error "Failed to install pnpm"
        return 1
    fi
}

################################################################################
# Configure NVM in shell
################################################################################
configure_nvm_shell() {
    local shell_rc
    shell_rc="$(get_shell_rc)"
    
    log_step "Configuring NVM in ${shell_rc}..."
    
    # NVM configuration is already added by the installer
    # Just verify it's there
    if grep -q "NVM_DIR" "${shell_rc}" 2>/dev/null; then
        log_success "NVM is already configured in ${shell_rc}"
    else
        log_warning "NVM configuration not found in ${shell_rc}"
        log_info "Please restart your shell or run: source ${shell_rc}"
    fi
}
