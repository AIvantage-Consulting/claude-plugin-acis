#!/usr/bin/env bash
# ACIS Path Validator Hook
# Validates file paths to prevent common path-related issues
#
# This hook intercepts Edit/Write operations and validates paths:
#   - BLOCKS nested ACIS paths (docs/acis/goals/docs/acis/goals)
#   - BLOCKS absolute paths in .acis-config.json
#   - BLOCKS path traversal (..) in config files
#   - WARNS about ACIS artifacts in non-standard locations
#
# Exit codes:
#   0 - Allow operation (or warn only)
#   2 - Block operation

set -euo pipefail

# Read the tool input from stdin (JSON format)
read -r input 2>/dev/null || input=""

# Extract file path from JSON (works for both Edit and Write tools)
file_path=""
if [ -n "$input" ]; then
  file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")
fi

# If no file path, allow
if [ -z "$file_path" ]; then
  exit 0
fi

# =============================================================================
# CHECK 1: Nested ACIS paths
# =============================================================================
# Pattern: docs/acis/goals/docs/acis/goals or similar duplication

if echo "$file_path" | grep -qE '(docs/acis|docs/reviews|\.acis).*(docs/acis|docs/reviews|\.acis)'; then
  cat >&2 << EOF
╔══════════════════════════════════════════════════════════════════╗
║  ACIS PATH VALIDATOR - BLOCKED                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Nested ACIS path detected:                                       ║
║    $file_path
║                                                                   ║
║  This appears to be a path duplication bug.                       ║
║  Expected path structure:                                         ║
║    docs/reviews/goals/<goal-file>.json                            ║
║    docs/acis/traces/<trace-file>.json                             ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
EOF
  exit 2
fi

# =============================================================================
# CHECK 2: Absolute paths in .acis-config.json
# =============================================================================

if [[ "$file_path" == *".acis-config.json" ]]; then
  # Read the content being written (from the input JSON)
  content=$(echo "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null || echo "")

  # Check for absolute paths in the content
  if echo "$content" | grep -qE '"[^"]*": *"/' ; then
    cat >&2 << EOF
╔══════════════════════════════════════════════════════════════════╗
║  ACIS PATH VALIDATOR - BLOCKED                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Absolute path detected in .acis-config.json                      ║
║                                                                   ║
║  All paths in config must be relative to project root.            ║
║                                                                   ║
║  Example:                                                         ║
║    "goalsDirectory": "docs/reviews/goals"  (correct)              ║
║    "goalsDirectory": "/Users/.../goals"    (wrong)                ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    exit 2
  fi

  # Check for path traversal
  if echo "$content" | grep -qE '"\.\.' ; then
    cat >&2 << EOF
╔══════════════════════════════════════════════════════════════════╗
║  ACIS PATH VALIDATOR - BLOCKED                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Path traversal (..) detected in .acis-config.json                ║
║                                                                   ║
║  All paths must be within project directory.                      ║
║  Remove ".." from path values.                                    ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    exit 2
  fi
fi

# =============================================================================
# CHECK 3: ACIS artifacts in non-standard locations (WARN only)
# =============================================================================

# Check if this looks like an ACIS artifact going to wrong place
is_acis_artifact=false
if echo "$file_path" | grep -qiE '\.(goal|trace|skill)\.json$'; then
  is_acis_artifact=true
elif echo "$file_path" | grep -qiE 'SKILL\.md$'; then
  is_acis_artifact=true
fi

if [ "$is_acis_artifact" = true ]; then
  # Check if it's going to a standard location
  is_standard_location=false
  if echo "$file_path" | grep -qE '^docs/(reviews/goals|acis/traces)/'; then
    is_standard_location=true
  elif echo "$file_path" | grep -qE '^skills/'; then
    is_standard_location=true
  elif echo "$file_path" | grep -qE '^\.acis/'; then
    is_standard_location=true
  fi

  if [ "$is_standard_location" = false ]; then
    cat >&2 << EOF
╔══════════════════════════════════════════════════════════════════╗
║  ACIS PATH VALIDATOR - WARNING                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  ACIS artifact in non-standard location:                          ║
║    $file_path
║                                                                   ║
║  Standard locations:                                              ║
║    Goals:  docs/reviews/goals/                                    ║
║    Traces: docs/acis/traces/ or .acis/traces/                     ║
║    Skills: skills/                                                ║
║                                                                   ║
║  Proceeding anyway...                                             ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    # Warning only - don't block
  fi
fi

# All checks passed
exit 0
