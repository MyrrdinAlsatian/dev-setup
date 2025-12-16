#!/usr/bin/env bash

################################################################################
# Git Installation and Configuration Module
################################################################################

################################################################################
# Install Git
################################################################################
install_git() {
    if command_exists git; then
        local git_version
        git_version=$(git --version | awk '{print $3}')
        log_success "Git is already installed (version ${git_version})"
        
        if [[ "${DRY_RUN:-false}" == true ]]; then
            log_dry_run "Would prompt to configure Git"
            configure_git
        elif confirm "Would you like to configure Git?"; then
            configure_git
        fi
        return 0
    fi
    
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_dry_run "Would install Git using package manager: ${PACKAGE_MANAGER}"
        log_dry_run "Would configure Git with user name and email"
        return 0
    fi
    
    log_step "Installing Git..."
    
    case "${PACKAGE_MANAGER}" in
        apt)
            run_as_root apt-get update -qq
            run_as_root apt-get install -y git
            ;;
        dnf|yum)
            run_as_root "${PACKAGE_MANAGER}" install -y git
            ;;
        pacman)
            run_as_root pacman -S --noconfirm git
            ;;
        brew)
            brew install git
            ;;
        *)
            install_package "git"
            ;;
    esac
    
    if command_exists git; then
        log_success "Git installed successfully"
        configure_git
    else
        die "Failed to install Git"
    fi
}

################################################################################
# Configure Git
################################################################################
configure_git() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_dry_run "Would configure Git settings:"
        log_dry_run "  - Set user name and email (if not already set)"
        log_dry_run "  - Set default branch to 'main'"
        log_dry_run "  - Configure Git aliases (co, br, ci, st, etc.)"
        log_dry_run "  - Set pull.rebase to false"
        log_dry_run "  - Enable color output"
        log_dry_run "  - Configure credential helper based on OS"
        return 0
    fi
    
    log_step "Configuring Git..."
    
    # Get user name
    local current_name
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    
    if [[ -z "${current_name}" ]]; then
        read -r -p "Enter your Git user name: " git_name
        git config --global user.name "${git_name}"
    else
        log_info "Git user name already set: ${current_name}"
    fi
    
    # Get user email
    local current_email
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    
    if [[ -z "${current_email}" ]]; then
        read -r -p "Enter your Git email: " git_email
        git config --global user.email "${git_email}"
    else
        log_info "Git email already set: ${current_email}"
    fi
    
    # Set default branch name
    git config --global init.defaultBranch main
    
    # Set useful aliases
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.unstage 'reset HEAD --'
    git config --global alias.last 'log -1 HEAD'
    git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    
    # Set pull behavior
    git config --global pull.rebase false
    
    # Enable color
    git config --global color.ui auto
    
    # Configure credential helper
    if is_macos; then
        git config --global credential.helper osxkeychain
    elif is_linux; then
        git config --global credential.helper cache
    fi
    
    log_success "Git configured successfully"
}
