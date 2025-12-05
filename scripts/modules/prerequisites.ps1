################################################################################
# Prerequisites Module - PowerShell
# Checks for required tools and system requirements
################################################################################

################################################################################
# Check all prerequisites
################################################################################
function Check-Prerequisites {
    Write-LogInfo "Checking system prerequisites..."
    
    $missingTools = @()
    
    # Check for essential tools
    if (-not (Test-CommandExists "git")) {
        $missingTools += "git"
    }
    
    # Check for package manager
    if (-not (Test-Chocolatey) -and -not (Test-Winget)) {
        Write-LogWarning "No package manager found. Installing Chocolatey..."
        Install-Chocolatey
    }
    
    # Report results
    if ($missingTools.Count -gt 0) {
        Write-LogWarning "Missing required tools:"
        foreach ($tool in $missingTools) {
            Write-LogError "  - $tool"
        }
        
        if (Confirm-Action "Would you like to install missing tools?") {
            Install-Prerequisites $missingTools
        } else {
            Write-LogError "Cannot proceed without required tools"
            exit 1
        }
    } else {
        Write-LogSuccess "All prerequisites met"
    }
}

################################################################################
# Install Chocolatey package manager
################################################################################
function Install-Chocolatey {
    Write-LogStep "Installing Chocolatey package manager..."
    
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-LogSuccess "Chocolatey installed"
}

################################################################################
# Install prerequisites
################################################################################
function Install-Prerequisites {
    param([string[]]$Tools)
    
    Write-LogStep "Installing prerequisites..."
    
    foreach ($tool in $Tools) {
        Install-Package $tool
    }
    
    Write-LogSuccess "Prerequisites installed"
}

################################################################################
# Check system resources
################################################################################
function Check-SystemResources {
    Write-LogInfo "Checking system resources..."
    
    # Check available disk space
    $drive = Get-PSDrive -Name C
    $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
    
    if ($freeSpaceGB -lt 1) {
        Write-LogWarning "Low disk space: $freeSpaceGB GB available"
    } else {
        Write-LogSuccess "Disk space: $freeSpaceGB GB available"
    }
    
    # Check available memory
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $freeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    Write-LogInfo "Available memory: $freeMemoryGB GB"
}
