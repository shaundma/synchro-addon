# Synchro Add-on Development Guide

**Current Version:** v1.9.2
**Last Updated:** 2025-11-13

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Key Components](#key-components)
- [Technical Implementation](#technical-implementation)
- [Development Workflow](#development-workflow)
- [Important Lessons Learned](#important-lessons-learned)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Future Improvements](#future-improvements)

## Architecture Overview

Synchro Add-on is a Jelastic JPS (JSON Package Standard) add-on that synchronizes files between nodes using rsync over SSH. The add-on consists of:

1. **manifest.jps** - Main JPS manifest defining UI, installation workflow, and actions
2. **scripts/synchro-sync.sh** - Bash script template that performs the actual sync
3. **images/** - Icon and screenshots

### Core Features

- Bidirectional sync (local→remote or remote→local)
- Two sync modes: one-time or automatic recurring
- Separate folder paths for local and remote
- Configurable remote user (default: root)
- Optional local ownership management
- Auto SSH key generation and distribution
- Support for private (RFC 1918) and public IP addresses
- Environment auto-discovery for private IPs

## Key Components

### 1. manifest.jps

**Form Fields** (in order):
1. `syncFolder` - Folder on local node
2. `localOwner` - Optional user to chown after sync (only for TO local)
3. `remoteSyncFolder` - Folder on remote node
4. `syncDirection` - "from" or "to"
5. `remoteUser` - SSH user on remote (default: root)
6. `remoteIP` - IP address of remote node
7. `syncMode` - "onetime" or "automatic"
8. `syncInterval` - Minutes between syncs (for automatic mode)

**Installation Workflow** (`onInstall`):
1. `installDependencies` - Install rsync
2. `setupSSHKey` - Generate 4096-bit RSA key
3. `getNodeInfo` - Get hostname
4. `checkIPType` - Detect RFC 1918 private IP
5. `copyPublicKeyToRemoteConditional` - Auto-install SSH key for private IPs
6. `setupSyncScript` - Download and configure sync script
7. `setupCronJob` - Install/remove cron job based on mode
8. `testSync` - Run initial sync
9. `showSuccessMessage` - Display configuration

**Key Actions**:
- `configure` - Update settings after installation
- `syncNow` - Manually trigger immediate sync
- `setupCronJob` - Script-based cron installation (runtime evaluation)

### 2. scripts/synchro-sync.sh

Template script with placeholders replaced by `sed`:
- `__SYNC_FOLDER__`
- `__LOCAL_OWNER__`
- `__REMOTE_SYNC_FOLDER__`
- `__SYNC_DIRECTION__`
- `__REMOTE_IP__`
- `__REMOTE_USER__`

**Key Features**:
- Uses `rsync -avz --delete --no-owner --no-group`
- Logs to `/var/log/synchro-addon.log`
- Conditional chown: only if `LOCAL_OWNER` is set AND direction is "to"
- SSH key: `/root/.ssh/id_synchro`

## Technical Implementation

### SSH Key Management

**Generation:**
```bash
ssh-keygen -q -t rsa -b 4096 -f /root/.ssh/id_synchro -N '' -C 'synchro-addon'
```

**Distribution:**
- **Private IPs**: Automatic via `jelastic.env.control.ExecCmdById()`
  - Searches all environments via `GetEnvs()`
  - Finds node by matching `intIP` or `address`
  - Appends public key to `~/.ssh/authorized_keys`

- **Public IPs**: Manual
  - Installation message includes public key
  - User manually adds to remote node

### RFC 1918 Private IP Detection

JavaScript in `checkIPType` action:
```javascript
var first = parseInt(parts[0]);
var second = parseInt(parts[1]);

if (first === 10) isInternal = true;
else if (first === 172 && second >= 16 && second <= 31) isInternal = true;
else if (first === 192 && second === 168) isInternal = true;
```

### Rsync Flags Explained

- `-a` - Archive mode (preserves permissions, times, symlinks, etc.)
- `-v` - Verbose
- `-z` - Compression
- `--delete` - Mirror mode (delete files on destination not in source)
- `--no-owner` - Don't preserve ownership (prevents re-sync after chown)
- `--no-group` - Don't preserve group (prevents re-sync after chown)

### Local Ownership Management

Only runs when:
1. `LOCAL_OWNER` is not empty
2. `SYNC_DIRECTION` is "to" (syncing TO local FROM remote)
3. Sync completed successfully (exit code 0)

```bash
chown -R "$LOCAL_OWNER:$LOCAL_OWNER" "$SYNC_FOLDER"
```

## Development Workflow

### Local Development

```bash
cd /srv/www/claude/synchro-add-on-v2

# Make changes to manifest.jps or scripts/synchro-sync.sh

# Commit and push
git add .
git commit -m "Description of changes"
git push origin master
```

### Testing in Jelastic

Use cache-busting URL to bypass GitHub CDN cache:
```
https://raw.githubusercontent.com/shaundma/synchro-addon/master/manifest.jps?t=TIMESTAMP
```

Example:
```
https://raw.githubusercontent.com/shaundma/synchro-addon/master/manifest.jps?t=20251113192
```

### Version Numbering

Follow semantic versioning:
- **Major** (x.0.0): Breaking changes
- **Minor** (1.x.0): New features, backward compatible
- **Patch** (1.9.x): Bug fixes

Update in 3 places:
1. `manifest.jps` - `name` and `version` fields
2. `README.md` - Current Version
3. `README.md` - Version History section

## Important Lessons Learned

### 1. JPS Conditional "if" is Parse-Time, Not Runtime

**Problem**: Using `if (${settings.syncMode} == 'automatic')` in actions didn't work when called from `configure` action.

**Reason**: JPS conditional `if` statements are evaluated at manifest parse time, not at action execution time.

**Solution**: Use script-based approach with runtime evaluation:
```javascript
var syncMode = '${settings.syncMode}';
if (syncMode == 'automatic') {
  // build command
}
return jelastic.env.control.ExecCmdByGroup(...);
```

### 2. Radio Field Order

**Problem**: Radio button options displayed alphabetically, not in definition order.

**Solution**: Use array format instead of object format:
```javascript
// Wrong (alphabetical):
"values": {
  "onetime": "One-time sync only",
  "automatic": "Automatic recurring sync"
}

// Correct (preserves order):
"values": [
  {"value": "onetime", "caption": "One-time sync only"},
  {"value": "automatic", "caption": "Automatic recurring sync"}
]
```

### 3. Rsync and Ownership

**Problem**: After using `chown` to change local ownership, rsync would re-sync all files on next run because it detected ownership differences.

**Solution**: Add `--no-owner --no-group` flags to rsync commands.

### 4. Conditional Field Visibility Not Supported

**Attempted**: Hide/show interval field based on sync mode selection.

**Result**: Jelastic JPS doesn't support `showIf`, `hideFor`, or any conditional field visibility.

**Workaround**: Use clear field labels and placeholders instead.

### 5. Environment Discovery

For private IPs, environment is auto-discovered:
1. Get all environments via `jelastic.env.control.GetEnvs()`
2. Extract short name from domain (e.g., "env-123" from "env-123.domain.com")
3. Loop through and call `GetEnvInfo()` for each
4. Check if any node's `intIP` or `address` matches the provided IP
5. Use `ExecCmdById()` to install SSH key on matched node

## Testing

### Manual Testing Checklist

**Installation:**
- [ ] Install with one-time mode
- [ ] Install with automatic mode
- [ ] Install with private IP (auto SSH key)
- [ ] Install with public IP (manual SSH key)
- [ ] Install with local owner specified
- [ ] Install without local owner

**Configure Button:**
- [ ] Change sync direction
- [ ] Change folders
- [ ] Change remote user
- [ ] Change remote IP
- [ ] Switch from one-time to automatic (verify cron installed)
- [ ] Switch from automatic to one-time (verify cron removed)
- [ ] Change interval (verify cron updated)

**Sync Now Button:**
- [ ] Manual sync with one-time mode
- [ ] Manual sync with automatic mode
- [ ] Verify log entries in `/var/log/synchro-addon.log`

**Verification Commands:**
```bash
# Check SSH key exists
ls -la /root/.ssh/id_synchro*

# Check cron job
crontab -l | grep synchro

# Check sync script
cat /usr/local/bin/synchro-sync.sh

# Check logs
tail -f /var/log/synchro-addon.log

# Test SSH connectivity
ssh -i /root/.ssh/id_synchro REMOTE_USER@REMOTE_IP echo "test"

# Manual sync test
/usr/local/bin/synchro-sync.sh

# Check ownership (if using local owner)
ls -la /path/to/sync/folder
```

## Troubleshooting

### SSH Connection Failed

Check known_hosts and connectivity:
```bash
ssh-keyscan -H REMOTE_IP >> /root/.ssh/known_hosts
ssh -i /root/.ssh/id_synchro -v REMOTE_USER@REMOTE_IP
```

### Cron Job Not Running

Check cron syntax:
```bash
crontab -l
# Should show: */INTERVAL * * * * /usr/local/bin/synchro-sync.sh
```

Check cron logs:
```bash
grep CRON /var/log/syslog  # or /var/log/cron
```

### Files Re-syncing After Chown

Verify `--no-owner --no-group` flags in script:
```bash
grep "no-owner" /usr/local/bin/synchro-sync.sh
```

### Ownership Not Changing

Check sync direction is "to":
```bash
grep SYNC_DIRECTION /usr/local/bin/synchro-sync.sh
```

Check local owner is set:
```bash
grep LOCAL_OWNER /usr/local/bin/synchro-sync.sh
```

### Environment Not Found (Private IP)

User may not have access to remote environment. Fallback to public IP approach:
1. Get public key: `cat /root/.ssh/id_synchro.pub`
2. Manually add to remote: `~/.ssh/authorized_keys`

## Future Improvements

### Potential Features
- [ ] Pre/post sync hooks (run custom commands)
- [ ] Exclude patterns (like .gitignore)
- [ ] Compression level configuration
- [ ] Bandwidth limiting
- [ ] Sync statistics dashboard
- [ ] Multiple remote targets
- [ ] Conflict resolution strategies
- [ ] Dry-run mode
- [ ] Email notifications on sync failure
- [ ] Webhook integration

### Code Improvements
- [ ] Input validation for IP addresses
- [ ] Better error messages
- [ ] Rollback on failed installation
- [ ] Health check endpoint
- [ ] Metrics collection

### Documentation
- [ ] Video tutorial
- [ ] Use case examples with screenshots
- [ ] API documentation for advanced users
- [ ] Troubleshooting flowcharts

## Code Patterns

### Sed Substitution Pattern
```bash
sed -i "s|__PLACEHOLDER__|${settings.value}|g" /path/to/file
```

### Cron Job Atomic Installation
```bash
(crontab -l 2>/dev/null | grep -v 'script.sh'; echo 'NEW_CRON_LINE') | crontab -
```

### SSH with Key and No Host Checking
```bash
ssh -i /root/.ssh/id_synchro -o StrictHostKeyChecking=no user@host "command"
```

### Jelastic API Call from Script
```javascript
return jelastic.env.control.ExecCmdByGroup(
  '${env.envName}',
  session,
  nodeGroup,
  toJSON([{ command: cmd }]),
  true,
  false,
  'root'
);
```

## Repository Structure

```
synchro-add-on-v2/
├── manifest.jps           # Main JPS manifest
├── README.md             # User-facing documentation
├── DEVELOPMENT.md        # This file
├── LICENSE.md            # License information
├── scripts/
│   └── synchro-sync.sh  # Sync script template
└── images/
    ├── icon.png         # Add-on icon
    ├── screenshot-01.png
    └── screenshot-02.png
```

## Support Resources

- **GitHub Issues**: https://github.com/shaundma/synchro-addon/issues
- **Jelastic Docs**: https://docs.jelastic.com/jps/
- **Rsync Manual**: https://linux.die.net/man/1/rsync
- **Jelastic API**: https://docs.jelastic.com/api/

## Changelog Summary

- **v1.9.2**: Added --no-owner --no-group to rsync
- **v1.9.1**: Fixed cron job installation via Configure button
- **v1.9.0**: Added Local owner field with automatic chown
- **v1.8.x**: Added Remote User field and form improvements
- **v1.7.x**: Added Sync Now button and form field ordering
- **v1.6.x**: Added sync mode options and improved UI
- **v1.5.x**: Added external IP support
- **v1.4.0**: Added Configure button
- **v1.3.x**: Auto-discovery from IP, separate folder paths
- **v1.2.6**: Initial stable release

---

**Maintained by**: Shaun (shaundma)
**Repository**: https://github.com/shaundma/synchro-addon
