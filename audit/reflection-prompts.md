# Process Auditor Reflection Prompts

Prompts used during the REFLECT and LEARN phases of `/acis audit`.

## Purpose

These prompts guide the Process Auditor's analysis of completed remediation cycles. They are designed to surface patterns, identify what's working, and detect opportunities for skill extraction.

---

## REFLECT Phase Prompts

### Extraction Coverage Verification

**Prompt 0: Extraction Coverage (Runs FIRST)**
```
Before analyzing goal patterns, verify that the extraction itself was complete.

For each unique source.pr_number in the audited goals:

1. LOAD COVERAGE DATA:
   - Primary: Load {goals_dir}/extraction-coverage-PR{N}.json (written by /acis extract v2.12.0+)
   - Fallback (pre-v2.12.0): Fetch PR review via `gh api repos/{owner}/{repo}/pulls/{N}/reviews`
     and compare review items against extracted goals manually

2. CLASSIFY EACH GAP (if any unmatched items exist):
   For each item in the review that has no corresponding goal:
   - `missed_by_llm`: Item was quantifiable but the extraction LLM did not identify it
   - `filtered_by_severity`: Item was extracted but filtered out by --severity flag
   - `dedup_false_positive`: Item was incorrectly deduplicated against an existing resolution
   - `cross_section_missed`: Item appeared in multiple sections but was only extracted from one,
     missing the cross-section severity escalation

3. TIMESTAMP GAP DETECTION:
   - Sort all goals by metadata.created_at
   - Flag gaps >5 minutes between consecutive goal creation timestamps
   - Gaps indicate possible manual intervention or extraction interruption
   - Record as: { gap_after: "{goal_id}", gap_duration_minutes: {N}, indicator: "manual_intervention" }

4. COVERAGE ASSESSMENT:
   - 100% coverage = COMPLETE → log as reinforcement
   - >=90% coverage = ACCEPTABLE → log gaps as minor corrections
   - <90% coverage = INCOMPLETE → auto-classify as CORRECTION with priority: high
   - <75% coverage = CRITICAL → auto-classify as CORRECTION with priority: critical

Output:
  - coverage_assessment: COMPLETE | ACCEPTABLE | INCOMPLETE | CRITICAL
  - gap_classifications: [{ item, classification, section, severity }]
  - manual_interventions: [{ gap_after, duration, indicator }]
  - recommendation: reinforcement | correction (with priority)
```

### Pattern Analysis

**Prompt 1: Cross-Goal Patterns**
```
Analyze the {N} goals completed since the last audit:

1. What patterns emerged across these remediations?
   - Common root causes
   - Similar fix approaches
   - Repeated code locations

2. Which categories had the most goals?
   - Security: {count}
   - Architecture: {count}
   - UX: {count}
   - Performance: {count}
   - Operations: {count}

3. What's the distribution of iteration counts?
   - Quick wins (1-2 iterations): {count}
   - Moderate (3-5 iterations): {count}
   - Hard problems (6+ iterations): {count}
```

**Prompt 2: Detection Effectiveness**
```
Evaluate the detection commands used:

For each detection command in achieved goals:
1. Did it catch the issue accurately? (no false positives)
2. Did it verify the fix correctly? (no false negatives)
3. How quickly did it run?

Detection commands to investigate:
- Commands with >1 false positive/negative
- Commands that took >10 seconds
- Commands used in >3 goals (potential for abstraction)
```

**Prompt 2.5: Functional Correctness Gap Analysis**
```
Analyze functional verification coverage across achieved goals:

1. CLASSIFY EACH ACHIEVED GOAL by verification method:

   | Classification | Criteria | Risk Level |
   |----------------|----------|------------|
   | `grep_only` | strategy=replace/refactor, NO functional_checks | HIGH RISK |
   | `functional_verified` | strategy=replace/refactor, functional_checks present AND passed | LOW RISK |
   | `false_positive_caught` | functional_checks caught broken replacement (false_positive_flags non-empty) | MEDIUM RISK (was caught) |
   | `not_applicable` | strategy=remove/add/wrap/custom OR no detection.functional_checks needed | N/A |

2. COVERAGE METRICS:
   - Total replace/refactor goals: {count}
   - With functional checks: {count} ({pct}%)
   - Without functional checks (grep-only): {count} ({pct}%)
   - False positives caught: {count}

3. GREP-ONLY RISK ANALYSIS:
   For each grep_only goal:
   - Goal ID: {id}
   - Strategy: {strategy}
   - Detection command: {primary_command}
   - Risk: Replacement could be functionally broken but pass detection
   - Recommendation: Add functional_checks (suggest specific checks based on project context)

4. FALSE POSITIVE ANALYSIS:
   For each goal with false_positive_flags:
   - Goal ID: {id}
   - Iteration where caught: {iteration}
   - What was broken: {notes}
   - Impact if not caught: {assessment}

5. RECOMMENDATIONS:
   - If grep_only_pct > 20%: "CRITICAL: {N} replace/refactor goals lack functional verification"
   - If false_positive_count > 0: "REINFORCEMENT: Functional checks prevented {N} false achievements"
   - Suggest specific functional checks for unprotected goals
   - Flag any patterns where same functional check could cover multiple goals

Output:
  - functional_coverage_pct: {number}
  - grep_only_goals: [{goal_ids}]
  - false_positives_caught: {count}
  - risk_assessment: LOW | MEDIUM | HIGH | CRITICAL
  - recommendations: [{type, description, affected_goals}]
```

**Prompt 3: 5 Whys Effectiveness**
```
Review the 5 Whys analyses:

1. How deep did analyses typically go?
   - Stopped at WHY-1/2: {count} (shallow)
   - Reached WHY-3/4: {count} (moderate)
   - Full WHY-5: {count} (deep)

2. Did deeper analyses correlate with better fixes?
   - Goals with WHY-5 that didn't need rework: {count}
   - Goals with shallow analysis that needed rework: {count}

3. What patterns appear in root causes (WHY-5)?
   - Type mismatches
   - Missing validation
   - Incorrect assumptions
   - Integration gaps
```

### Sequence Detection

**Prompt 4: Step Sequence Analysis**
```
Scan for repeated step sequences in goal fixes:

Extract the steps from each achieved goal's fix process.
Group by similarity.

For sequences appearing 5+ times:
- What are the exact steps?
- Are they project-specific or generic?
- What's the estimated time per execution?
- Is there a natural trigger phrase?

Format findings as:
  Sequence: {name}
  Steps: [step1, step2, step3, ...]
  Frequency: {count}
  Time estimate: {minutes}
  Trigger phrase: "{phrase}"
```

---

## LEARN Phase Prompts

### Reinforcement Identification

**Prompt 5: What's Working**
```
Identify behaviors to reinforce (keep doing):

1. PROMPT PATTERNS that led to efficient fixes:
   - Which prompt structures got to root cause fastest?
   - Which agent combinations worked well together?

2. DETECTION PATTERNS that caught issues early:
   - Commands with 100% accuracy
   - Patterns that prevented rework

3. FIX PATTERNS that stuck:
   - Code changes that didn't need revisiting
   - Test additions that caught regressions

For each reinforcement:
  Pattern: {description}
  Evidence: {goal IDs where this worked}
  Recommendation: {how to apply more consistently}
```

### Correction Identification

**Prompt 6: What Needs to Change**
```
Identify behaviors to correct (stop/change):

1. FRICTION POINTS - what caused delays?
   - Goals with >5 iterations: Why?
   - Goals with rework: What was missed?

2. WRONG ASSUMPTIONS - what did we assume incorrectly?
   - Type assumptions that were wrong
   - API assumptions that failed
   - Test assumptions that missed cases

3. DETECTION GAPS - what did we miss?
   - Issues found late that should have been caught early
   - False positives that wasted time
   - Commands that didn't scale

For each correction:
  Problem: {description}
  Impact: {time wasted, rework caused}
  Proposed fix: {specific change}
```

### Skill Candidate Evaluation

**Prompt 7: Skill Extraction Decision**
```
For each skill candidate meeting frequency threshold (5+):

Evaluate against ALL criteria:

1. REPETITION: {frequency} occurrences ✓/✗
   - Where did this appear? {goal IDs}

2. ROI: Estimated {X}% time savings ✓/✗
   - Calculation: {steps} steps × {time/step} × {frequency}
   - Threshold: >20%

3. PROJECT-SPECIFIC: Requires local context? ✓/✗
   - What project-specific knowledge is needed?
   - Would this work in any project? (if yes, it's not a skill candidate)

4. MEASURABLE: Detection command exists? ✓/✗
   - What command verifies this was done correctly?

5. STEP SEQUENCE: {count} sequential steps ✓/✗
   - Threshold: 3+ steps
   - Are steps clearly defined and ordered?

DECISION: Generate skill? YES / NO
If YES: Proceed to skill generation
If NO: Reason for rejection: {reason}
```

---

## APPLY Phase Prompts

### Process Adjustment Proposal

**Prompt 8: Propose Changes**
```
Based on the corrections identified, propose specific changes:

For each correction with clear fix:

1. CHANGE TYPE: {prompt | template | detection | lens_weight}

2. CURRENT STATE:
   {what exists now}

3. PROPOSED CHANGE:
   {what should change}

4. RATIONALE:
   {why this fixes the problem}

5. RISK ASSESSMENT:
   - Could this break existing functionality?
   - Is this reversible?

Present to user for approval: [Approve] [Modify] [Reject]
```

### Skill Generation

**Prompt 9: Generate Skill Content**
```
Generate SKILL.md for: {skill_name}

Using template from skill-templates/skill-template.md:

1. YAML FRONTMATTER:
   - name: {kebab-case-name}
   - description: {one-line description}
   - trigger: {phrase that activates}
   - source: "Process Auditor extraction"
   - extracted_at: {ISO timestamp}
   - pattern_frequency: {count}
   - efficiency_gain: {percentage}
   - roi_validated: true

2. PURPOSE:
   {Why this skill exists - what problem it solves}

3. PATTERN ORIGIN:
   {List the goal IDs where this pattern appeared}

4. STEPS:
   {Numbered, actionable steps}
   Each step should be:
   - Concrete (not vague)
   - Bash 3.2 compatible (POSIX syntax)
   - Idempotent when possible

5. VERIFICATION:
   Detection command: {command}
   Expected result: {value}

6. PROJECT CONTEXT:
   {Why this is specific to this project}
```

---

## DOCUMENT Phase Prompts

### Report Generation

**Prompt 10: Summarize Audit**
```
Generate audit report summary:

AUDIT OVERVIEW:
- Scope: {N} goals analyzed
- Period: {start_date} to {end_date}
- Duration: {minutes} minutes

METRICS:
- Quick wins (1-2 iter): {count} ({percentage}%)
- Moderate (3-5 iter): {count} ({percentage}%)
- Hard problems (6+): {count} ({percentage}%)
- Average iterations: {avg}

REINFORCEMENTS:
- {count} patterns identified
- Top 3: {list}

CORRECTIONS:
- {count} issues flagged
- {count} changes applied
- Top 3: {list}

SKILLS:
- {count} candidates evaluated
- {count} skills generated
- {count} skills deprecated

NEXT AUDIT:
- Threshold: {auditThreshold} goals
- Current count: 0
```

---

## Prompt Customization

Projects can override these prompts by creating:
`docs/audits/custom-reflection-prompts.md`

If custom prompts exist, they are merged with defaults.
