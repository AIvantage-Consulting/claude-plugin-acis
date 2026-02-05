# /acis upgrade - Upgrade ACIS Installation

Detect and install missing ACIS components for existing installations.

## Trigger

User invokes `/acis upgrade` with optional flags:
- `--check` - Only check for updates, don't install anything
- `--force` - Reinstall all components even if already present
- `--hooks-only` - Only upgrade hooks (skip config changes)

## Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                        /acis upgrade                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────┐
            │  STEP 1: Read Plugin Version    │
            │  from plugin.json               │
            └─────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────┐
            │  STEP 2: Read Project State     │
            │  - .acis-config.json version    │
            │  - Installed hooks              │
            │  - Hook configuration           │
            └─────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────┐
            │  STEP 3: Compare & Report       │
            │  - Version mismatch             │
            │  - Missing hooks                │
            │  - New features available       │
            └─────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
        Up to date                     Upgrade available
              │                               │
              ▼                               ▼
    ┌─────────────────┐           ┌─────────────────────┐
    │ Display status  │           │ STEP 4: Show diff   │
    │ "All current"   │           │ Ask to proceed      │
    └─────────────────┘           └─────────────────────┘
                                              │
                                              ▼
                                  ┌─────────────────────┐
                                  │ STEP 5: Install     │
                                  │ missing components  │
                                  └─────────────────────┘
                                              │
                                              ▼
                                  ┌─────────────────────┐
                                  │ STEP 6: Update      │
                                  │ config version      │
                                  └─────────────────────┘
```

## Step 1: Read Plugin Version

```bash
plugin_version=$(jq -r '.version' "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json")
```

## Step 2: Read Project State

### Check config version
```bash
if [ -f ".acis-config.json" ]; then
  config_version=$(jq -r '.acisVersion // "unknown"' .acis-config.json)
  has_config=true
else
  config_version="none"
  has_config=false
fi
```

### Check installed hooks
```bash
has_path_validator=false
has_pre_commit=false

if [ -f ".claude/hooks/acis-path-validator.sh" ]; then
  has_path_validator=true
fi

if [ -f ".claude/hooks/acis-pre-commit-hook.sh" ]; then
  has_pre_commit=true
fi

# Also check settings.json for hook configuration
if [ -f ".claude/settings.json" ]; then
  path_validator_configured=$(jq 'any(.hooks.PreToolUse[]?; .hooks[]?.command | contains("acis-path-validator"))' .claude/settings.json 2>/dev/null || echo "false")
  pre_commit_configured=$(jq 'any(.hooks.PreToolUse[]?; .hooks[]?.command | contains("acis-pre-commit-hook"))' .claude/settings.json 2>/dev/null || echo "false")
fi
```

## Step 3: Compare & Report

### Version Comparison

Compare plugin version with config's `acisVersion` field:

```javascript
const pluginVersion = parseVersion(plugin_version);  // e.g., "2.7.0" -> {major: 2, minor: 7, patch: 0}
const configVersion = parseVersion(config_version);  // e.g., "2.6.0" -> {major: 2, minor: 6, patch: 0}

const needsUpgrade = {
  major: pluginVersion.major > configVersion.major,
  minor: pluginVersion.minor > configVersion.minor,
  patch: pluginVersion.patch > configVersion.patch
};
```

### Missing Components Detection

| Component | Detection | Introduced In |
|-----------|-----------|---------------|
| Path validator hook | `.claude/hooks/acis-path-validator.sh` exists | v2.1.0 |
| Pre-commit hook | `.claude/hooks/acis-pre-commit-hook.sh` exists | v2.7.0 |
| Hook configuration | Both hooks in `.claude/settings.json` | v2.1.0+ |
| Config version field | `.acis-config.json` has `acisVersion` | v2.7.0 |

### Display Status

```
╔══════════════════════════════════════════════════════════════════╗
║  ACIS Upgrade Check                                               ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Plugin Version:  2.7.0                                           ║
║  Config Version:  2.6.0 (from .acis-config.json)                  ║
║                                                                   ║
╠══════════════════════════════════════════════════════════════════╣
║  Component Status:                                                ║
║                                                                   ║
║    Path validator hook:    ✓ Installed                            ║
║    Pre-commit hook:        ✗ Missing (new in 2.7.0)               ║
║    Hook configuration:     ⚠ Partial (pre-commit not configured) ║
║                                                                   ║
╠══════════════════════════════════════════════════════════════════╣
║  New Features in 2.7.0:                                           ║
║                                                                   ║
║    • /acis pre-commit-review - Quick design review before commit  ║
║    • /acis version - Display plugin version                       ║
║    • Pre-commit hook reminder (installed by default)              ║
║                                                                   ║
╠══════════════════════════════════════════════════════════════════╣
║  Upgrade available. Install missing components?                   ║
╚══════════════════════════════════════════════════════════════════╝
```

## Step 4: Confirm Upgrade

Use AskUserQuestion:

```
Install missing ACIS components?

Options:
  [1] Yes, install all missing components (Recommended)
  [2] Only install hooks
  [3] Only update config version
  [4] Skip for now
```

## Step 5: Install Missing Components

### Install Missing Hooks

```bash
# Run the install script with appropriate flags
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-hooks.sh" "${PROJECT_ROOT}"
```

The install script is idempotent - it detects existing hooks and only adds missing ones.

### Update Config Version

If `.acis-config.json` exists, add or update the `acisVersion` field:

```bash
# Add acisVersion to config
jq --arg v "$plugin_version" '. + {acisVersion: $v}' .acis-config.json > .acis-config.json.tmp
mv .acis-config.json.tmp .acis-config.json
```

## Step 6: Show Completion

```
╔══════════════════════════════════════════════════════════════════╗
║  ACIS Upgrade Complete                                            ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Installed:                                                       ║
║    ✓ Pre-commit review hook                                       ║
║    ✓ Updated config version to 2.7.0                              ║
║                                                                   ║
║  New commands available:                                          ║
║    /acis pre-commit-review  - Quick design review before commit   ║
║    /acis version            - Show plugin version                 ║
║                                                                   ║
║  The pre-commit hook will remind you to run design review.        ║
║  Skip with: git commit --no-verify                                ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

## --check Flag (No Install)

When `--check` is passed, only show status without prompting to install:

```
╔══════════════════════════════════════════════════════════════════╗
║  ACIS Upgrade Available                                           ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Current: 2.6.0  →  Available: 2.7.0                              ║
║                                                                   ║
║  Missing components:                                              ║
║    • Pre-commit review hook                                       ║
║                                                                   ║
║  Run '/acis upgrade' to install.                                  ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

## Already Up-to-Date

```
╔══════════════════════════════════════════════════════════════════╗
║  ACIS - Up to Date                                                ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Version: 2.7.0                                                   ║
║                                                                   ║
║  All components installed:                                        ║
║    ✓ Path validator hook                                          ║
║    ✓ Pre-commit review hook                                       ║
║    ✓ Hook configuration                                           ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

## No Config File

If no `.acis-config.json` exists:

```
╔══════════════════════════════════════════════════════════════════╗
║  ACIS Not Initialized                                             ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  No .acis-config.json found in this project.                      ║
║                                                                   ║
║  Run '/acis init' to initialize ACIS for this project.            ║
║  This will create the config and install all hooks.               ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

## Version History Lookup

To show "New Features in X.Y.Z", the command reads from a version history embedded in the command or a separate file.

### Feature Changelog (Embedded)

```javascript
const CHANGELOG = {
  "2.7.0": {
    features: [
      "/acis pre-commit-review - Quick design review before commit",
      "/acis version - Display plugin version",
      "Pre-commit hook reminder (installed by default)"
    ],
    hooks: ["acis-pre-commit-hook.sh"]
  },
  "2.6.0": {
    features: [
      "GENESIS Framework - Vision-to-architecture transformation",
      "10 new GENESIS agents"
    ],
    hooks: []
  },
  "2.5.0": {
    features: [
      "Swarm Orchestration with TeammateTool"
    ],
    hooks: []
  }
  // ... etc
};
```

## Flags Reference

| Flag | Effect |
|------|--------|
| `--check` | Only show status, don't prompt to install |
| `--force` | Reinstall all components even if present |
| `--hooks-only` | Only upgrade hooks, skip config changes |

## Integration with Other Commands

The upgrade check can be triggered from any ACIS command on first use per session. See "Auto-Detect" section in `commands/acis.md`.
