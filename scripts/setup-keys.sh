#!/usr/bin/env bash

################################################################################
# SSH and GPG Keys Setup Script
# Génère et configure les clés SSH et GPG pour GitHub/GitLab
################################################################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
if [[ -f "${SCRIPT_DIR}/lib/logger.sh" ]]; then
    # shellcheck source=lib/logger.sh
    source "${SCRIPT_DIR}/lib/logger.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
    # shellcheck source=lib/utils.sh
    source "${SCRIPT_DIR}/lib/utils.sh"
fi

# Fallback logging functions if libraries not available
if ! command -v log_info >/dev/null 2>&1; then
    log_info() { echo "ℹ $1"; }
    log_success() { echo "✓ $1"; }
    log_warning() { echo "⚠ $1"; }
    log_error() { echo "✗ $1" >&2; }
    log_step() { echo "→ $1"; }
    log_section() { echo ""; echo "=== $1 ==="; echo ""; }
    print_banner() { echo ""; echo "=== $1 ==="; echo ""; }
    die() { log_error "$1"; exit "${2:-1}"; }
fi

if ! command -v command_exists >/dev/null 2>&1; then
    command_exists() { command -v "$1" >/dev/null 2>&1; }
fi

################################################################################
# Configuration variables
################################################################################
USER_EMAIL=""
USER_NAME=""
SSH_KEY_PATH=""
SSH_KEY_TYPE="ed25519"
GENERATE_SSH=true
GENERATE_GPG=true
NON_INTERACTIVE=false

################################################################################
# Afficher l'aide
################################################################################
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Script d'initialisation des clés SSH et GPG pour GitHub/GitLab.

OPTIONS:
    --email EMAIL          Adresse e-mail (utilisée pour SSH et GPG)
    --name NAME            Nom complet (utilisé pour GPG et Git)
    --ssh-path PATH        Chemin de la clé SSH (défaut: ~/.ssh/id_ed25519 ou id_rsa)
    --ssh-type TYPE        Type de clé SSH: ed25519 (défaut) ou rsa
    --no-ssh               Ne pas générer de clé SSH
    --no-gpg               Ne pas générer de clé GPG
    --help                 Afficher cette aide

EXEMPLES:
    # Mode interactif (par défaut)
    ./setup-keys.sh

    # Mode non-interactif avec paramètres
    ./setup-keys.sh --email "user@example.com" --name "John Doe" --ssh-type rsa

    # Générer uniquement une clé SSH
    ./setup-keys.sh --no-gpg --email "user@example.com"

    # Générer uniquement une clé GPG
    ./setup-keys.sh --no-ssh --email "user@example.com" --name "John Doe"

EOF
    exit 0
}

################################################################################
# Parser les arguments de ligne de commande
################################################################################
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --email)
                if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                    log_error "L'option --email nécessite une valeur"
                    exit 1
                fi
                USER_EMAIL="$2"
                shift 2
                ;;
            --name)
                if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                    log_error "L'option --name nécessite une valeur"
                    exit 1
                fi
                USER_NAME="$2"
                shift 2
                ;;
            --ssh-path)
                if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                    log_error "L'option --ssh-path nécessite une valeur"
                    exit 1
                fi
                SSH_KEY_PATH="$2"
                shift 2
                ;;
            --ssh-type)
                if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                    log_error "L'option --ssh-type nécessite une valeur"
                    exit 1
                fi
                if [[ "$2" != "ed25519" ]] && [[ "$2" != "rsa" ]]; then
                    log_error "Type de clé SSH invalide: $2 (valeurs acceptées: ed25519, rsa)"
                    exit 1
                fi
                SSH_KEY_TYPE="$2"
                shift 2
                ;;
            --no-ssh)
                GENERATE_SSH=false
                shift
                ;;
            --no-gpg)
                GENERATE_GPG=false
                shift
                ;;
            --help)
                show_help
                ;;
            *)
                log_error "Option inconnue: $1"
                echo "Utilisez --help pour afficher l'aide."
                exit 1
                ;;
        esac
    done

    # Vérifier si on est en mode non-interactif
    if [[ -n "${USER_EMAIL}" ]] || [[ -n "${USER_NAME}" ]] || [[ -n "${SSH_KEY_PATH}" ]]; then
        NON_INTERACTIVE=true
    fi
}

################################################################################
# Vérifier les dépendances requises
################################################################################
check_dependencies() {
    log_section "Vérification des dépendances"
    
    local missing_deps=()
    
    if [[ "${GENERATE_SSH}" == true ]]; then
        if ! command_exists ssh-keygen; then
            missing_deps+=("ssh-keygen")
        fi
        if ! command_exists ssh-agent; then
            missing_deps+=("ssh-agent")
        fi
        if ! command_exists ssh-add; then
            missing_deps+=("ssh-add")
        fi
    fi
    
    if [[ "${GENERATE_GPG}" == true ]]; then
        if ! command_exists gpg; then
            missing_deps+=("gpg")
        fi
    fi
    
    if ! command_exists git; then
        missing_deps+=("git")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Dépendances manquantes: ${missing_deps[*]}"
        echo ""
        log_info "Instructions d'installation:"
        echo ""
        
        if [[ -f /etc/debian_version ]]; then
            echo "  sudo apt-get update"
            echo "  sudo apt-get install -y ${missing_deps[*]}"
        elif [[ -f /etc/redhat-release ]]; then
            echo "  sudo dnf install -y ${missing_deps[*]}"
        elif [[ -f /etc/arch-release ]]; then
            echo "  sudo pacman -S ${missing_deps[*]}"
        elif [[ "$(uname)" == "Darwin" ]]; then
            echo "  brew install ${missing_deps[*]}"
        else
            echo "  Installez les paquets suivants: ${missing_deps[*]}"
        fi
        
        exit 1
    fi
    
    log_success "Toutes les dépendances sont présentes"
}

################################################################################
# Valider une adresse e-mail
################################################################################
validate_email() {
    local email="$1"
    
    # Pattern de validation basique pour e-mail
    if [[ ! "${email}" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    
    return 0
}

################################################################################
# Sanitize une chaîne de caractères (enlever les caractères dangereux)
################################################################################
sanitize_string() {
    local input="$1"
    
    # Enlever les caractères spéciaux dangereux pour le shell
    # Garder uniquement les lettres, chiffres, espaces, tirets, underscores, points, @
    echo "${input}" | sed 's/[^a-zA-Z0-9 @._-]//g'
}

################################################################################
# Sanitize un chemin de fichier
################################################################################
sanitize_path() {
    local input="$1"
    
    # Enlever les caractères dangereux des chemins
    # Garder uniquement les lettres, chiffres, /, _, -, ., ~
    echo "${input}" | sed 's/[^a-zA-Z0-9/_.~-]//g'
}

################################################################################
# Fonction pour poser une question oui/non
################################################################################
ask() {
    local question="$1"
    local response
    
    while true; do
        read -r -p "${question} (o/n): " response
        case "${response}" in
            [oOyY]*)
                return 0
                ;;
            [nN]*)
                return 1
                ;;
            *)
                echo "Réponse invalide. Veuillez entrer o (oui) ou n (non)."
                ;;
        esac
    done
}

################################################################################
# Collecter les informations utilisateur
################################################################################
collect_user_info() {
    log_section "Informations utilisateur"
    
    # E-mail
    if [[ -z "${USER_EMAIL}" ]]; then
        while true; do
            read -r -p "Entrez votre adresse e-mail: " email_input
            email_input=$(sanitize_string "${email_input}")
            
            if validate_email "${email_input}"; then
                USER_EMAIL="${email_input}"
                break
            else
                log_error "Adresse e-mail invalide. Veuillez réessayer."
            fi
        done
    else
        log_info "Adresse e-mail: ${USER_EMAIL}"
    fi
    
    # Nom (requis uniquement si GPG est activé)
    if [[ "${GENERATE_GPG}" == true ]] && [[ -z "${USER_NAME}" ]]; then
        read -r -p "Entrez votre nom complet: " name_input
        USER_NAME=$(sanitize_string "${name_input}")
    fi
    
    if [[ -n "${USER_NAME}" ]]; then
        log_info "Nom: ${USER_NAME}"
    fi
}

################################################################################
# Configurer les permissions du répertoire .ssh
################################################################################
setup_ssh_directory() {
    local ssh_dir="${HOME}/.ssh"
    
    if [[ ! -d "${ssh_dir}" ]]; then
        log_step "Création du répertoire ${ssh_dir}"
        mkdir -p "${ssh_dir}"
    fi
    
    # Définir les permissions correctes
    chmod 700 "${ssh_dir}"
    log_step "Permissions définies sur ${ssh_dir}: 700"
}

################################################################################
# Générer une clé SSH
################################################################################
generate_ssh_key() {
    log_section "Génération de la clé SSH"
    
    # Déterminer le chemin de la clé
    if [[ -z "${SSH_KEY_PATH}" ]]; then
        if [[ "${SSH_KEY_TYPE}" == "ed25519" ]]; then
            SSH_KEY_PATH="${HOME}/.ssh/id_ed25519"
        else
            SSH_KEY_PATH="${HOME}/.ssh/id_rsa"
        fi
        
        if [[ "${NON_INTERACTIVE}" == false ]]; then
            read -r -p "Chemin de la clé SSH [${SSH_KEY_PATH}]: " custom_path
            if [[ -n "${custom_path}" ]]; then
                SSH_KEY_PATH=$(sanitize_path "${custom_path}")
                # Expand tilde
                SSH_KEY_PATH="${SSH_KEY_PATH/#\~/$HOME}"
            fi
        fi
    else
        SSH_KEY_PATH=$(sanitize_path "${SSH_KEY_PATH}")
        SSH_KEY_PATH="${SSH_KEY_PATH/#\~/$HOME}"
    fi
    
    # Vérifier si la clé existe déjà
    if [[ -f "${SSH_KEY_PATH}" ]]; then
        log_warning "Une clé SSH existe déjà à: ${SSH_KEY_PATH}"
        
        if [[ "${NON_INTERACTIVE}" == true ]]; then
            log_info "Mode non-interactif: utilisation de la clé existante"
            return 0
        fi
        
        if ! ask "Voulez-vous la remplacer?"; then
            log_info "Utilisation de la clé existante"
            return 0
        fi
    fi
    
    # Configurer le répertoire .ssh
    setup_ssh_directory
    
    # Générer la clé
    log_step "Génération de la clé SSH ${SSH_KEY_TYPE}..."
    
    if [[ "${SSH_KEY_TYPE}" == "ed25519" ]]; then
        ssh-keygen -t ed25519 -C "${USER_EMAIL}" -f "${SSH_KEY_PATH}" -N ""
    elif [[ "${SSH_KEY_TYPE}" == "rsa" ]]; then
        ssh-keygen -t rsa -b 4096 -C "${USER_EMAIL}" -f "${SSH_KEY_PATH}" -N ""
    else
        log_error "Type de clé SSH invalide: ${SSH_KEY_TYPE}"
        return 1
    fi
    
    # Définir les permissions correctes
    chmod 600 "${SSH_KEY_PATH}"
    chmod 644 "${SSH_KEY_PATH}.pub"
    log_step "Permissions définies: 600 (clé privée), 644 (clé publique)"
    
    log_success "Clé SSH générée: ${SSH_KEY_PATH}"
    
    # Ajouter à l'agent SSH
    add_to_ssh_agent
    
    # Proposer la configuration SSH pour GitHub/GitLab
    configure_ssh_config
    
    # Afficher la clé publique
    show_ssh_public_key
}

################################################################################
# Ajouter la clé à l'agent SSH
################################################################################
add_to_ssh_agent() {
    log_step "Ajout de la clé à l'agent SSH..."
    
    # Démarrer l'agent SSH si nécessaire
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
        eval "$(ssh-agent -s)" > /dev/null
    fi
    
    # Ajouter la clé
    if ssh-add "${SSH_KEY_PATH}" 2>/dev/null; then
        log_success "Clé ajoutée à l'agent SSH"
    else
        log_warning "Impossible d'ajouter la clé à l'agent SSH (peut nécessiter une intervention manuelle)"
    fi
}

################################################################################
# Configurer ~/.ssh/config pour GitHub/GitLab
################################################################################
configure_ssh_config() {
    if [[ "${NON_INTERACTIVE}" == true ]]; then
        return 0
    fi
    
    if ! ask "Voulez-vous ajouter une entrée dans ~/.ssh/config pour GitHub/GitLab?"; then
        return 0
    fi
    
    local ssh_config="${HOME}/.ssh/config"
    
    # Créer le fichier si il n'existe pas
    if [[ ! -f "${ssh_config}" ]]; then
        touch "${ssh_config}"
        chmod 600 "${ssh_config}"
    fi
    
    # Ajouter les configurations pour GitHub et GitLab
    if ! grep -q "Host github.com" "${ssh_config}"; then
        log_step "Ajout de la configuration GitHub..."
        cat >> "${ssh_config}" << EOF

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ${SSH_KEY_PATH}
    IdentitiesOnly yes
EOF
    fi
    
    if ! grep -q "Host gitlab.com" "${ssh_config}"; then
        log_step "Ajout de la configuration GitLab..."
        cat >> "${ssh_config}" << EOF

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ${SSH_KEY_PATH}
    IdentitiesOnly yes
EOF
    fi
    
    log_success "Configuration SSH mise à jour: ${ssh_config}"
}

################################################################################
# Afficher la clé SSH publique
################################################################################
show_ssh_public_key() {
    log_section "Clé SSH publique"
    
    echo ""
    log_info "Voici votre clé SSH publique:"
    echo ""
    cat "${SSH_KEY_PATH}.pub"
    echo ""
    
    log_info "Pour ajouter cette clé sur GitHub:"
    log_step "1. Allez sur https://github.com/settings/keys"
    log_step "2. Cliquez sur 'New SSH key'"
    log_step "3. Collez la clé ci-dessus"
    echo ""
    
    log_info "Pour ajouter cette clé sur GitLab:"
    log_step "1. Allez sur https://gitlab.com/-/profile/keys"
    log_step "2. Collez la clé ci-dessus"
    echo ""
}

################################################################################
# Générer une clé GPG
################################################################################
generate_gpg_key() {
    log_section "Génération de la clé GPG"
    
    # Vérifier si une clé existe déjà pour cet e-mail
    local existing_keys
    existing_keys=$(gpg --list-keys --with-colons "${USER_EMAIL}" 2>/dev/null | grep -c "^uid" || true)
    
    if [[ "${existing_keys}" -gt 0 ]]; then
        log_warning "Une clé GPG existe déjà pour ${USER_EMAIL}"
        
        if [[ "${NON_INTERACTIVE}" == true ]]; then
            log_info "Mode non-interactif: utilisation de la clé existante"
            return 0
        fi
        
        if ! ask "Voulez-vous en générer une nouvelle?"; then
            log_info "Utilisation de la clé existante"
            return 0
        fi
    fi
    
    log_step "Génération de la clé GPG (cela peut prendre un moment)..."
    
    # Créer un fichier de configuration temporaire pour gpg --batch
    local batch_file
    batch_file=$(mktemp)
    
    cat > "${batch_file}" << EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: ${USER_NAME}
Name-Email: ${USER_EMAIL}
Expire-Date: 0
%no-protection
%commit
EOF
    
    # Générer la clé
    if gpg --batch --gen-key "${batch_file}" 2>/dev/null; then
        log_success "Clé GPG générée avec succès"
    else
        log_error "Échec de la génération de la clé GPG"
        rm -f "${batch_file}"
        return 1
    fi
    
    # Nettoyer le fichier temporaire
    rm -f "${batch_file}"
    
    # Afficher la clé publique
    show_gpg_public_key
    
    # Proposer de configurer Git
    configure_git_gpg
}

################################################################################
# Afficher la clé GPG publique
################################################################################
show_gpg_public_key() {
    log_section "Clé GPG publique"
    
    # Récupérer l'ID de la clé
    local gpg_key_id
    gpg_key_id=$(gpg --list-keys --with-colons "${USER_EMAIL}" 2>/dev/null | grep "^fpr" | head -n 1 | cut -d ':' -f 10)
    
    if [[ -z "${gpg_key_id}" ]]; then
        log_error "Impossible de trouver la clé GPG"
        return 1
    fi
    
    echo ""
    log_info "Voici votre clé GPG publique:"
    echo ""
    gpg --armor --export "${gpg_key_id}"
    echo ""
    
    log_info "Pour ajouter cette clé sur GitHub:"
    log_step "1. Allez sur https://github.com/settings/keys"
    log_step "2. Cliquez sur 'New GPG key'"
    log_step "3. Collez la clé ci-dessus"
    echo ""
    
    log_info "Pour ajouter cette clé sur GitLab:"
    log_step "1. Allez sur https://gitlab.com/-/profile/gpg_keys"
    log_step "2. Collez la clé ci-dessus"
    echo ""
}

################################################################################
# Configurer Git pour utiliser GPG
################################################################################
configure_git_gpg() {
    if [[ "${NON_INTERACTIVE}" == false ]]; then
        if ! ask "Voulez-vous configurer Git pour signer vos commits avec GPG?"; then
            return 0
        fi
    fi
    
    log_step "Configuration de Git pour GPG..."
    
    # Récupérer l'ID de la clé
    local gpg_key_id
    gpg_key_id=$(gpg --list-keys --with-colons "${USER_EMAIL}" 2>/dev/null | grep "^fpr" | head -n 1 | cut -d ':' -f 10)
    
    if [[ -z "${gpg_key_id}" ]]; then
        log_error "Impossible de trouver la clé GPG"
        return 1
    fi
    
    # Configurer Git
    git config --global user.signingkey "${gpg_key_id}"
    git config --global commit.gpgsign true
    
    log_success "Git configuré pour signer les commits avec la clé GPG"
}

################################################################################
# Configurer Git (user.name et user.email)
################################################################################
configure_git_user() {
    log_section "Configuration de Git"
    
    # Vérifier la configuration actuelle
    local current_name
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    
    local current_email
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    
    # Configurer le nom si nécessaire
    if [[ -z "${current_name}" ]] && [[ -n "${USER_NAME}" ]]; then
        git config --global user.name "${USER_NAME}"
        log_success "Git user.name configuré: ${USER_NAME}"
    elif [[ -n "${current_name}" ]]; then
        log_info "Git user.name déjà configuré: ${current_name}"
    fi
    
    # Configurer l'e-mail si nécessaire
    if [[ -z "${current_email}" ]] && [[ -n "${USER_EMAIL}" ]]; then
        git config --global user.email "${USER_EMAIL}"
        log_success "Git user.email configuré: ${USER_EMAIL}"
    elif [[ -n "${current_email}" ]]; then
        log_info "Git user.email déjà configuré: ${current_email}"
    fi
}

################################################################################
# Fonction principale
################################################################################
main() {
    print_banner "Configuration des clés SSH et GPG"
    
    # Parser les arguments
    parse_arguments "$@"
    
    # Vérifier les dépendances
    check_dependencies
    
    # Collecter les informations utilisateur
    collect_user_info
    
    # Générer la clé SSH
    if [[ "${GENERATE_SSH}" == true ]]; then
        generate_ssh_key
    fi
    
    # Générer la clé GPG
    if [[ "${GENERATE_GPG}" == true ]]; then
        if [[ -z "${USER_NAME}" ]]; then
            log_warning "Le nom est requis pour générer une clé GPG"
            if [[ "${NON_INTERACTIVE}" == false ]]; then
                read -r -p "Entrez votre nom complet: " name_input
                USER_NAME=$(sanitize_string "${name_input}")
            fi
        fi
        
        if [[ -n "${USER_NAME}" ]]; then
            generate_gpg_key
        else
            log_warning "Génération de la clé GPG ignorée (nom manquant)"
        fi
    fi
    
    # Configurer Git
    configure_git_user
    
    # Message final
    echo ""
    log_section "Configuration terminée"
    log_success "Vos clés ont été générées avec succès!"
    echo ""
    log_info "N'oubliez pas d'ajouter vos clés publiques sur GitHub/GitLab"
    log_info "et de tester votre connexion SSH avec: ssh -T git@github.com"
    echo ""
}

# Exécuter le script
main "$@"
