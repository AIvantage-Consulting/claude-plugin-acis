# ACIS Installation Guide

This guide covers all methods for installing the ACIS (Automated Code Improvement System) Claude Plugin.

## Prerequisites

- Claude Code CLI installed
- (Optional) Codex MCP server configured for advanced analysis

## Installation Methods

### Method 1: Marketplace Installation (Recommended)

The marketplace provides version tracking, automatic updates, and easy installation.

**Step 1: Add the marketplace**

```bash
# From GitHub (public release)
/plugin marketplace add aivantage-consulting/claude-plugin-acis
```

**Step 2: Install the plugin**

```bash
/plugin install acis@aivantage-acis
```

**Step 3: Verify installation**

```bash
/acis:help
```

### Method 2: Direct Development Installation

For local development and testing:

```bash
# Start Claude Code with the plugin
claude --plugin-dir /path/to/acis

# Or with the full path
claude --plugin-dir ~/AI_Products/aivantage/claude-plugins/acis
```

### Method 3: Symlink Installation

Create a symlink in Claude's plugin cache for permanent local installation:

```bash
# Create the repos directory if it doesn't exist
mkdir -p ~/.claude/plugins/repos

# Create symlink
ln -s /path/to/acis ~/.claude/plugins/repos/acis

# Verify
ls -la ~/.claude/plugins/repos/
```

### Method 4: Project-Wide Configuration

Configure a specific project to use ACIS automatically.

**Add to your project's `.claude/settings.json`:**

```json
{
  "extraKnownMarketplaces": {
    "aivantage-acis": {
      "source": {
        "source": "github",
        "repo": "aivantage-consulting/claude-plugin-acis"
      }
    }
  },
  "enabledPlugins": {
    "acis@aivantage-acis": true
  }
}
```

When team members open this project, they'll be prompted to install the marketplace.

### Method 5: System-Wide Configuration

Configure ACIS for all your projects.

**Add to `~/.claude/settings.json`:**

```json
{
  "extraKnownMarketplaces": {
    "aivantage-acis": {
      "source": "./repos/acis"
    }
  },
  "enabledPlugins": {
    "acis@aivantage-acis": true
  }
}
```

## Post-Installation Setup

### 1. Bootstrap Your Project

Run the init command to create project configuration:

```bash
/acis:init
```

This will either:
- Extract context from existing documentation (vision.md, prd.md, etc.)
- Interview you with BA/PM-style questions

Output: `.acis-config.json` in your project root.

### 2. Verify Commands Work

Test the plugin is working:

```bash
# Show help
/acis:help

# Check status (will show "no goals found" for new projects)
/acis:status
```

### 3. Optional: Configure Codex MCP

For advanced multi-agent analysis, configure the Codex MCP server:

**Add to `.mcp.json` or `~/.claude/mcp.json`:**

```json
{
  "mcpServers": {
    "codex": {
      "command": "codex-cli",
      "args": ["--mode", "mcp"]
    }
  }
}
```

## Verifying Installation

### Check Plugin is Loaded

```bash
/plugin list
```

Look for `acis@aivantage-acis` or `acis` in the list.

### Check Commands Available

```bash
/acis:help
```

Should display all available ACIS commands.

### Run Status Check

```bash
/acis:status
```

Should display the progress dashboard (empty for new projects).

## Troubleshooting

### "Command not found" Error

**Cause:** Plugin not loaded or namespace incorrect.

**Fix:**
1. Verify plugin installation: `/plugin list`
2. Check the correct namespace is used: `/acis:help` (not `/acis help`)
3. Restart Claude Code session

### Plugin Not Auto-Loading

**Cause:** Not in enabled plugins list.

**Fix:**
Add to your settings:
```json
{
  "enabledPlugins": {
    "acis@aivantage-acis": true
  }
}
```

### Marketplace Not Found

**Cause:** Marketplace not added or wrong name.

**Fix:**
```bash
# List current marketplaces
/plugin marketplace list

# Re-add marketplace
/plugin marketplace add aivantage-consulting/claude-plugin-acis
```

### Private Repository Access

**Cause:** Authentication token not set for private repos.

**Fix:**
Set GitHub token in your environment:
```bash
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

### Commands Work But No Output

**Cause:** `.acis-config.json` not found or goals directory doesn't exist.

**Fix:**
```bash
# Initialize ACIS for the project
/acis:init

# Or create config manually
touch .acis-config.json
mkdir -p docs/reviews/goals
```

## Updating the Plugin

### Via Marketplace

```bash
# Update marketplace catalog
/plugin marketplace update

# Reinstall to get latest version
/plugin install acis@aivantage-acis --force
```

### Via Symlink (Local Development)

```bash
# Pull latest changes
cd ~/path/to/acis
git pull

# Plugin automatically uses latest
```

## Uninstalling

### Remove Plugin

```bash
/plugin uninstall acis@aivantage-acis
```

### Remove Marketplace

```bash
/plugin marketplace remove aivantage-acis
```

### Remove Symlink

```bash
rm ~/.claude/plugins/repos/acis
```

### Remove Project Configuration

Delete from `.claude/settings.json`:
- `extraKnownMarketplaces.aivantage-acis`
- `enabledPlugins["acis@aivantage-acis"]`

## Support

- **Documentation:** See `docs/ACIS_USER_GUIDE.md`
- **Issues:** https://github.com/aivantage-consulting/claude-plugin-acis/issues
- **Email:** support@aivantage-consulting.com
