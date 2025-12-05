# Dotfiles Repository Setup Guide

This guide explains how to structure your dotfiles repository to work with this automation tool.

## Why Use Dotfiles?

Dotfiles are configuration files (usually hidden files starting with `.`) that customize your development environment. Managing them in a Git repository lets you:

- **Sync** configurations across multiple machines
- **Version control** your settings
- **Share** your setup with others
- **Backup** your customizations
- **Quickly restore** your environment

## Repository Structure

### For Linux/macOS (Using GNU Stow)

GNU Stow creates symlinks from your dotfiles repository to your home directory.

**Recommended structure:**

```
dotfiles/
├── bash/
│   └── .bashrc              # Bash configuration
├── zsh/
│   ├── .zshrc              # Zsh configuration
│   └── .zshenv             # Zsh environment
├── git/
│   ├── .gitconfig          # Git configuration
│   └── .gitignore_global   # Global gitignore
├── vim/
│   └── .vimrc              # Vim configuration
├── tmux/
│   └── .tmux.conf          # Tmux configuration
├── nvim/
│   └── .config/
│       └── nvim/
│           └── init.vim    # Neovim configuration
└── README.md               # Documentation
```

**How it works:**

When you run `stow bash` from the dotfiles directory, it creates:
- `~/.bashrc` → `~/.dotfiles/bash/.bashrc`

### For Windows

Windows doesn't typically use GNU Stow, so we use a simpler approach.

**Recommended structure:**

```
dotfiles/
├── windows/
│   ├── .config/
│   │   └── starship.toml
│   └── AppData/
│       └── Roaming/
│           └── ...
├── powershell/
│   └── Microsoft.PowerShell_profile.ps1
└── git/
    └── .gitconfig
```

## Creating Your Dotfiles Repository

### Step 1: Create the Repository

```bash
# Create a new directory
mkdir -p ~/.dotfiles
cd ~/.dotfiles

# Initialize Git
git init
git branch -M main
```

### Step 2: Create Package Directories

```bash
# For each tool, create a directory
mkdir -p bash git vim tmux
```

### Step 3: Move Existing Dotfiles

```bash
# Example: Move .bashrc
mv ~/.bashrc bash/

# Example: Move .gitconfig
mv ~/.gitconfig git/

# Example: Move .vimrc
mv ~/.vimrc vim/

# Example: Move .tmux.conf
mv ~/.tmux.conf tmux/
```

### Step 4: For Nested Configurations

Some tools store config in subdirectories like `.config/`. To handle this with Stow:

```bash
# Create the directory structure
mkdir -p nvim/.config/nvim

# Move the config
mv ~/.config/nvim/init.vim nvim/.config/nvim/
```

### Step 5: Add and Commit

```bash
# Add all files
git add .

# Commit
git commit -m "Initial dotfiles commit"
```

### Step 6: Push to GitHub

```bash
# Create a repository on GitHub named 'dotfiles'

# Add remote
git remote add origin https://github.com/yourusername/dotfiles.git

# Push
git push -u origin main
```

## Example Dotfiles

### .bashrc Example

```bash
# ~/.dotfiles/bash/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Prompt
export PS1='\u@\h:\w\$ '

# History
export HISTSIZE=10000
export HISTFILESIZE=20000

# Colors for ls
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Starship prompt (if installed)
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi
```

### .gitconfig Example

```ini
# ~/.dotfiles/git/.gitconfig

[user]
    name = Your Name
    email = your.email@example.com

[core]
    editor = vim
    autocrlf = input

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    lg = log --graph --oneline --decorate --all

[color]
    ui = auto

[pull]
    rebase = false

[init]
    defaultBranch = main
```

### .tmux.conf Example

```bash
# ~/.dotfiles/tmux/.tmux.conf

# Set prefix to Ctrl-a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Enable mouse
set -g mouse on

# Start windows at 1
set -g base-index 1
set -g pane-base-index 1

# Split panes with | and -
bind | split-window -h
bind - split-window -v
```

## Using the Dotfiles

### On a New Machine

```bash
# 1. Clone your dotfiles
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. Use this automation tool
cd /path/to/dev-setup
./setup.sh
# It will automatically detect and apply your dotfiles

# Or manually with stow
cd ~/.dotfiles
stow bash git vim tmux
```

### Updating Dotfiles

```bash
# Make changes
vim ~/.dotfiles/bash/.bashrc

# Commit and push
cd ~/.dotfiles
git add bash/.bashrc
git commit -m "Update bash aliases"
git push
```

### Syncing to Other Machines

```bash
cd ~/.dotfiles
git pull
stow bash  # Re-stow if needed
```

## Best Practices

1. **Don't commit secrets**: Never commit API keys, passwords, or tokens
2. **Use .gitignore**: Ignore OS-specific files
3. **Document**: Add README explaining your setup
4. **Test**: Test on a fresh system before deploying widely
5. **Separate sensitive data**: Use a separate private config for sensitive settings
6. **Version control everything**: Commit small, logical changes
7. **Use branches**: Create branches for experiments

## Example .gitignore for Dotfiles

```gitignore
# OS Files
.DS_Store
Thumbs.db

# Backup files
*.backup
*.bak
*~

# Secrets
.env
secrets/
*.secret

# Cache
.cache/
```

## Advanced: Handling Secrets

For sensitive information, use environment variables or a separate private repository:

```bash
# In your .bashrc
if [ -f ~/.secrets ]; then
    source ~/.secrets
fi
```

Create `~/.secrets` (not in your dotfiles repo):
```bash
export API_KEY="your-secret-key"
export DATABASE_PASSWORD="your-password"
```

## Resources

- [GitHub Dotfiles Guide](https://dotfiles.github.io/)
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/)
- [Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles)
