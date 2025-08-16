#!/bin/bash
# System status check script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INVENTORY_DIR="$PROJECT_DIR/inventories"
PLAYBOOK_DIR="$PROJECT_DIR/playbooks"

# Default values
ENVIRONMENT="production"
VERBOSE=""

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Check system and service status using Ansible

OPTIONS:
    -e, --environment ENV    Target environment (production, staging) [default: production]
    -v, --verbose           Enable verbose output
    -h, --help              Show this help message

EXAMPLES:
    $0                      # Check production environment status
    $0 -e staging           # Check staging environment status
    $0 -v                   # Check with verbose output

EOF
}

validate_environment() {
    if [[ ! -d "$INVENTORY_DIR/$ENVIRONMENT" ]]; then
        log_error "Environment '$ENVIRONMENT' not found in $INVENTORY_DIR"
        exit 1
    fi
}

run_status_check() {
    local inventory="$INVENTORY_DIR/$ENVIRONMENT/hosts.yml"
    
    log_info "Checking system status..."
    log_info "Environment: $ENVIRONMENT"
    log_info "Inventory: $inventory"
    
    ansible-playbook \
        -i "$inventory" \
        "$PLAYBOOK_DIR/status.yml" \
        $VERBOSE \
        --ask-vault-pass
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE="-v"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Validate inputs
    validate_environment
    
    # Check if Ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        log_error "ansible-playbook is not installed. Please install Ansible first."
        exit 1
    fi
    
    # Change to project directory
    cd "$PROJECT_DIR"
    
    # Run status check
    run_status_check
    
    log_success "Status check completed!"
}

# Run main function
main "$@"
