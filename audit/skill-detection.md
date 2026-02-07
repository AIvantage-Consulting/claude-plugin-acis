# Skill Detection Criteria

Criteria and algorithms for identifying patterns worthy of extraction into Skills.

## Core Principle

**Don't let the system reinvent wheels.**

If a sequence of steps is executed repeatedly across remediation cycles, and that sequence provides clear ROI, codify it as a Skill.

---

## Detection Criteria (ALL must be met)

| Criterion | Threshold | Rationale |
|-----------|-----------|-----------|
| **Repetition** | 5+ occurrences | Proven recurring need; not a one-off or occasional pattern |
| **ROI** | >20% time savings | Clear return on abstraction investment |
| **Project-Specific** | Requires local context | Generic patterns belong in plugin defaults |
| **Measurable** | Detection command exists | Must be verifiable |
| **Step Sequence** | 3+ sequential steps | Enough complexity to warrant abstraction |

---

## Criterion Details

### 1. Repetition (5+ occurrences)

**How to measure**: Count distinct goals where the step sequence appears.

**Matching rules**:
- Exact match: Same commands in same order
- Semantic match: Same intent, different syntax (e.g., `npm test` ≈ `pnpm test`)
- Template match: Parameterized pattern (e.g., `grep {pattern} {path}`)

**Examples**:
```
✓ QUALIFIES: "Run tests, check coverage, verify no regressions" appears in 7 goals
✗ REJECTS: "Fix typo in README" appears only 2 times
```

### 2. ROI (>20% time savings)

**How to calculate**:
```
estimated_time_per_execution = sum(step_times) + context_switching_overhead
manual_time_without_skill = N * estimated_time_per_execution
skill_invocation_time = N * (skill_overhead + reduced_step_time)
savings = (manual_time_without_skill - skill_invocation_time) / manual_time_without_skill
```

**Rule of thumb**:
- Each step saved ≈ 2-5 minutes
- Context switching overhead ≈ 1-2 minutes per manual execution
- Skill overhead ≈ 30 seconds per invocation

**Examples**:
```
✓ QUALIFIES: 5-step sequence × 7 occurrences = ~35 manual executions
             Estimated 3 min/step × 5 = 15 min manual
             Skill reduces to 2 min = 87% savings ✓

✗ REJECTS: 2-step sequence × 5 occurrences
           Estimated 1 min/step × 2 = 2 min manual
           Skill overhead ≈ 1 min = only 50% savings
           But sequence too simple (fails criterion 5) ✗
```

### 3. Project-Specific (requires local context)

**How to evaluate**: Would this skill work in a completely different project?

**Project-specific indicators**:
- References project directory structure (`packages/foundation/...`)
- Uses project-specific config files (`.acis-config.json`)
- Knows project personas or compliance requirements
- References project-specific test patterns

**Generic patterns (DON'T qualify)**:
- "Run git status"
- "Check npm dependencies"
- "Lint code"

These belong in plugin defaults, not project skills.

**Examples**:
```
✓ QUALIFIES: "Verify PHI encryption in foundation layer"
             - Knows about three-layer architecture
             - Knows about PHI-safe builders
             - Project-specific compliance

✗ REJECTS: "Run tests before commit"
           - Generic pattern
           - Works in any project
           - Should be a default, not a skill
```

### 4. Measurable (detection command exists)

**Requirement**: The skill must have a verification step that can be automated.

**Good detection commands** (Bash 3.2 compatible):
```bash
# Counting pattern (expect specific count)
grep -rn "Math.random" packages/ | wc -l  # expect: 0

# Existence check (expect file exists)
[ -f ".acis-config.json" ] && echo "exists"  # expect: exists

# Command success (expect exit code 0)
pnpm test -- --passWithNoTests && echo "pass"  # expect: pass
```

**Examples**:
```
✓ QUALIFIES: Skill has command `pnpm test --coverage | grep "All files"`
             expected: ">80%"

✗ REJECTS: "Make sure the code looks clean"
           - No automated verification possible
           - Subjective criterion
```

### 5. Step Sequence (3+ sequential steps)

**Requirement**: The pattern must involve at least 3 distinct, ordered steps.

**Why 3+**: Simpler sequences don't benefit from abstraction. The overhead of invoking a skill should be less than doing the steps manually.

**Counting rules**:
- Each distinct action = 1 step
- Conditional branches don't count separately
- Verification at the end = 1 step

**Examples**:
```
✓ QUALIFIES:
1. Check Jest config exists
2. Verify coverage thresholds set
3. Run smoke test
4. Verify test output
= 4 steps ✓

✗ REJECTS:
1. Run tests
2. Check output
= 2 steps ✗ (too simple)
```

---

## Detection Algorithm

```python
def detect_skill_candidates(goals):
    step_sequences = extract_step_sequences(goals)
    candidates = []

    for sequence in step_sequences:
        # Criterion 1: Repetition
        if sequence.frequency < 5:
            continue

        # Criterion 2: ROI
        if sequence.estimated_roi < 0.20:
            continue

        # Criterion 3: Project-specific
        if not requires_local_context(sequence):
            continue

        # Criterion 4: Measurable
        if not has_detection_command(sequence):
            continue

        # Criterion 5: Step count
        if len(sequence.steps) < 3:
            continue

        # All criteria met
        candidates.append(sequence)

    return candidates
```

---

## Skill Candidate Scoring

When multiple candidates qualify, prioritize by:

| Factor | Weight | Rationale |
|--------|--------|-----------|
| Frequency | 30% | More usage = more value |
| ROI | 30% | Higher savings = more impact |
| Step count | 20% | More steps = more abstraction value |
| Recency | 20% | Recent patterns = current relevance |

**Score formula**:
```
score = (frequency_normalized × 0.3) +
        (roi_normalized × 0.3) +
        (steps_normalized × 0.2) +
        (recency_normalized × 0.2)
```

---

## Bash 3.2 Compatibility

All detection commands in skills MUST work on macOS Bash 3.2.

**AVOID**:
- `declare -A` (associative arrays)
- `mapfile` / `readarray`
- `${var,,}` / `${var^^}` (case modification)
- `shopt -s globstar`

**USE**:
- `grep`, `find`, `sed`, `awk` (POSIX)
- `[ ]` test syntax
- `while read` loops
- `jq` for JSON (external tool, not bash)

---

## Edge Cases

### Skill Deduplication (MANDATORY before generation)

Before generating ANY new skill, perform deduplication checks against existing skills:

#### Step 1: Scan Existing Skills

```bash
# Find all existing skill definitions
existing_skills=$(find skills/*/SKILL.md -type f 2>/dev/null)
```

#### Step 2: Check for Exact Duplicates

For each candidate, compare against existing skills:
- Extract detection command from candidate and existing SKILL.md
- Extract step sequence from candidate and existing SKILL.md
- If detection command AND step sequence are identical → **SKIP** with trace:
  ```
  SKILL_DEDUP: Candidate "{candidate_name}" is exact duplicate of existing skill "{existing_name}". Skipping.
  ```

#### Step 3: Check for Semantic Overlap

If not an exact duplicate, check for semantic overlap:
- Compare step sequences: count shared steps between candidate and each existing skill
- If 80%+ steps are shared → **MERGE** instead of creating new:
  1. Identify variant steps (steps in candidate but not in existing)
  2. Add variant steps to existing skill's `variants` section
  3. Update existing skill's frequency count
  4. Trace: `SKILL_MERGE: Candidate "{candidate_name}" merged into existing skill "{existing_name}" (82% overlap, 2 variant steps added).`

#### Step 4: Deduplication Report

After checking all candidates, output deduplication summary:

| Candidate | Status | Action | Notes |
|-----------|--------|--------|-------|
| {name} | UNIQUE | Generate new skill | No overlap with existing |
| {name} | DUPLICATE | Skipped | Exact match with {existing} |
| {name} | OVERLAP_82% | Merged into {existing} | 2 variant steps added |

### Overlapping Patterns

If two skill candidates share 80%+ steps:
1. Merge into single skill with variants
2. Use the more frequent pattern as primary
3. Document the variant in skill notes

### Deprecated Patterns

If a skill candidate duplicates an existing skill:
1. Skip generation with trace
2. Note in audit report
3. Consider if existing skill needs update

### Evolution

If a pattern appears to be evolving:
1. Generate skill for current stable form
2. Note "may need update" in skill comments
3. Re-evaluate in next audit
