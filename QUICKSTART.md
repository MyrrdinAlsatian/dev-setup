# Quick Reference Guide

## Installation Commands

### Linux / macOS

```bash
# Clone and run
git clone https://github.com/MyrrdinAlsatian/dev-setup.git
cd dev-setup
chmod +x setup.sh
./setup.sh
```

### Windows (PowerShell - Run as Administrator)

```powershell
git clone https://github.com/MyrrdinAlsatian/dev-setup.git
cd dev-setup
.\setup.ps1
```

### WSL (Windows Subsystem for Linux)

```bash
# Same as Linux - WSL is auto-detected
git clone https://github.com/MyrrdinAlsatian/dev-setup.git
cd dev-setup
chmod +x setup.sh
./setup.sh
```

## Common Commands

```bash
# Show help
./setup.sh --help

# Dry run (see what would be done)
./setup.sh --dry-run

# Skip specific components
./setup.sh --skip-tools          # Skip tool installation
./setup.sh --skip-dotfiles       # Skip dotfiles setup
./setup.sh --skip-tools --skip-dotfiles  # Skip both

# Use custom configuration
./setup.sh --config config/my-config.conf

# Deploy to remote server
./setup.sh --remote user@hostname
```

## What Gets Installed

| Tool | Linux | macOS | Windows | WSL | Purpose |
|------|-------|-------|---------|-----|---------|
| Git | ✅ | ✅ | ✅ | ✅ | Version control |
| Docker | ✅ | ✅ | ✅ | ✅ | Containerization |
| NVM | ✅ | ✅ | ✅ | ✅ | Node.js version manager |
| Node.js | ✅ | ✅ | ✅ | ✅ | JavaScript runtime |
| Tmux | ✅ | ✅ | ❌ | ✅ | Terminal multiplexer |
| Starship | ✅ | ✅ | ✅ | ✅ | Cross-shell prompt |
| GNU Stow | ✅ | ✅ | ❌ | ✅ | Dotfiles manager |

## Configuration

Create `config/my-config.conf`:

```bash
# Your dotfiles repository
DOTFILES_REPO="https://github.com/yourusername/dotfiles.git"

# Which tools to install (true/false)
INSTALL_GIT=true
INSTALL_DOCKER=true
INSTALL_NVM=true
INSTALL_TMUX=true
INSTALL_STARSHIP=true
SETUP_DOTFILES=true
```

## Dotfiles Structure

### Linux/macOS (using GNU Stow)

```
~/.dotfiles/
├── bash/
│   └── .bashrc
├── git/
│   └── .gitconfig
├── vim/
│   └── .vimrc
└── tmux/
    └── .tmux.conf
```

### Windows

```
~/.dotfiles/
├── windows/
│   └── .config/
│       └── starship.toml
└── powershell/
    └── Microsoft.PowerShell_profile.ps1
```

## Troubleshooting

### Script Won't Run (Linux/macOS)
```bash
chmod +x setup.sh
```

### Permission Denied (Windows)
Run PowerShell as Administrator

### Docker Permission Error (Linux)
```bash
newgrp docker
# or logout and login again
```

### Path Not Updated After Installation
```bash
# Linux/macOS
source ~/.bashrc  # or ~/.zshrc

# Windows
# Restart PowerShell
```

### SSH Remote Deployment
```bash
# Setup SSH key first
ssh-copy-id user@hostname

# Test connection
ssh user@hostname

# Deploy
./setup.sh --remote user@hostname
```

## File Locations

| Item | Linux/macOS | Windows |
|------|-------------|---------|
| Scripts | `./scripts/` | `.\scripts\` |
| Config | `./config/` | `.\config\` |
| Dotfiles | `~/.dotfiles` | `%USERPROFILE%\.dotfiles` |
| Git config | `~/.gitconfig` | `%USERPROFILE%\.gitconfig` |
| Tmux config | `~/.tmux.conf` | N/A |
| Starship config | `~/.config/starship.toml` | `%USERPROFILE%\.config\starship.toml` |

## Getting Help

1. Read the [README.md](README.md)
2. Check [CONTRIBUTING.md](CONTRIBUTING.md)
3. Open an [issue](https://github.com/MyrrdinAlsatian/dev-setup/issues)

## Quick Tests

```bash
# Verify installations
git --version
docker --version
node --version
npm --version
tmux -V              # Linux/macOS only
starship --version

# Test tmux (Linux/macOS)
tmux

# Test starship prompt
# Restart shell and look for custom prompt
```
