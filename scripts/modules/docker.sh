#!/usr/bin/env bash

################################################################################
# Docker Installation Module
################################################################################

################################################################################
# Install Docker
################################################################################
install_docker() {
    if command_exists docker; then
        local docker_version
        docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
        log_success "Docker is already installed (version ${docker_version})"
        
        if [[ "${DRY_RUN:-false}" == true ]]; then
            if ! docker ps >/dev/null 2>&1; then
                log_dry_run "Would check Docker daemon status and permissions"
                log_dry_run "Would prompt: Would you like to configure Docker permissions?"
            else
                log_dry_run "Docker is already installed and running"
            fi
        elif ! docker ps >/dev/null 2>&1; then
            log_warning "Docker daemon is not running or you don't have permission"
            if confirm "Would you like to configure Docker permissions?"; then
                configure_docker_permissions
            fi
        fi
        return 0
    fi
    
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_dry_run "Would install Docker:"
        if is_linux; then
            log_dry_run "  - Install Docker Engine for Linux"
            log_dry_run "  - Configure Docker repository"
            log_dry_run "  - Start and enable Docker service"
            log_dry_run "  - Add user to docker group"
        elif is_macos; then
            log_dry_run "  - Install Docker Desktop via Homebrew"
        else
            log_warning "Docker installation not supported on this OS via this script"
            log_info "In actual run, you would need to install Docker Desktop manually from https://www.docker.com/products/docker-desktop"
        fi
        return 0
    fi
    
    log_step "Installing Docker..."
    
    if is_linux; then
        install_docker_linux
    elif is_macos; then
        install_docker_macos
    else
        log_error "Docker installation not supported on this OS via this script"
        log_info "Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop"
        return 1
    fi
}

################################################################################
# Install Docker on Linux
################################################################################
install_docker_linux() {
    if is_distro "ubuntu" || is_distro "debian"; then
        install_docker_debian
    elif is_distro "fedora" || is_distro "rhel" || is_distro "centos"; then
        install_docker_rhel
    else
        log_warning "Automated Docker installation not supported for ${OS_DISTRO}"
        log_info "Please install Docker manually from https://docs.docker.com/engine/install/"
        return 1
    fi
    
    # Start and enable Docker service
    run_as_root systemctl start docker
    run_as_root systemctl enable docker
    
    # Configure permissions
    configure_docker_permissions
    
    log_success "Docker installed successfully"
}

################################################################################
# Install Docker on Debian/Ubuntu
################################################################################
install_docker_debian() {
    log_step "Installing Docker on Debian/Ubuntu..."
    
    # Install prerequisites
    run_as_root apt-get update -qq
    run_as_root apt-get install -y ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    run_as_root install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/${OS_DISTRO}/gpg | run_as_root gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    run_as_root chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Set up the repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${OS_DISTRO} \
        $(lsb_release -cs) stable" | run_as_root tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    run_as_root apt-get update -qq
    run_as_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

################################################################################
# Install Docker on RHEL/Fedora/CentOS
################################################################################
install_docker_rhel() {
    log_step "Installing Docker on RHEL/Fedora/CentOS..."
    
    # Install prerequisites
    run_as_root "${PACKAGE_MANAGER}" install -y yum-utils
    
    # Add Docker repository
    run_as_root yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # Install Docker Engine
    run_as_root "${PACKAGE_MANAGER}" install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

################################################################################
# Install Docker on macOS
################################################################################
install_docker_macos() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_dry_run "Would install Docker Desktop on macOS via Homebrew"
        return 0
    fi
    
    log_step "Installing Docker on macOS..."
    
    if command_exists brew; then
        brew install --cask docker
        log_success "Docker installed. Please start Docker Desktop from Applications"
    else
        log_error "Homebrew is required to install Docker on macOS"
        log_info "Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop"
        return 1
    fi
}

################################################################################
# Configure Docker permissions
################################################################################
configure_docker_permissions() {
    if is_linux; then
        if [[ "${DRY_RUN:-false}" == true ]]; then
            log_dry_run "Would configure Docker permissions (add user to docker group)"
            return 0
        fi
        
        log_step "Configuring Docker permissions..."
        
        # Add user to docker group
        if ! groups | grep -q docker; then
            run_as_root usermod -aG docker "${USER}"
            log_warning "User added to docker group. Please log out and back in for changes to take effect"
            log_info "Or run: newgrp docker"
        else
            log_success "User is already in docker group"
        fi
    fi
}
