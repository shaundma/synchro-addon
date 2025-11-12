# Synchro Add-on - Development Notes

## Project Overview

A Jelastic JPS add-on that synchronizes files between nodes using rsync over SSH. Works with Jelastic/Virtuozzo platform's "Import" feature.

**Current Version:** v1.2.6 (WORKING)

**Repository:** https://github.com/shaundma/synchro-addon

**Installation URL:**
```
https://raw.githubusercontent.com/shaundma/synchro-addon/master/manifest.jps
```

## How It Works

1. User imports add-on via "Import" from top menu
2. Form collects:
   - Sync folder path (default: `/var/www/webroot/ROOT`)
   - Sync direction (FROM target TO remote, or vice versa)
   - Sync interval in minutes (1-2880, default: 5)
   - Remote environment (envlist selector)
   - Remote node IP address (text input)

3. Installation process:
   - Installs rsync if not present
   - Generates SSH key pair (`/root/.ssh/id_synchro`)
   - Copies public key to remote node via Jelastic API
   - Downloads and configures sync script from GitHub
   - Installs cron job for automatic syncing
   - Runs initial test sync

4. Automatic syncing runs every X minutes via cron

## Key Technical Learnings

### 1. JPS Type: "update" vs "install"

- Use `"jpsType": "update"` for add-ons
- Works with "Import" from top menu
- Allows user to select target environment and node group
- Access via: `${targetNodes.nodeGroup}`

### 2. Jelastic API - Environment Names

**CRITICAL:** The `envlist` field returns full domain but API needs short name.

```javascript
// envlist returns: "env-6601641.dma-paas.nl"
// GetEnvInfo needs: "env-6601641"

// Solution: Extract before first dot
if (remoteEnv.indexOf('.') > -1) {
  remoteEnv = remoteEnv.split('.')[0];
}
```

### 3. Command Execution Context

**ALWAYS** specify `"user": "root"` for privileged operations:

```json
"cmd [${targetNodes.nodeGroup}]": {
  "commands": ["mkdir -p /root/.ssh"],
  "user": "root"
}
```

Without this: "Permission denied" errors everywhere.

### 4. Bash Syntax in JPS

JPS joins multiple commands with semicolons. Avoid:
- Multi-line if/then/fi statements
- Heredocs
- Complex shell syntax

**Instead, use:**
- Single-line conditionals: `[ condition ] && command || true`
- Template files with sed substitution
- Simple command chaining

### 5. SSH Key Generation - Quiet Mode

**Problem:** ssh-keygen outputs ASCII art that breaks scripts.

**Solution:** Use quiet mode and redirect:
```bash
ssh-keygen -q -t rsa -b 4096 -f /root/.ssh/id_synchro -N '' -C 'synchro-addon' >/dev/null 2>&1 || true
```

Only capture the public key:
```bash
cat /root/.ssh/id_synchro.pub
```

### 6. Remote SSH Key Distribution

**Failed Approaches:**
- sshpass with password (no root password available)
- ssh-copy-id (requires authentication)
- SSH pipe (permission denied)

**Working Solution:** Jelastic API `ExecCmdById`

```javascript
var resp = jelastic.env.control.GetEnvInfo(remoteEnv, session);
var nodes = resp.nodes || [];
var remoteNodeId = null;

// Find node by IP
for (var i = 0; i < nodes.length; i++) {
  if (nodes[i].intIP == remoteIP || nodes[i].address == remoteIP) {
    remoteNodeId = nodes[i].id;
    break;
  }
}

// Execute command directly on remote node as root
var cmd = 'mkdir -p /root/.ssh && chmod 700 /root/.ssh && echo "' + publicKey.trim() + '" >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && sort -u /root/.ssh/authorized_keys -o /root/.ssh/authorized_keys';

return jelastic.env.control.ExecCmdById(
  remoteEnv,
  session,
  remoteNodeId,
  toJSON([{ command: cmd }]),
  true,
  'root'
);
```

### 7. Cron Job Installation

**Working single-line approach:**
```bash
(crontab -l 2>/dev/null | grep -v 'synchro-sync.sh'; echo '*/${settings.syncInterval} * * * * /usr/local/bin/synchro-sync.sh') | crontab - && echo 'Cron job installed: sync every ${settings.syncInterval} minutes'
```

This:
- Gets current crontab
- Removes old synchro entries
- Adds new entry
- Installs atomically

### 8. Dynamic Dropdowns (dependsOn)

**Conclusion:** The `dependsOn` feature does NOT work in Jelastic JPS.

Tried multiple approaches:
- Hardcoded values
- Script-based population
- Different field types

**Result:** Always failed to populate.

**Solution:** Use text input for remote node IP instead of dropdown.

### 9. Browser/Platform Caching

Jelastic aggressively caches JPS files. Solutions:

1. **Version in form title:** `"name": "Synchro Add-on v1.2.6"`
2. **Cache-busting URLs:** Add timestamp parameter
   ```
   https://raw.githubusercontent.com/shaundma/synchro-addon/master/manifest.jps?t=20251112002
   ```

### 10. Template-Based Script Creation

**Best Practice:** Use external template files instead of inline heredocs.

```json
"setupSyncScript": {
  "cmd [${targetNodes.nodeGroup}]": {
    "commands": [
      "curl -fsSL ${baseUrl}scripts/synchro-sync.sh -o /usr/local/bin/synchro-sync.sh",
      "sed -i \"s|__SYNC_FOLDER__|${settings.syncFolder}|g\" /usr/local/bin/synchro-sync.sh",
      "sed -i \"s|__SYNC_DIRECTION__|${settings.syncDirection}|g\" /usr/local/bin/synchro-sync.sh",
      "sed -i \"s|__REMOTE_IP__|${settings.remoteIP}|g\" /usr/local/bin/synchro-sync.sh",
      "chmod +x /usr/local/bin/synchro-sync.sh"
    ],
    "user": "root"
  }
}
```

Benefits:
- Avoids heredoc syntax errors
- Easier to test script independently
- Cleaner code organization

## File Structure

```
synchro-add-on-v2/
├── manifest.jps              # Main JPS manifest (v1.2.6)
├── scripts/
│   └── synchro-sync.sh      # Sync script template
├── images/
│   └── icon.png             # Add-on logo
└── README.md                # This file
```

## Working manifest.jps Structure

```json
{
  "jpsType": "update",
  "jpsVersion": "1.8",
  "id": "synchro-addon",
  "name": "Synchro Add-on v1.2.6",
  "version": "1.2.6",
  "targetNodes": {
    "nodeType": ["storage", "apache", "apache2", "nodejs", ...]
  },
  "settings": {
    "fields": [
      // Form fields
    ]
  },
  "onInstall": [
    "installDependencies",
    "setupSSHKey",
    "copyPublicKeyToRemote",
    "setupSyncScript",
    "setupCronJob",
    "testSync"
  ],
  "actions": {
    // Action definitions
  }
}
```

## Complete Working Code

### manifest.jps (v1.2.6)

Located at: `/srv/www/claude/synchro-add-on-v2/manifest.jps`

Key actions:
1. **installDependencies** - Installs rsync if needed
2. **setupSSHKey** - Generates SSH key pair, captures public key to global variable
3. **copyPublicKeyToRemote** - Uses Jelastic API to install key on remote node
4. **setupSyncScript** - Downloads template, replaces placeholders with sed
5. **setupCronJob** - Installs cron job with specified interval
6. **testSync** - Runs initial sync test

### scripts/synchro-sync.sh

Template with placeholders:
- `__SYNC_FOLDER__` - Replaced with actual folder path
- `__SYNC_DIRECTION__` - Replaced with "from" or "to"
- `__REMOTE_IP__` - Replaced with remote node IP

Script logic:
- Logs to `/var/log/synchro-addon.log`
- Uses rsync with delete flag
- SSH key: `/root/.ssh/id_synchro`
- Bidirectional sync support

## Version History

### v1.2.6 (2025-11-12) - WORKING ✅
- Fixed environment name extraction from domain
- Extract short name (e.g., "env-6601641") from full domain (e.g., "env-6601641.dma-paas.nl")
- All features working: SSH key distribution, cron job, automatic syncing

### v1.2.5 (2025-11-12)
- Implemented Jelastic API for SSH key distribution
- Simplified cron job installation
- Still had domain name issue

### v1.2.4 (2025-11-12)
- Template-based script creation working
- Permission issues resolved with "user": "root"
- SSH key generation working with quiet mode
- Still had SSH key distribution and cron issues

### v1.2.3 and earlier
- Multiple bash syntax errors
- Permission denied errors
- SSH key capture including ASCII art
- Heredoc syntax errors

### v1.1.x
- Form development
- Attempted dependsOn for dynamic dropdowns (failed)
- Switched to text input for remote node IP
- Added version to form title

### v1.0.0
- Initial version based on file-sync example

## Testing Procedures

### After Installation

1. **Verify SSH key exists:**
   ```bash
   ls -la /root/.ssh/id_synchro*
   ```

2. **Check cron job installed:**
   ```bash
   sudo crontab -l
   ```
   Should show: `*/5 * * * * /usr/local/bin/synchro-sync.sh`

3. **Test SSH connectivity:**
   ```bash
   ssh -i /root/.ssh/id_synchro root@REMOTE_IP echo "test"
   ```
   Should connect without password.

4. **Check sync log:**
   ```bash
   sudo tail -f /var/log/synchro-addon.log
   ```
   Should show successful sync entries every X minutes.

5. **Verify sync script exists:**
   ```bash
   ls -la /usr/local/bin/synchro-sync.sh
   cat /usr/local/bin/synchro-sync.sh
   ```

6. **Manual sync test:**
   ```bash
   sudo /usr/local/bin/synchro-sync.sh
   ```

### Test Actual File Sync

1. **Create test file on source:**
   ```bash
   echo "test" > /var/www/webroot/ROOT/test.txt
   ```

2. **Wait for next sync or run manually**

3. **Check remote node:**
   ```bash
   ssh -i /root/.ssh/id_synchro root@REMOTE_IP cat /var/www/webroot/ROOT/test.txt
   ```

## Common Issues and Solutions

### Issue: "Can't find environment by domain"
**Cause:** envlist returns full domain, API needs short name
**Solution:** Extract environment name before first dot (implemented in v1.2.6)

### Issue: Permission denied errors
**Cause:** Commands running as non-root user
**Solution:** Add `"user": "root"` to all cmd actions

### Issue: SSH key includes ASCII art
**Cause:** ssh-keygen outputs fingerprint and ASCII art
**Solution:** Use `-q` flag and redirect output: `>/dev/null 2>&1`

### Issue: Cron job not installed
**Cause:** Multi-line cron setup failing
**Solution:** Use single-line command with pipe to crontab

### Issue: SSH key not copied to remote
**Cause:** No password available for SSH authentication
**Solution:** Use Jelastic API `ExecCmdById` to execute directly on remote node

### Issue: Bash syntax errors
**Cause:** JPS joins commands with semicolons
**Solution:** Avoid multi-line bash constructs, use single-line conditionals

### Issue: Seeing old version after update
**Cause:** Browser/platform caching
**Solution:** Use cache-busting URL with timestamp parameter

## Development Workflow

1. **Edit manifest.jps locally**
   ```bash
   cd /srv/www/claude/synchro-add-on-v2
   # Edit files
   ```

2. **Commit changes**
   ```bash
   git add manifest.jps scripts/synchro-sync.sh
   git commit -m "Description of changes"
   git push origin master
   ```

3. **Test installation**
   - Import in Jelastic using cache-busting URL
   - Monitor installation logs
   - Verify all steps complete successfully

4. **Verify operation**
   - Check cron job: `sudo crontab -l`
   - Check sync log: `sudo tail -f /var/log/synchro-addon.log`
   - Test manual sync: `sudo /usr/local/bin/synchro-sync.sh`

## Important File Locations

**On target node (where add-on is installed):**
- SSH private key: `/root/.ssh/id_synchro`
- SSH public key: `/root/.ssh/id_synchro.pub`
- SSH known_hosts: `/root/.ssh/known_hosts`
- Sync script: `/usr/local/bin/synchro-sync.sh`
- Sync log: `/var/log/synchro-addon.log`
- Cron job: `crontab -l` (under root)

**On remote node:**
- Authorized keys: `/root/.ssh/authorized_keys` (contains target's public key)
- Synced folder: `/var/www/webroot/ROOT` (or configured path)

## Future Enhancements (Optional)

1. **Exclude patterns** - Allow user to specify files/folders to exclude from sync
2. **Bidirectional sync** - Support automatic two-way sync (currently one direction)
3. **Multiple remote nodes** - Sync to multiple nodes simultaneously
4. **Sync status dashboard** - Web UI to view sync status and logs
5. **Email notifications** - Alert on sync failures
6. **Bandwidth limiting** - rsync --bwlimit option
7. **Compression options** - More control over rsync compression

## References

- **Jelastic JPS Documentation:** https://docs.jelastic.com/jps/
- **Working Example:** https://github.com/jelastic-jps/file-sync
- **rsync Manual:** https://linux.die.net/man/1/rsync
- **Our Repository:** https://github.com/shaundma/synchro-addon

## Project Context

**Started:** 2025-11-11
**Working Version Achieved:** 2025-11-12 (v1.2.6)
**Development Directory:** `/srv/www/claude/synchro-add-on-v2/`
**Based On:** Cloned from jelastic-jps/file-sync (lsyncd-based solution)
**Approach:** Simplified rsync + cron approach instead of lsyncd daemon

## Key Decisions

1. **Why rsync instead of lsyncd?**
   - Simpler to configure
   - More predictable behavior
   - Easier debugging
   - Still efficient for periodic syncing

2. **Why text input instead of dynamic dropdown for remote node?**
   - dependsOn feature doesn't work in Jelastic
   - Text input is more flexible
   - User can see/verify IP address
   - Avoids complexity of broken feature

3. **Why template files instead of inline scripts?**
   - Avoids heredoc syntax issues with JPS command joining
   - Easier to test independently
   - Cleaner code organization
   - Better version control

4. **Why Jelastic API for SSH key distribution?**
   - No root password available for traditional methods
   - Direct execution on remote node as root
   - Most reliable approach in Jelastic environment
   - Leverages platform capabilities

## Success Criteria Met ✅

- [x] Form displays correctly with version number
- [x] All fields work (envlist, text inputs, radio, spinner)
- [x] Installation completes without errors
- [x] SSH keys generated successfully
- [x] SSH public key copied to remote node
- [x] Sync script created and configured
- [x] Cron job installed and running
- [x] Files sync automatically
- [x] Sync log shows successful operations
- [x] No manual intervention required after installation
- [x] Works with "Import" from top menu
- [x] Clean uninstallation process

## Quick Start Tomorrow

To continue development:

```bash
cd /srv/www/claude/synchro-add-on-v2
git pull  # Get latest changes if any
# Edit files as needed
git add .
git commit -m "Description"
git push origin master
# Test with cache-busting URL
```

**Current Status:** v1.2.6 is fully working and tested. All automatic features operational.
