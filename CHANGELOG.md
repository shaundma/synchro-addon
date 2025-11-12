# Changelog

All notable changes to the Synchro Add-on will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-12

### Added
- Initial release of Synchro Add-on
- Bidirectional sync support (FROM/TO)
- Sync by IP address or node name
- Environment and node selection from dropdown
- Configurable sync intervals (1-2880 minutes)
- Automated SSH key generation and management
- SSH key reuse on reinstall
- Dedicated sync script at `/usr/local/bin/synchro-addon-sync.sh`
- Cron-based scheduling
- Detailed logging to `/var/log/synchro-addon.log`
- Clean uninstall with SSH key cleanup from remote nodes
- Customizable rsync options
- Initial sync test after installation

### Security
- Dedicated SSH key for synchro operations (`id_synchro-add-on`)
- Root-only access to SSH keys
- Automatic SSH key distribution to target nodes

## [Unreleased]

### Planned Features
- Multi-node sync (sync to multiple targets)
- Exclude patterns configuration in UI
- Email notifications on sync failures
- Sync statistics dashboard
- Bandwidth throttling options
- Compression level configuration
- Retry logic for failed syncs
