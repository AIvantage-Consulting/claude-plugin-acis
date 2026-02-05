#!/usr/bin/env bash
# ACIS Pre-Commit Review Hook
# Reminds users to run /acis pre-commit-review before committing
#
# This hook intercepts `git commit` commands (via Claude's PreToolUse hook)
# and provides a non-blocking reminder to run the design review.
#
# BEHAVIOR: Non-blocking (exit 0). Shows reminder but allows commit to proceed.
#
# TO SKIP THIS HOOK:
#   - Use: git commit --no-verify
#   - Or:  ACIS_SKIP_PRE_COMMIT=1 git commit
#
# TO DISABLE PERMANENTLY:
#   - Remove the PreToolUse hook from .claude/settings.json
#   - Or reinstall ACIS with: /acis init --skip-pre-commit-hook

set -euo pipefail

# Read the tool input from stdin (JSON format)
read -r input 2>/dev/null || input=""

# Extract command from JSON
command=""
if [ -n "$input" ]; then
  command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
fi

# Only intercept git commit commands
if [[ "$command" != git\ commit* ]]; then
  exit 0
fi

# Skip if --no-verify flag is present
if [[ "$command" == *--no-verify* ]]; then
  exit 0
fi

# Skip if environment variable is set
if [[ "${ACIS_SKIP_PRE_COMMIT:-}" == "1" ]]; then
  exit 0
fi

# Check if there are staged changes
if git diff --staged --quiet 2>/dev/null; then
  # No staged changes, nothing to review
  exit 0
fi

# Count staged files and lines
staged_files=$(git diff --staged --name-only 2>/dev/null | wc -l | tr -d ' ')
staged_lines=$(git diff --staged 2>/dev/null | wc -l | tr -d ' ')

# Display reminder
cat >&2 << EOF

╔══════════════════════════════════════════════════════════════════╗
║  ACIS Pre-Commit Review Available                                 ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Staged: ${staged_files} files, ~${staged_lines} lines                              ║
║                                                                   ║
║  Quick design review before commit:                               ║
║    /acis pre-commit-review                                        ║
║                                                                   ║
║  Skip this reminder:                                              ║
║    git commit --no-verify                                         ║
║    ACIS_SKIP_PRE_COMMIT=1 git commit                              ║
║                                                                   ║
║  Disable permanently:                                             ║
║    /acis init --skip-pre-commit-hook                              ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝

EOF

# Non-blocking - always allow commit to proceed
exit 0
