#!/bin/bash

# PostgreSQL Configuration
PG_USER="pguser"
PG_PASSWORD="pgpass"
PG_DATABASE="dbname"
PG_HOST="localhost"
PG_PORT="5432"

# S3 Configuration
BUCKET_NAME="bucketname"
S3_ENDPOINT="https://s3.storage.endpoint.com"
LOCAL_BACKUP_DIR="/tmp/pg-backups"
S3_BACKUP_DIR="backups"
DATE=$(date +"%Y%m%d%H%M")
BACKUP_FILE="$LOCAL_BACKUP_DIR/${PG_DATABASE}_backup_$DATE.sql.gz"

# Optional Features
DELETE_LOCAL_BACKUP="true"
SEND_HEARTBEAT="false"
HEARTBEAT_URL="https://heartbeat.uptimerobot.com/m794yyyyyyyy-xxxxxxxxxxxxxxx"
BACKUP_RETENTION_DAYS=30
ENABLE_LOGGING="true"
LOG_FILE="/var/log/pg-backups.log"

# Logging function
tlog() {
    local msg="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [ "$ENABLE_LOGGING" == "true" ]; then
        echo "$timestamp - $msg" | tee -a "$LOG_FILE"
    else
        echo "$timestamp - $msg"
    fi
}

# Start backup process
tlog "Starting PostgreSQL backup for database '$PG_DATABASE'"

# Ensure local backup directory exists
mkdir -p "$LOCAL_BACKUP_DIR"
tlog "Ensured local backup directory exists: $LOCAL_BACKUP_DIR"

# Export password for non‑interactive authentication
export PGPASSWORD="$PG_PASSWORD"

# Run pg_dump and compress
tlog "Running pg_dump..."
pg_dump -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -F plain "$PG_DATABASE" | gzip > "$BACKUP_FILE"
if [ $? -ne 0 ]; then
    tlog "ERROR: PostgreSQL backup failed"
    exit 1
else
    tlog "PostgreSQL backup created: $BACKUP_FILE"
fi

# Unset the password variable for safety
unset PGPASSWORD

# Upload to S3-compatible storage
tlog "Uploading backup to S3: s3://$BUCKET_NAME/$S3_BACKUP_DIR/$(basename "$BACKUP_FILE")"
aws s3api put-object \
    --bucket "$BUCKET_NAME" \
    --key "$S3_BACKUP_DIR/$(basename "$BACKUP_FILE")" \
    --body "$BACKUP_FILE" \
    --endpoint-url "$S3_ENDPOINT" \
    --checksum-algorithm CRC32
if [ $? -ne 0 ]; then
    tlog "ERROR: Upload to S3 failed"
    exit 1
else
    tlog "Upload to S3 successful"

    # Optionally delete local backup
    if [ "$DELETE_LOCAL_BACKUP" == "true" ]; then
        rm -f "$BACKUP_FILE"
        tlog "Local backup deleted: $BACKUP_FILE"
    fi

    # Optionally send heartbeat
    if [ "$SEND_HEARTBEAT" == "true" ]; then
        tlog "Sending heartbeat to $HEARTBEAT_URL"
        curl -s -o /dev/null -w "%{http_code}" "$HEARTBEAT_URL" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            tlog "WARNING: Failed to send heartbeat"
        else
            tlog "Heartbeat sent successfully"
        fi
    fi
fi

# Clean up old backups
tlog "Cleaning up backups older than $BACKUP_RETENTION_DAYS days in $LOCAL_BACKUP_DIR"
if [ "$BACKUP_RETENTION_DAYS" -gt 0 ]; then
    find "$LOCAL_BACKUP_DIR" -type f -name "${PG_DATABASE}_backup_*.sql.gz" -mtime +"$BACKUP_RETENTION_DAYS" -exec rm -f {} \;
    tlog "Old backups older than $BACKUP_RETENTION_DAYS days deleted successfully"
else
    tlog "Backup deletion disabled (BACKUP_RETENTION_DAYS is set to 0)"
fi

tlog "PostgreSQL backup process completed"
