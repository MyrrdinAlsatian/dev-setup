# Dev Environment Setup

**Multi-OS Development Environment Automation Agent**

Automate the setup of your development environment across Linux, macOS, Windows, and remote servers. This tool generates clean, modular, and well-documented Bash/PowerShell scripts that configure essential development tools and manage dotfiles.

## Features

✨ **Multi-OS Support**
- Linux (Ubuntu, Debian, Fedora, RHEL, CentOS, Arch, Alpine)
- macOS
- Windows (via PowerShell)
- WSL (Windows Subsystem for Linux)
- Remote deployment via SSH/SCP

🛠️ **Tool Installation & Configuration**
- Git with sensible defaults and aliases
- Docker (Docker Desktop on Windows/macOS, Docker Engine on Linux)
- NVM (Node Version Manager) with LTS Node.js
- Tmux with optimized configuration
- Starship cross-shell prompt

📁 **Dotfiles Management**
- GNU Stow integration for symlink-based dotfiles (Linux/macOS)
- Git-based dotfiles repository synchronization
- Automatic backup of existing configurations
- Safe conflict resolution
- Configuration overwrite protection

🔐 **Security & Best Practices**
- Robust error handling
- Prerequisite verification
- Package manager detection
- Non-destructive operations with backups
- Configuration detection before any modifications
- User prompts for all potentially destructive operations

📊 **Developer Experience**
- Colored, informative logging
- Clear progress indicators
- Interactive confirmations
- Dry-run mode for testing
- Modular, maintainable code

## Quick Start

### Linux / macOS

```bash
# Clone the repository
git clone https://github.com/MyrrdinAlsatian/dev-setup.git
cd dev-setup

# Make the script executable
chmod +x setup.sh

# Run the setup
./setup.sh
```

### Windows (PowerShell)

```powershell
# Clone the repository
git clone https://github.com/MyrrdinAlsatian/dev-setup.git
cd dev-setup

# Run as Administrator
.\setup.ps1
```

### WSL (Windows Subsystem for Linux)

```bash
# WSL is detected automatically and works like Linux
# Clone the repository
git clone https://github.com/MyrrdinAlsatian/dev-setup.git
cd dev-setup

# Make the script executable
chmod +x setup.sh

# Run the setup
./setup.sh
```

**Note**: On WSL, the script will detect that it's running under Windows Subsystem for Linux and display this information during setup. All Linux-based tools work normally in WSL.

### Remote Deployment

```bash
# Deploy to a remote server via SSH
./setup.sh --remote user@hostname
```

## Usage

### Basic Usage

```bash
# Full setup with defaults
./setup.sh

# Dry run (see what would be done)
./setup.sh --dry-run

# Skip specific components
./setup.sh --skip-tools
./setup.sh --skip-dotfiles

# Use custom configuration
./setup.sh --config my-config.conf
```

### Advanced Options

```
Options:
    --help              Show help message
    --remote HOST       Deploy to remote host via SSH
    --config FILE       Use custom configuration file
    --dry-run           Show what would be done without executing
    --skip-tools        Skip tool installation
    --skip-dotfiles     Skip dotfiles configuration
```

## Project Structure

```
dev-setup/
├── setup.sh                    # Main setup script (Unix)
├── setup.ps1                   # Main setup script (Windows)
├── scripts/
│   ├── lib/                    # Core libraries
│   │   ├── logger.sh           # Colored logging functions
│   │   ├── logger.ps1          # PowerShell logging functions
│   │   ├── os_detect.sh        # OS detection
│   │   ├── os_detect.ps1       # PowerShell OS detection
│   │   ├── utils.sh            # Utility functions
│   │   └── utils.ps1           # PowerShell utilities
│   └── modules/                # Installation modules
│       ├── prerequisites.sh    # Prerequisite checks
│       ├── git.sh              # Git installation & config
│       ├── docker.sh           # Docker installation
│       ├── nvm.sh              # NVM installation
│       ├── tmux.sh             # Tmux installation & config
│       ├── starship.sh         # Starship prompt installation
│       ├── optional_tools.sh   # Optional development tools
│       ├── dotfiles.sh         # Dotfiles management
│       └── *.ps1               # PowerShell equivalents
├── config/
│   └── default.conf            # Default configuration
└── README.md                   # This file
```

## Configuration

Create a custom configuration file to override defaults:

```bash
# config/my-config.conf
DOTFILES_REPO="https://github.com/yourusername/dotfiles.git"
INSTALL_GIT=true
INSTALL_DOCKER=true
INSTALL_NVM=true
INSTALL_TMUX=true
INSTALL_STARSHIP=true
INSTALL_OPTIONAL_TOOLS=true
SETUP_DOTFILES=true
```

Then use it:

```bash
./setup.sh --config config/my-config.conf
```

## Dotfiles Setup

This tool integrates with GNU Stow for managing dotfiles on Linux/macOS. Structure your dotfiles repository like this:

```
dotfiles/
├── bash/
│   └── .bashrc
├── git/
│   └── .gitconfig
├── vim/
│   └── .vimrc
└── tmux/
    └── .tmux.conf
```

The setup script will:
1. Clone your dotfiles repository to `~/.dotfiles`
2. Detect any existing configuration files that would be overwritten
3. Prompt you with options for each conflict:
   - **Backup and install** (recommended): Creates timestamped backups in `~/.dotfiles-backup/`
   - **Skip**: Leaves existing files untouched
   - **Overwrite**: Replaces files without backup (not recommended)
4. Ask which packages to install
5. Use GNU Stow to create symlinks safely

### Configuration Safety Features

**Conflict Detection**: Before modifying any files, the tool scans for existing configurations and lists all conflicts.

**Backup Protection**: When you choose to backup, files are saved to `~/.dotfiles-backup/YYYYMMDD_HHMMSS/` with the full directory structure preserved.

**User Control**: You're always prompted before any destructive operations, ensuring no accidental data loss.

### Windows Dotfiles

For Windows, structure your repository with a `windows/` directory:

```
dotfiles/
├── windows/
│   └── .config/
│       └── starship.toml
└── powershell/
    └── Microsoft.PowerShell_profile.ps1
```

## Installed Tools

### Git
- Latest version from official repositories
- Configured with useful aliases
- Credential helpers for each OS
- Default branch set to `main`

### Docker
- Docker Engine on Linux
- Docker Desktop on macOS/Windows
- Automatic permission configuration on Linux
- Compose plugin included

### NVM (Node Version Manager)
- Latest version
- Automatic LTS Node.js installation
- Shell integration

### Tmux (Linux/macOS only)
- Terminal multiplexer
- Customized configuration with:
  - Mouse support
  - Better key bindings
  - Custom status bar
  - Vim-friendly settings
- **Safe installation**: Prompts before overwriting existing `~/.tmux.conf`

### Starship
- Fast, cross-shell prompt
- Nerd Font icons
- Git status integration
- Custom configuration
- **Safe installation**: Prompts before overwriting existing `~/.config/starship.toml`

### Optional Development Tools

The setup includes optional but recommended development tools for enhanced productivity. These are installed interactively when `INSTALL_OPTIONAL_TOOLS=true` (default).

#### Fonts
- **Fira Code Nerd Font**: Programming font with ligatures and icon support

#### CLI Utilities
- **jq**: Command-line JSON processor for parsing and manipulating JSON data
- **yq**: Command-line YAML processor (similar to jq but for YAML)
- **make**: Build automation tool for compiling and building projects

#### Terminal Emulator
- **Tabby**: Modern, cross-platform terminal (requires manual installation from https://tabby.sh/)
- **Alacritty**: Alternative GPU-accelerated terminal emulator (offered as substitute)

#### Image Processing Tools
- **ffmpeg**: Complete solution for recording, converting, and streaming audio/video
- **imagemagick**: Image manipulation and conversion tool suite
- **jpegoptim**: JPEG optimization utility for reducing file sizes
- **optipng**: PNG optimization utility for lossless compression

#### Certificate Management
- **mkcert**: Locally trusted development certificates for HTTPS testing
  - After installation, run `mkcert -install` to set up the local CA

#### Database Tools
- **DBeaver**: Free universal database management tool with GUI
  - Supports PostgreSQL, MySQL, SQLite, Oracle, and more
- **PostgreSQL Client**: Command-line tools for PostgreSQL databases
  - Includes `psql`, `pg_dump`, and other PostgreSQL utilities

**Note**: All optional tools prompt for installation individually. You can skip any tool by declining the prompt or disable all optional tools by setting `INSTALL_OPTIONAL_TOOLS=false` in your configuration file.


## Requirements

### Linux
- `bash` 4.0+
- `curl` or `wget`
- `git`
- `sudo` access (for system packages)

### macOS
- Homebrew (will be installed if missing)
- Xcode Command Line Tools

### Windows
- PowerShell 5.1+ or PowerShell Core 7+
- Administrator privileges
- Chocolatey or Winget (will be installed if missing)

## Security Considerations

- Scripts use `set -euo pipefail` for robust error handling
- No hardcoded credentials
- All external downloads use HTTPS
- **Configuration Protection**: All modules detect existing configuration files and prompt before overwriting
- Timestamped backups created automatically (when chosen)
- User confirmation required for destructive operations

## Troubleshooting

### Permission Errors

```bash
# Linux/macOS - ensure script is executable
chmod +x setup.sh

# Windows - run PowerShell as Administrator
```

### SSH Remote Deployment Issues

```bash
# Ensure SSH key authentication is set up
ssh-copy-id user@hostname

# Test SSH connection
ssh user@hostname
```

### Docker Permission Issues (Linux)

After installation, you may need to:
```bash
# Re-login or run:
newgrp docker

# Or restart your system
```

### Path Not Updated

After installation, restart your shell or run:
```bash
# Linux/macOS
source ~/.bashrc  # or ~/.zshrc

# Windows (PowerShell)
# Restart PowerShell session
```

## Development

### Adding New Tools

1. Create a new module in `scripts/modules/`
2. Follow the existing module pattern
3. Add installation function
4. Add configuration function
5. Source the module in `setup.sh`

Example module structure:

```bash
#!/usr/bin/env bash

install_mytool() {
    if command_exists mytool; then
        log_success "MyTool is already installed"
        return 0
    fi
    
    log_step "Installing MyTool..."
    
    # Installation logic here
    
    log_success "MyTool installed successfully"
}
```

### Testing

```bash
# Test with dry-run mode
./setup.sh --dry-run

# Test specific components
./setup.sh --skip-dotfiles
./setup.sh --skip-tools
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is open source and available under the MIT License.

## Acknowledgments

- [GNU Stow](https://www.gnu.org/software/stow/) for dotfiles management
- [Starship](https://starship.rs/) for the amazing prompt
- [NVM](https://github.com/nvm-sh/nvm) for Node.js version management
- The open-source community for inspiration and tools

## Support

For issues, questions, or suggestions, please [open an issue](https://github.com/MyrrdinAlsatian/dev-setup/issues) on GitHub.
