#!/usr/bin/env bash

################################################################################
# Dotfiles Management Module
# Uses GNU Stow to manage dotfiles from a Git repository
################################################################################

# Default dotfiles repository
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/username/dotfiles.git}"
DOTFILES_DIR="${HOME}/.dotfiles"

################################################################################
# Setup dotfiles
################################################################################
setup_dotfiles() {
    log_info "Setting up dotfiles management..."
    
    # Check if stow is installed
    if ! command_exists stow; then
        log_step "Installing GNU Stow..."
        install_stow
    fi
    
    # Ask for dotfiles repository
    configure_dotfiles_repo
    
    # Clone or update dotfiles repository
    sync_dotfiles
    
    # Apply dotfiles using stow
    if [[ -d "${DOTFILES_DIR}" ]]; then
        apply_dotfiles
    else
        log_warning "Dotfiles directory not found, skipping application"
    fi
}

################################################################################
# Install GNU Stow
################################################################################
install_stow() {
    if is_macos; then
        brew install stow
    elif is_linux; then
        install_package "stow"
    else
        log_error "GNU Stow installation not supported on this OS"
        return 1
    fi
    
    if command_exists stow; then
        log_success "GNU Stow installed successfully"
    else
        log_error "Failed to install GNU Stow"
        return 1
    fi
}

################################################################################
# Configure dotfiles repository
################################################################################
configure_dotfiles_repo() {
    local repo_url
    
    # Check if dotfiles directory already exists
    if [[ -d "${DOTFILES_DIR}" ]] && [[ -d "${DOTFILES_DIR}/.git" ]]; then
        log_info "Dotfiles repository already exists at: ${DOTFILES_DIR}"
        repo_url=$(git -C "${DOTFILES_DIR}" config --get remote.origin.url)
        log_info "Current repository: ${repo_url}"
        
        if ! confirm "Would you like to keep this repository?"; then
            read -r -p "Enter new dotfiles repository URL: " repo_url
            DOTFILES_REPO="${repo_url}"
            # Remove old repository
            log_step "Removing old dotfiles repository..."
            rm -rf "${DOTFILES_DIR}"
        else
            DOTFILES_REPO="${repo_url}"
            return 0
        fi
    else
        # Ask for repository URL
        log_info "Please provide your dotfiles repository URL"
        log_info "Example: https://github.com/username/dotfiles.git"
        read -r -p "Dotfiles repository URL (or press Enter to skip): " repo_url
        
        if [[ -z "${repo_url}" ]]; then
            log_warning "No repository provided, skipping dotfiles setup"
            log_info "You can manually clone your dotfiles to ${DOTFILES_DIR} later"
            return 1
        fi
        
        DOTFILES_REPO="${repo_url}"
    fi
}

################################################################################
# Clone or update dotfiles repository
################################################################################
sync_dotfiles() {
    if [[ -d "${DOTFILES_DIR}/.git" ]]; then
        log_step "Updating dotfiles repository..."
        
        # Save current directory
        local current_dir="${PWD}"
        
        # Update repository
        cd "${DOTFILES_DIR}" || return 1
        git pull origin main || git pull origin master
        
        # Return to previous directory
        cd "${current_dir}" || return 1
        
        log_success "Dotfiles repository updated"
    else
        log_step "Cloning dotfiles repository from ${DOTFILES_REPO}..."
        
        # Create parent directory if needed
        ensure_directory "$(dirname "${DOTFILES_DIR}")"
        
        # Clone repository
        if git clone "${DOTFILES_REPO}" "${DOTFILES_DIR}"; then
            log_success "Dotfiles repository cloned successfully"
        else
            log_error "Failed to clone dotfiles repository"
            return 1
        fi
    fi
}

################################################################################
# Apply dotfiles using stow
################################################################################
apply_dotfiles() {
    log_step "Applying dotfiles using GNU Stow..."
    
    # Change to dotfiles directory
    cd "${DOTFILES_DIR}" || return 1
    
    # Find all directories (potential stow packages)
    local packages
    packages=$(find . -maxdepth 1 -type d ! -name ".*" ! -name "scripts" ! -name "bin" -printf "%f\n")
    
    if [[ -z "${packages}" ]]; then
        log_warning "No stow packages found in ${DOTFILES_DIR}"
        log_info "Create directories for each package (e.g., 'bash', 'vim', 'git')"
        log_info "Place config files in package directories using home directory structure"
        return 1
    fi
    
    log_info "Found packages: ${packages}"
    
    # Ask which packages to install
    if confirm "Would you like to install all packages?"; then
        for package in ${packages}; do
            install_stow_package "${package}"
        done
    else
        log_info "Available packages:"
        for package in ${packages}; do
            echo "  - ${package}"
        done
        
        read -r -p "Enter packages to install (space-separated): " selected_packages
        
        for package in ${selected_packages}; do
            if [[ -d "${package}" ]]; then
                install_stow_package "${package}"
            else
                log_warning "Package not found: ${package}"
            fi
        done
    fi
    
    # Return to previous directory
    cd - >/dev/null || return 1
    
    log_success "Dotfiles applied successfully"
}

################################################################################
# Install a single stow package
# Arguments:
#   $1 - Package name
################################################################################
install_stow_package() {
    local package="$1"
    
    log_step "Installing package: ${package}"
    
    # Backup existing files that would be overwritten
    backup_existing_files "${package}"
    
    # Stow the package
    if stow -v -t "${HOME}" "${package}" 2>&1 | grep -v "BUG in find_stowed_path"; then
        log_success "Package ${package} installed"
    else
        log_error "Failed to install package ${package}"
        log_info "You may need to manually resolve conflicts"
    fi
}

################################################################################
# Backup existing files before stowing
# Arguments:
#   $1 - Package name
################################################################################
backup_existing_files() {
    local package="$1"
    local backup_dir="${HOME}/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
    
    # Find files in package
    local files
    files=$(find "${package}" -type f -o -type l)
    
    for file in ${files}; do
        # Remove package prefix to get relative path
        local rel_path="${file#${package}/}"
        local target_file="${HOME}/${rel_path}"
        
        # Backup if file exists and is not a symlink to our dotfiles
        if [[ -e "${target_file}" ]] && [[ ! -L "${target_file}" ]]; then
            ensure_directory "${backup_dir}/$(dirname "${rel_path}")"
            cp "${target_file}" "${backup_dir}/${rel_path}" 2>/dev/null || true
        fi
    done
    
    if [[ -d "${backup_dir}" ]]; then
        log_info "Backed up existing files to: ${backup_dir}"
    fi
}
