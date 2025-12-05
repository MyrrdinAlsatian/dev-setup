################################################################################
# OS Detection Library - PowerShell
# Detects operating system and architecture
################################################################################

################################################################################
# Detect the operating system
################################################################################
function Detect-OS {
    $script:OS_TYPE = "windows"
    $script:OS_VERSION = [System.Environment]::OSVersion.Version
    $script:OS_ARCH = if ([System.Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    
    # Check if Chocolatey is installed
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        $script:PACKAGE_MANAGER = "choco"
    } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        $script:PACKAGE_MANAGER = "winget"
    } else {
        $script:PACKAGE_MANAGER = "none"
    }
}

################################################################################
# Check if Chocolatey is available
################################################################################
function Test-Chocolatey {
    return (Get-Command choco -ErrorAction SilentlyContinue) -ne $null
}

################################################################################
# Check if Winget is available
################################################################################
function Test-Winget {
    return (Get-Command winget -ErrorAction SilentlyContinue) -ne $null
}
