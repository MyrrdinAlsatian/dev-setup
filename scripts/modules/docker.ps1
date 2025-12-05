################################################################################
# Docker Installation Module - PowerShell
################################################################################

################################################################################
# Install Docker
################################################################################
function Install-Docker {
    if (Test-CommandExists "docker") {
        $dockerVersion = (docker --version) -replace 'Docker version ', '' -replace ',.*', ''
        Write-LogSuccess "Docker is already installed (version $dockerVersion)"
        return
    }
    
    Write-LogStep "Installing Docker Desktop..."
    
    if (Test-Chocolatey) {
        choco install docker-desktop -y
    } elseif (Test-Winget) {
        winget install --id Docker.DockerDesktop -e --source winget --silent --accept-package-agreements
    } else {
        Write-LogError "No package manager available"
        Write-LogInfo "Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop"
        return
    }
    
    Write-LogSuccess "Docker Desktop installed"
    Write-LogWarning "Please start Docker Desktop manually and complete the setup"
    Write-LogInfo "You may need to restart your computer for changes to take effect"
}
