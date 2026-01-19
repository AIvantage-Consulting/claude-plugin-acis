# Process Auditor Flow

Detailed orchestration for the `/acis audit` command's five phases.

## Overview

The Process Auditor operates on the principle: **Don't let the system reinvent wheels.**

When patterns are detected that have clear ROI, they become Skills - codified sequences that make future work more efficient.

## Phase Orchestration

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PROCESS AUDITOR EXECUTION                           │
└─────────────────────────────────────────────────────────────────────────────┘

Entry Point: /acis audit
     │
     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: PAUSE                                                               │
│                                                                              │
│ 1. Check for active remediation (goal with status: in_progress)             │
│ 2. If active: Save state, mark as paused                                    │
│ 3. Establish audit scope:                                                   │
│    - Last audit timestamp (from state or default to epoch)                  │
│    - Goals modified since then                                              │
│ 4. Load config from .acis-config.json                                       │
│                                                                              │
│ Output: { scope: { since: timestamp, goalCount: N }, config: {...} }        │
└─────────────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: REFLECT                                                             │
│                                                                              │
│ 1. Read all goal files in goalsDirectory                                    │
│ 2. Filter to scope (modified since last audit)                              │
│ 3. For each goal, extract:                                                  │
│    - status (achieved, pending, failed)                                     │
│    - iterations (how many attempts)                                         │
│    - detection.command (what verified it)                                   │
│    - progress.notes (any recorded observations)                             │
│ 4. Build pattern matrix:                                                    │
│    - Group by lens/category                                                 │
│    - Group by fix type (code, test, config, docs)                          │
│    - Group by iteration count (quick wins vs. hard problems)                │
│ 5. Run reflection prompts (from reflection-prompts.md)                      │
│                                                                              │
│ Output: { goals: [...], patterns: {...}, metrics: {...} }                   │
└─────────────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: LEARN                                                               │
│                                                                              │
│ A. REINFORCEMENTS (what's working)                                          │
│    - Detection commands with 100% accuracy                                  │
│    - Goals achieved in ≤2 iterations                                        │
│    - Patterns that appear in successful fixes                               │
│                                                                              │
│ B. CORRECTIONS (what needs to change)                                       │
│    - Goals that took >5 iterations                                          │
│    - Detection commands that gave false positives/negatives                 │
│    - Patterns that led to rework                                            │
│                                                                              │
│ C. SKILL CANDIDATES (repeated sequences)                                    │
│    - Scan goal notes and fix descriptions for step patterns                 │
│    - Count occurrences across goals                                         │
│    - Filter: frequency >= 5                                                 │
│    - Score: ROI estimate (time saved per invocation)                        │
│    - Validate: project-specific, measurable, 3+ steps                       │
│                                                                              │
│ Output: { reinforcements: [...], corrections: [...], skillCandidates: [...]}│
└─────────────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: APPLY                                                               │
│                                                                              │
│ A. PROCESS ADJUSTMENTS (with user approval)                                 │
│    For each correction:                                                     │
│    1. Propose specific change                                               │
│    2. Ask user to approve/modify/reject                                     │
│    3. If approved: Apply change                                             │
│                                                                              │
│ B. SKILL GENERATION                                                         │
│    For each skill candidate meeting ALL criteria:                           │
│    1. Load skill template                                                   │
│    2. Extract step sequence from goals                                      │
│    3. Generate SKILL.md with:                                               │
│       - YAML frontmatter (name, trigger, frequency, ROI)                    │
│       - Purpose section                                                     │
│       - Pattern origin (which goals)                                        │
│       - Steps (numbered)                                                    │
│       - Verification command                                                │
│       - Project context                                                     │
│    4. Create skills/{skill-name}/SKILL.md                                   │
│    5. Register in generated_skills list                                     │
│                                                                              │
│ C. SKILL DEPRECATION                                                        │
│    1. Check existing skills for usage (if tracking available)               │
│    2. Flag skills not invoked in N audits                                   │
│    3. Propose deprecation for user approval                                 │
│                                                                              │
│ Output: { adjustments: [...], generatedSkills: [...], deprecatedSkills: []} │
└─────────────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: DOCUMENT                                                            │
│                                                                              │
│ 1. Generate audit report using template                                     │
│ 2. Write to docs/audits/AUDIT-{timestamp}.md                                │
│ 3. Update last_audit timestamp in state                                     │
│ 4. Reset goal counter                                                       │
│ 5. Display completion summary                                               │
│                                                                              │
│ Output: Audit report file, updated state                                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Pattern Detection Algorithm

### Step Sequence Detection

```
FOR each achieved goal:
  Extract fix_steps from progress.notes or infer from diff
  Normalize steps to canonical form (e.g., "run tests" -> "execute-tests")
  Add to step_sequences[]

FOR each unique step_sequence:
  count = occurrences across goals
  IF count >= 5:
    Add to skill_candidates

FOR each skill_candidate:
  Calculate ROI = (avg_time_per_step * step_count) * frequency
  IF ROI > 20% threshold:
    Mark as skill_eligible
```

### Similarity Matching

Steps are matched using:
1. Exact match (same command)
2. Semantic match (similar intent, different syntax)
3. Template match (parameterized pattern)

Example:
```
"grep -rn 'Math.random' packages/"
≈ "grep -rn '{pattern}' {directory}/"
→ Template: "search-codebase-pattern"
```

## State Management

### Audit State (`.acis-state.json` or embedded in config)

```json
{
  "lastAudit": {
    "timestamp": "2026-01-19T10:00:00Z",
    "goalsAnalyzed": 5,
    "skillsGenerated": 2
  },
  "goalsSinceAudit": 3,
  "deferralCount": 0,
  "skillUsage": {
    "test-setup-verification": {
      "invocations": 7,
      "lastUsed": "2026-01-18T15:00:00Z"
    }
  }
}
```

## Integration Points

### With Loop 2 (Discovery)
- Discovery reports can include hints for skill candidates
- Decision patterns feed into reinforcement/correction analysis

### With Loop 3 (Remediation)
- Each remediation logs steps for pattern detection
- Iteration counts inform correction identification
- Success patterns inform reinforcement

### With Skills System
- Generated skills appear in `skills/` directory
- Claude auto-discovers skills at session start
- Skills can reference ACIS commands

## Rollback Capability

If skill generation causes issues:
1. Skills can be manually deleted from `skills/`
2. Archived skills can be restored from `skills/.archive/`
3. Audit report documents what was generated for traceability
