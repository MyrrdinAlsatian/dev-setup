################################################################################
# UV Tools Installation Module - PowerShell
# Installe specify-cli depuis github/spec-kit en utilisant l'outil 'uv'
################################################################################

################################################################################
# Installer les outils CLI via uv
################################################################################
function Install-UvCliTools {
    Write-LogStep "Installation de specify-cli via uv..."
    
    # Vérifier si uv est disponible dans PATH
    if (-not (Test-CommandExists "uv")) {
        Write-LogWarning "L'outil 'uv' n'est pas installé ou n'est pas dans PATH"
        Write-LogInfo "Pour installer specify-cli, veuillez d'abord installer uv en suivant les instructions sur:"
        Write-LogInfo "  https://github.com/astral-sh/uv"
        Write-LogInfo ""
        Write-LogInfo "Une fois uv installé, exécutez cette commande:"
        Write-LogInfo "  uv tool install specify-cli --from git+https://github.com/github/spec-kit.git"
        Write-LogInfo ""
        Write-LogInfo "Installation de specify-cli ignorée (non fatal)"
        return
    }
    
    # Mode dry-run
    if ($DryRun) {
        Write-LogInfo "[DRY RUN] Exécuterait: uv tool install specify-cli --from git+https://github.com/github/spec-kit.git"
        return
    }
    
    # Installer specify-cli via uv
    Write-LogStep "Exécution: uv tool install specify-cli --from git+https://github.com/github/spec-kit.git"
    try {
        $output = uv tool install specify-cli --from git+https://github.com/github/spec-kit.git 2>&1
        Write-LogSuccess "specify-cli installé avec succès via uv"
    }
    catch {
        # Si l'installation échoue, ce n'est pas fatal (peut-être déjà installé)
        Write-LogWarning "L'installation de specify-cli a échoué ou l'outil est déjà installé"
        Write-LogInfo "Note: Si specify-cli est déjà installé, ceci est normal et peut être ignoré"
    }
}
