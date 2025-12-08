#!/usr/bin/env bash

################################################################################
# Starship Prompt Installation and Configuration Module
################################################################################

################################################################################
# Install Starship
################################################################################
install_starship() {
    if command_exists starship; then
        local starship_version
        starship_version=$(starship --version | awk '{print $2}')
        log_success "Starship is already installed (version ${starship_version})"
        
        if confirm "Would you like to configure Starship?"; then
            configure_starship
        fi
        return 0
    fi
    
    log_step "Installing Starship..."
    
    # Download and install Starship
    if command_exists curl; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    else
        log_error "curl is required to install Starship"
        return 1
    fi
    
    if command_exists starship; then
        log_success "Starship installed successfully"
        configure_starship
    else
        log_error "Failed to install Starship"
        return 1
    fi
}

################################################################################
# Configure Starship
################################################################################
configure_starship() {
    local shell_rc
    shell_rc="$(get_shell_rc)"
    local shell_name
    shell_name="$(get_default_shell)"
    
    log_step "Configuring Starship for ${shell_name}..."
    
    # Add Starship initialization to shell config
    case "${shell_name}" in
        bash)
            add_line_to_file 'eval "$(starship init bash)"' "${shell_rc}"
            ;;
        zsh)
            add_line_to_file 'eval "$(starship init zsh)"' "${shell_rc}"
            ;;
        fish)
            ensure_directory "${HOME}/.config/fish"
            add_line_to_file 'starship init fish | source' "${shell_rc}"
            ;;
        *)
            log_warning "Unknown shell: ${shell_name}"
            log_info "Please add 'eval \"\$(starship init ${shell_name})\"' to your shell configuration"
            ;;
    esac
    
    # Create Starship configuration
    create_starship_config
    
    log_success "Starship configured successfully"
    log_info "Restart your shell or run: source ${shell_rc}"
}

################################################################################
# Create Starship configuration
################################################################################
create_starship_config() {
    local config_dir="${HOME}/.config"
    local starship_config="${config_dir}/starship.toml"
    
    ensure_directory "${config_dir}"
    
    # Prompt user if config already exists
    if ! prompt_config_overwrite "${starship_config}" "Starship configuration"; then
        return 0
    fi
    
    log_step "Creating Starship configuration..."
    
    cat > "${starship_config}" << 'EOF'
# Starship Configuration

# Get editor completions based on the config schema
"$schema" = 'https://starship.rs/config-schema.json'

# Timeout for commands executed by starship (in milliseconds)
command_timeout = 500

# Inserts a blank line between shell prompts
add_newline = true

# Change the default prompt format
format = """
[╭╴](238)$os\
$all[╰─](238)$character"""

# Change the default prompt characters
[character]
success_symbol = "[](238)"
error_symbol = "[](238)"

# Show current directory
[directory]
style = "blue"
read_only = " 󰌾"
truncation_length = 4
truncate_to_repo = false

# Git branch
[git_branch]
symbol = " "
format = "[$symbol$branch]($style) "
style = "bright-black"

# Git status
[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "cyan"

# Git state
[git_state]
format = '\([$state( $progress_current/$progress_total)]($style)\) '
style = "bright-black"

# Git metrics
[git_metrics]
disabled = false

# Package version
[package]
symbol = "󰏗 "

# Programming Languages
[nodejs]
symbol = " "
format = "[$symbol($version )]($style)"

[python]
symbol = " "
format = '[${symbol}${pyenv_prefix}(${version} )(\($virtualenv\) )]($style)'

[rust]
symbol = " "

[golang]
symbol = " "

[docker_context]
symbol = " "
format = "[$symbol$context]($style) "

# OS
[os]
format = '[$symbol](bold white) '
disabled = false

[os.symbols]
Ubuntu = " "
Macos = " "
Windows = "󰍲 "
Arch = "󰣇 "
Debian = " "
Fedora = " "

# Time
[time]
disabled = false
format = '🕙[\[ $time \]]($style) '
time_format = "%T"

# Battery
[battery]
full_symbol = "🔋 "
charging_symbol = "⚡️ "
discharging_symbol = "💀 "
EOF
    
    log_success "Starship configuration created at: ${starship_config}"
}
