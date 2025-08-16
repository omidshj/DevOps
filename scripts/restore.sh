#!/bin/bash
# MongoDB restore script

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
BACKUP_FILE=""
DATABASE=""
DROP_EXISTING="no"
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

Restore MongoDB database from backup using Ansible

OPTIONS:
    -e, --environment ENV    Target environment (production, staging) [default: production]
    -f, --file FILE         Path to backup file (required)
    -d, --database DB       Specific database to restore (optional, restores all if not specified)
    --drop-existing         Drop existing databases before restore
    -v, --verbose           Enable verbose output
    -h, --help              Show this help message

EXAMPLES:
    $0 -f /opt/mongodb/backups/backup_20231201.archive
    $0 -f backup.archive -d myapp -e staging
    $0 -f backup.archive --drop-existing
    $0 -f backup.archive -v

WARNING:
    This operation will restore data to your MongoDB instance.
    Use --drop-existing with caution as it will delete existing data.

EOF
}

validate_environment() {
    if [[ ! -d "$INVENTORY_DIR/$ENVIRONMENT" ]]; then
        log_error "Environment '$ENVIRONMENT' not found in $INVENTORY_DIR"
        exit 1
    fi
}

validate_backup_file() {
    if [[ -z "$BACKUP_FILE" ]]; then
        log_error "Backup file is required. Use -f option."
        exit 1
    fi
    
    if [[ ! -f "$BACKUP_FILE" ]]; then
        log_error "Backup file '$BACKUP_FILE' does not exist."
        exit 1
    fi
}

confirm_restore() {
    log_warning "You are about to restore MongoDB from: $BACKUP_FILE"
    log_warning "Environment: $ENVIRONMENT"
    
    if [[ -n "$DATABASE" ]]; then
        log_warning "Database filter: $DATABASE"
    else
        log_warning "Database filter: All databases"
    fi
    
    if [[ "$DROP_EXISTING" == "yes" ]]; then
        log_warning "Drop existing: YES (DANGER: This will delete existing data!)"
    else
        log_warning "Drop existing: NO"
    fi
    
    echo
    read -p "Do you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        log_info "Restore cancelled by user."
        exit 0
    fi
}

run_restore() {
    local inventory="$INVENTORY_DIR/$ENVIRONMENT/hosts.yml"
    
    log_info "Starting MongoDB restore..."
    log_info "Environment: $ENVIRONMENT"
    log_info "Backup file: $BACKUP_FILE"
    log_info "Inventory: $inventory"
    
    # Create temporary vars file
    local temp_vars=$(mktemp)
    cat > "$temp_vars" << EOF
restore_source: "$BACKUP_FILE"
restore_database: "$DATABASE"
drop_existing_confirm: "$DROP_EXISTING"
mongodb_override:
  restore:
    drop_existing: $([ "$DROP_EXISTING" == "yes" ] && echo "true" || echo "false")
EOF
    
    ansible-playbook \
        -i "$inventory" \
        "$PLAYBOOK_DIR/mongodb-restore.yml" \
        -e "@$temp_vars" \
        $VERBOSE \
        --ask-vault-pass
    
    # Clean up temporary file
    rm -f "$temp_vars"
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -f|--file)
                BACKUP_FILE="$2"
                shift 2
                ;;
            -d|--database)
                DATABASE="$2"
                shift 2
                ;;
            --drop-existing)
                DROP_EXISTING="yes"
                shift
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
    validate_backup_file
    
    # Check if Ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        log_error "ansible-playbook is not installed. Please install Ansible first."
        exit 1
    fi
    
    # Confirm restore operation
    confirm_restore
    
    # Change to project directory
    cd "$PROJECT_DIR"
    
    # Run restore
    run_restore
    
    log_success "Restore completed!"
}

# Run main function
main "$@"
