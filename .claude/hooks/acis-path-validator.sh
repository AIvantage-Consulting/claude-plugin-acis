#!/usr/bin/env bash
# ACIS Path Validator Hook
# Runs BEFORE Edit/Write operations to prevent nested paths and invalid ACIS artifacts
#
# Exit codes:
#   0 = Allow the operation
#   2 = Block the operation (validation failed)

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# If no file path, allow (not a file operation we care about)
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# =============================================================================
# RULE 1: Detect nested ACIS paths (the bug we're preventing)
# =============================================================================
# Pattern: docs/acis/goals/docs/acis/goals or docs/reviews/goals/docs/reviews/goals

detect_nested_path() {
  local path="$1"

  # Check for doubled ACIS segments
  case "$path" in
    *docs/acis/*docs/acis*)
      echo "BLOCKED: Nested ACIS path detected" >&2
      echo "  Path: $path" >&2
      echo "  Pattern: docs/acis appears twice" >&2
      echo "" >&2
      echo "This indicates a path construction bug. Use resolve_acis_path():" >&2
      echo "  CORRECT: \${PROJECT_ROOT}/\${config.paths.goals}/file.json" >&2
      echo "  WRONG:   \${config.paths.goals}/\${config.paths.goals}/file.json" >&2
      return 1
      ;;
    *docs/reviews/*docs/reviews*)
      echo "BLOCKED: Nested reviews path detected" >&2
      echo "  Path: $path" >&2
      echo "  Pattern: docs/reviews appears twice" >&2
      return 1
      ;;
    *goals/*goals*)
      # More specific nested goals check
      if [[ "$path" =~ goals/.*goals/ ]]; then
        echo "BLOCKED: Nested goals path detected" >&2
        echo "  Path: $path" >&2
        return 1
      fi
      ;;
  esac

  return 0
}

# =============================================================================
# RULE 2: Validate ACIS artifact paths are under expected roots
# =============================================================================

validate_acis_artifact_location() {
  local path="$1"

  # Check if this is an ACIS artifact (goal, discovery, decision, etc.)
  case "$path" in
    # Goal files - should be in docs/acis/goals/ or configured path
    *-G[0-9]*-*.json|*GOAL*.json|*goal*.json)
      # Warn if not in expected location (but don't block)
      if [[ ! "$path" =~ docs/acis/goals/ ]] && [[ ! "$path" =~ docs/reviews/goals/ ]]; then
        echo "WARNING: Goal file not in standard ACIS location" >&2
        echo "  Path: $path" >&2
        echo "  Expected: docs/acis/goals/ or configured paths.goals" >&2
      fi
      ;;

    # Discovery reports
    *DISC-*.md|*discovery*.md)
      if [[ ! "$path" =~ docs/acis/discovery/ ]] && [[ ! "$path" =~ docs/acis/state/discovery/ ]]; then
        echo "WARNING: Discovery report not in standard ACIS location" >&2
        echo "  Path: $path" >&2
      fi
      ;;

    # Decision manifests
    *DEC-*.json|*decision*.json|*manifest*.json)
      if [[ ! "$path" =~ docs/acis/decisions/ ]]; then
        echo "WARNING: Decision manifest not in standard ACIS location" >&2
        echo "  Path: $path" >&2
      fi
      ;;

    # Audit reports
    *AUDIT-*.md|*audit*.md)
      if [[ ! "$path" =~ docs/acis/audits/ ]]; then
        echo "WARNING: Audit report not in standard ACIS location" >&2
        echo "  Path: $path" >&2
      fi
      ;;

    # State files
    *STATE.md|*progress/*.json)
      if [[ ! "$path" =~ docs/acis/state/ ]] && [[ ! "$path" =~ .acis/ ]]; then
        echo "WARNING: State file not in standard ACIS location" >&2
        echo "  Path: $path" >&2
      fi
      ;;
  esac

  return 0  # Warnings don't block
}

# =============================================================================
# RULE 3: Prevent absolute paths in ACIS config
# =============================================================================

validate_not_absolute_in_config() {
  local path="$1"
  local content=""

  # Only check .acis-config.json writes
  if [[ "$path" =~ \.acis-config\.json$ ]]; then
    # For Write tool, check content
    content=$(echo "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null)

    if [ -n "$content" ]; then
      # Check if any path value starts with /
      if echo "$content" | jq -e '.paths | to_entries[] | select(.value | startswith("/"))' >/dev/null 2>&1; then
        echo "BLOCKED: Absolute path in .acis-config.json" >&2
        echo "  All paths must be relative to project root" >&2
        echo "  Found paths starting with '/'" >&2
        return 1
      fi

      # Check for path traversal
      if echo "$content" | jq -e '.paths | to_entries[] | select(.value | contains(".."))' >/dev/null 2>&1; then
        echo "BLOCKED: Path traversal in .acis-config.json" >&2
        echo "  Paths must not contain '..'" >&2
        return 1
      fi
    fi
  fi

  return 0
}

# =============================================================================
# MAIN VALIDATION FLOW
# =============================================================================

main() {
  local exit_code=0

  # Run all validations

  # CRITICAL: Nested path detection (blocks)
  if ! detect_nested_path "$FILE_PATH"; then
    exit 2
  fi

  # CRITICAL: Config validation (blocks)
  if ! validate_not_absolute_in_config "$FILE_PATH"; then
    exit 2
  fi

  # WARNING: Location validation (doesn't block)
  validate_acis_artifact_location "$FILE_PATH"

  # All critical validations passed
  exit 0
}

main
