#!/bin/bash

# UC-1 Pro Automated Backup Script
# This script is run by the backup-cron container

set -e

# Configuration
BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${BACKUP_DIR}/backup.log"

# Ensure backup directory exists
mkdir -p "${BACKUP_DIR}/postgres" "${BACKUP_DIR}/redis" "${BACKUP_DIR}/qdrant"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to cleanup old backups
cleanup_old_backups() {
    local dir=$1
    local pattern=$2
    local retention_days=${BACKUP_RETENTION_DAYS:-7}
    
    log "Cleaning up backups older than ${retention_days} days in ${dir}"
    find "${dir}" -name "${pattern}" -type f -mtime +${retention_days} -delete 2>/dev/null || true
}

# Start backup process
log "=== Starting UC-1 Pro backup ==="

# Backup PostgreSQL
log "Backing up PostgreSQL database..."
PGPASSWORD=${POSTGRES_PASSWORD} pg_dump \
    -h postgresql \
    -U ${POSTGRES_USER} \
    -d ${POSTGRES_DB} \
    -f "${BACKUP_DIR}/postgres/postgres_${TIMESTAMP}.sql" \
    --verbose 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    log "PostgreSQL backup completed successfully"
    # Compress the backup
    gzip "${BACKUP_DIR}/postgres/postgres_${TIMESTAMP}.sql"
    log "PostgreSQL backup compressed"
else
    log "ERROR: PostgreSQL backup failed"
fi

# Backup Redis
log "Backing up Redis..."
redis-cli -h redis --rdb "${BACKUP_DIR}/redis/redis_${TIMESTAMP}.rdb" 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    log "Redis backup completed successfully"
else
    log "ERROR: Redis backup failed"
fi

# Backup Qdrant (via HTTP API)
log "Backing up Qdrant snapshots..."
# Create Qdrant snapshot
SNAPSHOT_NAME="backup_${TIMESTAMP}"
curl -X POST "http://qdrant:6333/snapshots" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"${SNAPSHOT_NAME}\"}" 2>&1 | tee -a "$LOG_FILE"

# Download the snapshot
sleep 5  # Give Qdrant time to create the snapshot
curl -o "${BACKUP_DIR}/qdrant/qdrant_${TIMESTAMP}.snapshot" \
    "http://qdrant:6333/snapshots/${SNAPSHOT_NAME}" 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    log "Qdrant backup completed successfully"
    # Delete the snapshot from Qdrant to save space
    curl -X DELETE "http://qdrant:6333/snapshots/${SNAPSHOT_NAME}" 2>&1 | tee -a "$LOG_FILE"
else
    log "ERROR: Qdrant backup failed"
fi

# Create a consolidated archive
log "Creating consolidated backup archive..."
cd "${BACKUP_DIR}"
tar -czf "uc1pro_backup_${TIMESTAMP}.tar.gz" \
    "postgres/postgres_${TIMESTAMP}.sql.gz" \
    "redis/redis_${TIMESTAMP}.rdb" \
    "qdrant/qdrant_${TIMESTAMP}.snapshot" 2>/dev/null || true

# Cleanup old backups
cleanup_old_backups "${BACKUP_DIR}/postgres" "postgres_*.sql.gz"
cleanup_old_backups "${BACKUP_DIR}/redis" "redis_*.rdb"
cleanup_old_backups "${BACKUP_DIR}/qdrant" "qdrant_*.snapshot"
cleanup_old_backups "${BACKUP_DIR}" "uc1pro_backup_*.tar.gz"

# Report backup sizes
log "Backup sizes:"
du -sh "${BACKUP_DIR}"/* 2>/dev/null | grep -E "(postgres|redis|qdrant|uc1pro_backup)" | tee -a "$LOG_FILE"

# Check available disk space
log "Available disk space:"
df -h "${BACKUP_DIR}" | tail -1 | tee -a "$LOG_FILE"

log "=== Backup completed successfully ==="