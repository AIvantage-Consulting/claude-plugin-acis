# /acis version - Display Plugin Version

Display the canonical version of the installed ACIS plugin.

## Trigger

User invokes `/acis version` or `/acis:version`.

## Behavior

1. **Read Plugin Manifest**

   Read the version from the plugin manifest:
   ```bash
   cat "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" | jq -r '.version'
   ```

2. **Display Version Information**

   Output in this format:
   ```
   ╔══════════════════════════════════════════════════════════════════╗
   ║  ACIS - Automated Code Improvement System                        ║
   ╠══════════════════════════════════════════════════════════════════╣
   ║                                                                   ║
   ║  Version: 2.7.0                                                   ║
   ║  Author:  AIvantage Consulting Inc                               ║
   ║  License: MIT                                                     ║
   ║                                                                   ║
   ║  Repository: https://github.com/aivantage-consulting/claude-plugin-acis
   ║                                                                   ║
   ╚══════════════════════════════════════════════════════════════════╝
   ```

## Implementation

Read the plugin.json and extract all relevant metadata:

```bash
plugin_json="${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json"

if [ -f "$plugin_json" ]; then
  version=$(jq -r '.version // "unknown"' "$plugin_json")
  name=$(jq -r '.name // "acis"' "$plugin_json")
  author=$(jq -r '.author.name // .author // "unknown"' "$plugin_json")
  license=$(jq -r '.license // "unknown"' "$plugin_json")
  repo=$(jq -r '.repository // .homepage // "unknown"' "$plugin_json")
  description=$(jq -r '.description // ""' "$plugin_json")
else
  echo "Error: plugin.json not found at $plugin_json"
  exit 1
fi
```

## Optional: Project Status

If `.acis-config.json` exists in the current directory, also show:

```
╔══════════════════════════════════════════════════════════════════╗
║  Project Status                                                   ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Project: MyHealthApp                                             ║
║  Config:  .acis-config.json                                       ║
║  Hooks:   path-validator ✓  pre-commit ✓                         ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

## Flags

| Flag | Effect |
|------|--------|
| `--json` | Output version info as JSON |
| `--short` | Output version number only (e.g., `2.7.0`) |

### --json Output

```json
{
  "name": "acis",
  "version": "2.7.0",
  "author": "AIvantage Consulting Inc",
  "license": "MIT",
  "repository": "https://github.com/aivantage-consulting/claude-plugin-acis"
}
```

### --short Output

```
2.7.0
```

## Examples

```bash
# Full version info
/acis version

# Just the version number
/acis version --short

# JSON format (for scripting)
/acis version --json
```
