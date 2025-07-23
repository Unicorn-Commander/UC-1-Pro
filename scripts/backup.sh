#!/bin/bash

# UC-1 Pro Manual Backup Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}UC-1 Pro Manual Backup${NC}"
echo "========================"

# Check if backup service is running
if docker ps | grep -q unicorn-backup-cron; then
    echo -e "${GREEN}Backup service is running${NC}"
    echo ""
    echo "Options:"
    echo "1. Trigger immediate backup"
    echo "2. View backup logs"
    echo "3. List existing backups"
    echo "4. Exit"
    echo ""
    read -p "Select option (1-4): " option
    
    case $option in
        1)
            echo -e "${YELLOW}Triggering immediate backup...${NC}"
            docker exec unicorn-backup-cron /bin/bash /automated-backup.sh
            ;;
        2)
            echo -e "${YELLOW}Recent backup logs:${NC}"
            docker exec unicorn-backup-cron tail -n 50 /backups/backup.log
            ;;
        3)
            echo -e "${YELLOW}Existing backups:${NC}"
            ls -lah backups/*.tar.gz 2>/dev/null || echo "No backups found"
            ;;
        4)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${YELLOW}Backup service not running. Starting manual backup...${NC}"
    
    # Create backup directory
    mkdir -p backups
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    # Load environment
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
    fi
    
    # Backup PostgreSQL
    echo "Backing up PostgreSQL..."
    docker exec unicorn-postgresql pg_dump -U ${POSTGRES_USER:-unicorn} ${POSTGRES_DB:-unicorn_db} > backups/postgres_${TIMESTAMP}.sql
    gzip backups/postgres_${TIMESTAMP}.sql
    
    # Backup Redis
    echo "Backing up Redis..."
    docker exec unicorn-redis redis-cli --rdb backups/redis_${TIMESTAMP}.rdb
    
    # Backup configuration
    echo "Backing up configuration..."
    cp .env backups/.env.${TIMESTAMP}
    cp docker-compose.yml backups/docker-compose.yml.${TIMESTAMP}
    
    # Create archive
    echo "Creating backup archive..."
    tar -czf backups/uc1pro_manual_backup_${TIMESTAMP}.tar.gz \
        -C backups \
        postgres_${TIMESTAMP}.sql.gz \
        redis_${TIMESTAMP}.rdb \
        .env.${TIMESTAMP} \
        docker-compose.yml.${TIMESTAMP}
    
    # Cleanup temporary files
    rm -f backups/postgres_${TIMESTAMP}.sql.gz \
          backups/redis_${TIMESTAMP}.rdb \
          backups/.env.${TIMESTAMP} \
          backups/docker-compose.yml.${TIMESTAMP}
    
    echo -e "${GREEN}Manual backup completed: backups/uc1pro_manual_backup_${TIMESTAMP}.tar.gz${NC}"
fi
