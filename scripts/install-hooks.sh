#!/usr/bin/env bash
# ACIS Hook Installation Script
# Installs path validation and pre-commit review hooks into a project
#
# Usage: ./install-hooks.sh [project_root] [options]
#        If no project_root provided, uses current directory
#
# Options:
#   --skip-pre-commit-hook   Don't install the pre-commit review reminder hook
#   --skip-path-validator    Don't install the path validation hook
#   --pre-commit-only        Only install pre-commit hook (skip path validator)
#   --path-validator-only    Only install path validator (skip pre-commit)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

# Parse arguments
PROJECT_ROOT="."
INSTALL_PRE_COMMIT=true
INSTALL_PATH_VALIDATOR=true

for arg in "$@"; do
  case $arg in
    --skip-pre-commit-hook)
      INSTALL_PRE_COMMIT=false
      ;;
    --skip-path-validator)
      INSTALL_PATH_VALIDATOR=false
      ;;
    --pre-commit-only)
      INSTALL_PATH_VALIDATOR=false
      ;;
    --path-validator-only)
      INSTALL_PRE_COMMIT=false
      ;;
    -*)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
    *)
      PROJECT_ROOT="$arg"
      ;;
  esac
done

echo "Installing ACIS hooks to: $PROJECT_ROOT"
echo ""

# Create hooks directory
mkdir -p "$PROJECT_ROOT/.claude/hooks"

# Track what was installed
installed_hooks=()

# =============================================================================
# INSTALL PATH VALIDATOR HOOK
# =============================================================================

if [ "$INSTALL_PATH_VALIDATOR" = true ]; then
  echo "Installing path validator hook..."
  cp "$PLUGIN_ROOT/.claude/hooks/acis-path-validator.sh" "$PROJECT_ROOT/.claude/hooks/"
  chmod +x "$PROJECT_ROOT/.claude/hooks/acis-path-validator.sh"
  installed_hooks+=("path-validator")
fi

# =============================================================================
# INSTALL PRE-COMMIT REVIEW HOOK
# =============================================================================

if [ "$INSTALL_PRE_COMMIT" = true ]; then
  echo "Installing pre-commit review hook..."
  cp "$PLUGIN_ROOT/.claude/hooks/acis-pre-commit-hook.sh" "$PROJECT_ROOT/.claude/hooks/"
  chmod +x "$PROJECT_ROOT/.claude/hooks/acis-pre-commit-hook.sh"
  installed_hooks+=("pre-commit-review")
fi

# =============================================================================
# CONFIGURE SETTINGS.JSON
# =============================================================================

SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"

# Build the hooks configuration
build_hooks_config() {
  local hooks_json='{"hooks":{"PreToolUse":[]}}'

  # Add path validator hook
  if [ "$INSTALL_PATH_VALIDATOR" = true ]; then
    hooks_json=$(echo "$hooks_json" | jq '.hooks.PreToolUse += [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/acis-path-validator.sh\"",
        "timeout": 10
      }]
    }]')
  fi

  # Add pre-commit hook
  if [ "$INSTALL_PRE_COMMIT" = true ]; then
    hooks_json=$(echo "$hooks_json" | jq '.hooks.PreToolUse += [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/acis-pre-commit-hook.sh\"",
        "timeout": 5
      }]
    }]')
  fi

  echo "$hooks_json"
}

if [ -f "$SETTINGS_FILE" ]; then
  echo "Found existing settings.json, merging hooks..."

  # Check for existing hooks
  existing_hooks=$(jq -r '.hooks.PreToolUse // []' "$SETTINGS_FILE" 2>/dev/null || echo "[]")

  # Check if our hooks are already there
  has_path_validator=$(echo "$existing_hooks" | jq 'any(.[]; .hooks[]?.command | contains("acis-path-validator"))' 2>/dev/null || echo "false")
  has_pre_commit=$(echo "$existing_hooks" | jq 'any(.[]; .hooks[]?.command | contains("acis-pre-commit-hook"))' 2>/dev/null || echo "false")

  # Add hooks that don't exist
  if [ "$INSTALL_PATH_VALIDATOR" = true ] && [ "$has_path_validator" = "false" ]; then
    jq '.hooks.PreToolUse += [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/acis-path-validator.sh\"",
        "timeout": 10
      }]
    }]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  elif [ "$INSTALL_PATH_VALIDATOR" = true ]; then
    echo "  Path validator hook already configured."
  fi

  if [ "$INSTALL_PRE_COMMIT" = true ] && [ "$has_pre_commit" = "false" ]; then
    # Ensure hooks.PreToolUse exists
    if ! jq -e '.hooks.PreToolUse' "$SETTINGS_FILE" >/dev/null 2>&1; then
      jq '. + {"hooks": {"PreToolUse": []}}' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    fi

    jq '.hooks.PreToolUse += [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/acis-pre-commit-hook.sh\"",
        "timeout": 5
      }]
    }]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  elif [ "$INSTALL_PRE_COMMIT" = true ]; then
    echo "  Pre-commit hook already configured."
  fi

else
  # Create new settings.json with all requested hooks
  echo "Creating new settings.json..."

  cat > "$SETTINGS_FILE" << 'SETTINGS_START'
{
  "$schema": "https://code.claude.com/settings.schema.json",
  "hooks": {
    "PreToolUse": [
SETTINGS_START

  first_hook=true

  if [ "$INSTALL_PATH_VALIDATOR" = true ]; then
    cat >> "$SETTINGS_FILE" << 'HOOK_PATH_VALIDATOR'
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
HOOK_PATH_VALIDATOR
    first_hook=false
  fi

  if [ "$INSTALL_PRE_COMMIT" = true ]; then
    if [ "$first_hook" = false ]; then
      # Add comma before this hook
      sed -i.bak '$ s/}$/},/' "$SETTINGS_FILE" && rm -f "$SETTINGS_FILE.bak"
    fi
    cat >> "$SETTINGS_FILE" << 'HOOK_PRE_COMMIT'
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/acis-pre-commit-hook.sh\"",
            "timeout": 5
          }
        ]
      }
HOOK_PRE_COMMIT
  fi

  cat >> "$SETTINGS_FILE" << 'SETTINGS_END'
    ]
  }
}
SETTINGS_END
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "============================================================"
echo "ACIS hooks installed successfully!"
echo "============================================================"
echo ""
echo "Installed files:"
if [ "$INSTALL_PATH_VALIDATOR" = true ]; then
  echo "  - $PROJECT_ROOT/.claude/hooks/acis-path-validator.sh"
fi
if [ "$INSTALL_PRE_COMMIT" = true ]; then
  echo "  - $PROJECT_ROOT/.claude/hooks/acis-pre-commit-hook.sh"
fi
echo "  - $PROJECT_ROOT/.claude/settings.json (updated)"
echo ""

if [ "$INSTALL_PATH_VALIDATOR" = true ]; then
  echo "Path Validator will:"
  echo "  - BLOCK writes that create nested paths (docs/acis/goals/docs/acis/goals)"
  echo "  - BLOCK .acis-config.json with absolute or traversal paths"
  echo "  - WARN about ACIS artifacts written to non-standard locations"
  echo ""
fi

if [ "$INSTALL_PRE_COMMIT" = true ]; then
  echo "Pre-Commit Review will:"
  echo "  - Remind you to run /acis pre-commit-review before git commit"
  echo "  - Show staged file count and line count"
  echo "  - Non-blocking (you can proceed with commit)"
  echo ""
  echo "To skip the pre-commit reminder:"
  echo "  git commit --no-verify"
  echo "  ACIS_SKIP_PRE_COMMIT=1 git commit"
  echo ""
  echo "To disable permanently:"
  echo "  /acis init --skip-pre-commit-hook"
  echo ""
fi
