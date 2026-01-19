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
┌───────┐                    ┌──────────┐
│ APPLY │───────────────────►│ DOCUMENT │───────────────► Resume work
└───────┘                    └──────────┘
  Update prompts               Write audit log
  Adjust lens weights          Generate report
  GENERATE SKILLS              Archive patterns
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
4. Load reflection prompts from `${CLAUDE_PLUGIN_ROOT}/audit/reflection-prompts.md`
5. Run pattern analysis

**Key Questions** (from reflection-prompts.md):
- What patterns emerged across these remediations?
- Which detection commands caught issues early vs. late?
- Which 5 Whys analyses led to lasting fixes vs. rework?
- What step sequences were repeated?

**Output**: Pattern analysis data

### Phase 3: LEARN

**Purpose**: Extract insights from patterns.

**Actions**:
1. **Identify Reinforcements** (behaviors to keep doing):
   - Prompt patterns that led to efficient fixes
   - Agent combinations that worked well
   - Detection commands with high accuracy

2. **Identify Corrections** (behaviors to change):
   - Patterns that caused friction or rework
   - Assumptions that proved wrong
   - Detection commands that missed issues

3. **Identify Skill Candidates** (repeated sequences):
   - Scan for step sequences executed 5+ times
   - Evaluate against skill detection criteria (from skill-detection.md)
   - Score ROI potential (>20% time savings threshold)

**Output**: Reinforcements, corrections, skill candidates

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

## Output Locations

| Artifact | Location |
|----------|----------|
| Audit reports | `docs/audits/AUDIT-{timestamp}.md` |
| Generated skills | `skills/{skill-name}/SKILL.md` |
| Archived skills | `skills/.archive/` |
| State updates | `.acis-state.json` (if used) |

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

Reinforcements: {M} patterns identified
Corrections: {K} issues flagged
Skills Generated: {J} new skills

Report: docs/audits/AUDIT-{timestamp}.md

New skills available:
  - {skill-name-1}
  - {skill-name-2}

Next audit after: {auditThreshold} more goal completions
```
