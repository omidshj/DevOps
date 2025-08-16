#!/bin/bash
# MongoDB deployment script for DevOps infrastructure

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
OPERATION="deploy"
VERBOSE=""
CHECK_MODE=""

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

Deploy MongoDB infrastructure using Ansible

OPTIONS:
    -e, --environment ENV    Target environment (production, staging) [default: production]
    -o, --operation OP       Operation to perform (deploy, backup, restore, maintenance) [default: deploy]
    -v, --verbose           Enable verbose output
    -c, --check             Run in check mode (dry run)
    -h, --help              Show this help message

EXAMPLES:
    $0                                  # Deploy MongoDB to production
    $0 -e staging                       # Deploy to staging environment
    $0 -o backup                        # Backup MongoDB
    $0 -o maintenance -e staging -v     # Run maintenance on staging with verbose output
    $0 -c                               # Dry run deployment

OPERATIONS:
    deploy      Deploy MongoDB infrastructure
    backup      Backup MongoDB databases
    restore     Restore MongoDB from backup (interactive)
    maintenance Check MongoDB status and perform maintenance

EOF
}

validate_environment() {
    if [[ ! -d "$INVENTORY_DIR/$ENVIRONMENT" ]]; then
        log_error "Environment '$ENVIRONMENT' not found in $INVENTORY_DIR"
        exit 1
    fi
}

validate_operation() {
    case $OPERATION in
        deploy|backup|restore|maintenance)
            ;;
        *)
            log_error "Invalid operation '$OPERATION'. Valid options: deploy, backup, restore, maintenance"
            exit 1
            ;;
    esac
}

run_ansible_playbook() {
    local playbook="$1"
    local inventory="$INVENTORY_DIR/$ENVIRONMENT/hosts.yml"
    
    log_info "Running playbook: $playbook"
    log_info "Environment: $ENVIRONMENT"
    log_info "Inventory: $inventory"
    
    ansible-playbook \
        -i "$inventory" \
        "$playbook" \
        $VERBOSE \
        $CHECK_MODE \
        --ask-vault-pass
}

deploy_mongodb() {
    log_info "Deploying MongoDB infrastructure..."
    run_ansible_playbook "$PLAYBOOK_DIR/site.yml"
}

backup_mongodb() {
    log_info "Backing up MongoDB..."
    run_ansible_playbook "$PLAYBOOK_DIR/mongodb-backup.yml"
}

restore_mongodb() {
    log_info "Restoring MongoDB..."
    run_ansible_playbook "$PLAYBOOK_DIR/mongodb-restore.yml"
}

maintenance_mongodb() {
    log_info "Running MongoDB maintenance..."
    run_ansible_playbook "$PLAYBOOK_DIR/status.yml"
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -o|--operation)
                OPERATION="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE="-v"
                shift
                ;;
            -c|--check)
                CHECK_MODE="--check"
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
    validate_operation
    
    # Check if Ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        log_error "ansible-playbook is not installed. Please install Ansible first."
        exit 1
    fi
    
    # Change to project directory
    cd "$PROJECT_DIR"
    
    log_info "Starting MongoDB operation..."
    log_info "Environment: $ENVIRONMENT"
    log_info "Operation: $OPERATION"
    
    # Execute based on operation selection
    case $OPERATION in
        deploy)
            deploy_mongodb
            ;;
        backup)
            backup_mongodb
            ;;
        restore)
            restore_mongodb
            ;;
        maintenance)
            maintenance_mongodb
            ;;
    esac
    
    log_success "MongoDB operation completed!"
}

# Run main function
main "$@"
