#!/usr/bin/env bash

################################################################################
# Logger Library
# Provides colored logging functions with different severity levels
################################################################################

# Color codes
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_MAGENTA='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_WHITE='\033[0;37m'
readonly COLOR_BOLD='\033[1m'

# Log level icons
readonly ICON_INFO="ℹ"
readonly ICON_SUCCESS="✓"
readonly ICON_WARNING="⚠"
readonly ICON_ERROR="✗"
readonly ICON_STEP="→"

################################################################################
# Print a colored message
# Arguments:
#   $1 - Color code
#   $2 - Message
################################################################################
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${COLOR_RESET}"
}

################################################################################
# Log an informational message
# Arguments:
#   $1 - Message
################################################################################
log_info() {
    print_color "${COLOR_BLUE}" "${ICON_INFO} $1"
}

################################################################################
# Log a success message
# Arguments:
#   $1 - Message
################################################################################
log_success() {
    print_color "${COLOR_GREEN}" "${ICON_SUCCESS} $1"
}

################################################################################
# Log a warning message
# Arguments:
#   $1 - Message
################################################################################
log_warning() {
    print_color "${COLOR_YELLOW}" "${ICON_WARNING} $1"
}

################################################################################
# Log an error message
# Arguments:
#   $1 - Message
################################################################################
log_error() {
    print_color "${COLOR_RED}" "${ICON_ERROR} $1" >&2
}

################################################################################
# Log a step message
# Arguments:
#   $1 - Message
################################################################################
log_step() {
    print_color "${COLOR_CYAN}" "${ICON_STEP} $1"
}

################################################################################
# Print a section header
# Arguments:
#   $1 - Section title
################################################################################
log_section() {
    echo ""
    print_color "${COLOR_BOLD}${COLOR_MAGENTA}" "═══════════════════════════════════════════════════════════════"
    print_color "${COLOR_BOLD}${COLOR_MAGENTA}" "  $1"
    print_color "${COLOR_BOLD}${COLOR_MAGENTA}" "═══════════════════════════════════════════════════════════════"
    echo ""
}

################################################################################
# Print a banner
# Arguments:
#   $1 - Banner text
################################################################################
print_banner() {
    echo ""
    print_color "${COLOR_BOLD}${COLOR_CYAN}" "╔═══════════════════════════════════════════════════════════════╗"
    print_color "${COLOR_BOLD}${COLOR_CYAN}" "║                                                               ║"
    printf "${COLOR_BOLD}${COLOR_CYAN}║  %-59s  ║${COLOR_RESET}\n" "$1"
    print_color "${COLOR_BOLD}${COLOR_CYAN}" "║                                                               ║"
    print_color "${COLOR_BOLD}${COLOR_CYAN}" "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
}

################################################################################
# Log and exit on error
# Arguments:
#   $1 - Error message
#   $2 - Exit code (optional, default: 1)
################################################################################
die() {
    local message="$1"
    local exit_code="${2:-1}"
    log_error "${message}"
    exit "${exit_code}"
}
