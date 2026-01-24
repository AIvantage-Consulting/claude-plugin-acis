# ACIS Extract - Goal Extraction from PR Reviews

You are executing the ACIS extract command. This command transforms PR review comments into quantifiable, trackable remediation goals.

## Arguments

- `$ARGUMENTS` - PR number or review file path (e.g., `55` or `path/to/review.json`)

## Workflow

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

**Include**:
- Specific code patterns (Math.random, console.log, any type)
- Code smells (empty catch, magic numbers)
- Security concerns (hardcoded secrets, injection)
- Performance issues (N+1, memory leaks)
- Accessibility gaps (missing alt, no keyboard nav)

**Skip**:
- Subjective opinions without patterns
- Questions or clarifications
- Praise or acknowledgments
- Already resolved in PR

### Step 5: Generate Goal Files

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

### Step 6: Measure Baselines

For each generated goal, run the detection command to establish baseline:

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
║  │ PR55-G1-math-random        │ security │ high     │ 47      │ 0        │  ║
║  │ PR55-G2-uninit-session     │ security │ critical │ 12      │ 0        │  ║
║  │ PR55-G3-console-log        │ maintain │ low      │ 89      │ 0        │  ║
║  └────────────────────────────┴──────────┴──────────┴─────────┴──────────┘  ║
║                                                                              ║
║  ⏭️ SKIPPED COMMENTS: {count}                                                ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  • Subjective/Opinion: {count}                                               ║
║  • Questions: {count}                                                        ║
║  • Already resolved: {count}                                                 ║
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
| `--severity <level>` | Filter by minimum severity (critical, high, medium, low) |
| `--reviewer <name>` | Filter by reviewer name |
| `--output-dir <path>` | Override goals output directory |
| `--skip-baseline` | Skip baseline measurement (faster, fill in later) |
| `--json` | Output raw JSON instead of formatted report |

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
