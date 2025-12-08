################################################################################
# Dotfiles Management Module - PowerShell
# Note: GNU Stow is not typically used on Windows
# This module provides basic dotfiles syncing
################################################################################

# Default dotfiles repository
$script:DOTFILES_REPO = $env:DOTFILES_REPO
if ([string]::IsNullOrEmpty($script:DOTFILES_REPO)) {
    $script:DOTFILES_REPO = "https://github.com/username/dotfiles.git"
}
$script:DOTFILES_DIR = Join-Path $env:USERPROFILE ".dotfiles"

################################################################################
# Setup dotfiles
################################################################################
function Setup-Dotfiles {
    Write-LogInfo "Setting up dotfiles management..."
    
    # Ask for dotfiles repository
    Configure-DotfilesRepo
    
    # Clone or update dotfiles repository
    Sync-Dotfiles
    
    # Apply dotfiles
    if (Test-Path $script:DOTFILES_DIR) {
        Apply-Dotfiles
    } else {
        Write-LogWarning "Dotfiles directory not found, skipping application"
    }
}

################################################################################
# Configure dotfiles repository
################################################################################
function Configure-DotfilesRepo {
    # Check if dotfiles directory already exists
    if ((Test-Path $script:DOTFILES_DIR) -and (Test-Path (Join-Path $script:DOTFILES_DIR ".git"))) {
        Write-LogInfo "Dotfiles repository already exists at: $script:DOTFILES_DIR"
        
        $repoUrl = git -C $script:DOTFILES_DIR config --get remote.origin.url
        Write-LogInfo "Current repository: $repoUrl"
        
        if (-not (Confirm-Action "Would you like to keep this repository?")) {
            $newRepo = Read-Host "Enter new dotfiles repository URL"
            $script:DOTFILES_REPO = $newRepo
            
            Write-LogStep "Removing old dotfiles repository..."
            Remove-Item -Path $script:DOTFILES_DIR -Recurse -Force
        } else {
            $script:DOTFILES_REPO = $repoUrl
            return
        }
    } else {
        Write-LogInfo "Please provide your dotfiles repository URL"
        Write-LogInfo "Example: https://github.com/username/dotfiles.git"
        $repoUrl = Read-Host "Dotfiles repository URL (or press Enter to skip)"
        
        if ([string]::IsNullOrEmpty($repoUrl)) {
            Write-LogWarning "No repository provided, skipping dotfiles setup"
            Write-LogInfo "You can manually clone your dotfiles to $script:DOTFILES_DIR later"
            return
        }
        
        $script:DOTFILES_REPO = $repoUrl
    }
}

################################################################################
# Clone or update dotfiles repository
################################################################################
function Sync-Dotfiles {
    if (Test-Path (Join-Path $script:DOTFILES_DIR ".git")) {
        Write-LogStep "Updating dotfiles repository..."
        
        Push-Location $script:DOTFILES_DIR
        try {
            git pull origin main
            if ($LASTEXITCODE -ne 0) {
                git pull origin master
            }
        } finally {
            Pop-Location
        }
        
        Write-LogSuccess "Dotfiles repository updated"
    } else {
        Write-LogStep "Cloning dotfiles repository from $script:DOTFILES_REPO..."
        
        if (git clone $script:DOTFILES_REPO $script:DOTFILES_DIR) {
            Write-LogSuccess "Dotfiles repository cloned successfully"
        } else {
            Write-LogError "Failed to clone dotfiles repository"
            return
        }
    }
}

################################################################################
# Apply dotfiles (Windows-specific method)
################################################################################
function Apply-Dotfiles {
    Write-LogStep "Applying dotfiles..."
    
    # Look for Windows-specific dotfiles
    $windowsDir = Join-Path $script:DOTFILES_DIR "windows"
    
    if (Test-Path $windowsDir) {
        Apply-WindowsDotfiles $windowsDir
    } else {
        Write-LogWarning "No Windows-specific dotfiles found"
        Write-LogInfo "Create a 'windows' directory in your dotfiles repository for Windows configs"
    }
    
    # Look for PowerShell profile
    $profileSource = Join-Path $script:DOTFILES_DIR "powershell\Microsoft.PowerShell_profile.ps1"
    if (Test-Path $profileSource) {
        $profileDest = $PROFILE
        
        # Check if profile already exists
        if (Test-Path $profileDest) {
            Write-LogWarning "PowerShell profile already exists at: $profileDest"
            Write-LogInfo "Options:"
            Write-LogInfo "  1) Backup existing and install new profile (recommended)"
            Write-LogInfo "  2) Skip profile installation"
            Write-LogInfo "  3) Overwrite without backup (not recommended)"
            Write-Host ""
            
            $choice = Read-Host "Choose an option [1/2/3]"
            
            switch ($choice) {
                "1" {
                    Backup-Item $profileDest
                    Copy-Item -Path $profileSource -Destination $profileDest -Force
                    Write-LogSuccess "PowerShell profile installed (backup created)"
                }
                "2" {
                    Write-LogWarning "Skipped PowerShell profile installation"
                }
                "3" {
                    Copy-Item -Path $profileSource -Destination $profileDest -Force
                    Write-LogSuccess "PowerShell profile installed (no backup)"
                }
                default {
                    Write-LogError "Invalid option. Skipping profile installation."
                }
            }
        } else {
            # No existing profile, just install
            Copy-Item -Path $profileSource -Destination $profileDest -Force
            Write-LogSuccess "PowerShell profile installed"
        }
    }
    
    Write-LogSuccess "Dotfiles applied successfully"
}

################################################################################
# Apply Windows-specific dotfiles
################################################################################
function Apply-WindowsDotfiles {
    param([string]$SourceDir)
    
    # Get all files that would be copied
    $items = Get-ChildItem -Path $SourceDir -Recurse -File
    $conflicts = @()
    
    # First pass: detect conflicts
    foreach ($item in $items) {
        $relativePath = $item.FullName.Substring($SourceDir.Length + 1)
        $destPath = Join-Path $env:USERPROFILE $relativePath
        
        if (Test-Path $destPath) {
            $conflicts += $destPath
        }
    }
    
    # If conflicts exist, ask user what to do
    if ($conflicts.Count -gt 0) {
        Write-LogWarning "Found existing configuration files that would be overwritten:"
        foreach ($conflict in $conflicts) {
            Write-Host "  - $conflict"
        }
        Write-Host ""
        Write-LogInfo "Options:"
        Write-LogInfo "  1) Backup existing files and install (recommended)"
        Write-LogInfo "  2) Skip all conflicting files"
        Write-LogInfo "  3) Overwrite without backup (not recommended)"
        Write-Host ""
        
        $choice = Read-Host "Choose an option [1/2/3]"
        
        switch ($choice) {
            "1" {
                Write-LogStep "Backing up existing files..."
                $backupCreated = $false
                
                foreach ($item in $items) {
                    $relativePath = $item.FullName.Substring($SourceDir.Length + 1)
                    $destPath = Join-Path $env:USERPROFILE $relativePath
                    
                    if (Test-Path $destPath) {
                        Ensure-Directory (Split-Path $destPath -Parent)
                        Backup-Item $destPath
                        $backupCreated = $true
                    }
                    
                    Ensure-Directory (Split-Path $destPath -Parent)
                    Copy-Item -Path $item.FullName -Destination $destPath -Force
                    Write-LogStep "Installed: $relativePath"
                }
                
                if ($backupCreated) {
                    Write-LogSuccess "Files backed up and installed"
                }
            }
            "2" {
                Write-LogWarning "Skipping conflicting files, installing new files only..."
                
                foreach ($item in $items) {
                    $relativePath = $item.FullName.Substring($SourceDir.Length + 1)
                    $destPath = Join-Path $env:USERPROFILE $relativePath
                    
                    if (-not (Test-Path $destPath)) {
                        Ensure-Directory (Split-Path $destPath -Parent)
                        Copy-Item -Path $item.FullName -Destination $destPath -Force
                        Write-LogStep "Installed: $relativePath"
                    } else {
                        Write-LogInfo "Skipped (already exists): $relativePath"
                    }
                }
            }
            "3" {
                Write-LogWarning "Proceeding without backup..."
                
                foreach ($item in $items) {
                    $relativePath = $item.FullName.Substring($SourceDir.Length + 1)
                    $destPath = Join-Path $env:USERPROFILE $relativePath
                    
                    Ensure-Directory (Split-Path $destPath -Parent)
                    Copy-Item -Path $item.FullName -Destination $destPath -Force
                    Write-LogStep "Installed: $relativePath"
                }
            }
            default {
                Write-LogError "Invalid option. Aborting installation."
                return
            }
        }
    } else {
        # No conflicts, install normally
        foreach ($item in $items) {
            $relativePath = $item.FullName.Substring($SourceDir.Length + 1)
            $destPath = Join-Path $env:USERPROFILE $relativePath
            
            Ensure-Directory (Split-Path $destPath -Parent)
            Copy-Item -Path $item.FullName -Destination $destPath -Force
            Write-LogStep "Installed: $relativePath"
        }
    }
}
