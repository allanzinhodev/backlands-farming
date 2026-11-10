#!/bin/bash
# Anti-Rollback Server Launcher
# Runs the server under GDB for crash recovery, auto-restarts, and creates database backups.
# Usage: chmod +x start.sh && ./start.sh

# ============================================================
# Configuration — adjust these to match your environment
# ============================================================
SERVER_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_BIN="./tfs"
SERVER_NAME="860"
MYSQL_USER="root"
MYSQL_PASS=""
MYSQL_HOST="127.0.0.1"
LOG_DIR="${SERVER_DIR}/logs"
BACKUP_DIR="${SERVER_DIR}/database"
COOLDOWN=3

# ============================================================
# Setup
# ============================================================
cd "$SERVER_DIR" || exit 1
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

if [ ! -f "$SERVER_BIN" ]; then
    echo "[Error] Server binary not found: $SERVER_BIN"
    exit 1
fi

if [ ! -f "gdb_config" ]; then
    echo "[Error] gdb_config not found in $SERVER_DIR"
    exit 1
fi

# ============================================================
# Main Loop
# ============================================================
echo "============================================"
echo " Anti-Rollback Server Launcher"
echo " Server: $SERVER_NAME"
echo " Logs:   $LOG_DIR"
echo " Backup: $BACKUP_DIR"
echo "============================================"

while true; do
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    LOG_FILE="${LOG_DIR}/${TIMESTAMP}.log"

    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting server..."
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Log: $LOG_FILE"

    # Run under GDB with anti-rollback crash handler
    gdb --batch -return-child-result --command=gdb_config --args "$SERVER_BIN" \
        2>&1 | awk '{ print strftime("%F %T - "), $0; fflush(); }' \
        | tee "$LOG_FILE"

    # The pipeline ends in tee, so $? would report tee's status instead of GDB's.
    # PIPESTATUS[0] is the real server/GDB exit code used for restart decisions.
    EXIT_CODE=${PIPESTATUS[0]}

    if [ $EXIT_CODE -eq 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Server shut down cleanly (exit 0). Not restarting."
        break
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Server exited with code $EXIT_CODE — creating database backup..."

    # Database backup after crash
    BACKUP_FILE="${BACKUP_DIR}/${SERVER_NAME}_${TIMESTAMP}.sql.gz"
    if [ -n "$MYSQL_PASS" ]; then
        mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASS" -h"$MYSQL_HOST" \
            --add-drop-table --add-locks --allow-keywords \
            --extended-insert --quick --compress "$SERVER_NAME" \
            2>/dev/null | gzip > "$BACKUP_FILE"
    else
        mysqldump -u"$MYSQL_USER" -h"$MYSQL_HOST" \
            --add-drop-table --add-locks --allow-keywords \
            --extended-insert --quick --compress "$SERVER_NAME" \
            2>/dev/null | gzip > "$BACKUP_FILE"
    fi

    if [ -s "$BACKUP_FILE" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup saved: $BACKUP_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Warning] Backup may have failed (empty file)."
        rm -f "$BACKUP_FILE"
    fi

    # Cleanup: keep only last 30 backups
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.sql.gz 2>/dev/null | wc -l)
    if [ "$BACKUP_COUNT" -gt 30 ]; then
        ls -1t "$BACKUP_DIR"/*.sql.gz | tail -n +31 | xargs rm -f
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Old backups cleaned (keeping last 30)."
    fi

    # Cleanup: keep only last 50 logs
    LOG_COUNT=$(ls -1 "$LOG_DIR"/*.log 2>/dev/null | wc -l)
    if [ "$LOG_COUNT" -gt 50 ]; then
        ls -1t "$LOG_DIR"/*.log | tail -n +51 | xargs rm -f
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restarting in ${COOLDOWN}s..."
    sleep "$COOLDOWN"
done
