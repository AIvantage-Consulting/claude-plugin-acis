# ACIS Critical Review - Multi-Perspective Code Health Assessment

You are executing the ACIS Critical Review workflow. This command performs a targeted code health assessment, combining T1 pattern detection, multi-perspective agent analysis, cross-perspective correlation, and health score computation to produce a structured diagnostic report.

## Arguments

- `$ARGUMENTS` - Optional scope and flags: `[<scope>] [--depth shallow|medium|deep] [--lens <list>] [--generate-goals] [--severity <level>] [--skip-codex] [--compare <path>] [--json] [--output <path>]`

## Overview

```
/acis:critical-review [<scope>] [flags]
```

Scope can be:
- **File path**: `src/services/auth.ts`
- **Directory path**: `src/services/`
- **Module name**: `auth` (resolves via `find`)
- **Topic string**: `"error handling"` (resolves via `grep -rl`)
- **Omitted**: Full project scan (with warning)

---

## Phase 0: Initialization

### Config Loading (MANDATORY)

```bash
# 1. Load project config
if [ ! -f ".acis-config.json" ]; then
  echo "ERROR: No .acis-config.json found. Run /acis:init first."
  exit 1
fi

# 2. Validate paths (reuse acis.md Phase 0 logic)
# 3. Apply pluginDefaults for --skip-codex
# 4. Read plugin version
plugin_version=$(jq -r '.version' "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" 2>/dev/null || echo "unknown")
```

### Parse Arguments and Flags

```bash
# Parse $ARGUMENTS
scope=""
depth="medium"
lens_filter=""
generate_goals=false
severity_filter=""
skip_codex=false    # or from pluginDefaults
compare_path=""
json_output=false
output_dir="${config_paths_discovery}"

# Flag parsing (from $ARGUMENTS)
# --depth shallow|medium|deep
# --lens security,privacy,architecture (comma-separated)
# --generate-goals
# --severity critical|high|medium|low
# --skip-codex
# --compare <path-to-previous-findings.json>
# --json
# --output <path>
```

### Scope Resolution

Resolve scope to a file list:

```bash
resolve_scope() {
  local arg="$1"
  local scope_type=""
  local file_list=""

  if [ -z "$arg" ]; then
    # No argument: full project scan
    scope_type="project"
    echo "WARNING: No scope specified. Scanning full project. Consider narrowing with a path or topic."
    file_list=$(find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
      -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" \
      -not -path "*/build/*" -not -path "*/coverage/*" | head -200)

  elif [ -f "$arg" ]; then
    # Single file
    scope_type="file"
    file_list="$arg"

  elif [ -d "$arg" ]; then
    # Directory
    scope_type="directory"
    file_list=$(find "$arg" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
      -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" \
      -not -path "*/build/*" | head -200)

  elif find . -type d -name "$arg" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -1 | grep -q .; then
    # Module name (directory exists)
    scope_type="module"
    local module_dir
    module_dir=$(find . -type d -name "$arg" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -1)
    file_list=$(find "$module_dir" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
      -not -path "*/node_modules/*" | head -200)

  else
    # Topic string: grep for matching files
    scope_type="topic"
    file_list=$(grep -rlE "$arg" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
      . 2>/dev/null | grep -v node_modules | grep -v ".git/" | head -50)
    if [ -z "$file_list" ]; then
      echo "ERROR: No files matched topic '$arg'. Try a different search term."
      exit 1
    fi
  fi

  echo "$file_list"
}
```

### Count Files and LOC

```bash
file_count=$(echo "$file_list" | wc -l | tr -d ' ')
total_loc=0
while IFS= read -r f; do
  if [ -f "$f" ]; then
    loc=$(wc -l < "$f" 2>/dev/null | tr -d ' ')
    total_loc=$((total_loc + loc))
  fi
done <<< "$file_list"
```

### Generate Review ID

```bash
date_str=$(date +%Y-%m-%d)
scope_slug=$(echo "$scope_arg" | tr '/' '-' | tr ' ' '-' | tr -cd 'a-zA-Z0-9-' | head -c 30)
review_id="REVIEW-${date_str}-${scope_slug}"
```

---

## Phase 1: T1 Pattern Detection

**Reuses `${CLAUDE_PLUGIN_ROOT}/configs/assessment-lenses.json` directly.**

Load assessment lenses and run each pattern's grep against scope files.

```bash
# Load lenses config
lenses_config="${CLAUDE_PLUGIN_ROOT}/configs/assessment-lenses.json"

# Get lens IDs (optionally filtered by --lens flag)
if [ -n "$lens_filter" ]; then
  # Use only specified lenses
  lens_ids=$(echo "$lens_filter" | tr ',' '\n')
else
  # Use all lenses
  lens_ids=$(jq -r '.lenses | keys[]' "$lenses_config")
fi

# For each lens, for each pattern:
findings=()
finding_seq=0

for lens_id in $lens_ids; do
  patterns=$(jq -c ".lenses[\"$lens_id\"].patterns[]" "$lenses_config")

  while IFS= read -r pattern_json; do
    pattern_id=$(echo "$pattern_json" | jq -r '.id')
    pattern_regex=$(echo "$pattern_json" | jq -r '.pattern')
    severity=$(echo "$pattern_json" | jq -r '.severity')
    description=$(echo "$pattern_json" | jq -r '.description')
    replacement=$(echo "$pattern_json" | jq -r '.replacement')
    exclusions=$(echo "$pattern_json" | jq -r '.exclusions[]?' 2>/dev/null)

    # Run grep against scope files (respecting exclusions)
    while IFS= read -r file; do
      # Skip excluded files
      skip=false
      for excl in $exclusions; do
        case "$file" in
          *$excl*) skip=true; break ;;
        esac
      done
      [ "$skip" = true ] && continue

      # Grep for pattern
      matches=$(grep -nE "$pattern_regex" "$file" 2>/dev/null)
      if [ -n "$matches" ]; then
        while IFS= read -r match_line; do
          finding_seq=$((finding_seq + 1))
          line_num=$(echo "$match_line" | cut -d: -f1)
          match_text=$(echo "$match_line" | cut -d: -f2-)

          # Record finding: finding_id, lens, severity, pattern_id, file, line, match_text, description, recommendation
          # Store as structured data for Phase 4
        done <<< "$matches"
      fi
    done <<< "$file_list"
  done <<< "$patterns"
done
```

**Output**: Raw findings list with `source: "t1-pattern"`.

If `--depth shallow`: Skip to Phase 4 (health score computation).

---

## Phase 2: Multi-Perspective Deep Analysis (PARALLEL)

**Skipped at `--depth shallow`.**

### Internal Agents (single message, all parallel)

Spawn perspective agents based on scope content. Each agent receives:
- Scope file list
- Relevant T1 findings for their lens
- Representative code samples (first 100 lines of key files)

```
# ALL IN SINGLE MESSAGE FOR PARALLEL EXECUTION

Task(
  prompt="Critical review from security/privacy perspective.
    Scope: {SCOPE_DESCRIPTION} ({FILE_COUNT} files)
    Files: {FILE_LIST}
    T1 Security Findings: {SECURITY_T1_FINDINGS}
    Code Samples: {REPRESENTATIVE_CODE}

    Analyze for: Vulnerabilities, access control issues, data exposure, encryption gaps.
    Output: Structured findings with file:line, severity (critical/high/medium/low), description, recommendation.
    Also note positive security patterns observed.
    End with a health grade A-F for this perspective.",
  subagent_type="security-privacy"
)

Task(
  prompt="Critical review from architecture/design perspective.
    Scope: {SCOPE_DESCRIPTION} ({FILE_COUNT} files)
    Files: {FILE_LIST}
    T1 Architecture Findings: {ARCH_T1_FINDINGS}
    Code Samples: {REPRESENTATIVE_CODE}

    Analyze for: SOLID violations, coupling issues, layer boundary violations, design pattern misuse.
    Output: Structured findings with file:line, severity, description, recommendation.
    Also note positive architectural patterns observed.
    End with a health grade A-F for this perspective.",
  subagent_type="tech-lead"
)

Task(
  prompt="Critical review from testing perspective.
    Scope: {SCOPE_DESCRIPTION} ({FILE_COUNT} files)
    Files: {FILE_LIST}
    T1 Testing Findings: {TESTING_T1_FINDINGS}
    Code Samples: {REPRESENTATIVE_CODE}

    Analyze for: Coverage gaps, test quality issues, missing edge cases, test anti-patterns.
    Output: Structured findings with file:line, severity, description, recommendation.
    Also note positive testing patterns observed.
    End with a health grade A-F for this perspective.",
  subagent_type="test-lead"
)

Task(
  prompt="Critical review from performance perspective (performance-analyst).
    Scope: {SCOPE_DESCRIPTION} ({FILE_COUNT} files)
    Files: {FILE_LIST}
    T1 Performance Findings: {PERF_T1_FINDINGS}
    Code Samples: {REPRESENTATIVE_CODE}

    Analyze for: N+1 patterns, memory leaks, algorithm inefficiency, unnecessary re-renders.
    Output: Structured findings with file:line, severity, description, recommendation.
    Also note positive performance patterns observed.
    End with a health grade A-F for this perspective.",
  subagent_type="oracle"  # maps to performance-analyst in acis-perspectives.json
)

Task(
  prompt="Critical review from crash-resilience perspective.
    Scope: {SCOPE_DESCRIPTION} ({FILE_COUNT} files)
    Files: {FILE_LIST}
    T1 Maintainability Findings: {MAINT_T1_FINDINGS}
    Code Samples: {REPRESENTATIVE_CODE}

    Analyze for: Silent failures, empty catch blocks, missing error propagation, state corruption risks.
    Output: Structured findings with file:line, severity, description, recommendation.
    Also note positive resilience patterns observed.
    End with a health grade A-F for this perspective.",
  subagent_type="oracle"
)

Task(
  prompt="Critical review from operations & maintainability perspective (operations-maintenance).
    Scope: {SCOPE_DESCRIPTION} ({FILE_COUNT} files)
    Files: {FILE_LIST}
    T1 Maintainability Findings: {MAINT_T1_FINDINGS}
    T1 Operational-Costs Findings: {OPCOST_T1_FINDINGS}
    Code Samples: {REPRESENTATIVE_CODE}

    Analyze for: Code complexity, documentation gaps, dependency management, build/deploy friction,
    operational cost drivers, resource utilization patterns, logging/monitoring gaps.
    Covers both MAINTAINABILITY and OPERATIONAL-COSTS assessment lenses.
    Output: Structured findings with file:line, severity, description, recommendation.
    Also note positive maintainability/operational patterns observed.
    End with health grades A-F for maintainability AND operational-costs separately.",
  subagent_type="general-purpose"  # maps to operations-maintenance in acis-perspectives.json
)

Task(
  prompt="Critical review from end-user accessibility perspective (oracle-enduser).
    Scope: {SCOPE_DESCRIPTION} ({FILE_COUNT} files)
    Files: {FILE_LIST}
    T1 Accessibility Findings: {A11Y_T1_FINDINGS}
    Code Samples: {REPRESENTATIVE_CODE}

    Analyze for: Missing ARIA attributes, keyboard navigation gaps, screen reader compatibility,
    color contrast issues, focus management, semantic HTML usage, responsive design gaps.
    Covers the ACCESSIBILITY assessment lens.
    Output: Structured findings with file:line, severity, description, recommendation.
    Also note positive accessibility patterns observed.
    End with a health grade A-F for this perspective.",
  subagent_type="general-purpose"  # maps to oracle-enduser in acis-perspectives.json
)
```

### Conditional Agents

Activate only if scope matches `file_to_perspective_mapping` from `acis-perspectives.json`:

```bash
# Check if scope files match mobile/iOS/Android patterns
has_mobile=$(echo "$file_list" | grep -iE 'mobile|ios|android|native' | head -1)
if [ -n "$has_mobile" ]; then
  # Also spawn mobile-lead agent
fi

# Check if scope files match CI/config/deployment patterns
has_devops=$(echo "$file_list" | grep -iE 'config|deploy|docker|ci|cd' | head -1)
if [ -n "$has_devops" ]; then
  # Also spawn devops-lead agent
fi
```

### Codex Delegations (only at `--depth deep`)

**Skipped with `--skip-codex` or `--depth` != `deep`.**

```
# Codex Code Reviewer - adapted from codex-critical-review.md template
mcp__codex__codex(
  prompt="Code quality review for critical-review health assessment.
    Scope: {SCOPE_DESCRIPTION}
    Files: {FILE_LIST}
    T1 Findings: {ALL_T1_FINDINGS}
    Code Samples: {REPRESENTATIVE_CODE}

    Review for SOLID, DRY, algorithm quality, architecture conformance.
    Return structured findings with severity, file:line, description, recommendation.
    End with health grade A-F.",
  developer-instructions="Read @${CLAUDE_PLUGIN_ROOT}/templates/codex-critical-review.md",
  sandbox="read-only"
)

# Codex Architect
mcp__codex__codex(
  prompt="Architecture health assessment for critical review.
    Scope: {SCOPE_DESCRIPTION}
    Files: {FILE_LIST}
    Architecture Findings: {ARCH_T1_FINDINGS}

    Assess structural health: dependency direction, module boundaries, coupling level.
    Return structured findings and health grade A-F.",
  developer-instructions="Read @${CLAUDE_PLUGIN_ROOT}/templates/codex-architect-discovery.md",
  sandbox="read-only"
)

# Codex Security Analyst
mcp__codex__codex(
  prompt="Security health assessment for critical review.
    Scope: {SCOPE_DESCRIPTION}
    Files: {FILE_LIST}
    Security Findings: {SECURITY_T1_FINDINGS}

    Assess security posture: vulnerabilities, hardening opportunities.
    Return structured findings and health grade A-F.",
  developer-instructions="Read @${CLAUDE_PLUGIN_ROOT}/templates/codex-security-discovery.md",
  sandbox="read-only"
)
```

**Degraded Mode**: If Codex unavailable or `--skip-codex`:
- Skip all `mcp__codex__codex` calls
- Log: "Running without Codex - internal agents only"
- Continue with internal agent findings

---

## Phase 3: Cross-Perspective Correlation

**Skipped at `--depth shallow`.**

Adapted from `extract.md` Step 4.5 — "review sections" become "agent perspectives".

### Step 3.1: Build Perspective-Origin Index

Group findings by which agent(s) surfaced them. Two findings are considered "the same" if ANY match:

| Match Criterion | Example |
|-----------------|---------|
| Same pattern (pattern_id match) | Both reference `math-random` |
| Same file + overlapping line range (within 5 lines) | Both point to `auth.ts:45` and `auth.ts:48` |
| >80% keyword overlap in description | "Empty catch block" vs "Catch block swallows errors" |

### Step 3.2: Escalation Rules

| Condition | Action | Tag |
|-----------|--------|-----|
| Finding from ANY perspective + security-privacy | Auto-escalate to HIGH minimum | `escalated:security-perspective-overlap` |
| Finding from 3+ perspectives | Auto-escalate to HIGH minimum | `escalated:cross-perspective-3plus` |
| Finding from 2 perspectives (non-security) | Link findings, keep severity | `correlated:cross-perspective-2` |
| Finding from 1 perspective only | No action | -- |

```bash
# Apply cross-perspective correlation (Bash 3.2 compatible)
correlate_perspectives() {
  local finding_file="$1"
  local perspectives_json="$2"

  local perspective_count=$(echo "$perspectives_json" | jq -r 'length')
  local has_security=$(echo "$perspectives_json" | jq -r 'map(select(test("security"))) | length')
  local current_severity=$(jq -r '.severity' "$finding_file")
  local original_severity="$current_severity"

  local escalation_reason=""

  # Rule 1: Any perspective + security -> escalate to HIGH
  if [ "$has_security" -gt 0 ] && [ "$perspective_count" -gt 1 ]; then
    if [ "$current_severity" = "low" ] || [ "$current_severity" = "medium" ]; then
      current_severity="high"
      escalation_reason="security-perspective-overlap"
    fi
  fi

  # Rule 2: 3+ perspectives -> escalate to HIGH
  if [ "$perspective_count" -ge 3 ]; then
    if [ "$current_severity" = "low" ] || [ "$current_severity" = "medium" ]; then
      current_severity="high"
      escalation_reason="cross-perspective:${perspective_count}-perspectives"
    fi
  fi

  # Apply escalation: update finding severity and add tags
  if [ "$current_severity" != "$original_severity" ]; then
    jq --arg sev "$current_severity" \
       --arg orig "$original_severity" \
       --arg reason "$escalation_reason" \
       '.severity = $sev |
        .escalation_tags += ["escalated:" + $reason, "original-severity:" + $orig]' \
       "$finding_file" > "${finding_file}.tmp" && mv "${finding_file}.tmp" "$finding_file"
    echo "ESCALATED: $(jq -r '.finding_id' "$finding_file") $orig -> $current_severity ($escalation_reason)"
  fi
}
```

### Step 3.3: Security Keyword Detection

Reuse the same 40+ keyword list from `extract.md` Step 4.5.3:

```bash
SECURITY_KEYWORDS="auth|token|session|password|credential|secret|key|encrypt|decrypt|hash|salt|certificate|ssl|tls|oauth|jwt|api.key|access.control|permission|role|privilege|injection|xss|csrf|ssrf|sanitize|validate|escape|cors|helmet|rate.limit|brute.force|phishing|malware|vulnerability|exploit|payload|header|cookie|storage|cache|log.*sensitive|PHI|HIPAA|PII|GDPR"

# Scan all findings for security keywords
while IFS= read -r finding; do
  desc=$(echo "$finding" | jq -r '.description')
  if echo "$desc" | grep -qiE "$SECURITY_KEYWORDS"; then
    severity=$(echo "$finding" | jq -r '.severity')
    if [ "$severity" = "low" ] || [ "$severity" = "medium" ]; then
      # Escalate to HIGH, add tag
    fi
  fi
done
```

### Step 3.4: Link Related Findings

Adapted from `extract.md` Step 4.5.4. For findings correlated across 2+ perspectives, link them so remediation can batch related issues.

```bash
# Link related findings (Bash 3.2 compatible)
# Adapted from extract.md link_related_goals()
link_related_findings() {
  local index_file="$1"

  # For each group with multiple findings
  jq -c '.[] | select(.finding_ids | length > 1)' "$index_file" | while IFS= read -r group; do
    local finding_ids=$(echo "$group" | jq -r '.finding_ids[]')
    local perspectives=$(echo "$group" | jq -r '.perspectives | join(", ")')

    # Record correlation: finding_ids share the same underlying issue
    # These will be grouped in the findings JSON under correlation.groups[]
    echo "CORRELATED: $(echo "$group" | jq -r '.finding_ids | join(" + ")') (perspectives: $perspectives)"
  done
}
```

### Step 3.5: Correlation Summary

Adapted from `extract.md` Step 4.5.5. Generates the `correlation` object required by `critical-review-findings.schema.json`.

```bash
# Generate correlation summary (populates findings JSON "correlation" object)
generate_correlation_summary() {
  local all_findings="$1"  # path to aggregated findings JSON array

  jq '
    {
      total_findings_analyzed: length,
      escalated_count: [.[] | select(.escalation_tags[]? | test("^escalated:"))] | length,
      cross_perspective_groups: (
        group_by(.finding_id) |
        map(select(length > 1)) |
        map({
          pattern: .[0].description,
          perspectives: [.[].perspectives[]?] | unique,
          finding_ids: [.[].finding_id],
          action: (
            if ([.[].perspectives[]?] | unique | length) >= 3 then "escalated"
            elif ([.[].perspectives[]?] | unique | map(test("security")) | any) then "escalated"
            else "linked" end
          )
        })
      ),
      keyword_escalations: [.[] | select(.escalation_tags[]? | test("^escalated:security-keyword:"))] | length
    }
  ' "$all_findings"
}
```

---

## Phase 4: Health Score Computation + Report

### Density Calculation

```bash
# Per-lens density = sum(severity_weights) / lines_in_scope * 1000
#
# Severity weights (from assessment-lenses.json):
#   critical = 100
#   high     = 50
#   medium   = 20
#   low      = 5

compute_density() {
  local weighted_sum="$1"
  local loc="$2"

  if [ "$loc" -eq 0 ]; then
    echo "0"
    return
  fi

  # Bash integer math: multiply by 1000 first to avoid truncation
  echo $(( (weighted_sum * 1000) / loc ))
}

# Grade thresholds (density per kLOC):
#   A: 0-5
#   B: 6-15
#   C: 16-30
#   D: 31-60
#   F: 61+

density_to_grade() {
  local density="$1"
  if [ "$density" -le 5 ]; then echo "A"
  elif [ "$density" -le 15 ]; then echo "B"
  elif [ "$density" -le 30 ]; then echo "C"
  elif [ "$density" -le 60 ]; then echo "D"
  else echo "F"
  fi
}
```

### Overall Grade

```bash
# Overall = weighted average of per-lens densities
# Security and privacy lenses weighted 2x
# NOTE: Bash 3.2 does not support associative arrays (declare -A).
# Store per-lens densities in a flat variable naming convention:
#   lens_density_security=90
#   lens_density_privacy=20
# Use eval to read them dynamically.

# After Phase 1/2, store each lens density:
# eval "lens_density_${lens_id}=${density}"

compute_overall() {
  local total_weighted=0
  local total_weight=0

  for lens_id in $lens_ids; do
    # Bash 3.2 compatible: use eval to read dynamic variable name
    local density
    eval "density=\${lens_density_${lens_id}:-0}"
    local weight=1

    # Security/privacy weighted 2x
    case "$lens_id" in
      security|privacy) weight=2 ;;
    esac

    total_weighted=$((total_weighted + density * weight))
    total_weight=$((total_weight + weight))
  done

  if [ "$total_weight" -eq 0 ]; then
    echo "0"
    return
  fi

  echo $((total_weighted / total_weight))
}
```

### Generate Report

Use report template from `${CLAUDE_PLUGIN_ROOT}/templates/acis-critical-review-report.md`.

Output paths (using safe path resolution):
```bash
# Report output paths
report_file="$(resolve_acis_path "${config_paths_discovery}" "${review_id}.md")"
findings_file="$(resolve_acis_path "${config_paths_discovery}" "${review_id}-findings.json")"

# Validate no nested paths
case "$report_file" in
  *"docs/acis"*"docs/acis"*) echo "ERROR: Nested path detected"; exit 1 ;;
esac
```

### JSON Output (--json flag)

If `--json`, write findings JSON conforming to `${CLAUDE_PLUGIN_ROOT}/schemas/critical-review-findings.schema.json` instead of ASCII report.

### Findings JSON (always written)

Always write the machine-readable findings JSON alongside the report:

```bash
# Write findings JSON (conforming to critical-review-findings.schema.json)
cat > "$findings_file" << EOF
{
  "review_id": "$review_id",
  "scope": {
    "type": "$scope_type",
    "original_argument": "$scope_arg",
    "files": [...],
    "file_count": $file_count,
    "lines_of_code": $total_loc
  },
  "depth": "$depth",
  "health_scores": {
    "overall": { "grade": "$overall_grade", "density": $overall_density, ... },
    "per_lens": { ... }
  },
  "findings": [...],
  "correlation": { ... },
  "positive_patterns": [...],
  "metadata": {
    "acis_version": "$plugin_version",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "depth": "$depth",
    "lenses_used": [...],
    "agents_consulted": [...],
    "codex_used": $codex_used
  }
}
EOF
```

---

## Phase 5: Goal Generation (optional, `--generate-goals`)

**Only runs with `--generate-goals` flag.**

For findings at or above `--severity` threshold (default: high), generate goal files using `${CLAUDE_PLUGIN_ROOT}/schemas/acis-goal.schema.json`.

```bash
# Goal generation
if [ "$generate_goals" = true ]; then
  goal_seq=0

  for finding in $(echo "$findings" | jq -c '.[] | select(.severity == "critical" or .severity == "high")'); do
    goal_seq=$((goal_seq + 1))
    severity=$(echo "$finding" | jq -r '.severity' | tr '[:lower:]' '[:upper:]')
    lens=$(echo "$finding" | jq -r '.lens')
    desc=$(echo "$finding" | jq -r '.description' | tr ' ' '-' | tr -cd 'a-zA-Z0-9-' | head -c 30)

    goal_id="REVIEW-${severity}-$(printf '%03d' $goal_seq)-${desc}"
    goal_file="$(resolve_acis_path "${config_paths_goals}" "${goal_id}.json")"

    # Generate goal with:
    #   source.origin = "critical-review"
    #   source.lens = lens
    #   source.severity = severity
    #   detection from finding pattern/location
    #   remediation.guidance from finding recommendation
  done

  echo "Generated $goal_seq goal files in ${config_paths_goals}/"
fi
```

---

## Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--depth` | `shallow` (T1 only) / `medium` (T1+agents) / `deep` (T1+agents+Codex+correlation) | `medium` |
| `--lens` | Comma-separated lens filter (e.g., `security,privacy`) | all |
| `--generate-goals` | Create remediation goals from findings | OFF |
| `--severity` | Only report/generate goals for findings >= this level | all |
| `--skip-codex` | Skip Codex delegations | per `pluginDefaults` |
| `--compare <path>` | Compare against previous review findings JSON | none |
| `--json` | Machine-readable JSON output instead of ASCII report | OFF |
| `--output <path>` | Override output directory | `${config.paths.discovery}` |

---

## Output Artifacts

| Artifact | Path | When |
|----------|------|------|
| Health Report | `${config.paths.discovery}/REVIEW-{date}-{scope}.md` | Always |
| Findings JSON | `${config.paths.discovery}/REVIEW-{date}-{scope}-findings.json` | Always |
| Goal files | `${config.paths.goals}/REVIEW-{SEV}-{SEQ}-{slug}.json` | `--generate-goals` |

---

## Comparison Mode (`--compare`)

When `--compare <path>` is provided, load the previous findings JSON and compute deltas:

```bash
if [ -n "$compare_path" ] && [ -f "$compare_path" ]; then
  prev_review=$(jq -r '.review_id' "$compare_path")
  prev_grade=$(jq -r '.health_scores.overall.grade' "$compare_path")
  prev_density=$(jq -r '.health_scores.overall.density' "$compare_path")

  # Compare finding lists
  prev_finding_ids=$(jq -r '.findings[].finding_id' "$compare_path" | sort)
  curr_finding_ids=$(echo "$findings_json" | jq -r '.findings[].finding_id' | sort)

  # Compute deltas
  new_findings=$(comm -23 <(echo "$curr_finding_ids") <(echo "$prev_finding_ids") | wc -l)
  resolved_findings=$(comm -13 <(echo "$curr_finding_ids") <(echo "$prev_finding_ids") | wc -l)
  persistent_findings=$(comm -12 <(echo "$curr_finding_ids") <(echo "$prev_finding_ids") | wc -l)

  # Determine trend
  if [ "$curr_density" -lt "$prev_density" ]; then
    trend="improving"
  elif [ "$curr_density" -gt "$prev_density" ]; then
    trend="degrading"
  else
    trend="stable"
  fi
fi
```

---

## Integration Points

| Flow | Mechanism |
|------|-----------|
| critical-review -> remediate | `--generate-goals` creates goals in `${config.paths.goals}` |
| critical-review -> discovery | Report suggests `/acis:discovery` for low-grade lenses |
| critical-review -> critical-review | `--compare` flag tracks health improvement over time |
| audit-process reads reviews | Findings JSON discoverable by `REVIEW-` prefix in `${config.paths.discovery}` |
| status shows reviews | `REVIEW-` naming convention in discovery directory |

---

## Example Usage

```bash
# Quick T1-only scan of a directory
/acis:critical-review src/ --depth shallow

# Medium scan of a specific module
/acis:critical-review src/services/ --depth medium

# Deep scan with Codex of a single file
/acis:critical-review src/services/auth.ts --depth deep

# Filter to security and privacy lenses only
/acis:critical-review src/ --lens security,privacy

# Generate remediation goals for high+ findings
/acis:critical-review src/ --generate-goals --severity high

# Track improvement over time
/acis:critical-review src/ --compare docs/acis/discovery/REVIEW-2026-02-15-src-findings.json

# Machine-readable output
/acis:critical-review src/ --json

# Full project scan (caution: may be large)
/acis:critical-review

# Topic-based scan
/acis:critical-review "error handling" --depth medium
```

---

## Schema References

- Findings output: `${CLAUDE_PLUGIN_ROOT}/schemas/critical-review-findings.schema.json`
- Assessment lenses: `${CLAUDE_PLUGIN_ROOT}/configs/assessment-lenses.json`
- Agent perspectives: `${CLAUDE_PLUGIN_ROOT}/configs/acis-perspectives.json`
- Goal schema: `${CLAUDE_PLUGIN_ROOT}/schemas/acis-goal.schema.json`
- Report template: `${CLAUDE_PLUGIN_ROOT}/templates/acis-critical-review-report.md`
- Codex review template: `${CLAUDE_PLUGIN_ROOT}/templates/codex-critical-review.md`
