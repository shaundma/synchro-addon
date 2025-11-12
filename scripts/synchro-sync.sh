#!/bin/bash
# Synchro Add-on Sync Script
# Variables will be replaced by sed during installation

SYNC_FOLDER='__SYNC_FOLDER__'
SYNC_DIRECTION='__SYNC_DIRECTION__'
REMOTE_IP='__REMOTE_IP__'
SSH_KEY='/root/.ssh/id_synchro'
LOG_FILE='/var/log/synchro-addon.log'

# Ensure log directory exists
mkdir -p $(dirname $LOG_FILE)

# Log function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

log "Starting sync: Direction=$SYNC_DIRECTION, Remote=$REMOTE_IP"

# Perform sync based on direction
if [ "$SYNC_DIRECTION" = "from" ]; then
  # Sync FROM target TO remote
  rsync -avz --delete -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" "$SYNC_FOLDER/" "root@$REMOTE_IP:$SYNC_FOLDER/" >> $LOG_FILE 2>&1
else
  # Sync TO target FROM remote
  rsync -avz --delete -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" "root@$REMOTE_IP:$SYNC_FOLDER/" "$SYNC_FOLDER/" >> $LOG_FILE 2>&1
fi

SYNC_RESULT=$?

if [ $SYNC_RESULT -eq 0 ]; then
  log "Sync completed successfully"
else
  log "Sync failed with exit code $SYNC_RESULT"
fi

exit $SYNC_RESULT
