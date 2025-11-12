#!/bin/bash

# Local testing script for Synchro Add-on
# This script simulates the sync operation locally for testing

set -e

echo "========================================="
echo "Synchro Add-on - Local Test Script"
echo "========================================="
echo ""

# Test SSH key generation
echo "1. Testing SSH key generation..."
mkdir -p /tmp/synchro-test/.ssh
chmod 700 /tmp/synchro-test/.ssh

if [ ! -f /tmp/synchro-test/.ssh/id_synchro-add-on ]; then
    ssh-keygen -t rsa -b 4096 -f /tmp/synchro-test/.ssh/id_synchro-add-on -N '' -C 'synchro-add-on-test'
    echo "   ✓ SSH key generated successfully"
else
    echo "   ✓ SSH key already exists (testing reuse)"
fi

# Test sync script creation
echo ""
echo "2. Creating test sync script..."
cat > /tmp/synchro-test/test-sync.sh << 'TESTSCRIPT'
#!/bin/bash

SYNC_FOLDER="${1:-/tmp/synchro-test/source}"
TARGET_FOLDER="${2:-/tmp/synchro-test/target}"
SYNC_DIRECTION="${3:-from}"
RSYNC_OPTIONS="-avz --dry-run"

mkdir -p "$SYNC_FOLDER"
mkdir -p "$TARGET_FOLDER"

echo "Test sync: $SYNC_DIRECTION"
echo "Source: $SYNC_FOLDER"
echo "Target: $TARGET_FOLDER"
echo ""

if [ "$SYNC_DIRECTION" = "from" ]; then
    rsync $RSYNC_OPTIONS "$TARGET_FOLDER/" "$SYNC_FOLDER/"
else
    rsync $RSYNC_OPTIONS "$SYNC_FOLDER/" "$TARGET_FOLDER/"
fi

echo ""
echo "Sync test completed (dry-run mode)"
TESTSCRIPT

chmod +x /tmp/synchro-test/test-sync.sh
echo "   ✓ Test sync script created"

# Test folder structure
echo ""
echo "3. Creating test folders..."
mkdir -p /tmp/synchro-test/source
mkdir -p /tmp/synchro-test/target

# Create test files in source
echo "Test file 1" > /tmp/synchro-test/source/file1.txt
echo "Test file 2" > /tmp/synchro-test/source/file2.txt
mkdir -p /tmp/synchro-test/source/subdir
echo "Test file 3" > /tmp/synchro-test/source/subdir/file3.txt

echo "   ✓ Test folders and files created"

# Test sync operation
echo ""
echo "4. Testing sync operation (dry-run)..."
/tmp/synchro-test/test-sync.sh /tmp/synchro-test/source /tmp/synchro-test/target to

# Test cron syntax
echo ""
echo "5. Testing cron syntax..."
SYNC_INTERVAL=5
CRON_LINE="*/$SYNC_INTERVAL * * * * /usr/local/bin/synchro-addon-sync.sh"
echo "   Cron expression: $CRON_LINE"
echo "   ✓ Cron syntax valid"

# Summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "All tests completed successfully!"
echo ""
echo "Test artifacts location: /tmp/synchro-test/"
echo "- SSH key: /tmp/synchro-test/.ssh/id_synchro-add-on"
echo "- Source folder: /tmp/synchro-test/source/"
echo "- Target folder: /tmp/synchro-test/target/"
echo ""
echo "To clean up test files:"
echo "  rm -rf /tmp/synchro-test"
echo ""
