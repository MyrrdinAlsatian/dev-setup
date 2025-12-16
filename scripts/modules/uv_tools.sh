#!/usr/bin/env bash

################################################################################
# UV Tools Installation Module
# Installe specify-cli depuis github/spec-kit en utilisant l'outil 'uv'
################################################################################

################################################################################
# Installer les outils CLI via uv
################################################################################
install_uv_cli_tools() {
    log_step "Installation de specify-cli via uv..."
    
    # Vérifier si uv est disponible dans PATH
    if ! command_exists uv; then
        log_warning "L'outil 'uv' n'est pas installé ou n'est pas dans PATH"
        log_info "Pour installer specify-cli, veuillez d'abord installer uv en suivant les instructions sur:"
        log_info "  https://github.com/astral-sh/uv"
        log_info ""
        log_info "Une fois uv installé, exécutez cette commande:"
        log_info "  uv tool install specify-cli --from git+https://github.com/github/spec-kit.git"
        log_info ""
        log_info "Installation de specify-cli ignorée (non fatal)"
        return 1
    fi
    
    # Mode dry-run
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_dry_run "Would execute: uv tool install specify-cli --from git+https://github.com/github/spec-kit.git"
        return 0
    fi
    
    # Installer specify-cli via uv
    log_step "Exécution: uv tool install specify-cli --from git+https://github.com/github/spec-kit.git"
    if uv tool install specify-cli --from git+https://github.com/github/spec-kit.git; then
        log_success "specify-cli installé avec succès via uv"
        return 0
    else
        # Si l'installation échoue, ce n'est pas fatal (peut-être déjà installé)
        log_warning "L'installation de specify-cli a échoué ou l'outil est déjà installé"
        log_info "Note: Si specify-cli est déjà installé, ceci est normal et peut être ignoré"
        return 0
    fi
}
