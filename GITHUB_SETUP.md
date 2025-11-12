# GitHub Repository Setup Guide

Follow these steps to create and push your Synchro Add-on to GitHub.

## Step 1: Create Repository on GitHub

### Option A: Via GitHub Web Interface

1. Go to [https://github.com/new](https://github.com/new)
2. Fill in the details:
   - **Repository name**: `synchro-addon`
   - **Description**: `Virtuozzo/Jelastic JPS add-on for file synchronization between nodes using rsync`
   - **Visibility**: Choose Public or Private
   - **Do NOT** initialize with README, .gitignore, or license (we already have these)
3. Click **Create repository**

### Option B: Via GitHub CLI (if installed)

```bash
gh repo create synchro-addon --public --source=. --remote=origin \
  --description="Virtuozzo/Jelastic JPS add-on for file synchronization between nodes using rsync"
```

## Step 2: Add Remote and Push

Once the GitHub repository is created, run these commands:

```bash
cd /srv/www/claude/synchro-add-on

# Add the remote repository
git remote add origin https://github.com/shaundma/synchro-addon.git

# Push to GitHub
git push -u origin master
```

### If using SSH (recommended):

```bash
cd /srv/www/claude/synchro-add-on

# Add the remote repository with SSH
git remote add origin git@github.com:shaundma/synchro-addon.git

# Push to GitHub
git push -u origin master
```

## Step 3: Verify Upload

1. Go to [https://github.com/shaundma/synchro-addon](https://github.com/shaundma/synchro-addon)
2. Verify all files are present:
   - ✅ manifest.jps
   - ✅ README.md
   - ✅ QUICKSTART.md
   - ✅ DEPLOYMENT.md
   - ✅ CHANGELOG.md
   - ✅ LICENSE
   - ✅ .gitignore
   - ✅ .gitattributes
   - ✅ test-local.sh

## Step 4: Add Repository Description and Topics

On your GitHub repository page:

1. Click the **⚙️ Settings** gear icon next to About
2. Add description:
   ```
   Virtuozzo/Jelastic JPS add-on for file synchronization between nodes using rsync
   ```
3. Add website:
   ```
   https://github.com/shaundma/synchro-addon
   ```
4. Add topics (tags):
   - `jelastic`
   - `virtuozzo`
   - `jps`
   - `rsync`
   - `sync`
   - `file-sync`
   - `addon`
   - `cloud`

## Step 5: (Optional) Add an Icon

If you want a custom icon for your add-on:

```bash
cd /srv/www/claude/synchro-addon
mkdir images

# Add your icon file (PNG, 64x64 or 128x128 recommended)
# Name it: icon.png

# Commit and push
git add images/icon.png
git commit -m "Add add-on icon"
git push
```

## Step 6: Test Installation URL

Your add-on is now accessible at:

```
https://raw.githubusercontent.com/shaundma/synchro-addon/master/manifest.jps
```

### Test it in Jelastic:

1. Go to any environment in Jelastic
2. Click on a node
3. Click **Add-ons**
4. Click **Import**
5. Enter URL:
   ```
   https://raw.githubusercontent.com/shaundma/synchro-addon/master/manifest.jps
   ```
6. Click **Install**

## Authentication Issues?

If you encounter authentication issues when pushing:

### For HTTPS:

You may need a Personal Access Token (PAT):

1. Go to [https://github.com/settings/tokens](https://github.com/settings/tokens)
2. Click **Generate new token (classic)**
3. Select scopes: `repo` (all)
4. Generate and copy the token
5. Use the token as password when pushing

### For SSH:

1. Generate SSH key if you don't have one:
   ```bash
   ssh-keygen -t ed25519 -C "shaun@dma.nl"
   ```

2. Add to GitHub:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   Copy and add at [https://github.com/settings/ssh/new](https://github.com/settings/ssh/new)

3. Test connection:
   ```bash
   ssh -T git@github.com
   ```

## Quick Commands Reference

```bash
# Check repository status
git status

# View commit history
git log --oneline

# Check remote URL
git remote -v

# Change remote URL (if needed)
git remote set-url origin https://github.com/shaundma/synchro-addon.git

# Create a new branch
git checkout -b develop

# Tag a release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## Next Steps

After pushing to GitHub:

1. ✅ Test installation in Jelastic
2. ✅ Add repository topics and description
3. ✅ Consider adding an icon
4. ✅ Star your own repository
5. ✅ Share the URL with others
6. ✅ Consider submitting to Jelastic Marketplace (see DEPLOYMENT.md)

## Troubleshooting

### Error: "remote origin already exists"

```bash
git remote remove origin
git remote add origin https://github.com/shaundma/synchro-addon.git
```

### Error: "Permission denied"

Check your authentication method (HTTPS vs SSH) and credentials.

### Error: "Updates were rejected"

```bash
# Only if you're sure about overwriting
git push -f origin master
```

## Support

Need help?
- GitHub Docs: [https://docs.github.com](https://docs.github.com)
- Git Docs: [https://git-scm.com/doc](https://git-scm.com/doc)
