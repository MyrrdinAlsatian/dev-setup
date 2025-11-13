################################################################################
# Starship Prompt Installation and Configuration Module - PowerShell
################################################################################

################################################################################
# Install Starship
################################################################################
function Install-Starship {
    if (Test-CommandExists "starship") {
        $starshipVersion = (starship --version) -replace 'starship ', ''
        Write-LogSuccess "Starship is already installed (version $starshipVersion)"
        
        if (Confirm-Action "Would you like to configure Starship?") {
            Configure-Starship
        }
        return
    }
    
    Write-LogStep "Installing Starship..."
    
    if (Test-Chocolatey) {
        choco install starship -y
    } elseif (Test-Winget) {
        winget install --id Starship.Starship -e --source winget --silent --accept-package-agreements
    } else {
        # Install using PowerShell script
        Invoke-Expression (&{(Invoke-WebRequest -Uri https://starship.rs/install.ps1 -UseBasicParsing).Content})
    }
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    if (Test-CommandExists "starship") {
        Write-LogSuccess "Starship installed successfully"
        Configure-Starship
    } else {
        Write-LogWarning "Starship installed but may require PowerShell restart"
    }
}

################################################################################
# Configure Starship
################################################################################
function Configure-Starship {
    Write-LogStep "Configuring Starship for PowerShell..."
    
    $profile_path = $PROFILE
    
    # Create profile if it doesn't exist
    if (-not (Test-Path $profile_path)) {
        New-Item -Path $profile_path -ItemType File -Force | Out-Null
    }
    
    # Add Starship initialization
    $starship_init = 'Invoke-Expression (&starship init powershell)'
    Add-LineToFile $starship_init $profile_path
    
    # Create Starship configuration
    Create-StarshipConfig
    
    Write-LogSuccess "Starship configured successfully"
    Write-LogInfo "Restart your PowerShell session to see changes"
}

################################################################################
# Create Starship configuration
################################################################################
function Create-StarshipConfig {
    $config_dir = Join-Path $env:USERPROFILE ".config"
    $starship_config = Join-Path $config_dir "starship.toml"
    
    Ensure-Directory $config_dir
    
    if (Test-Path $starship_config) {
        Write-LogInfo "Starship configuration already exists at: $starship_config"
        return
    }
    
    Write-LogStep "Creating Starship configuration..."
    
    @'
# Starship Configuration

# Get editor completions based on the config schema
"$schema" = 'https://starship.rs/config-schema.json'

# Timeout for commands executed by starship (in milliseconds)
command_timeout = 500

# Inserts a blank line between shell prompts
add_newline = true

# Change the default prompt format
format = """
[╭╴](238)$os\
$all[╰─](238)$character"""

# Change the default prompt characters
[character]
success_symbol = "[](238)"
error_symbol = "[](238)"

# Show current directory
[directory]
style = "blue"
read_only = " 󰌾"
truncation_length = 4
truncate_to_repo = false

# Git branch
[git_branch]
symbol = " "
format = "[$symbol$branch]($style) "
style = "bright-black"

# Git status
[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "cyan"

# Package version
[package]
symbol = "󰏗 "

# Programming Languages
[nodejs]
symbol = " "
format = "[$symbol($version )]($style)"

[python]
symbol = " "
format = '[${symbol}${pyenv_prefix}(${version} )(\($virtualenv\) )]($style)'

[docker_context]
symbol = " "
format = "[$symbol$context]($style) "

# OS
[os]
format = '[$symbol](bold white) '
disabled = false

[os.symbols]
Windows = "󰍲 "
'@ | Out-File -FilePath $starship_config -Encoding utf8
    
    Write-LogSuccess "Starship configuration created at: $starship_config"
}
