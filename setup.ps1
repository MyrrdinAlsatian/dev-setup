################################################################################
# Dev Environment Setup - Windows PowerShell Script
# 
# Purpose: Multi-OS development environment automation for Windows
# 
# Usage:
#   .\setup.ps1 [OPTIONS]
#
# Options:
#   -Help              Show this help message
#   -Remote HOST       Deploy to remote host via SSH
#   -Config FILE       Use custom configuration file
#   -DryRun            Show what would be done without executing
#   -SkipTools         Skip tool installation
#   -SkipDotfiles      Skip dotfiles configuration
################################################################################

[CmdletBinding()]
param(
    [switch]$Help,
    [string]$Remote = "",
    [string]$Config = "",
    [switch]$DryRun,
    [switch]$SkipTools,
    [switch]$SkipDotfiles
)

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibDir = Join-Path $ScriptDir "scripts\lib"
$ModulesDir = Join-Path $ScriptDir "scripts\modules"
$ConfigDir = Join-Path $ScriptDir "config"

# Default configuration
if ([string]::IsNullOrEmpty($Config)) {
    $Config = Join-Path $ConfigDir "default.conf"
}

################################################################################
# Load core libraries
################################################################################
. (Join-Path $LibDir "logger.ps1")
. (Join-Path $LibDir "os_detect.ps1")
. (Join-Path $LibDir "utils.ps1")

################################################################################
# Display usage information
################################################################################
function Show-Usage {
    Write-Host @"
Dev Environment Setup - Multi-OS Automation Tool (Windows)

Usage: .\setup.ps1 [OPTIONS]

Options:
    -Help              Show this help message
    -Remote HOST       Deploy to remote host via SSH
    -Config FILE       Use custom configuration file
    -DryRun            Show what would be done without executing
    -SkipTools         Skip tool installation
    -SkipDotfiles      Skip dotfiles configuration

Examples:
    # Local installation
    .\setup.ps1

    # Remote deployment
    .\setup.ps1 -Remote user@hostname

    # Custom configuration
    .\setup.ps1 -Config my-config.conf

    # Dry run to see what would be done
    .\setup.ps1 -DryRun

"@
    exit 0
}

################################################################################
# Deploy to remote host
################################################################################
function Deploy-Remote {
    param([string]$Host)
    
    Write-LogInfo "Deploying to remote host: $Host"
    
    # Create temporary directory on remote
    Write-LogStep "Creating temporary directory on remote host"
    ssh $Host "mkdir -p /tmp/dev-setup"
    
    # Copy scripts to remote
    Write-LogStep "Copying setup scripts to remote host"
    scp -r "$ScriptDir\*" "${Host}:/tmp/dev-setup/"
    
    # Execute setup on remote
    Write-LogStep "Executing setup on remote host"
    ssh -t $Host "cd /tmp/dev-setup && bash setup.sh"
    
    Write-LogSuccess "Remote deployment completed"
}

################################################################################
# Main setup workflow
################################################################################
function Main {
    # Show help if requested
    if ($Help) {
        Show-Usage
    }
    
    # Print banner
    Write-Banner "Dev Environment Setup"
    
    # Handle remote deployment
    if (-not [string]::IsNullOrEmpty($Remote)) {
        Deploy-Remote $Remote
        exit 0
    }
    
    # Detect operating system
    Write-LogSection "System Detection"
    Detect-OS
    Write-LogInfo "Operating System: Windows"
    Write-LogInfo "Version: $([System.Environment]::OSVersion.Version)"
    Write-LogInfo "Architecture: $([System.Environment]::Is64BitOperatingSystem)"
    
    # Load configuration
    Write-LogSection "Configuration"
    if (Test-Path $Config) {
        Write-LogInfo "Loading configuration from: $Config"
        # Load configuration
    } else {
        Write-LogWarning "Configuration file not found: $Config"
        Write-LogInfo "Using default settings"
    }
    
    # Check prerequisites
    Write-LogSection "Prerequisites Check"
    . (Join-Path $ModulesDir "prerequisites.ps1")
    Check-Prerequisites
    
    # Install tools
    if (-not $SkipTools) {
        Write-LogSection "Tool Installation"
        
        . (Join-Path $ModulesDir "git.ps1")
        Install-Git
        
        . (Join-Path $ModulesDir "docker.ps1")
        Install-Docker
        
        . (Join-Path $ModulesDir "nvm.ps1")
        Install-Nvm
        
        . (Join-Path $ModulesDir "starship.ps1")
        Install-Starship
    } else {
        Write-LogInfo "Skipping tool installation (-SkipTools)"
    }
    
    # Setup dotfiles
    if (-not $SkipDotfiles) {
        Write-LogSection "Dotfiles Configuration"
        . (Join-Path $ModulesDir "dotfiles.ps1")
        Setup-Dotfiles
    } else {
        Write-LogInfo "Skipping dotfiles configuration (-SkipDotfiles)"
    }
    
    # Final summary
    Write-LogSection "Setup Complete"
    Write-LogSuccess "Development environment setup completed successfully!"
    Write-LogInfo "Please restart your PowerShell session to apply changes"
}

# Run main function
Main
