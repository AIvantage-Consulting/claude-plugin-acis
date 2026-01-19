# Process Auditor Reflection Prompts

Prompts used during the REFLECT and LEARN phases of `/acis audit`.

## Purpose

These prompts guide the Process Auditor's analysis of completed remediation cycles. They are designed to surface patterns, identify what's working, and detect opportunities for skill extraction.

---

## REFLECT Phase Prompts

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
