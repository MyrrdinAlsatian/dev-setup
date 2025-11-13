################################################################################
# Logger Library - PowerShell
# Provides colored logging functions with different severity levels
################################################################################

# Icons
$script:ICON_INFO = "ℹ"
$script:ICON_SUCCESS = "✓"
$script:ICON_WARNING = "⚠"
$script:ICON_ERROR = "✗"
$script:ICON_STEP = "→"

################################################################################
# Write an informational message
################################################################################
function Write-LogInfo {
    param([string]$Message)
    Write-Host "$script:ICON_INFO $Message" -ForegroundColor Blue
}

################################################################################
# Write a success message
################################################################################
function Write-LogSuccess {
    param([string]$Message)
    Write-Host "$script:ICON_SUCCESS $Message" -ForegroundColor Green
}

################################################################################
# Write a warning message
################################################################################
function Write-LogWarning {
    param([string]$Message)
    Write-Host "$script:ICON_WARNING $Message" -ForegroundColor Yellow
}

################################################################################
# Write an error message
################################################################################
function Write-LogError {
    param([string]$Message)
    Write-Host "$script:ICON_ERROR $Message" -ForegroundColor Red
}

################################################################################
# Write a step message
################################################################################
function Write-LogStep {
    param([string]$Message)
    Write-Host "$script:ICON_STEP $Message" -ForegroundColor Cyan
}

################################################################################
# Write a section header
################################################################################
function Write-LogSection {
    param([string]$Title)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "  $Title" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""
}

################################################################################
# Write a banner
################################################################################
function Write-Banner {
    param([string]$Text)
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                               ║" -ForegroundColor Cyan
    Write-Host "║  $($Text.PadRight(59))  ║" -ForegroundColor Cyan
    Write-Host "║                                                               ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}
