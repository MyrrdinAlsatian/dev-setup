################################################################################
# Git Installation and Configuration Module - PowerShell
################################################################################

################################################################################
# Install Git
################################################################################
function Install-Git {
    if (Test-CommandExists "git") {
        $gitVersion = (git --version) -replace 'git version ', ''
        Write-LogSuccess "Git is already installed (version $gitVersion)"
        
        if (Confirm-Action "Would you like to configure Git?") {
            Configure-Git
        }
        return
    }
    
    Write-LogStep "Installing Git..."
    
    if (Test-Chocolatey) {
        choco install git -y
    } elseif (Test-Winget) {
        winget install --id Git.Git -e --source winget --silent --accept-package-agreements
    } else {
        Write-LogError "No package manager available"
        return
    }
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    if (Test-CommandExists "git") {
        Write-LogSuccess "Git installed successfully"
        Configure-Git
    } else {
        Write-LogError "Failed to install Git"
    }
}

################################################################################
# Configure Git
################################################################################
function Configure-Git {
    Write-LogStep "Configuring Git..."
    
    # Get user name
    $currentName = git config --global user.name 2>$null
    
    if ([string]::IsNullOrEmpty($currentName)) {
        $gitName = Read-Host "Enter your Git user name"
        git config --global user.name $gitName
    } else {
        Write-LogInfo "Git user name already set: $currentName"
    }
    
    # Get user email
    $currentEmail = git config --global user.email 2>$null
    
    if ([string]::IsNullOrEmpty($currentEmail)) {
        $gitEmail = Read-Host "Enter your Git email"
        git config --global user.email $gitEmail
    } else {
        Write-LogInfo "Git email already set: $currentEmail"
    }
    
    # Set default branch name
    git config --global init.defaultBranch main
    
    # Set useful aliases
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.unstage 'reset HEAD --'
    git config --global alias.last 'log -1 HEAD'
    git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    
    # Set pull behavior
    git config --global pull.rebase false
    
    # Enable color
    git config --global color.ui auto
    
    # Configure credential helper for Windows
    git config --global credential.helper manager-core
    
    Write-LogSuccess "Git configured successfully"
}
