# ACIS Path Validation

**Purpose**: Runtime validation to prevent nested paths, absolute paths, and path traversal bugs.

---

## Validation Rules

### Rule 1: No Absolute Paths

Paths MUST be relative to project root.

```bash
# Validation (Bash 3.2 compatible)
validate_not_absolute() {
  local path="$1"
  if [ "${path:0:1}" = "/" ]; then
    echo "ERROR: Absolute path not allowed: $path" >&2
    return 1
  fi
  return 0
}
```

### Rule 2: No Path Traversal

Paths MUST NOT contain `..` segments.

```bash
validate_no_traversal() {
  local path="$1"
  case "$path" in
    *..*)
      echo "ERROR: Path traversal not allowed: $path" >&2
      return 1
      ;;
  esac
  return 0
}
```

### Rule 3: No Nested ACIS Paths

Output paths MUST NOT create nested structures like `docs/acis/goals/docs/acis/goals/`.

```bash
validate_no_nesting() {
  local base="$1"
  local target="$2"

  # Check if target already contains base
  case "$target" in
    *"$base"*)
      echo "ERROR: Nested path detected: $target contains $base" >&2
      return 1
      ;;
  esac
  return 0
}
```

### Rule 4: Under ACIS Root

All paths (except acisRoot itself) SHOULD be under the acisRoot directory.

```bash
validate_under_root() {
  local acis_root="$1"
  local path="$2"
  local path_name="$3"

  case "$path" in
    "$acis_root"/*)
      return 0
      ;;
    "$acis_root")
      return 0
      ;;
    *)
      echo "WARNING: $path_name ($path) is outside acisRoot ($acis_root)" >&2
      return 0  # Warning only, not error
      ;;
  esac
}
```

---

## Complete Validation Function

```bash
#!/usr/bin/env bash
# ACIS Path Validator - Bash 3.2 Compatible

validate_acis_paths() {
  local config_file="${1:-.acis-config.json}"
  local errors=0

  # Check if jq is available
  if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required for path validation" >&2
    return 1
  fi

  # Read paths from config (with defaults)
  local acis_root
  acis_root=$(jq -r '.paths.acisRoot // "docs/acis"' "$config_file" 2>/dev/null)

  local paths_keys=("goals" "discovery" "decisions" "audits" "skills" "state")
  local defaults=("docs/acis/goals" "docs/acis/discovery" "docs/acis/decisions" "docs/acis/audits" "docs/acis/skills" "docs/acis/state")

  for i in "${!paths_keys[@]}"; do
    local key="${paths_keys[$i]}"
    local default="${defaults[$i]}"
    local value

    value=$(jq -r ".paths.$key // \"$default\"" "$config_file" 2>/dev/null)

    # Rule 1: No absolute paths
    if [ "${value:0:1}" = "/" ]; then
      echo "ERROR: paths.$key is absolute: $value" >&2
      errors=$((errors + 1))
      continue
    fi

    # Rule 2: No path traversal
    case "$value" in
      *..*)
        echo "ERROR: paths.$key contains traversal: $value" >&2
        errors=$((errors + 1))
        continue
        ;;
    esac

    # Rule 4: Under acis_root (warning only)
    case "$value" in
      "$acis_root"/*|"$acis_root")
        ;;
      *)
        echo "WARNING: paths.$key ($value) is outside acisRoot ($acis_root)" >&2
        ;;
    esac
  done

  if [ $errors -gt 0 ]; then
    echo "Path validation failed with $errors error(s)" >&2
    return 1
  fi

  echo "Path validation passed"
  return 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  validate_acis_paths "$@"
fi
```

---

## Safe Path Resolution

When constructing output paths, ALWAYS use this pattern:

```bash
# CORRECT: Join project root with relative config path
resolve_acis_path() {
  local project_root="$1"
  local config_path="$2"
  local filename="$3"

  # Validate config_path first
  if [ "${config_path:0:1}" = "/" ]; then
    echo "ERROR: Config path must be relative" >&2
    return 1
  fi

  # Join safely
  local full_path="$project_root/$config_path"
  if [ -n "$filename" ]; then
    full_path="$full_path/$filename"
  fi

  # Normalize (remove double slashes)
  echo "$full_path" | sed 's|//|/|g'
}

# Example usage:
# resolve_acis_path "$(pwd)" "docs/acis/goals" "PR55-G1.json"
# Output: /path/to/project/docs/acis/goals/PR55-G1.json
```

---

## Nested Path Detection Command

Run this to find existing nested path bugs:

```bash
# Find nested ACIS paths in current project
find_nested_acis_paths() {
  local project_root="${1:-.}"

  # Look for patterns like docs/acis/goals/docs/acis/goals
  find "$project_root" -type d \( \
    -path "*docs/acis/*docs/acis*" -o \
    -path "*docs/reviews/*docs/reviews*" \
  \) 2>/dev/null

  # Count results
  local count
  count=$(find "$project_root" -type d \( \
    -path "*docs/acis/*docs/acis*" -o \
    -path "*docs/reviews/*docs/reviews*" \
  \) 2>/dev/null | wc -l | tr -d ' ')

  if [ "$count" -gt 0 ]; then
    echo ""
    echo "Found $count nested path(s). Fix before proceeding."
    return 1
  fi

  echo "No nested paths found."
  return 0
}
```

---

## Integration Points

### At `/acis init`

```markdown
After generating .acis-config.json:
1. Run validate_acis_paths
2. If errors, show user and ask to fix
3. If warnings, show user but continue
```

### At `/acis remediate`, `/acis extract`, `/acis discovery`

```markdown
Before writing any files:
1. Resolve output path using resolve_acis_path
2. Validate resolved path doesn't already exist with nested structure
3. Create parent directories if needed
4. Write file
```

### At `/acis audit`

```markdown
At REFLECT phase:
1. Run find_nested_acis_paths
2. If found, add to audit report as process issue
3. Recommend cleanup in APPLY phase
```

---

## Example: Preventing the Bug

### The Bug

```bash
# WRONG - config.paths.goals used twice
config_goals="docs/acis/goals"
output_path="$config_goals/$config_goals/$filename"
# Result: docs/acis/goals/docs/acis/goals/PR55-G1.json
```

### The Fix

```bash
# CORRECT - project root + config path + filename
project_root="$(pwd)"
config_goals="docs/acis/goals"
output_path="$project_root/$config_goals/$filename"
# Result: /path/to/project/docs/acis/goals/PR55-G1.json
```

---

## Detection Command for CI

Add to CI pipeline to catch nested paths:

```yaml
- name: Check for nested ACIS paths
  run: |
    if find . -type d -path "*docs/acis/*docs/acis*" 2>/dev/null | grep -q .; then
      echo "ERROR: Nested ACIS paths detected"
      find . -type d -path "*docs/acis/*docs/acis*"
      exit 1
    fi
    echo "No nested paths found"
```

---

## Runtime Hook Enforcement (ACTIVE)

ACIS uses Claude Code PreToolUse hooks to BLOCK invalid paths **before** files are written.

### Installation

Hooks are installed automatically by `/acis init`, or manually:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-hooks.sh" "${PROJECT_ROOT}"
```

### Hook Location

- **Validator Script**: `.claude/hooks/acis-path-validator.sh`
- **Configuration**: `.claude/settings.json`

### What Gets Blocked

| Pattern | Detection | Action |
|---------|-----------|--------|
| `docs/acis/goals/docs/acis/goals/...` | Nested ACIS path | **BLOCKED (exit 2)** |
| `docs/reviews/goals/docs/reviews/goals/...` | Nested reviews path | **BLOCKED (exit 2)** |
| `.acis-config.json` with `/absolute/path` | Absolute path in config | **BLOCKED (exit 2)** |
| `.acis-config.json` with `../traversal` | Path traversal in config | **BLOCKED (exit 2)** |
| Goal file not in `docs/acis/goals/` | Non-standard location | **WARNING (allowed)** |

### How It Works

1. Claude Code intercepts Edit/Write tool calls
2. Hook receives JSON input via stdin: `{"tool_input": {"file_path": "..."}}`
3. Validator checks path against rules
4. Exit code 0 = allow, Exit code 2 = block

### Testing the Hook

```bash
# Should BLOCK (nested path)
echo '{"tool_input":{"file_path":"docs/acis/goals/docs/acis/goals/test.json"}}' | \
  bash .claude/hooks/acis-path-validator.sh

# Should ALLOW (valid path)
echo '{"tool_input":{"file_path":"docs/acis/goals/PR55-G1.json"}}' | \
  bash .claude/hooks/acis-path-validator.sh
```

### Bypassing (NOT Recommended)

If you need to bypass hooks temporarily:

```bash
# Remove hook from settings.json (manual edit)
# Or rename the validator script
mv .claude/hooks/acis-path-validator.sh .claude/hooks/acis-path-validator.sh.disabled
```

**Warning**: Bypassing hooks removes all path validation protection.
