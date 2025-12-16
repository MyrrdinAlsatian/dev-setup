#!/usr/bin/env bash

################################################################################
# Tmux Installation and Configuration Module
################################################################################

################################################################################
# Install Tmux
################################################################################
install_tmux() {
    if command_exists tmux; then
        local tmux_version
        tmux_version=$(tmux -V | awk '{print $2}')
        log_success "Tmux is already installed (version ${tmux_version})"
        
        if confirm "Would you like to configure tmux?"; then
            configure_tmux
        fi
        return 0
    fi
    
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_dry_run "Would install Tmux:"
        log_dry_run "  - Install tmux package"
        log_dry_run "  - Create custom ~/.tmux.conf configuration"
        log_dry_run "  - Enable mouse support and custom key bindings"
        return 0
    fi
    
    log_step "Installing Tmux..."
    
    if is_macos; then
        brew install tmux
    elif is_linux; then
        install_package "tmux"
    else
        log_warning "Tmux installation not supported on this OS"
        return 1
    fi
    
    if command_exists tmux; then
        log_success "Tmux installed successfully"
        configure_tmux
    else
        log_error "Failed to install Tmux"
        return 1
    fi
}

################################################################################
# Configure Tmux
################################################################################
configure_tmux() {
    local tmux_conf="${HOME}/.tmux.conf"
    
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_dry_run "Would create Tmux configuration at: ${tmux_conf}"
        log_dry_run "Would configure mouse support, custom key bindings, and status bar"
        return 0
    fi
    
    log_step "Configuring Tmux..."
    
    # Prompt user about existing configuration
    if ! prompt_config_overwrite "${tmux_conf}" "Tmux configuration"; then
        return 0
    fi
    
    # Create basic tmux configuration
    cat > "${tmux_conf}" << 'EOF'
# Tmux Configuration

# Set prefix to Ctrl-a (like screen)
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Enable mouse support
set -g mouse on

# Start window numbering at 1
set -g base-index 1
set -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Increase scrollback buffer size
set -g history-limit 10000

# Enable 256 color support
set -g default-terminal "screen-256color"

# Set escape time to 0 for better vim experience
set -sg escape-time 0

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Reload config file
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Status bar customization
set -g status-style bg=colour234,fg=colour137
set -g status-left ''
set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '
set -g status-right-length 50
set -g status-left-length 20

# Window status
setw -g window-status-current-style fg=colour81,bg=colour238,bold
setw -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F '
setw -g window-status-style fg=colour138,bg=colour235,none
setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '

# Pane border
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=colour51

# Message style
set -g message-style fg=colour232,bg=colour166,bold
EOF
    
    log_success "Tmux configured successfully"
    log_info "Configuration saved to: ${tmux_conf}"
    log_info "Start tmux with: tmux"
    log_info "Reload config with: tmux source-file ~/.tmux.conf"
}
