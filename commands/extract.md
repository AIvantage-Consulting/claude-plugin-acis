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
  "progress": {
    "current_count": null,
    "iterations": 0,
    "history": [],
    "status": "pending"
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
