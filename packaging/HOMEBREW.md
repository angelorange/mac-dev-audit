# Homebrew Packaging Guide

This guide explains how to distribute `mac-dev-audit` via Homebrew.

## Option 1: Personal Tap (Recommended for Start)

A "tap" is a third-party repository of Homebrew formulae.

### Step 1: Create a Tap Repository

1. Create a new GitHub repository named `homebrew-tap` (the `homebrew-` prefix is required)
   - Example: `github.com/YOUR_USERNAME/homebrew-tap`

2. Clone it locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/homebrew-tap.git
   cd homebrew-tap
   mkdir Formula
   ```

3. Copy the formula:
   ```bash
   cp /path/to/mac-audit-dev/Formula/mac-dev-audit.rb Formula/
   ```

4. Edit `Formula/mac-dev-audit.rb`:
   - Replace `YOUR_USERNAME` with your GitHub username
   - Update the `sha256` (see Step 2)

5. Commit and push:
   ```bash
   git add Formula/mac-dev-audit.rb
   git commit -m "Add mac-dev-audit formula"
   git push
   ```

### Step 2: Create a Release

1. Tag a release in your `mac-dev-audit` repository:
   ```bash
   cd /path/to/mac-dev-audit
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

2. Download the tarball and get its SHA256:
   ```bash
   curl -sL https://github.com/YOUR_USERNAME/mac-dev-audit/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256
   ```

3. Update the formula with the SHA256 hash.

### Step 3: Install via Tap

Users can now install with:
```bash
brew tap YOUR_USERNAME/tap
brew install mac-dev-audit
```

Or in one command:
```bash
brew install YOUR_USERNAME/tap/mac-dev-audit
```

---

## Option 2: Homebrew Core (For Popular Projects)

For wider distribution, you can submit to `homebrew-core`:

1. Ensure your project meets [Homebrew's criteria](https://docs.brew.sh/Acceptable-Formulae):
   - Notable project (GitHub stars, users, etc.)
   - Stable releases
   - Working test block

2. Fork `homebrew-core` and add your formula
3. Submit a pull request

---

## Updating the Formula

When you release a new version:

1. Create a new git tag:
   ```bash
   git tag -a v1.1.0 -m "Release v1.1.0"
   git push origin v1.1.0
   ```

2. Get the new SHA256:
   ```bash
   curl -sL https://github.com/YOUR_USERNAME/mac-dev-audit/archive/refs/tags/v1.1.0.tar.gz | shasum -a 256
   ```

3. Update the formula in your tap:
   ```ruby
   url "https://github.com/YOUR_USERNAME/mac-dev-audit/archive/refs/tags/v1.1.0.tar.gz"
   sha256 "NEW_SHA256_HERE"
   ```

4. Commit and push the tap repository.

---

## Testing the Formula Locally

Before publishing, test locally:

```bash
# Install from local formula
brew install --build-from-source ./Formula/mac-dev-audit.rb

# Run tests
brew test mac-dev-audit

# Check formula style
brew audit --strict mac-dev-audit

# Uninstall
brew uninstall mac-dev-audit
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `brew tap USER/tap` | Add a tap |
| `brew install mac-dev-audit` | Install |
| `brew upgrade mac-dev-audit` | Upgrade |
| `brew uninstall mac-dev-audit` | Uninstall |
| `brew info mac-dev-audit` | Show info |
