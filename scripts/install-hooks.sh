#!/usr/bin/env bash
# ACIS Hook Installation Script
# Installs path validation hooks into a project
#
# Usage: ./install-hooks.sh [project_root]
#        If no project_root provided, uses current directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="${1:-.}"

echo "Installing ACIS hooks to: $PROJECT_ROOT"

# Create hooks directory
mkdir -p "$PROJECT_ROOT/.claude/hooks"

# Copy the validator script
cp "$PLUGIN_ROOT/.claude/hooks/acis-path-validator.sh" "$PROJECT_ROOT/.claude/hooks/"
chmod +x "$PROJECT_ROOT/.claude/hooks/acis-path-validator.sh"

# Check if settings.json exists
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
  echo "Found existing settings.json, merging hooks..."

  # Check if hooks already configured
  if jq -e '.hooks.PreToolUse' "$SETTINGS_FILE" >/dev/null 2>&1; then
    # Check if our hook is already there
    if jq -e '.hooks.PreToolUse[] | select(.hooks[].command | contains("acis-path-validator"))' "$SETTINGS_FILE" >/dev/null 2>&1; then
      echo "ACIS hooks already installed."
      exit 0
    fi

    # Add our hook to existing PreToolUse array
    jq '.hooks.PreToolUse += [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/acis-path-validator.sh\"",
        "timeout": 10
      }]
    }]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  else
    # Add hooks section
    jq '. + {
      "hooks": {
        "PreToolUse": [{
          "matcher": "Edit|Write",
          "hooks": [{
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/acis-path-validator.sh\"",
            "timeout": 10
          }]
        }]
      }
    }' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  fi
else
  # Create new settings.json
  cat > "$SETTINGS_FILE" << 'EOF'
{
  "$schema": "https://code.claude.com/settings.schema.json",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/acis-path-validator.sh\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
EOF
fi

echo ""
echo "✅ ACIS hooks installed successfully!"
echo ""
echo "Installed files:"
echo "  - $PROJECT_ROOT/.claude/hooks/acis-path-validator.sh"
echo "  - $PROJECT_ROOT/.claude/settings.json (updated)"
echo ""
echo "The hook will now:"
echo "  - BLOCK writes that create nested paths (docs/acis/goals/docs/acis/goals)"
echo "  - BLOCK .acis-config.json with absolute or traversal paths"
echo "  - WARN about ACIS artifacts written to non-standard locations"
