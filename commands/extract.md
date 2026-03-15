# ACIS Extract - Goal Extraction from PR Reviews

You are executing the ACIS extract command. This command transforms PR review comments into quantifiable, trackable remediation goals.

## Arguments

- `$ARGUMENTS` - PR number or review file path (e.g., `55` or `path/to/review.json`)

## Workflow

### Phase 0: TRUST BUT RE-VERIFY (Duplicate & Resolution Check)

Before creating new goals, check for existing resolutions and apply re-verification logic.

**Principle**: Don't skip entirely—downgrade priority with re-verification triggers.

#### Phase 0.1: Load Existing State

```bash
# Load config
config=$(cat .acis-config.json 2>/dev/null || echo '{}')
goals_dir=$(echo "$config" | jq -r '.paths.goals // "docs/acis/goals"')
resolutions_file=$(echo "$config" | jq -r '.paths.resolutions // "docs/acis/known-resolutions.json"')

# Load existing goals and resolutions
existing_goals=$(find "$goals_dir" -name "*.json" -type f 2>/dev/null)
known_resolutions=$(cat "$resolutions_file" 2>/dev/null || echo '{"resolutions":[]}')
```

#### Phase 0.2: Build Resolution Index

For each potential issue found, check against:

1. **Known Resolutions Registry** (`known-resolutions.json`)
   - Intentional exceptions: `by_design`, `mitigated`, `false_positive`, `wont_fix`

2. **Existing Goals** (in `goals_dir/*.json`)
   - Status: `achieved`, `verified_acceptable`, `blocked`, `deferred`

#### Phase 0.3: Re-verification Triggers (CRITICAL)

**DO NOT skip resolved items blindly. Apply these checks:**

| Condition | Action | Rationale |
|-----------|--------|-----------|
| File changed since resolution | **FULL RE-CHECK** | Regression risk |
| TTL expired (> N days) | **SPOT-CHECK** | Stale assumption |
| Low confidence verification | **RE-CHECK** | Weak evidence |
| Random 10% sample | **SPOT-CHECK** | Catch silent failures |

```bash
# Phase 0.3.1: Git Change Detection
check_file_changed() {
  local file_path="$1"
  local since_date="$2"
  local changes=$(git log --since="$since_date" --oneline -- "$file_path" 2>/dev/null | head -1)
  [ -n "$changes" ] && echo "CHANGED" || echo "UNCHANGED"
}

# Phase 0.3.2: TTL Expiration Check
check_ttl_expired() {
  local recheck_after="$1"
  local now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  [[ "$now" > "$recheck_after" ]] && echo "EXPIRED" || echo "VALID"
}

# Phase 0.3.3: Confidence-Based TTL
get_ttl_days() {
  local confidence="$1"
  case "$confidence" in
    "high")   echo 60 ;;
    "medium") echo 30 ;;
    "low")    echo 14 ;;
    *)        echo 30 ;;
  esac
}
```

#### Phase 0.4: Categorize Each Potential Issue

For each issue detected, categorize:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     RESOLUTION CHECK DECISION TREE                          │
└─────────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │  Issue Found    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
     ┌────────────┐  ┌────────────┐  ┌────────────┐
     │ In Known   │  │ In Existing│  │ New Issue  │
     │ Resolutions│  │ Goals      │  │            │
     └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
           │               │               │
           ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │File Changed?│ │File Changed?│ │CREATE NEW   │
    └──────┬──────┘ └──────┬──────┘ │GOAL         │
           │               │        └─────────────┘
     ┌─────┴─────┐   ┌─────┴─────┐
     │YES    NO  │   │YES    NO  │
     ▼           ▼   ▼           ▼
┌─────────┐┌────────┐┌─────────┐┌────────┐
│RE-CHECK ││TTL     ││RE-CHECK ││TTL     │
│MANDATORY││Expired?││MANDATORY││Expired?│
└─────────┘└───┬────┘└─────────┘└───┬────┘
               │                    │
         ┌─────┴─────┐        ┌─────┴─────┐
         │YES    NO  │        │YES    NO  │
         ▼           ▼        ▼           ▼
    ┌─────────┐┌────────┐┌─────────┐┌────────┐
    │SPOT     ││SOFT    ││SPOT     ││SOFT    │
    │CHECK    ││SKIP    ││CHECK    ││SKIP    │
    └─────────┘└────────┘└─────────┘└────────┘
```

#### Phase 0.5: Risk-Weighted Spot-Check Sampling

Instead of flat 10% sampling, use a risk-weighted formula:

```
rate = 0.10 × severity_multiplier × confidence_inverse × age_factor

Where:
  severity_multiplier:  critical=4.0, high=2.5, medium=1.0, low=0.5
  confidence_inverse:   high=0.5, medium=1.0, low=2.0
  age_factor:           days_since_verified / 30 (capped at 3.0, min 0.5)
  rate is clamped to [0.025, 1.0] (2.5% minimum, 100% maximum)

Examples:
  critical + low confidence + 90 days old = 0.10 × 4.0 × 2.0 × 3.0 = 2.4 → clamped to 1.0 (100% check)
  low + high confidence + 7 days old     = 0.10 × 0.5 × 0.5 × 0.23 = 0.006 → clamped to 0.025 (2.5%)
  medium + medium confidence + 30 days   = 0.10 × 1.0 × 1.0 × 1.0 = 0.10 (10%, same as before)
```

```bash
# Risk-weighted sampling for spot-checks
should_spot_check() {
  local severity="$1"     # critical|high|medium|low
  local confidence="$2"   # high|medium|low
  local days_old="$3"     # integer

  # Compute rate (simplified for Bash 3.2 - integer arithmetic)
  # Multiply by 1000 for precision, compare against random 0-999
  local sev_mult=10  # medium default (x1.0 * 10)
  case "$severity" in
    "critical") sev_mult=40 ;;
    "high")     sev_mult=25 ;;
    "low")      sev_mult=5 ;;
  esac

  local conf_inv=10  # medium default (x1.0 * 10)
  case "$confidence" in
    "high") conf_inv=5 ;;
    "low")  conf_inv=20 ;;
  esac

  # age_factor: days/30, capped at 30 (representing 3.0 * 10)
  local age_f=$((days_old * 10 / 30))
  [ "$age_f" -lt 5 ] && age_f=5
  [ "$age_f" -gt 30 ] && age_f=30

  # rate = (100 * sev * conf * age) / (10 * 10 * 10) = sev*conf*age/10
  local rate=$((sev_mult * conf_inv * age_f / 10))
  [ "$rate" -lt 25 ] && rate=25      # 2.5% floor
  [ "$rate" -gt 1000 ] && rate=1000  # 100% ceiling

  local random=$((RANDOM % 1000))
  [ $random -lt $rate ] && echo "YES" || echo "NO"
}

# Run spot-check: re-run detection command
run_spot_check() {
  local goal_file="$1"
  local detection_cmd=$(jq -r '.detection.primary_command // .detection.command' "$goal_file")
  local result=$(eval "$detection_cmd" 2>/dev/null)
  local expected=$(jq -r '.target.count // 0' "$goal_file")

  # Compare result to expected
  if [ "$result" = "$expected" ]; then
    echo "STILL_VALID"
  else
    echo "REGRESSION_DETECTED:$result"
  fi
}
```

#### Phase 0.6: Output Categories

After Phase 0, issues are categorized into:

| Category | Action | Show in Report |
|----------|--------|----------------|
| `NEW` | Create goal | Goals Extracted |
| `RE_CHECK_MANDATORY` | Create goal (file changed) | Re-checking (regression risk) |
| `SPOT_CHECK_FAILED` | Create goal (regression) | Regression Detected |
| `SPOT_CHECK_PASSED` | Log only | Spot-Check Verified |
| `SOFT_SKIP` | Log only | Soft-Skipped |
| `BLOCKED_RETRY` | Prompt user | Previously Blocked |

### Step 1: Load Configuration

```bash
# Load .acis-config.json (or use defaults)
if [ -f ".acis-config.json" ]; then
  config=$(cat .acis-config.json)
  goals_dir=$(echo "$config" | jq -r '.paths.goals // "docs/acis/goals"')
else
  goals_dir="docs/acis/goals"
fi

# Ensure goals directory exists
mkdir -p "$goals_dir"
```

### Step 2: Fetch PR Review Comments

**If argument is a PR number**:
```bash
pr_number="$ARGUMENTS"

# Fetch PR reviews via GitHub API
gh api repos/{owner}/{repo}/pulls/${pr_number}/reviews \
  --jq '.[] | {user: .user.login, body: .body, state: .state}' > /tmp/pr_reviews.json

# Fetch individual review comments (inline)
gh api repos/{owner}/{repo}/pulls/${pr_number}/comments \
  --jq '.[] | {user: .user.login, body: .body, path: .path, line: .line}' > /tmp/pr_comments.json

# Fetch general PR comments
gh api repos/{owner}/{repo}/issues/${pr_number}/comments \
  --jq '.[] | {user: .user.login, body: .body}' > /tmp/issue_comments.json
```

**If argument is a file path**:
```bash
# Read review comments from provided file
review_file="$ARGUMENTS"
if [ ! -f "$review_file" ]; then
  echo "ERROR: File not found: $review_file"
  exit 1
fi
```

### Step 3: Apply Assessment Lenses

Load assessment lenses from config:
```bash
lenses_file="${CLAUDE_PLUGIN_ROOT}/configs/assessment-lenses.json"
lenses=$(cat "$lenses_file")
```

Categorize each comment by lens:
- **security**: vulnerabilities, auth issues, injection risks
- **privacy**: PHI exposure, data leakage, compliance
- **performance**: inefficiencies, N+1, memory leaks
- **maintainability**: code smells, complexity, duplication
- **accessibility**: a11y gaps, screen reader issues
- **architecture**: layer violations, coupling, cohesion
- **testing**: coverage gaps, flaky tests, missing assertions
- **operational-costs**: resource usage, scaling issues

### Step 4: Analyze Comments with LLM

Use the extraction prompt template:
```
Read ${CLAUDE_PLUGIN_ROOT}/prompts/extract-goals-from-review.prompt.md
```

For each comment, determine if it represents a quantifiable issue:

**Include** (ALL severities - critical, high, medium, low):
- Specific code patterns (Math.random, console.log, any type)
- Code smells (empty catch, magic numbers)
- Security concerns (hardcoded secrets, injection)
- Performance issues (N+1, memory leaks)
- Accessibility gaps (missing alt, no keyboard nav)
- Recommendations with actionable patterns
- Notes identifying specific code issues
- Items marked "Risk: Low/Medium" with clear detection criteria

**Skip** (NOT extractable):
- Subjective opinions without patterns
- Questions or clarifications
- Praise or acknowledgments
- Already resolved in PR
- Comments without quantifiable detection criteria

**CRITICAL: Severity Does NOT Affect Extraction Eligibility**

| Old Behavior (WRONG) | New Behavior (CORRECT) |
|---------------------|------------------------|
| Extract only `critical` and `high` | Extract ALL severities |
| Skip `medium` and `low` | Include `medium` and `low` |
| Severity filters inclusion | Severity affects ORDER only |

Extraction should maximize **recall** (catch everything quantifiable).
Remediation considers **precision** (prioritize high-impact first).

**Framing Language Patterns** (extract these too):
- "Recommendation:" → extract as quantifiable if pattern exists
- "Note:" → extract if identifies specific code issue
- "Risk: Low/Medium" → extract with corresponding severity
- "⚠️" emoji → extract as medium severity minimum
- "Potential Bug" section → extract all quantifiable items
- "Performance Review" section → extract all quantifiable items
- "Code Quality" section → extract all quantifiable items

**Section-Agnostic Extraction**: Treat ALL sections equally. Whether an issue appears in "Issues", "Performance Review", "Code Quality", or "Specific Issues" section - if it's quantifiable, extract it. Section only affects the `lens` categorization in the goal file.

### Step 4.1: Auto-Generate Functional Checks

For each goal with `remediation.strategy` of `replace` or `refactor`, auto-generate `detection.functional_checks[]` entries based on project context:

#### Auto-Generation Rules by Strategy

| Strategy | Auto-Generated Checks | Condition |
|----------|----------------------|-----------|
| `replace` | `tsc --noEmit` (TypeScript compilation) | `tsconfig.json` exists in project |
| `replace` | Targeted test command for affected files | Test framework detected (jest, vitest, mocha) |
| `refactor` | Same as `replace` + behavior preservation check | Always |
| `remove` | Optional — removal rarely breaks functionality | At agent discretion |
| `add` | Recommended — test the new feature works | Test framework detected |
| `wrap` / `custom` | At agent discretion | — |

#### Project Detection

```bash
# Detect TypeScript project
has_typescript() {
  [ -f "tsconfig.json" ] && echo "YES" || echo "NO"
}

# Detect test framework
detect_test_framework() {
  if [ -f "package.json" ]; then
    local pkg=$(cat package.json)
    if echo "$pkg" | grep -q '"jest"'; then echo "jest"
    elif echo "$pkg" | grep -q '"vitest"'; then echo "vitest"
    elif echo "$pkg" | grep -q '"mocha"'; then echo "mocha"
    else echo "none"
    fi
  else
    echo "none"
  fi
}

# Detect test files for affected paths
find_related_tests() {
  local file_path="$1"
  local base_name=$(basename "$file_path" | sed 's/\.[^.]*$//')
  local dir_name=$(dirname "$file_path")

  # Check common test file patterns
  for pattern in "${base_name}.test" "${base_name}.spec" "${base_name}-test"; do
    found=$(find "$dir_name" -name "${pattern}.*" -type f 2>/dev/null | head -1)
    [ -n "$found" ] && echo "$found" && return
  done

  # Check __tests__ directory
  found=$(find "$dir_name/__tests__" -name "${base_name}.*" -type f 2>/dev/null | head -1)
  [ -n "$found" ] && echo "$found"
}
```

#### Example Auto-Generated Functional Checks

For a TypeScript project using Jest with `strategy: "replace"`:

```json
{
  "functional_checks": [
    {
      "check_id": "typescript_compiles",
      "description": "Verify replacement code compiles without type errors",
      "command": "npx tsc --noEmit 2>&1 | head -20; exit ${PIPESTATUS[0]}",
      "parse_type": "exit_code",
      "expected_exit_code": 0,
      "severity": "blocking",
      "tier": "T2"
    },
    {
      "check_id": "related_tests_pass",
      "description": "Verify tests for affected files still pass after replacement",
      "command": "npx jest --testPathPattern='SessionManager' --passWithNoTests 2>&1; exit $?",
      "parse_type": "exit_code",
      "expected_exit_code": 0,
      "severity": "blocking",
      "tier": "T2"
    }
  ]
}
```

#### Missing Functional Check Warning

If a goal has `remediation.strategy` of `replace` or `refactor` and no `functional_checks` could be auto-generated (no test framework, no TypeScript):

```
WARNING: Goal {id} has strategy="{strategy}" with grep-only verification.
Risk: Replacement code could be functionally broken but pass detection.
Recommendation: Add manual functional_checks to the goal file.
```

Log this warning in the extraction report (Step 7) under a new "Functional Verification Warnings" subsection.

### Step 4.5: Cross-Section Correlation & Security Keyword Escalation

After extracting all quantifiable items (Step 4), correlate items across review sections to catch severity misclassification and ensure security-related items are properly escalated.

#### Step 4.5.1: Build Section-Origin Index

Group extracted items by which review section(s) they appeared in. Two items are considered "the same" if ANY of these match:

| Match Criterion | Example |
|-----------------|---------|
| Same code pattern (detection.pattern) | Both reference `Math\.random` |
| Same file + overlapping line range | Both point to `auth.ts:45-60` |
| >80% keyword overlap in description | "HMAC not used for tokens" vs "Token signing lacks HMAC" |

```bash
# Build section index from extracted items (Bash 3.2 compatible)
# Each item has source_sections[] from the LLM extraction (Step 4)
section_index_file="/tmp/acis-section-index-PR${pr_number}.json"

# Aggregate: for each item, list all sections it appeared in
jq -s '
  group_by(.detection.pattern) |
  map({
    pattern: .[0].detection.pattern,
    description: .[0].detection.pattern_description,
    sections: [.[].source.source_sections[]?] | unique,
    items: [.[].id],
    severity: .[0].source.severity
  }) |
  map(select(.sections | length > 0))
' "$goals_dir"/PR${pr_number}-*.json > "$section_index_file"
```

#### Step 4.5.2: Cross-Section Correlation Rules

Apply escalation rules based on cross-section presence:

| Condition | Action | Tag |
|-----------|--------|-----|
| Item in ANY section + "Security Assessment" section | Auto-escalate to HIGH minimum | `escalated:security-section-overlap` |
| Item in 3+ sections (any type) | Auto-escalate to HIGH minimum | `escalated:cross-section-3plus` |
| Item in 2 sections (non-security) | Link via `metadata.related_goals`, keep severity | `correlated:cross-section-2` |
| Item in 1 section only | No action | — |

```bash
# Apply cross-section correlation rules (Bash 3.2 compatible)
correlate_cross_section() {
  local item_file="$1"
  local sections_json="$2"  # JSON array of section names

  local section_count=$(echo "$sections_json" | jq -r 'length')
  local has_security=$(echo "$sections_json" | jq -r 'map(select(test("(?i)security"))) | length')
  local current_severity=$(jq -r '.source.severity' "$item_file")
  local original_severity="$current_severity"
  local escalation_reason=""

  # Rule 1: Any section + Security Assessment → escalate to HIGH
  if [ "$has_security" -gt 0 ] && [ "$section_count" -gt 1 ]; then
    if [ "$current_severity" = "low" ] || [ "$current_severity" = "medium" ]; then
      current_severity="high"
      escalation_reason="security-section-overlap"
    fi
  fi

  # Rule 2: 3+ sections → escalate to HIGH
  if [ "$section_count" -ge 3 ]; then
    if [ "$current_severity" = "low" ] || [ "$current_severity" = "medium" ]; then
      current_severity="high"
      escalation_reason="cross-section:${section_count}-sections"
    fi
  fi

  # Apply escalation if needed
  if [ "$current_severity" != "$original_severity" ]; then
    jq --arg sev "$current_severity" \
       --arg orig "$original_severity" \
       --arg reason "$escalation_reason" \
       '.source.severity = $sev |
        .metadata.tags += ["escalated:" + $reason, "original-severity:" + $orig]' \
       "$item_file" > "${item_file}.tmp" && mv "${item_file}.tmp" "$item_file"
    echo "ESCALATED: $(jq -r '.id' "$item_file") $orig → $current_severity ($escalation_reason)"
  fi
}
```

#### Step 4.5.3: Security-Domain Keyword Detection

Scan all extracted items for security-domain keywords. Items matching any keyword that are below HIGH severity are auto-escalated.

**Security Keyword List**:
```
HMAC, crypto, salt, hash, encrypt, decrypt, token, key, auth, JWT,
OAuth, password, secret, credential, certificate, TLS, SSL, signature,
signing, PKI, RSA, AES, SHA, MD5, bcrypt, scrypt, argon2, PBKDF2,
session, cookie, CORS, CSRF, XSS, injection, sanitize, escape, validate
```

```bash
# Security keyword detection (Bash 3.2 compatible)
SECURITY_KEYWORDS="HMAC|crypto|salt|hash|encrypt|decrypt|token|key|auth|JWT|OAuth|password|secret|credential|certificate|TLS|SSL|signature|signing|PKI|RSA|AES|SHA|MD5|bcrypt|scrypt|argon2|PBKDF2|session|cookie|CORS|CSRF|XSS|injection|sanitize|escape|validate"

check_security_keywords() {
  local item_file="$1"
  local description=$(jq -r '.detection.pattern_description // .source.original_comment' "$item_file")
  local current_severity=$(jq -r '.source.severity' "$item_file")

  # Case-insensitive grep for security keywords
  matched_keyword=$(echo "$description" | grep -oiE "$SECURITY_KEYWORDS" | head -1)

  if [ -n "$matched_keyword" ] && [ "$current_severity" != "high" ] && [ "$current_severity" != "critical" ]; then
    jq --arg sev "high" \
       --arg orig "$current_severity" \
       --arg kw "$matched_keyword" \
       '.source.severity = $sev |
        .metadata.tags += ["escalated:security-keyword:" + $kw, "original-severity:" + $orig]' \
       "$item_file" > "${item_file}.tmp" && mv "${item_file}.tmp" "$item_file"
    echo "ESCALATED (keyword): $(jq -r '.id' "$item_file") $current_severity → high (keyword: $matched_keyword)"
  fi
}

# Run keyword detection on all extracted goals
for goal_file in "$goals_dir"/PR${pr_number}-*.json; do
  check_security_keywords "$goal_file"
done
```

#### Step 4.5.4: Populate Related Goals

For items appearing in 2+ sections, create bi-directional `metadata.related_goals` links:

```bash
# Link related goals (items correlated across sections)
link_related_goals() {
  local index_file="$1"
  local goals_dir="$2"

  # For each group with multiple items
  jq -c '.[] | select(.items | length > 1)' "$index_file" | while IFS= read -r group; do
    local item_ids=$(echo "$group" | jq -r '.items[]')

    # For each item in the group, add all OTHER items as related
    for item_id in $item_ids; do
      local item_file="${goals_dir}/${item_id}.json"
      [ -f "$item_file" ] || continue

      local related=$(echo "$group" | jq -r --arg self "$item_id" '.items | map(select(. != $self))')
      jq --argjson related "$related" \
         '.metadata.related_goals = (.metadata.related_goals + $related | unique)' \
         "$item_file" > "${item_file}.tmp" && mv "${item_file}.tmp" "$item_file"
    done
  done
}

link_related_goals "$section_index_file" "$goals_dir"
```

#### Step 4.5.5: Correlation Summary JSON

Write a correlation summary for the Step 7 report and Step 6.5 completeness check:

```bash
# Generate correlation summary
correlation_summary="${goals_dir}/correlation-summary-PR${pr_number}.json"

jq -s '
  {
    pr_number: '"$pr_number"',
    timestamp: (now | todate),
    total_items_analyzed: length,
    escalated_items: [.[] | select(.metadata.tags[]? | test("^escalated:"))],
    cross_section_groups: (
      group_by(.detection.pattern) |
      map(select(length > 1)) |
      map({
        pattern: .[0].detection.pattern_description,
        sections: [.[].source.source_sections[]?] | unique,
        goal_ids: [.[].id],
        action: (if ([.[].source.source_sections[]?] | unique | length) >= 3 then "escalated"
                 elif ([.[].source.source_sections[]?] | unique | map(test("(?i)security")) | any) then "escalated"
                 else "linked" end)
      })
    ),
    keyword_escalations: [.[] | select(.metadata.tags[]? | test("^escalated:security-keyword:"))] | length
  }
' "$goals_dir"/PR${pr_number}-*.json > "$correlation_summary"

echo "Correlation summary written to: $correlation_summary"
```

### Step 5: Generate Goal Files

**Extract ALL quantifiable issues, then sort by severity for prioritization order**:

```
Severity Order (for remediation prioritization):
1. critical  - Address immediately
2. high      - Address in current PR/sprint
3. medium    - Address soon
4. low       - Address when convenient

Note: ALL are extracted. Severity affects ORDER, not INCLUSION.
```

For each quantifiable issue, create a goal file:

```json
{
  "id": "PR{N}-G{X}-{short-name}",
  "source": {
    "reviewer": "codex|claude|gemini|human",
    "comment_id": "{comment_id}",
    "pr_number": {N},
    "lens": "{lens}",
    "severity": "critical|high|medium|low",
    "original_comment": "{comment text}"
  },
  "detection": {
    "pattern": "{regex}",
    "pattern_description": "{human readable}",
    "command": "{detection command}",
    "search_paths": ["packages/"],
    "file_types": ["*.ts", "*.tsx"],
    "exclusions": ["*.spec.ts", "*.test.ts", "__mocks__"]
  },
  "baseline": {
    "count": {measured},
    "measured_at": "{timestamp}",
    "command_output": "{raw output}"
  },
  "target": {
    "type": "zero|threshold|reduction",
    "count": 0,
    "allowed_exceptions": {
      "in_tests": true,
      "in_mocks": true,
      "in_comments": false,
      "patterns": []
    }
  },
  "complexity": {
    "tier": 1,
    "reasoning": "{why this tier}",
    "agents_required": ["security-privacy"],
    "phases": {
      "analyze": ["tech-lead"],
      "design": ["tech-lead"],
      "implement": ["mobile-lead"],
      "verify": ["test-lead"]
    },
    "requires_user_approval": false
  },
  "remediation": {
    "strategy": "replace|remove|refactor|add",
    "replacement": "{what to use instead}",
    "imports_required": [],
    "context_rules": [],
    "requires_tests": true,
    "five_whys_required": false,
    "manual_review_required": false,
    "guidance": "{step-by-step}"
  },
  "verification": {
    "command": "{same as detection or different}",
    "success_condition": "output == 0",
    "parse_output": "count|regex|json"
  },
  "schema_version": "2.14",
  "progress": {
    "current_count": null,
    "iterations": 0,
    "history": [],
    "status": "pending",
    "iteration_episodes": [],
    "complexity_evidence": [],
    "checkpoint": {
      "phase": "init",
      "iteration": 0,
      "critical_decisions": [],
      "active_constraints": [],
      "files_modified_cumulative": [],
      "metric_snapshot": {},
      "next_action": "Begin remediation"
    },
    "architectural_constraints": [],
    "five_whys_analyses": []
  },
  "metadata": {
    "created_at": "{timestamp}",
    "updated_at": "{timestamp}",
    "deferred_to": null,
    "related_goals": [],
    "tags": ["pr-{N}", "{lens}", "p{tier}"]
  }
}
```



### Step 5.5: COMMENT CHALLENGE (v2.15)

Two independent challenger agents evaluate each extracted goal before baseline measurement. This prevents blind acceptance of review comments by critically assessing factual accuracy, codebase awareness, contradictions, architecture alignment, cost-benefit ROI, and persona impact.

Skip with `--skip-challenge`. Force deep investigation on all goals with `--deep-challenge`.

#### Step 5.5.0: Skip Conditions

Skip this step entirely if ANY of:
- `--skip-challenge` flag is set
- `--dry-run` flag is set (challengers are heavyweight; dry-run should be fast)

If skipped, set `challenge.status = "unchallenged"` and `challenge.investigation_depth = "skipped"` on each goal:

```bash
for goal_file in "$goals_dir"/PR${pr_number}-*.json; do
  jq '.challenge = {"status": "unchallenged", "investigation_depth": "skipped"}' \
    "$goal_file" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "$goal_file"
done
```

#### Step 5.5.1: Determine Investigation Depth

For each goal, determine investigation depth based on the ESCALATED severity (post-Step 4.5):

```bash
determine_depth() {
  local goal_file="$1"
  local force_deep="$2"  # "true" if --deep-challenge

  if [ "$force_deep" = "true" ]; then
    echo "deep"
    return
  fi

  local severity=$(jq -r '.source.severity' "$goal_file")
  local tier=$(jq -r '.complexity.tier // 1' "$goal_file")

  if [ "$severity" = "critical" ] || [ "$severity" = "high" ]; then
    echo "deep"
  elif [ "$tier" -ge 2 ]; then
    echo "deep"
  else
    echo "light"
  fi
}
```

#### Step 5.5.2: Launch Challengers (Parallel)

For each goal file, launch BOTH challengers simultaneously:

```
Technical Challenger:
  Task(
    prompt="Challenge this goal for technical validity.
      Goal: @{goal_file}
      All Goals: @{goals_dir}/PR{N}-*.json
      Investigation depth: {light|deep}
      Return: challenge-result.schema.json format",
    subagent_type="acis-technical-challenger"
  )

Strategic Challenger:
  Task(
    prompt="Challenge this goal for strategic value.
      Goal: @{goal_file}
      All Goals: @{goals_dir}/PR{N}-*.json
      Config: @.acis-config.json
      Investigation depth: {light|deep}
      Return: challenge-result.schema.json format",
    subagent_type="acis-strategic-challenger"
  )
```

Both agents return `challenge-result.schema.json`-conformant JSON. Each populates only its own dimensions (technical: factual_accuracy, codebase_awareness, contradictions, architecture_alignment; strategic: cost_benefit, persona_impact).

#### Step 5.5.3: Merge Verdicts

Apply the verdict precedence table. **REJECT requires unanimous agreement; any dissent preserves the goal.**

| Technical | Strategic | Result |
|-----------|-----------|--------|
| ACCEPT | ACCEPT | ACCEPT |
| ACCEPT | DOWNGRADE | DOWNGRADE |
| ACCEPT | LOW-ROI | LOW-ROI |
| ACCEPT | REJECT | LOW-ROI |
| DOWNGRADE | ACCEPT | DOWNGRADE |
| DOWNGRADE | DOWNGRADE | DOWNGRADE (take lower severity) |
| DOWNGRADE | LOW-ROI | LOW-ROI |
| DOWNGRADE | REJECT | DOWNGRADE |
| LOW-ROI | ACCEPT | LOW-ROI |
| LOW-ROI | DOWNGRADE | LOW-ROI |
| LOW-ROI | LOW-ROI | LOW-ROI |
| LOW-ROI | REJECT | LOW-ROI |
| REJECT | ACCEPT | LOW-ROI |
| REJECT | DOWNGRADE | DOWNGRADE |
| REJECT | LOW-ROI | LOW-ROI |
| REJECT | REJECT | REJECT (unanimous) |

When merging dimensions, combine both challengers' dimension objects:
```bash
merged_dimensions=$(echo "$tech_result" "$strat_result" | jq -s '.[0].dimensions + .[1].dimensions')
```

#### Step 5.5.4: Apply Verdicts

For each goal, based on merged verdict:

**ACCEPT**: No changes to goal. Record challenge data.

```bash
jq '.challenge.status = "accepted"' "${goal_file}" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "${goal_file}"
```

**DOWNGRADE**:
1. Record `challenge.original_severity` = current severity
2. Update `source.severity` to the lower of the two suggested severities
3. Add tag `challenger-downgraded`

```bash
jq --arg orig_sev "$current_severity" --arg new_sev "$lower_severity" \
  '.challenge.status = "downgraded" |
   .challenge.original_severity = $orig_sev |
   .source.severity = $new_sev |
   .metadata.tags += ["challenger-downgraded"]' \
  "${goal_file}" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "${goal_file}"
```

**LOW-ROI**:
1. Record `challenge.roi_analysis` and `challenge.persona_impact` from strategic challenger
2. Add tag `challenger-low-roi`
3. Goal is KEPT — surfaced in extraction report for user awareness

```bash
jq --argjson roi "$roi_json" --argjson persona "$persona_json" \
  '.challenge.status = "low_roi" |
   .challenge.roi_analysis = $roi |
   .challenge.persona_impact = $persona |
   .metadata.tags += ["challenger-low-roi"]' \
  "${goal_file}" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "${goal_file}"
```

**REJECT** (unanimous):
- If severity is **critical/high** → SAFETY GATE (prompt user):

```
CHALLENGE GATE: Both challengers recommend REJECT for {goal_id} (severity: {severity})
  Technical: {technical_reasoning}
  Strategic: {strategic_reasoning}
  Confirm rejection? [R]eject / [K]eep / [D]owngrade
```

User decision overrides the challengers.

- If severity is **medium/low** → Auto-reject:

```bash
jq '.progress.status = "rejected" |
    .challenge.status = "rejected" |
    .metadata.tags += ["challenger-rejected"]' \
  "${goal_file}" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "${goal_file}"
```

Goal file is KEPT on disk (not deleted) for future re-scan.

#### Step 5.5.5: Record Challenge Results

For each goal, write the merged challenge data:

```bash
jq --arg status "$merged_verdict" \
   --arg tech_v "$tech_verdict" --arg tech_r "$tech_reasoning" \
   --arg strat_v "$strat_verdict" --arg strat_r "$strat_reasoning" \
   --arg depth "$investigation_depth" \
   --argjson dims "$merged_dimensions" \
  '.challenge += {
    "status": $status,
    "technical_verdict": $tech_v,
    "technical_reasoning": $tech_r,
    "strategic_verdict": $strat_v,
    "strategic_reasoning": $strat_r,
    "investigation_depth": $depth,
    "challenged_at": (now | todate)
  } | .challenge.dimensions = $dims' \
  "${goal_file}" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "${goal_file}"
```

Include `roi_analysis`, `persona_impact`, and `contradictions` when present in challenger results.


### Step 6: Validate & Measure Baselines

#### Step 6.1: Detection Command Dry-Run Validation

Before measuring baselines, validate each detection command will work correctly:

For each generated goal file, validate `detection.command`:

1. **Execute in subshell**: Run command, capture exit code, stdout, stderr
2. **Validate exit code**: Must be 0. If non-zero → WARN and mark goal as `needs_review`
3. **Validate stderr**: Must be empty. If non-empty → WARN: "Detection command produced stderr"
4. **Validate stdout**: Must be non-empty. If empty → WARN: "Detection command produced no output — baseline will be 0"
5. **Validate output format**: stdout must be parseable as integer/float (not prose)
6. **Validate Bash 3.2 compatibility**: Scan command for forbidden constructs:
   - `declare -A`, `mapfile`, `readarray`, `${var,,}`, `${var^^}`, `shopt -s globstar` → REJECT goal with error

Goals with invalid detection commands are flagged in the extraction report as `DETECTION_INVALID`.

#### Step 6.2: Measure Baselines

For each validated goal, run the detection command to establish baseline:

```bash
for goal_file in "$goals_dir"/PR${pr_number}-*.json; do
  detection_cmd=$(jq -r '.detection.command' "$goal_file")
  baseline=$(eval "$detection_cmd" 2>/dev/null || echo "0")

  # Update baseline in goal file
  jq --arg count "$baseline" \
     --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '.baseline.count = ($count | tonumber) |
      .baseline.measured_at = $timestamp' \
     "$goal_file" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "$goal_file"
done
```


### Step 6.3: Evidence-Based Complexity Estimation (v2.14)

After baseline measurement, compute complexity tier using evidence-based heuristics:

```bash
# Evidence-based complexity estimation (Bash 3.2 compatible)
compute_evidence_tier() {
  local goal_file="$1"
  local baseline_count="$2"

  local strategy=$(jq -r '.remediation.strategy // "replace"' "$goal_file")
  local search_paths=$(jq -r '.detection.search_paths | length' "$goal_file")
  local metric_count=$(jq -r '.detection.verifiable_metrics | length' "$goal_file")
  local check_count=$(jq -r '.detection.functional_checks | length' "$goal_file" 2>/dev/null || echo "0")

  local tier=1
  local evidence_type="initial_assessment"
  local details=""

  # Rule 1: High baseline count → higher tier
  if [ "$baseline_count" -gt 50 ]; then
    tier=3
    details="Baseline count ${baseline_count} > 50"
  elif [ "$baseline_count" -gt 15 ]; then
    tier=2
    details="Baseline count ${baseline_count} > 15"
  fi

  # Rule 2: Multiple search paths → complexity
  if [ "$search_paths" -gt 3 ] && [ "$tier" -lt 2 ]; then
    tier=2
    details="Search paths: ${search_paths} > 3"
  fi

  # Rule 3: Multiple metrics → complexity
  if [ "$metric_count" -gt 2 ] && [ "$tier" -lt 2 ]; then
    tier=2
    details="Verifiable metrics: ${metric_count} > 2"
  fi

  # Rule 4: Strategy-based escalation
  if [ "$strategy" = "refactor" ] || [ "$strategy" = "custom" ]; then
    [ "$tier" -lt 2 ] && tier=2
    details="${details}; Strategy: ${strategy}"
  fi

  # Record initial complexity evidence
  jq --arg tier "$tier" --arg details "$details"     '.complexity.tier = ($tier | tonumber) |
     .progress.complexity_evidence += [{
       "evidence_id": "ce-001",
       "iteration": 0,
       "type": "initial_assessment",
       "details": ("Evidence-based extraction estimate: " + $details),
       "values": {"threshold": 0, "actual": '"$baseline_count"'},
       "recommendation": "continue",
       "original_tier": ($tier | tonumber),
       "recommended_tier": ($tier | tonumber)
     }]' "$goal_file" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "$goal_file"

  echo "$tier"
}

# Apply evidence-based tier estimation to each goal
for goal_file in "$goals_dir"/PR${pr_number}-*.json; do
  baseline=$(jq -r '.baseline.count // 0' "$goal_file")
  evidence_tier=$(compute_evidence_tier "$goal_file" "$baseline")
  echo "  Tier: ${evidence_tier} (evidence-based) — $(jq -r '.id' "$goal_file")"
done
```

This replaces the static heuristic with runtime evidence that gets recorded in the goal file for later escalation decisions.

### Step 6.5: Extraction Completeness Check

After generating and validating goals, verify extraction completeness by comparing the total quantifiable items identified in Step 4 against the goals successfully generated in Step 5.

#### Step 6.5.1: Count Items vs Goals

```bash
# Count total quantifiable items from Step 4 (LLM extraction output)
total_items=$(jq -r 'length' /tmp/acis-extracted-items-PR${pr_number}.json 2>/dev/null || echo "0")

# Count generated goal files
generated_goals=$(find "$goals_dir" -name "PR${pr_number}-*.json" -type f 2>/dev/null | wc -l | tr -d ' ')

# Adjust for challenged rejections (v2.15)
rejected_count=$(find "$goals_dir" -name "PR${pr_number}-*.json" -exec jq -r 'select(.progress.status == "rejected") | .id' {} \; 2>/dev/null | wc -l | tr -d ' ')
effective_goals=$((generated_goals - rejected_count))

# Compute coverage percentage (Bash 3.2 integer arithmetic)
if [ "$total_items" -gt 0 ]; then
  coverage_pct=$((effective_goals * 100 / total_items))
else
  coverage_pct=100
fi
```

#### Step 6.5.2: Identify Unmatched Items

For items that were identified but have no corresponding goal file, classify the reason:

| Reason | Description |
|--------|-------------|
| `dedup_removed` | Item was deduplicated against an existing resolution in Phase 0 |
| `detection_invalid` | Detection command failed dry-run validation in Step 6.1 |
| `severity_filtered` | Item was filtered out by `--severity` flag |
| `generation_error` | Goal file generation failed (JSON error, missing fields) |
| `challenged_rejected` | Goal rejected by unanimous challenger verdict (v2.15) |

```bash
# Build unmatched items list
unmatched_items="[]"

# Compare extracted items against generated goals
jq -c '.[]' /tmp/acis-extracted-items-PR${pr_number}.json 2>/dev/null | while IFS= read -r item; do
  item_id=$(echo "$item" | jq -r '.id')
  goal_file="${goals_dir}/${item_id}.json"

  if [ ! -f "$goal_file" ]; then
    # Determine reason
    reason="generation_error"  # default

    # Check if it was deduped
    if echo "$item" | jq -e '.resolution_status' > /dev/null 2>&1; then
      reason="dedup_removed"
    fi

    # Check if detection was invalid
    if echo "$item" | jq -e '.detection_invalid' > /dev/null 2>&1; then
      reason="detection_invalid"
    fi

    # Check if severity-filtered
    if echo "$item" | jq -e '.severity_filtered' > /dev/null 2>&1; then
      reason="severity_filtered"
    fi

    echo "{\"item_id\":\"$item_id\",\"description\":$(echo "$item" | jq '.detection.pattern_description'),\"reason\":\"$reason\",\"source_section\":$(echo "$item" | jq '.source.source_sections[0] // "unknown"'),\"original_severity\":$(echo "$item" | jq '.source.severity')}"
  fi
done | jq -s '.' > /tmp/acis-unmatched-PR${pr_number}.json
```

#### Step 6.5.3: Write Extraction Coverage File

```bash
# Load correlation data if available
correlation_file="${goals_dir}/correlation-summary-PR${pr_number}.json"
escalated_count=0
if [ -f "$correlation_file" ]; then
  escalated_count=$(jq -r '.keyword_escalations + (.escalated_items | length)' "$correlation_file" 2>/dev/null || echo "0")
fi

# Write extraction coverage file
coverage_file="${goals_dir}/extraction-coverage-PR${pr_number}.json"

cat > "$coverage_file" << COVERAGE_EOF
{
  "pr_number": ${pr_number},
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "acis_version": "2.12.0",
  "total_items": ${total_items},
  "extracted_items": ${generated_goals},
  "coverage_pct": ${coverage_pct},
  "escalated_items": ${escalated_count},
  "unmatched_items": $(cat /tmp/acis-unmatched-PR${pr_number}.json 2>/dev/null || echo "[]"),
  "coverage_status": "$(
    if [ "$coverage_pct" -eq 100 ]; then echo "COMPLETE"
    elif [ "$coverage_pct" -ge 90 ]; then echo "ACCEPTABLE"
    elif [ "$coverage_pct" -ge 75 ]; then echo "INCOMPLETE"
    else echo "CRITICAL"
    fi
  )"
}
COVERAGE_EOF

echo "Extraction coverage written to: $coverage_file"
```

#### Step 6.5.4: Warn on Incomplete Coverage

```bash
if [ "$coverage_pct" -lt 100 ]; then
  echo ""
  echo "⚠️  EXTRACTION COVERAGE: ${coverage_pct}% (${generated_goals} of ${total_items} items)"
  echo "    Unmatched items saved to: /tmp/acis-unmatched-PR${pr_number}.json"
  echo "    Coverage file: ${coverage_file}"
  if [ "$coverage_pct" -lt 90 ]; then
    echo "    STATUS: INCOMPLETE — review unmatched items before proceeding to remediation"
  fi
fi
```

### Step 7: Present Extraction Report

Output summary:

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  ACIS Goal Extraction Report - PR #{pr_number}                               ║
║  {timestamp}                                                                  ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  🔍 RE-VERIFICATION SUMMARY (Phase 0)                                        ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  Checked {N} prior resolutions against re-verification triggers:             ║
║    • File changes detected:     2 → mandatory re-check                       ║
║    • TTL expired:               1 → spot-check triggered                     ║
║    • Random 10% sample:         3 → spot-checked (all passed)                ║
║    • Still valid (soft-skip):   8 → logged, not re-extracted                 ║
║                                                                              ║
║  📥 COMMENTS ANALYZED: {total}                                               ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  • Codex: {count}                                                            ║
║  • Claude: {count}                                                           ║
║  • Human: {count}                                                            ║
║                                                                              ║
║  📊 GOALS EXTRACTED: {count}                                                 ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  ┌────────────────────────────┬──────────┬──────────┬─────────┬──────────┐  ║
║  │ Goal ID                    │ Lens     │ Severity │Baseline │ Target   │  ║
║  ├────────────────────────────┼──────────┼──────────┼─────────┼──────────┤  ║
║  │ PR55-G1-uninit-session     │ security │ critical │ 12      │ 0        │  ║
║  │ PR55-G2-math-random        │ security │ high     │ 47      │ 0        │  ║
║  │ PR55-G3-race-condition     │ perform  │ medium   │ 3       │ 0        │  ║
║  │ PR55-G4-console-log        │ maintain │ low      │ 89      │ 0        │  ║
║  └────────────────────────────┴──────────┴──────────┴─────────┴──────────┘  ║
║                                                                              ║
║  (Sorted by severity: critical → high → medium → low)                        ║
║                                                                              ║
║  COMMENT CHALLENGE RESULTS: {challenged_count}                               ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  ┌─────────────────────────────────┬──────────┬──────────┬─────────────────┐ ║
║  │ Goal ID                         │ Technical│ Strategic│ Final Verdict   │ ║
║  ├─────────────────────────────────┼──────────┼──────────┼─────────────────┤ ║
║  │ {goal_id}                       │ {t_verd} │ {s_verd} │ {final_verdict} │ ║
║  └─────────────────────────────────┴──────────┴──────────┴─────────────────┘ ║
║                                                                              ║
║  Accepted: {N}  Downgraded: {N}  Low-ROI: {N}  Rejected: {N}                ║
║                                                                              ║
║  LOW-ROI ITEMS (review recommended):                                         ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║  {goal_id}                                                                   ║
║    ROI: effort={effort}, impact={impact}                                     ║
║    Tech debt: {tech_debt_factor}                                             ║
║    Persona impact: {persona_notes}                                           ║
║                                                                              ║
║  REJECTED ITEMS: {rejected_count}                                            ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║  {goal_id}: {technical_reasoning} / {strategic_reasoning}                    ║
║                                                                              ║
║                                                                              ║
║  🔗 CROSS-SECTION CORRELATIONS: {correlation_count}                          ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  ┌──────────────────────────┬──────────────────────────┬───────────────────┐ ║
║  │ Pattern                  │ Sections Found In        │ Action            │ ║
║  ├──────────────────────────┼──────────────────────────┼───────────────────┤ ║
║  │ HMAC token signing       │ Security Assessment,     │ ESCALATED med→hi  │ ║
║  │                          │ Code Duplication,        │ (security-keyword │ ║
║  │                          │ Specific Issues          │  + 3 sections)    │ ║
║  │ Unused imports           │ Code Quality,            │ LINKED (2 sect)   │ ║
║  │                          │ Maintainability          │                   │ ║
║  └──────────────────────────┴──────────────────────────┴───────────────────┘ ║
║                                                                              ║
║  Keyword escalations: {keyword_count} items matched security keywords        ║
║  Section-overlap escalations: {section_count} items in 3+ sections           ║
║                                                                              ║
║  📈 EXTRACTION COMPLETENESS: {coverage_pct}% ({extracted}/{total} items)     ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  Status: {COMPLETE|ACCEPTABLE|INCOMPLETE|CRITICAL}                           ║
║  Coverage file: {goals_dir}/extraction-coverage-PR{N}.json                   ║
║                                                                              ║
║  {IF_UNMATCHED}                                                              ║
║  Unmatched items ({unmatched_count}):                                        ║
║    • {item_1}: {reason} (from "{section}")                                   ║
║    • {item_2}: {reason} (from "{section}")                                   ║
║  {END_IF}                                                                    ║
║                                                                              ║
║  🔄 RE-CHECKED (file changes detected): {count}                              ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  • PR55-G4-deprecated-api (was achieved 2026-01-10)                          ║
║    ↳ REASON: File modified on 2026-01-25 (15 days after resolution)         ║
║    ↳ ACTION: Re-created goal for verification                                ║
║                                                                              ║
║  ⏰ RE-CHECKED (TTL expired): {count}                                        ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  • PR42-G5-unsafe-cast (was achieved 2025-12-15, medium confidence)          ║
║    ↳ REASON: TTL expired (30-day limit reached on 2026-01-14)               ║
║    ↳ ACTION: Spot-check triggered, detection command re-run                  ║
║    ↳ RESULT: Still valid (0 instances) — resolution extended to 2026-02-27 ║
║                                                                              ║
║  • KR-002 metadata.status (by_design, verified 2025-12-01)                   ║
║    ↳ REASON: TTL expired (60-day limit reached on 2026-01-30)               ║
║    ↳ ACTION: Spot-check required — verify mitigations still apply           ║
║                                                                              ║
║  ⚠️ REGRESSIONS DETECTED (spot-check failed): {count}                        ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  • PR42-G2-hardcoded-secret (was achieved, now showing 2 instances)         ║
║    ↳ Was: 0, Now: 2 — goal re-opened                                         ║
║                                                                              ║
║  ✅ SPOT-CHECK VERIFIED: {count}                                             ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  • PR41-G1-sql-injection (sampled, still at 0 instances)                    ║
║                                                                              ║
║  ⏭️ SOFT-SKIPPED (previously resolved, no changes): {count}                  ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  • console.log in service-worker.js (KR-001, by_design, verified 2026-01-15)║
║    ↳ Recheck scheduled: 2026-02-15 or on file modification                   ║
║  • PR50-G3-any-type (achieved 2026-01-20, high confidence)                  ║
║    ↳ Recheck scheduled: 2026-03-20                                           ║
║                                                                              ║
║  ⏭️ SKIPPED COMMENTS: {count}                                                ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  • Subjective/Opinion: {count}                                               ║
║  • Questions: {count}                                                        ║
║                                                                              ║
║  📁 Files Created:                                                           ║
║    docs/acis/goals/PR55-G1-math-random.json                                 ║
║    docs/acis/goals/PR55-G2-uninit-session.json                              ║
║    docs/acis/goals/PR55-G3-console-log.json                                 ║
║                                                                              ║
║  🎯 NEXT STEPS:                                                              ║
║    1. Review generated goals: /acis:status goals                            ║
║    2. Start remediation: /acis:remediate docs/acis/goals/PR55-G1-*.json    ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Flags

| Flag | Description |
|------|-------------|
| `--dry-run` | Analyze and show what would be extracted, don't create files |
| `--lens <lens>` | Filter to specific assessment lens |
| `--severity <level>` | **OPTIONAL FILTER**: Only extract goals >= this severity. Default: extract ALL severities |
| `--reviewer <name>` | Filter by reviewer name |
| `--output-dir <path>` | Override goals output directory |
| `--skip-baseline` | Skip baseline measurement (faster, fill in later) |
| `--json` | Output raw JSON instead of formatted report |
| **Re-verification Flags** | |
| `--no-duplicate-check` | Skip Phase 0 entirely (extract all, ignore prior resolutions) |
| `--force-recheck` | Re-check ALL previously resolved items (ignore TTL/file-change logic) |
| `--show-soft-skipped` | Show detailed list of all soft-skipped items |
| `--spot-check-percent N` | Override spot-check sampling rate (default: 10) |
| `--ttl-override N` | Override TTL days for all confidence levels |
| `--update-registry` | Prompt to add new items to known-resolutions.json |
| `--recheck-blocked` | Include previously blocked goals for re-attempt |
| **Challenge Flags** | |
| `--skip-challenge` | Skip Step 5.5 comment challenge (trust reviewer completely) |
| `--deep-challenge` | Force deep investigation on ALL goals (not just critical/high) |

### Default Behavior (No Flags)

```
/acis extract 55
```

Extracts ALL quantifiable issues regardless of severity:
- ✅ critical issues
- ✅ high issues
- ✅ medium issues
- ✅ low issues

Goals are sorted by severity for remediation prioritization, but ALL are extracted.

### Filtered Behavior (With --severity)

```
/acis extract 55 --severity high
```

Only extracts issues with severity >= high:
- ✅ critical issues
- ✅ high issues
- ❌ medium issues (filtered out)
- ❌ low issues (filtered out)

Use this only when you intentionally want to defer low-priority items.

## Quality Criteria

Only extract goals that are:

- **Measurable**: Can be verified with a shell command
- **Actionable**: Clear path to remediation
- **Specific**: Precise pattern, not vague
- **Valuable**: Addresses real code quality issue

## Complexity Tiers

Automatically assign complexity tier based on:

| Tier | Criteria | Example |
|------|----------|---------|
| 1 | Single pattern, find-replace | Math.random → crypto |
| 2 | Context-aware replacement | Different fix per use case |
| 3 | Architecture changes needed | Layer violations |
| 4 | Design decisions required | Dual-CEO validation needed |

## Examples

```bash
# Extract goals from PR #55
/acis:extract 55

# Extract only security issues
/acis:extract 55 --lens security

# Dry run to preview
/acis:extract 55 --dry-run

# Extract from local review file
/acis:extract reviews/pr55-review.json

# Extract high/critical only
/acis:extract 55 --severity high

# JSON output for automation
/acis:extract 55 --json > extracted-goals.json
```

## Integration with Other Commands

After extraction:
1. **Review**: `/acis:status goals` - See all extracted goals
2. **Prioritize**: Goals sorted by severity × complexity
3. **Remediate**: `/acis:remediate <goal>` - Start TDD loop
4. **Track**: `/acis:status` - Monitor progress
