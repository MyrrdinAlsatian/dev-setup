################################################################################
# NVM (Node Version Manager) Installation Module - PowerShell
################################################################################

################################################################################
# Install NVM for Windows
################################################################################
function Install-Nvm {
    # Check if nvm-windows is installed
    if (Test-CommandExists "nvm") {
        Write-LogSuccess "NVM is already installed"
        $nvmVersion = (nvm version) 
        Write-LogInfo "NVM version: $nvmVersion"
        
        if (Confirm-Action "Would you like to install the latest LTS version of Node.js?") {
            Install-NodeLts
        }
        return
    }
    
    Write-LogStep "Installing NVM for Windows..."
    
    if (Test-Chocolatey) {
        choco install nvm -y
    } elseif (Test-Winget) {
        winget install --id CoreyButler.NVMforWindows -e --source winget --silent --accept-package-agreements
    } else {
        Write-LogError "No package manager available"
        Write-LogInfo "Please install NVM manually from https://github.com/coreybutler/nvm-windows/releases"
        return
    }
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    if (Test-CommandExists "nvm") {
        Write-LogSuccess "NVM installed successfully"
        Install-NodeLts
    } else {
        Write-LogWarning "NVM installed but not available in current session"
        Write-LogInfo "Please restart your PowerShell session and run: nvm install lts"
    }
}

################################################################################
# Install Node.js LTS version
################################################################################
function Install-NodeLts {
    Write-LogStep "Installing Node.js LTS version..."
    
    # Install latest LTS
    nvm install lts
    nvm use lts
    
    if (Test-CommandExists "node") {
        $nodeVersion = node --version
        Write-LogSuccess "Node.js $nodeVersion installed"
        
        $npmVersion = npm --version
        Write-LogInfo "npm version: $npmVersion"
    } else {
        Write-LogWarning "Node.js installed but not available in current session"
        Write-LogInfo "Please restart your PowerShell session"
    }
}
