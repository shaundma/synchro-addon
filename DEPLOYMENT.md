# Deployment Guide

This guide explains how to deploy and distribute the Synchro Add-on for Virtuozzo/Jelastic.

## Prerequisites

- GitHub account (or other Git hosting)
- Access to Jelastic dashboard
- Understanding of JPS (Jelastic Packaging Standard)

## Deployment Steps

### 1. Prepare the Repository

Upload all files to a public repository:

```bash
git init
git add .
git commit -m "Initial commit: Synchro Add-on v1.0.0"
git remote add origin https://github.com/shaundma/synchro-addon.git
git push -u origin master
```

### 2. Update manifest.jps URLs

Edit `manifest.jps` and update the following:

```json
"baseUrl": "https://raw.githubusercontent.com/shaundma/synchro-addon/master",
"homepage": "https://github.com/shaundma/synchro-addon",
"logo": "https://raw.githubusercontent.com/shaundma/synchro-addon/master/images/icon.png"
```

### 3. Add an Icon (Optional)

Create an `images/` directory and add an icon:

```bash
mkdir images
# Add your icon.png (64x64 or 128x128 recommended)
```

### 4. Test Installation

#### Method A: Direct URL Installation

Use the raw GitHub URL:

```
https://raw.githubusercontent.com/shaundma/synchro-addon/master/manifest.jps
```

In Jelastic Dashboard:
1. Go to your environment
2. Click on any node
3. Click **Add-ons**
4. Click **Import**
5. Paste the URL above
6. Click **Install**

#### Method B: Jelastic CLI

```bash
~/jelastic/environment/control/installpackagebyurl \
  --envName myenv \
  --url https://raw.githubusercontent.com/shaundma/synchro-addon/master/manifest.jps \
  --nodeGroup cp
```

### 5. Submit to Jelastic Marketplace (Optional)

To make your add-on available in the Jelastic Marketplace:

1. **Fork the marketplace repository:**
   ```bash
   git clone https://github.com/jelastic-jps/marketplace.git
   ```

2. **Create your add-on directory:**
   ```bash
   cd marketplace/addons
   mkdir synchro-addon
   ```

3. **Copy your manifest:**
   ```bash
   cp /path/to/your/manifest.jps marketplace/addons/synchro-addon/
   ```

4. **Create a metadata file:**

   Create `marketplace/addons/synchro-addon/metadata.yaml`:

   ```yaml
   type: update
   categories:
     - apps/dev-tools
   description: Synchronize files and folders between nodes using rsync
   name: Synchro Add-on
   homepage: https://github.com/shaundma/synchro-addon
   logo: https://raw.githubusercontent.com/shaundma/synchro-addon/master/images/icon.png
   ```

5. **Submit a pull request:**
   - Create a new branch
   - Commit your changes
   - Push to your fork
   - Open a pull request to the main marketplace repository

6. **Wait for review:**
   - Jelastic team will review your submission
   - Address any feedback
   - Once approved, it will appear in the marketplace

## Version Management

### Creating a New Release

1. **Update version in manifest.jps:**
   ```json
   "version": "1.1.0"
   ```

2. **Update CHANGELOG.md:**
   ```markdown
   ## [1.1.0] - 2025-12-01
   ### Added
   - New feature X
   ### Fixed
   - Bug Y
   ```

3. **Commit and tag:**
   ```bash
   git add .
   git commit -m "Release v1.1.0"
   git tag v1.1.0
   git push origin master --tags
   ```

4. **Create GitHub release:**
   - Go to GitHub releases
   - Click "Create a new release"
   - Select tag v1.1.0
   - Add release notes from CHANGELOG.md
   - Publish

## Using Branches for Development

### Development workflow:

```bash
# Create development branch
git checkout -b develop

# Update baseUrl in manifest.jps to point to develop branch
"baseUrl": "https://raw.githubusercontent.com/shaundma/synchro-addon/develop"

# Make changes and test
git add .
git commit -m "Feature: Added X"
git push origin develop

# Test with develop branch URL
https://raw.githubusercontent.com/shaundma/synchro-addon/develop/manifest.jps

# When ready, merge to master
git checkout master
git merge develop
git push origin master
```

## CDN Considerations

For better performance, consider using a CDN:

### jsDelivr

Change baseUrl to:
```json
"baseUrl": "https://cdn.jsdelivr.net/gh/shaundma/synchro-addon@master"
```

Benefits:
- Faster downloads
- Automatic caching
- Better global availability

## Testing Before Release

### Local Testing

1. **Run test script:**
   ```bash
   ./test-local.sh
   ```

2. **Validate JPS syntax:**
   - Use online JPS validators
   - Check JSON syntax with `jq`
   ```bash
   jq empty manifest.jps && echo "Valid JSON" || echo "Invalid JSON"
   ```

### Installation Testing

1. **Test on development environment:**
   - Install on a test environment
   - Verify all features work
   - Check logs for errors
   - Test uninstall process

2. **Test different scenarios:**
   - Different node types (Apache, Nginx, Docker, etc.)
   - Different sync directions
   - Different intervals
   - Large file transfers
   - Network interruptions

## Troubleshooting Deployment

### Common Issues

**1. Raw content not loading**
- Ensure repository is public
- Use raw.githubusercontent.com URLs
- Check URL is correct

**2. Logo not displaying**
- Verify image URL is accessible
- Use PNG or SVG format
- Recommended size: 64x64 or 128x128

**3. Installation fails**
- Check JPS syntax
- Verify all scripts are valid
- Test SSH connectivity between nodes
- Check Jelastic API permissions

## Security Checklist

Before deploying:

- [ ] No hardcoded passwords
- [ ] No sensitive data in repository
- [ ] SSH keys generated securely
- [ ] Proper file permissions set
- [ ] Input validation implemented
- [ ] Error handling in place
- [ ] Logs don't contain sensitive info

## Support and Maintenance

### Documentation
- Keep README.md updated
- Update CHANGELOG.md for each release
- Document known issues

### User Support
- Monitor GitHub issues
- Respond to user questions
- Accept pull requests
- Update based on feedback

### Monitoring
- Track installation metrics
- Monitor error reports
- Collect user feedback
- Plan improvements

## License Compliance

Ensure:
- LICENSE file is included
- Dependencies are properly licensed
- Attribution is provided
- License is compatible with Jelastic marketplace

## Resources

- [Jelastic JPS Documentation](https://docs.jelastic.com/jps/)
- [Jelastic Marketplace](https://github.com/jelastic-jps/marketplace)
- [JPS Examples](https://github.com/jelastic-jps)
- [Jelastic API Documentation](https://docs.jelastic.com/api/)
