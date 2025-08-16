# MongoDB Infrastructure with Ansible

A modular Ansible-based solution for managing MongoDB deployments with Docker, featuring comprehensive backup, restore, and maintenance capabilities.

## 🏗️ Architecture

This project provides a complete MongoDB infrastructure-as-code solution with:

- **MongoDB**: Robust database with automated backup/restore
- **Modular Design**: Reusable roles and playbooks
- **Multi-Environment**: Support for production, staging, and custom environments
- **Docker-Based**: All services run in Docker containers
- **Operations Focus**: Deploy, backup, restore, and maintenance operations

## 📁 Project Structure

```
DevOps/
├── ansible.cfg                 # Ansible configuration
├── inventories/                # Environment-specific inventories
│   ├── production/
│   │   └── hosts.yml
│   └── staging/
│       └── hosts.yml
├── group_vars/                 # Group variables
│   ├── all.yml                # Global variables
│   ├── mongo_nodes.yml        # MongoDB configuration
│   └── vault.yml              # Encrypted secrets
├── roles/                     # Ansible roles
│   └── mongodb/               # MongoDB database role
│       ├── meta/
│       ├── defaults/
│       ├── tasks/
│       ├── handlers/
│       └── templates/
├── playbooks/                 # Ansible playbooks
│   ├── site.yml               # Main deployment playbook
│   ├── mongodb-deploy.yml     # MongoDB deployment
│   ├── mongodb-backup.yml     # MongoDB backup
│   ├── mongodb-restore.yml    # MongoDB restore
│   └── status.yml             # System status check
├── docker-compose/            # MongoDB Docker Compose examples
│   ├── mongodb-standalone.yml # Single instance with monitoring
│   ├── mongodb-cluster.yml    # Replica set cluster
│   └── mongodb-with-app.yml   # MongoDB with sample application
└── scripts/                   # Utility scripts
    ├── setup.sh               # Initial setup
    ├── deploy.sh              # Deployment and operations script
    ├── backup.sh              # Backup script
    ├── restore.sh             # Restore script
    └── status.sh              # Status check script
```

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Run the setup script
./scripts/setup.sh --all

# Or step by step:
./scripts/setup.sh --install-ansible
./scripts/setup.sh --generate-ssh-key
./scripts/setup.sh --encrypt-vault
```

### 2. Configure Your Environment

Edit inventory files with your server details:

```bash
# Production environment
vim inventories/production/hosts.yml

# Staging environment
vim inventories/staging/hosts.yml
```

Update vault with your secrets:

```bash
ansible-vault edit group_vars/vault.yml
```

### 3. Deploy MongoDB

```bash
# Deploy MongoDB to production
./scripts/deploy.sh

# Deploy to staging
./scripts/deploy.sh -e staging

# Dry run deployment
./scripts/deploy.sh -c
```

### 4. MongoDB Operations

```bash
# Backup MongoDB
./scripts/deploy.sh -o backup
./scripts/backup.sh

# Restore MongoDB
./scripts/deploy.sh -o restore
./scripts/restore.sh -f /path/to/backup.archive

# Maintenance and status
./scripts/deploy.sh -o maintenance
./scripts/status.sh
```

## 🔧 Available Operations

### MongoDB Deployment

```bash
# Deploy MongoDB infrastructure
ansible-playbook -i inventories/production/hosts.yml playbooks/site.yml
ansible-playbook -i inventories/production/hosts.yml playbooks/mongodb-deploy.yml
```

**Features:**
- Authentication enabled by default
- Configurable storage engine and cache
- Health checks and monitoring
- Support for replica sets
- Automatic user creation (root and application users)
- Persistent data volumes

### MongoDB Backup

```bash
# Create backup
./scripts/backup.sh
./scripts/deploy.sh -o backup
ansible-playbook -i inventories/production/hosts.yml playbooks/mongodb-backup.yml
```

**Features:**
- Automated backups with retention policies
- Compression support
- Timestamped backup files
- Configurable retention periods
- Safe backup operations (no downtime)

### MongoDB Restore

```bash
# Restore from backup
./scripts/restore.sh -f /path/to/backup.archive
./scripts/restore.sh -f backup.archive -d specific_database
ansible-playbook -i inventories/production/hosts.yml playbooks/mongodb-restore.yml
```

**Features:**
- Point-in-time restore capabilities
- Database-specific restore options
- Safety confirmations
- Drop existing data option
- Restore validation

### Maintenance and Monitoring

```bash
# Check status and perform maintenance
./scripts/status.sh
./scripts/deploy.sh -o maintenance
```

**Features:**
- Container health checks
- Database size reporting
- Disk usage monitoring
- Connection testing
- Performance metrics
- Available backup listing

## 📋 Configuration

### MongoDB Configuration

Key configuration options in `group_vars/mongo_nodes.yml`:

```yaml
mongodb:
  version: "7.0"
  auth:
    enabled: true
    root_username: "root"
    root_password: "{{ vault_mongo_root_password }}"
  app_db:
    name: "appdb"
    username: "appuser"
    password: "{{ vault_mongo_app_password }}"
  backup:
    enabled: true
    schedule: "0 2 * * *"  # Daily at 2 AM
    retention_days: 7
    compression: true
  config:
    storage_engine: "wiredTiger"
    cache_size_gb: 1
    log_level: "1"
```

### Inventory Configuration

Update `inventories/production/hosts.yml`:

```yaml
all:
  children:
    docker_hosts:
      hosts:
        mongo-node-1:
          ansible_host: 10.0.1.10
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
        mongo-node-2:
          ansible_host: 10.0.1.11
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
    
    mongo_nodes:
      hosts:
        mongo-node-1:
        mongo-node-2:
      vars:
        mongo_data_dir: /opt/mongodb/data
        mongo_backup_dir: /opt/mongodb/backups
        mongo_config_dir: /opt/mongodb/config
```

## 🛡️ Security

### Vault Management

```bash
# Encrypt vault file
ansible-vault encrypt group_vars/vault.yml

# Edit encrypted vault
ansible-vault edit group_vars/vault.yml

# View encrypted vault
ansible-vault view group_vars/vault.yml

# Change vault password
ansible-vault rekey group_vars/vault.yml
```

### MongoDB Security

- Authentication enabled by default
- Separate root and application users
- Encrypted connections support
- Configurable access controls
- Secure file permissions

## 🔍 Monitoring and Maintenance

### System Status

```bash
# Check all services
./scripts/status.sh

# Detailed status with verbose output
./scripts/status.sh -v

# Check specific environment
./scripts/status.sh -e staging
```

### MongoDB Maintenance

```bash
# Run comprehensive maintenance
./scripts/deploy.sh -o maintenance

# Manual maintenance tasks
ansible-playbook -i inventories/production/hosts.yml roles/mongodb/tasks/maintenance.yml
```

### Logs and Debugging

```bash
# View MongoDB logs
docker logs mongodb

# Follow logs in real-time
docker logs -f mongodb

# MongoDB shell access
docker exec -it mongodb mongosh

# With authentication
docker exec -it mongodb mongosh -u root -p
```

## 📚 Examples and Use Cases

### Single MongoDB Instance

Use `docker-compose/mongodb-standalone.yml` for:
- Development environments
- Small applications
- Testing and prototyping

### MongoDB Replica Set

Use `docker-compose/mongodb-cluster.yml` for:
- Production environments
- High availability requirements
- Load distribution

### Application Integration

Use `docker-compose/mongodb-with-app.yml` for:
- Full-stack applications
- Microservices architecture
- Complete development environments

### MongoDB Connection Examples

```bash
# Connection string for applications
mongodb://appuser:password@mongo-node-1:27017/appdb

# Connection with replica set
mongodb://appuser:password@mongo-node-1:27017,mongo-node-2:27017/appdb?replicaSet=rs0

# Admin connection
mongodb://root:password@mongo-node-1:27017/admin
```

## 🚨 Troubleshooting

### Common Issues

1. **Ansible Connection Issues**
   ```bash
   # Test connectivity
   ansible all -i inventories/production/hosts.yml -m ping
   ```

2. **Docker Permission Issues**
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER
   # Logout and login again
   ```

3. **MongoDB Authentication Issues**
   ```bash
   # Check MongoDB status
   docker exec mongodb mongosh --eval "db.adminCommand('ping')"
   
   # Reset admin user (if needed)
   docker exec mongodb mongosh --eval "db.createUser({user:'root',pwd:'newpass',roles:['root']})"
   ```

4. **Backup/Restore Issues**
   ```bash
   # Check backup directory permissions
   ls -la /opt/mongodb/backups/
   
   # Verify backup file
   file /path/to/backup.archive
   ```

### Debug Mode

Run playbooks with debug information:

```bash
# Verbose output
./scripts/deploy.sh -v

# Maximum verbosity
ansible-playbook -i inventories/production/hosts.yml playbooks/site.yml -vvv
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly with different MongoDB versions
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:

1. Check the troubleshooting section
2. Review MongoDB and Docker logs
3. Test with the provided examples
4. Open an issue with detailed information

## 🔄 Updates and Maintenance

### Regular Tasks

```bash
# Update MongoDB to latest version
# Edit group_vars/mongo_nodes.yml and change version
./scripts/deploy.sh

# Backup before major updates
./scripts/backup.sh

# Test restore procedures
./scripts/restore.sh -f latest_backup.archive
```

### Monitoring Recommendations

- Set up automated backups via cron
- Monitor disk space on backup directories
- Regular connectivity tests
- Performance monitoring with MongoDB tools
- Log rotation for container logs

This MongoDB-focused infrastructure provides a solid foundation for database operations that can scale with your needs while maintaining security and operational best practices!
