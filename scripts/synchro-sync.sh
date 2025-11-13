#!/bin/bash
# Synchro Add-on Sync Script
# Variables will be replaced by sed during installation

SYNC_FOLDER='__SYNC_FOLDER__'
LOCAL_OWNER='__LOCAL_OWNER__'
REMOTE_SYNC_FOLDER='__REMOTE_SYNC_FOLDER__'
SYNC_DIRECTION='__SYNC_DIRECTION__'
REMOTE_IP='__REMOTE_IP__'
REMOTE_USER='__REMOTE_USER__'
SSH_KEY='/root/.ssh/id_synchro'
LOG_FILE='/var/log/synchro-addon.log'

# Ensure log directory exists
mkdir -p $(dirname $LOG_FILE)

# Log function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

log "Starting sync: Direction=$SYNC_DIRECTION, Local=$SYNC_FOLDER, Remote=$REMOTE_IP:$REMOTE_SYNC_FOLDER"

# Perform sync based on direction
if [ "$SYNC_DIRECTION" = "from" ]; then
  # Sync FROM local TO remote
  rsync -avz --delete -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" "$SYNC_FOLDER/" "$REMOTE_USER@$REMOTE_IP:$REMOTE_SYNC_FOLDER/" >> $LOG_FILE 2>&1
else
  # Sync TO local FROM remote
  rsync -avz --delete -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" "$REMOTE_USER@$REMOTE_IP:$REMOTE_SYNC_FOLDER/" "$SYNC_FOLDER/" >> $LOG_FILE 2>&1
fi

SYNC_RESULT=$?

if [ $SYNC_RESULT -eq 0 ]; then
  log "Sync completed successfully"

  # Change ownership if LOCAL_OWNER is set and we synced TO local
  if [ -n "$LOCAL_OWNER" ] && [ "$SYNC_DIRECTION" = "to" ]; then
    log "Changing ownership of $SYNC_FOLDER to $LOCAL_OWNER"
    chown -R "$LOCAL_OWNER:$LOCAL_OWNER" "$SYNC_FOLDER" >> $LOG_FILE 2>&1
    CHOWN_RESULT=$?
    if [ $CHOWN_RESULT -eq 0 ]; then
      log "Ownership changed successfully"
    else
      log "Failed to change ownership (exit code $CHOWN_RESULT)"
    fi
  fi
else
  log "Sync failed with exit code $SYNC_RESULT"
fi

exit $SYNC_RESULT
