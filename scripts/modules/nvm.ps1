################################################################################
# NVM (Node Version Manager) Installation Module - PowerShell
################################################################################

################################################################################
# Install NVM for Windows
################################################################################
function Install-Nvm {
    # Remove NPM_CONFIG_PREFIX to avoid nvm incompatibility
    # Reference: nvm is not compatible with the NPM_CONFIG_PREFIX environment variable
    if ($env:NPM_CONFIG_PREFIX) {
        Remove-Item Env:\NPM_CONFIG_PREFIX -ErrorAction SilentlyContinue
        Write-LogInfo "Removed NPM_CONFIG_PREFIX to allow nvm to work correctly"
    }
    
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
        
        # Install pnpm for better package management
        Install-Pnpm
    } else {
        Write-LogWarning "Node.js installed but not available in current session"
        Write-LogInfo "Please restart your PowerShell session"
    }
}

################################################################################
# Install pnpm package manager
################################################################################
function Install-Pnpm {
    Write-LogStep "Installing pnpm package manager..."
    
    # Try corepack first (preferred method for pnpm installation)
    if (Test-CommandExists "corepack") {
        Write-LogInfo "Using corepack to install pnpm"
        try {
            corepack enable 2>$null
            corepack prepare pnpm@latest --activate 2>$null
            if (Test-CommandExists "pnpm") {
                $pnpmVersion = pnpm --version
                Write-LogSuccess "pnpm $pnpmVersion installed via corepack"
                return
            }
        } catch {
            Write-LogWarning "corepack failed, falling back to npm installation"
        }
    }
    
    # Fallback to npm install -g pnpm
    Write-LogInfo "Installing pnpm via npm"
    try {
        npm install -g pnpm 2>$null
        if (Test-CommandExists "pnpm") {
            $pnpmVersion = pnpm --version
            Write-LogSuccess "pnpm $pnpmVersion installed via npm"
        } else {
            Write-LogError "Failed to install pnpm"
        }
    } catch {
        Write-LogError "Failed to install pnpm: $_"
    }
}
