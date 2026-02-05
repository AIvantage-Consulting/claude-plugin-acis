# /acis audit - Process Auditor Command

Process improvement through reflection, pattern detection, and dynamic skill generation.

## Trigger

The Process Auditor is triggered by:
1. **Manual invocation**: User runs `/acis audit`
2. **Automatic trigger**: After N goals remediated (default: 5, configurable via `auditThreshold`)
3. **Milestone completion**: All goals in a PR/WO achieved

## Purpose

The Process Auditor is the **outermost loop** (Loop 1) in ACIS's three-loop architecture. It observes patterns across remediation cycles (Loop 3) and discovery cycles (Loop 2), then:
- **Reinforces** effective behaviors
- **Corrects** problematic patterns
- **Extracts Skills** from repeated sequences (5+ occurrences)

## Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         /acis audit                                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
    ┌───────────────────────────────┼───────────────────────────────┐
    │                               │                               │
    ▼                               ▼                               ▼
┌───────┐                    ┌─────────┐                    ┌───────┐
│ PAUSE │───────────────────►│ REFLECT │───────────────────►│ LEARN │
└───────┘                    └─────────┘                    └───┬───┘
  Stop active                  Analyze completed                │
  remediation                  cycles                           │
                                                                │
    ┌───────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────┐                 ┌───────┐                    ┌───────┐
│ CLASSIFY │────────────────►│ APPLY │───────────────────►│ ROUTE │
└──────────┘                 └───────┘                    └───┬───┘
  Categorize by scope          Update prompts                 │
  project vs plugin            GENERATE SKILLS                │
                                                              │
    ┌─────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────┐
│ DOCUMENT │───────────────► Resume work
└──────────┘
  Write audit log
  GitHub issues (plugin)
  Feedback files (fallback)
  Generate report
```

### Recommendation Flow by Scope

```
LEARN Phase Output
         │
         ▼
┌─────────────────────────┐
│    CLASSIFY Phase       │
│    (scope assignment)   │
└─────────────────────────┘
         │
    ┌────┴────┐
    │         │
PROJECT     PLUGIN
    │         │
    ▼         ▼
┌─────────┐ ┌─────────────────┐
│ APPLY   │ │ APPLY + ROUTE   │
│ Phase   │ │ Phases          │
└─────────┘ └─────────────────┘
    │              │
    ▼              ▼
┌─────────────┐ ┌─────────────────┐
│ Project     │ │ GitHub Issue    │
│ skills/     │ │ OR              │
│ config      │ │ Feedback File   │
└─────────────┘ └─────────────────┘
```

## Phase Details

### Phase 1: PAUSE

**Purpose**: Halt active work and prepare for reflection.

**Actions**:
1. Save current remediation state if any goal is in-progress
2. Note the timestamp for audit scope (goals since last audit)
3. Load audit configuration from `.acis-config.json`

**Output**: Audit scope established

### Phase 2: REFLECT

**Purpose**: Analyze completed remediation and discovery cycles.

**Actions**:
1. Read all goal files with `status: achieved` since last audit
2. Read all goal files with `status: pending` or `status: failed`
3. Extract metrics from each goal:
   - Iteration count
   - Time to resolution (if tracked)
   - Detection command effectiveness
   - 5 Whys depth reached
4. **Load execution traces** from `${config.paths.processTraces}/`:
   - `decisions/*.jsonl` - Micro-decisions made during remediation
   - `knowledge/*.jsonl` - Knowledge gaps and applications
   - `skills/*.jsonl` - Skill usage and candidates
   - `effectiveness/*.jsonl` - Workflow effectiveness metrics
5. Load reflection prompts from `${CLAUDE_PLUGIN_ROOT}/audit/reflection-prompts.md`
6. Run pattern analysis (goal data + trace data)

**Trace-Informed Analysis**:
- Aggregate `decision` traces to find recurring approaches
- Scan for `process_auditor_hints.skill_candidate: true`
- Track `knowledge.event: "missing"` to identify documentation needs
- Compare `effectiveness.assessment` across goals

**Key Questions** (from reflection-prompts.md):
- What patterns emerged across these remediations?
- Which detection commands caught issues early vs. late?
- Which 5 Whys analyses led to lasting fixes vs. rework?
- What step sequences were repeated?
- What micro-decisions led to efficient vs. inefficient outcomes? *(from traces)*
- What knowledge gaps are recurring? *(from traces)*

**Output**: Pattern analysis data (enriched with trace insights)

### Phase 3: LEARN

**Purpose**: Extract insights from patterns.

**Actions**:
1. **Identify Reinforcements** (behaviors to keep doing):
   - Prompt patterns that led to efficient fixes
   - Agent combinations that worked well
   - Detection commands with high accuracy
   - Decision patterns with `confidence: high` and positive outcomes *(from traces)*
   - Knowledge applications that prevented blockers *(from traces)*

2. **Identify Corrections** (behaviors to change):
   - Patterns that caused friction or rework
   - Assumptions that proved wrong
   - Detection commands that missed issues
   - Decision patterns with repeated `confidence: low` *(from traces)*
   - Recurring `blocker` traces with same `blocker_type` *(from traces)*

3. **Identify Skill Candidates** (repeated sequences):
   - Scan for step sequences executed 5+ times
   - **Scan traces with `process_auditor_hints.skill_candidate: true`**
   - Evaluate against skill detection criteria (from skill-detection.md)
   - Score ROI potential (>20% time savings threshold)

4. **Identify Knowledge Gaps** *(from traces)*:
   - Aggregate `knowledge.event: "missing"` traces
   - Prioritize by `gap_impact: "blocking"` count
   - Recommend documentation or training additions

**Output**: Reinforcements, corrections, skill candidates, knowledge gap report

### Phase 3.5: CLASSIFY (Recommendation Routing)

**Purpose**: Classify each recommendation by applicability scope to determine routing.

**Actions**:

1. **For each recommendation** (reinforcement, correction, skill candidate):

   a. **Evaluate Scope Criteria**:

   | Criterion | → Project | → Plugin |
   |-----------|-----------|----------|
   | Affects `.acis-config.json` only | ✓ | |
   | Affects project-specific patterns | ✓ | |
   | Affects ACIS command behavior | | ✓ |
   | Affects extraction/deferral logic | | ✓ |
   | Generalizable across all projects | | ✓ |
   | Requires ACIS plugin code change | | ✓ |
   | Contains project-specific paths/names | ✓ | |
   | References generic ACIS components | | ✓ |

   b. **Assign Scope**:
   ```javascript
   if (requiresPluginCodeChange || affectsACISCommands || generalizable) {
     recommendation.applicability.scope = "plugin";
     recommendation.applicability.affected_components = identifyComponents(recommendation);
   } else {
     recommendation.applicability.scope = "project";
   }
   ```

   c. **Assess Generalizability** (for plugin-scope):
   - `high`: Would benefit all ACIS users
   - `medium`: Would benefit most projects with similar patterns
   - `low`: Edge case, but still plugin-level

2. **Create Structured Recommendations** using schema from `schemas/acis-recommendation.schema.json`

3. **Generate recommendation IDs**: `REC-{AUDIT_ID}-{SEQUENCE}`

**Classification Examples**:

| Recommendation | Scope | Rationale |
|----------------|-------|-----------|
| "Deferral heuristic needs parallelizability" | **plugin** | Affects `commands/extract.md`, generalizable |
| "Remove severity threshold from extraction" | **plugin** | Affects extraction logic, all users impacted |
| "Add framing language patterns" | **plugin** | Affects extraction patterns, generalizable |
| "Use lightweight parallel for crypto.randomUUID" | **project** | Project-specific pattern |
| "Early CI verification before push" | **project** | Project workflow preference |

**Output**: Classified recommendations with `applicability.scope` assigned

### Phase 4: APPLY

**Purpose**: Implement process improvements and generate skills.

**Actions**:

1. **Process Adjustments**:
   - Update prompts/templates if patterns suggest improvements
   - Add new detection commands if gaps found
   - Adjust assessment lens weights based on effectiveness
   - Propose changes for user approval

2. **Skill Extraction** (Dynamic Skill Generation):
   - For each skill candidate meeting all criteria:
     a. Extract the repeated step sequence
     b. Load skill template from `${CLAUDE_PLUGIN_ROOT}/skill-templates/skill-template.md`
     c. Generate SKILL.md with YAML frontmatter
     d. Write to `skills/{skill-name}/SKILL.md`
     e. Register in audit report

3. **Skill Deprecation**:
   - Identify skills no longer providing efficiency gains
   - Mark deprecated skills in audit report
   - Optionally archive to `skills/.archive/`

**Output**: Applied changes, generated skills

### Phase 4.5: ROUTE (Plugin Feedback Submission)

**Purpose**: Submit plugin-scope recommendations to ACIS repository for plugin-wide improvement.

**Routing Decision Tree**:

```
For each recommendation with applicability.scope === "plugin":
         │
         ▼
    ┌────────────────────────────┐
    │ Check GitHub CLI available │
    │ command -v gh              │
    └────────────────────────────┘
         │
    ┌────┴────┐
    │         │
  Found     Not Found
    │         │
    ▼         │
┌──────────────────────┐        │
│ Check GitHub auth    │        │
│ gh auth status       │        │
└──────────────────────┘        │
    │                           │
┌───┴───┐                       │
│       │                       │
OK    Failed                    │
│       │                       │
▼       └───────────────────────┤
┌──────────────────────┐        │
│ Check repo write     │        │
│ access               │        │
└──────────────────────┘        │
    │                           │
┌───┴───┐                       │
│       │                       │
OK    Failed                    │
│       │                       │
▼       └───────────────────────┤
                                │
CREATE GITHUB ISSUE ◄───────────┤
         │                      │
         │                      └───► CREATE FEEDBACK FILE
         │                                    │
         ▼                                    ▼
Update recommendation.routing    Update recommendation.routing
  .method = "github_issue"         .method = "feedback_file"
  .github_issue.issue_number       .feedback_file.path
  .github_issue.issue_url          .fallback_reason
```

**Primary: GitHub Issue Creation**:

```bash
# Load issue template
template="${CLAUDE_PLUGIN_ROOT}/templates/plugin-feedback-issue.md"

# Fill template variables
issue_body=$(fill_template "$template" "$recommendation")

# Create issue
gh issue create \
  --repo "aivantage-consulting/claude-plugin-acis" \
  --title "[Process Auditor] ${recommendation.type}: ${recommendation.title}" \
  --body "$issue_body" \
  --label "process-auditor,${recommendation.type},${recommendation.priority}"
```

**Fallback: Local Feedback File**:

If GitHub is unavailable, create local feedback file:

```bash
# Create feedback directory
mkdir -p .acis/plugin-feedback

# Generate feedback file
feedback_file=".acis/plugin-feedback/FEEDBACK-$(date +%Y%m%d)-${AUDIT_ID}.md"

# Load template and fill
template="${CLAUDE_PLUGIN_ROOT}/templates/plugin-feedback-file.md"
fill_template "$template" "$recommendations" > "$feedback_file"
```

**Update Recommendation Routing**:

After routing, update each recommendation's `routing` field:

```json
{
  "routing": {
    "method": "github_issue",
    "github_issue": {
      "repo": "aivantage-consulting/claude-plugin-acis",
      "issue_number": 42,
      "issue_url": "https://github.com/aivantage-consulting/claude-plugin-acis/issues/42",
      "created_at": "2026-02-05T23:45:00Z"
    }
  }
}
```

Or for fallback:

```json
{
  "routing": {
    "method": "feedback_file",
    "feedback_file": {
      "path": ".acis/plugin-feedback/FEEDBACK-20260205-PR60.md",
      "created_at": "2026-02-05T23:45:00Z"
    },
    "fallback_reason": "GitHub CLI not authenticated"
  }
}
```

**Output**: Routed recommendations (GitHub issues or feedback files)

### Phase 5: DOCUMENT

**Purpose**: Record learnings and generate audit report.

**Actions**:
1. Generate audit report using `${CLAUDE_PLUGIN_ROOT}/audit/audit-report.template.md`
2. Write report to `docs/audits/AUDIT-{timestamp}.md`
3. Update audit counter in state
4. Log summary to console

**Output**: Audit report, updated state

## Skill Generation Criteria

From `${CLAUDE_PLUGIN_ROOT}/audit/skill-detection.md`:

| Criterion | Threshold | Check |
|-----------|-----------|-------|
| Repetition | 5+ occurrences | Count step sequence matches |
| ROI | >20% time savings | Estimate based on step complexity |
| Project-Specific | Local context required | Not a generic pattern |
| Measurable | Detection command exists | Has verification step |
| Step Sequence | 3+ sequential steps | Complex enough to abstract |

## Auto-Trigger Logic

After each `/acis remediate` completion:

```
1. Read .acis-config.json for auditThreshold (default: 5)
2. Count goals with status: achieved since last audit
3. If count >= auditThreshold:
   a. Display: "Process Auditor trigger: {count} goals achieved since last audit"
   b. Ask: "Run /acis audit now? [Yes/Defer]"
   c. If Yes: Run audit
   d. If Defer: Continue, increment deferral counter
4. Reset counter after audit completes
```

## Ralph-Loop Profile

The Process Auditor can run autonomously via ralph-loop:

```json
{
  "profile": "process-auditor",
  "trigger": "after_n_goals_achieved | milestone | manual",
  "threshold": 5,
  "phases": ["PAUSE", "REFLECT", "LEARN", "APPLY", "DOCUMENT"],
  "outputs": ["audit-report", "process-adjustments", "skills"],
  "completion_criteria": "audit_report_generated && skills_evaluated"
}
```

## Trace Data Sources

The Process Auditor consumes structured traces from `${config.paths.processTraces}/`:

| Trace Type | Location | Usage |
|------------|----------|-------|
| Decisions | `decisions/{goal-id}-decisions.jsonl` | Pattern detection, approach effectiveness |
| Knowledge | `knowledge/knowledge-*.jsonl` | Gap identification, documentation needs |
| Skills | `skills/skill-*.jsonl` | Candidate identification, usage tracking |
| Effectiveness | `effectiveness/*.jsonl` | Workflow metrics, improvement detection |
| Blockers | (aggregated from session traces) | Recurring blocker analysis |

### Trace Query Examples

```bash
# Find skill candidates flagged during execution
grep '"skill_candidate":true' ${config.paths.processTraces}/decisions/*.jsonl

# Aggregate iterations to completion
jq -s 'map(select(.effectiveness.metric == "iterations_to_complete")) | group_by(.goal_id)' \
  ${config.paths.processTraces}/effectiveness/*.jsonl

# Find recurring knowledge gaps
jq -s 'map(select(.knowledge.event == "missing")) | group_by(.knowledge.domain) | map({domain: .[0].knowledge.domain, count: length}) | sort_by(-.count)' \
  ${config.paths.processTraces}/knowledge/*.jsonl

# Identify high-impact blockers
jq 'select(.blocker.blocker_type and .blocker.resolved == false)' \
  ${config.paths.traces}/*/trace-log.jsonl
```

## Output Locations

| Artifact | Location | Scope |
|----------|----------|-------|
| Audit reports | `${config.paths.audits}/AUDIT-{timestamp}.md` | Both |
| Generated skills | `${config.paths.skills}/{skill-name}/SKILL.md` | Project |
| Archived skills | `${config.paths.skills}/.archive/` | Project |
| State updates | `${config.paths.state}/audit-state.json` | Project |
| Recommendations | `${config.paths.audits}/recommendations/{audit-id}.json` | Both |
| GitHub issues | `aivantage-consulting/claude-plugin-acis/issues` | Plugin |
| Feedback files | `.acis/plugin-feedback/FEEDBACK-{date}-{audit-id}.md` | Plugin (fallback) |

### Recommendation Artifacts

Each recommendation is stored as structured JSON:

```
${config.paths.audits}/
├── AUDIT-20260205-PR60.md           # Human-readable report
├── recommendations/
│   ├── AUDIT-20260205-PR60.json     # All recommendations (JSON)
│   └── REC-PR60-0001.json           # Individual recommendation
```

The JSON follows `schemas/acis-recommendation.schema.json`.

## Integration with Other Commands

- `/acis remediate`: Increments goal counter, may trigger auto-audit
- `/acis status`: Shows "Goals until next audit: {N}"
- `/acis init`: Sets `auditThreshold` in config

## Error Handling

| Scenario | Action |
|----------|--------|
| No goals to analyze | Report "No completed goals since last audit" |
| Skill extraction fails | Log warning, continue with other skills |
| Template not found | Use inline defaults, warn user |
| Permission denied (file write) | Report error, show content for manual action |

## Completion Message

```
Process Auditor Complete!

Scope: {N} goals analyzed (since {last_audit_date})

╔═══════════════════════════════════════════════════════════════╗
║  Recommendations by Scope                                      ║
╠═══════════════════════════════════════════════════════════════╣
║                                                                ║
║  PROJECT-SCOPE ({P} total):                                   ║
║    Reinforcements: {M} patterns identified                     ║
║    Corrections: {K} issues flagged                             ║
║    Skills Generated: {J} new skills                            ║
║                                                                ║
║  PLUGIN-SCOPE ({Q} total):                                    ║
║    GitHub Issues Created: {G}                                  ║
║    Feedback Files (fallback): {F}                              ║
║                                                                ║
╚═══════════════════════════════════════════════════════════════╝

Report: docs/audits/AUDIT-{timestamp}.md

New skills available:
  - {skill-name-1}
  - {skill-name-2}

Plugin feedback submitted:
  - #{issue-1}: {title-1}
  - #{issue-2}: {title-2}
  (or: See .acis/plugin-feedback/ for pending submissions)

Next audit after: {auditThreshold} more goal completions
```

### GitHub Issue Summary (if created)

```
╔═══════════════════════════════════════════════════════════════╗
║  Plugin Feedback Submitted                                     ║
╠═══════════════════════════════════════════════════════════════╣
║                                                                ║
║  Created {G} issues on aivantage-consulting/claude-plugin-acis ║
║                                                                ║
║  #42: Remove severity threshold from extraction                ║
║       https://github.com/aivantage-consulting/.../issues/42    ║
║                                                                ║
║  #43: Add framing language patterns to extraction              ║
║       https://github.com/aivantage-consulting/.../issues/43    ║
║                                                                ║
╚═══════════════════════════════════════════════════════════════╝
```

### Fallback Summary (if GitHub unavailable)

```
╔═══════════════════════════════════════════════════════════════╗
║  Plugin Feedback Saved Locally                                 ║
╠═══════════════════════════════════════════════════════════════╣
║                                                                ║
║  {Q} plugin-scope recommendations saved to:                    ║
║    .acis/plugin-feedback/FEEDBACK-20260205-PR60.md            ║
║                                                                ║
║  Reason: {fallback_reason}                                     ║
║                                                                ║
║  To submit later:                                              ║
║    /acis submit-feedback                                       ║
║                                                                ║
╚═══════════════════════════════════════════════════════════════╝
```
