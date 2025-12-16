#!/usr/bin/env bash

################################################################################
# Optional Development Tools Installation Module
#
# This module installs optional but useful development tools including:
# - Fonts (Fira Code Nerd Font)
# - CLI utilities (jq, yq, make)
# - Terminal (tabby)
# - Image tools (ffmpeg, imagemagick, jpegoptim, optipng)
# - Certificate management (mkcert)
# - Database tools (DBeaver, PostgreSQL client)
################################################################################

# Version constants for tools installed via binary download
readonly YQ_VERSION="v4.40.5"
readonly MKCERT_VERSION="v1.4.4"

################################################################################
# Enable Ubuntu Universe Repository
################################################################################
enable_universe_repo() {
    # Only applicable for Ubuntu/Debian systems
    if ! is_linux; then
        return 0
    fi
    
    if [[ "${PACKAGE_MANAGER}" != "apt" ]]; then
        # Not applicable for non-apt package managers
        return 0
    fi
    
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_dry_run "Would enable Universe repository on Ubuntu/Debian"
        return 0
    fi
    
    log_step "Enabling Universe repository..."
    
    # Check if universe is already enabled
    if grep -q "^deb.*universe" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        log_success "Universe repository is already enabled"
        return 0
    fi
    
    if command_exists add-apt-repository; then
        run_as_root add-apt-repository -y universe
        run_as_root apt-get update -qq
        log_success "Universe repository enabled successfully"
    else
        log_warning "add-apt-repository not found, installing software-properties-common..."
        run_as_root apt-get install -y software-properties-common
        run_as_root add-apt-repository -y universe
        run_as_root apt-get update -qq
        log_success "Universe repository enabled successfully"
    fi
}

################################################################################
# Install Fira Code Nerd Font
################################################################################
install_fira_code_nerd_font() {
    log_step "Installing Fira Code Nerd Font..."
    
    local fonts_dir
    if is_macos; then
        fonts_dir="${HOME}/Library/Fonts"
    else
        fonts_dir="${HOME}/.local/share/fonts"
    fi
    
    mkdir -p "${fonts_dir}"
    
    # Check if already installed
    if find "${fonts_dir}" -name "*FiraCode*Nerd*" 2>/dev/null | grep -q .; then
        log_success "Fira Code Nerd Font is already installed"
        return 0
    fi
    
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
    local temp_dir
    temp_dir=$(mktemp -d)
    
    log_info "Downloading Fira Code Nerd Font..."
    if command_exists curl; then
        curl -fsSL "${font_url}" -o "${temp_dir}/FiraCode.zip"
    elif command_exists wget; then
        wget -q "${font_url}" -O "${temp_dir}/FiraCode.zip"
    else
        log_error "Neither curl nor wget found"
        return 1
    fi
    
    if command_exists unzip; then
        unzip -q "${temp_dir}/FiraCode.zip" -d "${fonts_dir}"
        rm -rf "${temp_dir}"
        
        # Update font cache on Linux
        if is_linux && command_exists fc-cache; then
            fc-cache -f "${fonts_dir}"
        fi
        
        log_success "Fira Code Nerd Font installed successfully"
        log_info "Font installed to: ${fonts_dir}"
    else
        log_error "unzip command not found, cannot extract font"
        rm -rf "${temp_dir}"
        return 1
    fi
}

################################################################################
# Install jq (JSON processor)
################################################################################
install_jq() {
    if command_exists jq; then
        local jq_version
        jq_version=$(jq --version 2>&1)
        log_success "jq is already installed (${jq_version})"
        return 0
    fi
    
    log_step "Installing jq..."
    
    if is_macos; then
        brew install jq
    elif is_linux; then
        install_package "jq"
    else
        log_warning "jq installation not supported on this OS"
        return 1
    fi
    
    if command_exists jq; then
        log_success "jq installed successfully"
    else
        log_error "Failed to install jq"
        return 1
    fi
}

################################################################################
# Install yq (YAML processor)
################################################################################
install_yq() {
    if command_exists yq; then
        local yq_version
        yq_version=$(yq --version 2>&1 | head -n 1)
        log_success "yq is already installed (${yq_version})"
        return 0
    fi
    
    log_step "Installing yq..."
    
    if is_macos; then
        brew install yq
    elif is_linux; then
        # Install the Go-based yq (mikefarah/yq) via binary download
        local arch
        case "${OS_ARCH}" in
            x86_64)
                arch="amd64"
                ;;
            aarch64|arm64)
                arch="arm64"
                ;;
            *)
                log_error "Unsupported architecture for yq: ${OS_ARCH}"
                return 1
                ;;
        esac
        
        local yq_url="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${arch}"
        
        log_info "Downloading yq..."
        if command_exists curl; then
            run_as_root sh -c "curl -fsSL '${yq_url}' -o /usr/local/bin/yq"
        elif command_exists wget; then
            run_as_root sh -c "wget -q '${yq_url}' -O /usr/local/bin/yq"
        else
            log_error "Neither curl nor wget found"
            return 1
        fi
        
        run_as_root chmod +x /usr/local/bin/yq
        log_success "yq installed successfully"
    else
        log_warning "yq installation not supported on this OS"
        return 1
    fi
}

################################################################################
# Install make
################################################################################
install_make() {
    if command_exists make; then
        local make_version
        make_version=$(make --version | head -n 1)
        log_success "make is already installed (${make_version})"
        return 0
    fi
    
    log_step "Installing make..."
    
    if is_macos; then
        # Usually included with Xcode Command Line Tools
        if ! xcode-select -p &>/dev/null; then
            xcode-select --install
        fi
    elif is_linux; then
        case "${PACKAGE_MANAGER}" in
            apt)
                install_package "build-essential"
                ;;
            dnf|yum)
                run_as_root "${PACKAGE_MANAGER}" groupinstall -y "Development Tools"
                ;;
            pacman)
                install_package "base-devel"
                ;;
            *)
                install_package "make"
                ;;
        esac
    else
        log_warning "make installation not supported on this OS"
        return 1
    fi
    
    if command_exists make; then
        log_success "make installed successfully"
    else
        log_error "Failed to install make"
        return 1
    fi
}

################################################################################
# Install Tabby (terminal emulator) or alternative
################################################################################
install_tabby() {
    log_step "Installing Tabby terminal..."
    log_info "Tabby requires manual installation from https://tabby.sh/"
    log_info "Alternative: You can use existing terminals like Alacritty, Kitty, or WezTerm"
    
    if confirm "Would you like to install Alacritty as an alternative modern terminal?"; then
        install_alacritty
    else
        log_info "Skipping terminal installation"
        log_info "To install Tabby manually, visit: https://tabby.sh/"
    fi
}

################################################################################
# Install Alacritty (alternative terminal)
################################################################################
install_alacritty() {
    if command_exists alacritty; then
        log_success "Alacritty is already installed"
        return 0
    fi
    
    log_step "Installing Alacritty..."
    
    if is_macos; then
        brew install --cask alacritty
    elif is_linux; then
        case "${PACKAGE_MANAGER}" in
            apt)
                install_package "alacritty"
                ;;
            dnf|yum)
                install_package "alacritty"
                ;;
            pacman)
                install_package "alacritty"
                ;;
            *)
                log_warning "Alacritty installation not supported via package manager"
                log_info "You can build from source: https://github.com/alacritty/alacritty"
                return 1
                ;;
        esac
    else
        log_warning "Alacritty installation not supported on this OS"
        return 1
    fi
    
    if command_exists alacritty; then
        log_success "Alacritty installed successfully"
    else
        log_error "Failed to install Alacritty"
        return 1
    fi
}

################################################################################
# Install Image Processing Tools
################################################################################
install_image_tools() {
    log_step "Installing image processing tools..."
    
    local tools=("ffmpeg" "imagemagick" "jpegoptim" "optipng")
    local failed=0
    
    for tool in "${tools[@]}"; do
        case "${tool}" in
            imagemagick)
                local cmd="convert"
                local pkg="imagemagick"
                ;;
            *)
                local cmd="${tool}"
                local pkg="${tool}"
                ;;
        esac
        
        if command_exists "${cmd}"; then
            log_success "${tool} is already installed"
        else
            log_info "Installing ${tool}..."
            if is_macos; then
                brew install "${pkg}" || failed=$((failed + 1))
            elif is_linux; then
                install_package "${pkg}" || failed=$((failed + 1))
            fi
        fi
    done
    
    if [[ ${failed} -eq 0 ]]; then
        log_success "All image processing tools installed successfully"
    else
        log_warning "Some image tools failed to install"
        return 1
    fi
}

################################################################################
# Install mkcert (local certificate management)
################################################################################
install_mkcert() {
    if command_exists mkcert; then
        local mkcert_version
        mkcert_version=$(mkcert --version 2>&1 || echo "unknown")
        log_success "mkcert is already installed (${mkcert_version})"
        return 0
    fi
    
    log_step "Installing mkcert..."
    
    if is_macos; then
        brew install mkcert
        brew install nss  # For Firefox support
    elif is_linux; then
        case "${PACKAGE_MANAGER}" in
            apt)
                # Install dependencies
                install_package "libnss3-tools"
                
                # Download and install mkcert binary
                local arch
                case "${OS_ARCH}" in
                    x86_64)
                        arch="amd64"
                        ;;
                    aarch64|arm64)
                        arch="arm64"
                        ;;
                    *)
                        log_error "Unsupported architecture for mkcert: ${OS_ARCH}"
                        return 1
                        ;;
                esac
                
                local mkcert_url="https://github.com/FiloSottile/mkcert/releases/download/${MKCERT_VERSION}/mkcert-${MKCERT_VERSION}-linux-${arch}"
                
                log_info "Downloading mkcert..."
                if command_exists curl; then
                    run_as_root sh -c "curl -fsSL '${mkcert_url}' -o /usr/local/bin/mkcert"
                elif command_exists wget; then
                    run_as_root sh -c "wget -q '${mkcert_url}' -O /usr/local/bin/mkcert"
                else
                    log_error "Neither curl nor wget found"
                    return 1
                fi
                
                run_as_root chmod +x /usr/local/bin/mkcert
                ;;
            dnf|yum)
                install_package "nss-tools"
                
                # Detect architecture for dnf/yum
                local arch
                case "${OS_ARCH}" in
                    x86_64)
                        arch="amd64"
                        ;;
                    aarch64|arm64)
                        arch="arm64"
                        ;;
                    *)
                        log_error "Unsupported architecture for mkcert: ${OS_ARCH}"
                        return 1
                        ;;
                esac
                
                local mkcert_url="https://github.com/FiloSottile/mkcert/releases/download/${MKCERT_VERSION}/mkcert-${MKCERT_VERSION}-linux-${arch}"
                
                # Add curl/wget fallback
                if command_exists curl; then
                    run_as_root sh -c "curl -fsSL '${mkcert_url}' -o /usr/local/bin/mkcert && chmod +x /usr/local/bin/mkcert"
                elif command_exists wget; then
                    run_as_root sh -c "wget -q '${mkcert_url}' -O /usr/local/bin/mkcert && chmod +x /usr/local/bin/mkcert"
                else
                    log_error "Neither curl nor wget found"
                    return 1
                fi
                ;;
            pacman)
                install_package "mkcert"
                install_package "nss"
                ;;
            *)
                log_warning "mkcert installation not supported via package manager"
                return 1
                ;;
        esac
    else
        log_warning "mkcert installation not supported on this OS"
        return 1
    fi
    
    if command_exists mkcert; then
        log_success "mkcert installed successfully"
        log_info "Run 'mkcert -install' to install the local CA"
    else
        log_error "Failed to install mkcert"
        return 1
    fi
}

################################################################################
# Install DBeaver (database management tool)
################################################################################
install_dbeaver() {
    log_step "Installing DBeaver..."
    
    if is_macos; then
        if brew list --cask dbeaver-community &>/dev/null; then
            log_success "DBeaver is already installed"
            return 0
        fi
        brew install --cask dbeaver-community
    elif is_linux; then
        case "${PACKAGE_MANAGER}" in
            apt)
                if dpkg -l | grep -q dbeaver-ce; then
                    log_success "DBeaver is already installed"
                    return 0
                fi
                
                log_info "Adding DBeaver repository..."
                if command_exists curl; then
                    run_as_root sh -c "curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key | gpg --dearmor -o /usr/share/keyrings/dbeaver.gpg"
                    echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" | run_as_root tee /etc/apt/sources.list.d/dbeaver.list
                    run_as_root apt-get update -qq
                    run_as_root apt-get install -y dbeaver-ce
                else
                    log_error "curl not found, cannot add DBeaver repository"
                    return 1
                fi
                ;;
            dnf)
                if rpm -q dbeaver-ce &>/dev/null; then
                    log_success "DBeaver is already installed"
                    return 0
                fi
                
                log_info "Adding DBeaver repository..."
                run_as_root rpm --import https://dbeaver.io/debs/dbeaver.gpg.key
                cat <<EOF | run_as_root tee /etc/yum.repos.d/dbeaver.repo
[dbeaver-ce]
name=DBeaver CE
baseurl=https://dbeaver.io/rpm/
enabled=1
gpgcheck=1
gpgkey=https://dbeaver.io/debs/dbeaver.gpg.key
EOF
                run_as_root dnf install -y dbeaver-ce
                ;;
            *)
                log_warning "DBeaver installation not supported via package manager"
                log_info "You can download it manually from: https://dbeaver.io/download/"
                return 1
                ;;
        esac
    else
        log_warning "DBeaver installation not supported on this OS"
        log_info "You can download it manually from: https://dbeaver.io/download/"
        return 1
    fi
    
    log_success "DBeaver installed successfully"
}

################################################################################
# Install PostgreSQL Client
################################################################################
install_postgresql_client() {
    if command_exists psql; then
        local psql_version
        psql_version=$(psql --version)
        log_success "PostgreSQL client is already installed (${psql_version})"
        return 0
    fi
    
    log_step "Installing PostgreSQL client..."
    
    if is_macos; then
        brew install libpq
        # Link psql to PATH
        brew link --force libpq
    elif is_linux; then
        case "${PACKAGE_MANAGER}" in
            apt)
                install_package "postgresql-client"
                install_package "postgresql-client-common"
                ;;
            dnf|yum)
                install_package "postgresql"
                ;;
            pacman)
                install_package "postgresql-libs"
                ;;
            *)
                install_package "postgresql-client"
                ;;
        esac
    else
        log_warning "PostgreSQL client installation not supported on this OS"
        return 1
    fi
    
    if command_exists psql; then
        log_success "PostgreSQL client installed successfully"
    else
        log_error "Failed to install PostgreSQL client"
        return 1
    fi
}

################################################################################
# Main installation function for all optional tools
################################################################################
install_optional_tools() {
    log_section "Optional Development Tools"
    log_info "Installing optional but useful development tools"
    log_info "These tools are not required but recommended for development"
    
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_dry_run "Would prompt to install optional tools:"
        log_dry_run "  - Fira Code Nerd Font"
        log_dry_run "  - jq (JSON processor)"
        log_dry_run "  - yq (YAML processor)"
        log_dry_run "  - make (build tool)"
        log_dry_run "  - Tabby or Alacritty terminal"
        log_dry_run "  - ffmpeg (media processing)"
        log_dry_run "  - imagemagick (image processing)"
        log_dry_run "  - jpegoptim and optipng (image optimization)"
        log_dry_run "  - mkcert (local HTTPS certificates)"
        log_dry_run "  - DBeaver (database GUI tool)"
        log_dry_run "  - PostgreSQL client tools"
        return 0
    fi
    
    # Enable universe repository (Ubuntu/Debian only)
    enable_universe_repo
    
    # Install Fira Code Nerd Font
    if confirm "Install Fira Code Nerd Font?"; then
        install_fira_code_nerd_font
    fi
    
    # Install CLI utilities
    if confirm "Install jq (JSON processor)?"; then
        install_jq
    fi
    
    if confirm "Install yq (YAML processor)?"; then
        install_yq
    fi
    
    if confirm "Install make?"; then
        install_make
    fi
    
    # Install terminal
    if confirm "Install a modern terminal emulator?"; then
        install_tabby
    fi
    
    # Install image tools
    if confirm "Install image processing tools (ffmpeg, imagemagick, jpegoptim, optipng)?"; then
        install_image_tools
    fi
    
    # Install mkcert
    if confirm "Install mkcert for local certificate management?"; then
        install_mkcert
    fi
    
    # Install database tools
    if confirm "Install DBeaver (database management GUI)?"; then
        install_dbeaver
    fi
    
    if confirm "Install PostgreSQL client utilities?"; then
        install_postgresql_client
    fi
    
    log_success "Optional tools installation completed"
}
