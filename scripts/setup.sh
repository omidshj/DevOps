#!/bin/bash
# Initial setup script for the Ansible MongoDB project

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

Initial setup for the Ansible MongoDB project

OPTIONS:
    --install-ansible       Install Ansible and dependencies
    --encrypt-vault         Encrypt vault files
    --generate-ssh-key      Generate SSH key for deployment
    --all                   Run all setup steps
    -h, --help              Show this help message

EXAMPLES:
    $0 --all                # Complete setup
    $0 --install-ansible    # Install Ansible only
    $0 --encrypt-vault      # Encrypt vault files only

EOF
}

install_ansible() {
    log_info "Installing Ansible and dependencies..."
    
    # Detect OS
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu
        sudo apt update
        sudo apt install -y ansible python3-pip python3-docker sshpass
        pip3 install --user docker docker-compose
    elif [[ -f /etc/redhat-release ]]; then
        # RHEL/CentOS/Fedora
        if command -v dnf &> /dev/null; then
            sudo dnf install -y ansible python3-pip python3-docker
        else
            sudo yum install -y ansible python3-pip
        fi
        pip3 install --user docker docker-compose
    else
        log_error "Unsupported operating system. Please install Ansible manually."
        exit 1
    fi
    
    log_success "Ansible installation completed!"
}

encrypt_vault_files() {
    log_info "Encrypting vault files..."
    
    cd "$PROJECT_DIR"
    
    # Check if vault file exists and is not encrypted
    if [[ -f "group_vars/vault.yml" ]]; then
        if ! grep -q "ANSIBLE_VAULT" "group_vars/vault.yml"; then
            log_warning "Encrypting group_vars/vault.yml..."
            log_warning "Please set a strong vault password!"
            ansible-vault encrypt group_vars/vault.yml
            log_success "Vault file encrypted!"
        else
            log_info "Vault file is already encrypted."
        fi
    else
        log_error "Vault file not found: group_vars/vault.yml"
        exit 1
    fi
}

generate_ssh_key() {
    log_info "Generating SSH key for deployment..."
    
    local ssh_key_path="$HOME/.ssh/ansible_devops"
    
    if [[ -f "$ssh_key_path" ]]; then
        log_info "SSH key already exists: $ssh_key_path"
        return
    fi
    
    ssh-keygen -t rsa -b 4096 -f "$ssh_key_path" -N "" -C "ansible-devops-$(date +%Y%m%d)"
    
    log_success "SSH key generated: $ssh_key_path"
    log_info "Public key:"
    cat "${ssh_key_path}.pub"
    echo
    log_warning "Don't forget to:"
    log_warning "1. Copy the public key to your target servers"
    log_warning "2. Update inventory files with the correct key path"
}

setup_permissions() {
    log_info "Setting up file permissions..."
    
    cd "$PROJECT_DIR"
    
    # Make scripts executable
    chmod +x scripts/*.sh
    
    # Set appropriate permissions for sensitive files
    chmod 600 group_vars/vault.yml 2>/dev/null || true
    
    log_success "File permissions set!"
}

validate_setup() {
    log_info "Validating setup..."
    
    # Check Ansible installation
    if ! command -v ansible &> /dev/null; then
        log_error "Ansible is not installed or not in PATH"
        return 1
    fi
    
    if ! command -v ansible-playbook &> /dev/null; then
        log_error "ansible-playbook is not installed or not in PATH"
        return 1
    fi
    
    # Check Python Docker module
    if ! python3 -c "import docker" 2>/dev/null; then
        log_warning "Python Docker module not found. Some features may not work."
    fi
    
    # Check project structure
    local required_dirs=("roles" "playbooks" "inventories" "group_vars")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$PROJECT_DIR/$dir" ]]; then
            log_error "Required directory missing: $dir"
            return 1
        fi
    done
    
    log_success "Setup validation passed!"
}

show_next_steps() {
    log_success "Setup completed successfully!"
    echo
    log_info "Next steps:"
    echo "1. Update inventory files with your server details:"
    echo "   - inventories/production/hosts.yml"
    echo "   - inventories/staging/hosts.yml"
    echo
    echo "2. Update vault file with your MongoDB passwords:"
    echo "   - ansible-vault edit group_vars/vault.yml"
    echo
    echo "3. Test connectivity:"
    echo "   - ansible all -i inventories/production/hosts.yml -m ping"
    echo
    echo "4. Deploy MongoDB:"
    echo "   - ./scripts/deploy.sh"
    echo "   - ./scripts/deploy.sh -e staging"
    echo
    echo "5. MongoDB operations:"
    echo "   - ./scripts/deploy.sh -o backup"
    echo "   - ./scripts/deploy.sh -o maintenance"
    echo "   - ./scripts/backup.sh"
    echo "   - ./scripts/status.sh"
    echo
    log_info "For help with any script, use the -h flag (e.g., ./scripts/deploy.sh -h)"
}

main() {
    local install_ansible=false
    local encrypt_vault=false
    local generate_ssh=false
    local run_all=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install-ansible)
                install_ansible=true
                shift
                ;;
            --encrypt-vault)
                encrypt_vault=true
                shift
                ;;
            --generate-ssh-key)
                generate_ssh=true
                shift
                ;;
            --all)
                run_all=true
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
    
    # If no specific options, show help
    if [[ "$install_ansible" == false && "$encrypt_vault" == false && "$generate_ssh" == false && "$run_all" == false ]]; then
        show_help
        exit 0
    fi
    
    # Change to project directory
    cd "$PROJECT_DIR"
    
    log_info "Starting setup process..."
    
    # Run selected setup steps
    if [[ "$run_all" == true || "$install_ansible" == true ]]; then
        install_ansible
    fi
    
    if [[ "$run_all" == true || "$generate_ssh" == true ]]; then
        generate_ssh_key
    fi
    
    # Always set permissions
    setup_permissions
    
    if [[ "$run_all" == true || "$encrypt_vault" == true ]]; then
        encrypt_vault_files
    fi
    
    # Validate setup
    validate_setup
    
    # Show next steps
    show_next_steps
}

# Run main function
main "$@"
