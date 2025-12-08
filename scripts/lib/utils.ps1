################################################################################
# Utilities Library - PowerShell
# Common utility functions
################################################################################

################################################################################
# Check if a command exists
################################################################################
function Test-CommandExists {
    param([string]$Command)
    return (Get-Command $Command -ErrorAction SilentlyContinue) -ne $null
}

################################################################################
# Check if running as administrator
################################################################################
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

################################################################################
# Ensure running as administrator
################################################################################
function Require-Administrator {
    if (-not (Test-Administrator)) {
        Write-LogError "This script must be run as Administrator"
        exit 1
    }
}

################################################################################
# Ask for user confirmation
################################################################################
function Confirm-Action {
    param([string]$Question)
    
    $response = Read-Host "$Question [y/N]"
    return ($response -match '^[yY]([eE][sS])?$')
}

################################################################################
# Create directory if it doesn't exist
################################################################################
function Ensure-Directory {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-LogStep "Creating directory: $Path"
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

################################################################################
# Backup a file or directory
################################################################################
function Backup-Item {
    param([string]$Path)
    
    if (Test-Path $Path) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backup = "$Path.backup.$timestamp"
        Write-LogStep "Backing up $Path to $backup"
        Copy-Item -Path $Path -Destination $backup -Recurse
    }
}

################################################################################
# Prompt user for action when config file exists
# Returns: 0 to proceed (with or without backup), 1 to skip
################################################################################
function Prompt-ConfigOverwrite {
    param(
        [string]$ConfigFile,
        [string]$Description
    )
    
    if (-not (Test-Path $ConfigFile)) {
        return 0  # File doesn't exist, safe to create
    }
    
    Write-LogWarning "$Description already exists at: $ConfigFile"
    Write-LogInfo "Options:"
    Write-LogInfo "  1) Backup existing and create new (recommended)"
    Write-LogInfo "  2) Skip (keep existing)"
    Write-LogInfo "  3) Overwrite without backup (not recommended)"
    Write-Host ""
    
    $choice = Read-Host "Choose an option [1/2/3]"
    
    switch ($choice) {
        "1" {
            Backup-Item $ConfigFile
            return 0  # Proceed with backup
        }
        "2" {
            Write-LogWarning "Skipping $Description"
            return 1  # Skip
        }
        "3" {
            Write-LogWarning "Proceeding without backup..."
            return 0  # Proceed without backup
        }
        default {
            Write-LogError "Invalid option. Skipping $Description"
            return 1  # Skip on invalid input
        }
    }
}

################################################################################
# Safe write to config file with backup prompt
################################################################################
function Safe-WriteConfig {
    param(
        [string]$ConfigFile,
        [string]$Description,
        [string]$Content
    )
    
    # Prompt if file exists
    $result = Prompt-ConfigOverwrite $ConfigFile $Description
    if ($result -eq 1) {
        return $false
    }
    
    # Create parent directory if needed
    $parentDir = Split-Path $ConfigFile -Parent
    if ($parentDir) {
        Ensure-Directory $parentDir
    }
    
    # Write content
    $Content | Out-File -FilePath $ConfigFile -Encoding utf8
    
    Write-LogSuccess "$Description created at: $ConfigFile"
    return $true
}


################################################################################
# Download a file
################################################################################
function Download-File {
    param(
        [string]$Url,
        [string]$Output
    )
    
    Write-LogStep "Downloading $Url"
    Invoke-WebRequest -Uri $Url -OutFile $Output
}

################################################################################
# Add a line to a file if it doesn't exist
################################################################################
function Add-LineToFile {
    param(
        [string]$Line,
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        New-Item -ItemType File -Path $FilePath -Force | Out-Null
    }
    
    $content = Get-Content $FilePath -ErrorAction SilentlyContinue
    if ($content -notcontains $Line) {
        Add-Content -Path $FilePath -Value $Line
        Write-LogStep "Added line to $FilePath"
    }
}

################################################################################
# Install package using Chocolatey or Winget
################################################################################
function Install-Package {
    param([string]$Package)
    
    Write-LogStep "Installing package: $Package"
    
    if (Test-CommandExists "choco") {
        choco install $Package -y
    } elseif (Test-CommandExists "winget") {
        winget install $Package --silent --accept-package-agreements --accept-source-agreements
    } else {
        Write-LogError "No package manager available (Chocolatey or Winget)"
        return $false
    }
    
    return $true
}
