# Codex Quality Gate - Phase 4.5 Code Review

Use this template when delegating to Codex for post-achievement quality review. This is a **quality gate** that reviews all changes made to achieve a goal before declaring victory.

## When Triggered

- Goal metric has been achieved (detection command passes)
- Before transitioning to ACHIEVED status
- Reviews cumulative diff of all iterations for this goal

## Delegation Format

```markdown
TASK: Quality review for goal {GOAL_ID} before marking ACHIEVED

EXPECTED OUTCOME: APPROVE to mark goal complete, or REQUEST_CHANGES with specific actionable feedback

MODE: Advisory (read-only)

## Goal Context

- **Goal ID**: {GOAL_ID}
- **Goal Summary**: {GOAL_DESCRIPTION}
- **Severity**: {SEVERITY}
- **Lens**: {LENS} (security, architecture, maintainability, etc.)
- **Iterations to Achieve**: {ITERATION_COUNT}

## Application Context

- **Application**: Healthcare companion app (offline-first, HIPAA-compliant)
- **Architecture**: Three-layer (Foundation → Journey → Composition)
- **Target Users**: Elderly patients, caregivers, healthcare providers
- **Critical Constraints**: PHI encryption, offline operation, accessibility

## Cumulative Changes

```diff
{CUMULATIVE_DIFF}
```

## Files Modified

{FILE_LIST_WITH_CHANGE_SUMMARY}

## Detection Verification

- **Command**: `{DETECTION_COMMAND}`
- **Before**: {INITIAL_VALUE}
- **After**: {FINAL_VALUE}
- **Target**: {TARGET_VALUE}
- **Status**: PASSING

---

## Review Checklist (Evaluate Each)

### 1. SOLID Principles

| Principle | Question | Assessment |
|-----------|----------|------------|
| **S**ingle Responsibility | Does each modified unit have one reason to change? | |
| **O**pen/Closed | Can this be extended without modification? | |
| **L**iskov Substitution | Do subtypes behave as expected? | |
| **I**nterface Segregation | Are interfaces minimal and focused? | |
| **D**ependency Inversion | Do high-level modules depend on abstractions? | |

### 2. DRY (Don't Repeat Yourself)

- Any duplicated logic that should be abstracted?
- Any copy-paste code that will diverge over time?
- Any magic numbers/strings that need constants?

### 3. Algorithm Quality

- Is this the right algorithmic approach?
- Any O(n²) or worse that could be O(n)?
- Edge cases handled correctly?
- Off-by-one errors?

### 4. Architecture Conformance

- **Layer Boundaries**: Foundation → Journey → Composition respected?
- **Dependency Direction**: Lower layers never import from higher?
- **Coupling**: Changes isolated or creating tight coupling?
- **Cohesion**: Related functionality grouped together?

### 5. Healthcare/Security Considerations

- **PHI Handling**: Any unencrypted PHI exposure?
- **HIPAA Compliance**: Audit trail maintained? Access controls respected?
- **Offline Safety**: Works without network? Sync conflicts handled?
- **Error Disclosure**: Errors reveal sensitive information?

### 6. Maintainability

- Will another developer understand this in 6 months?
- Are variable/function names self-documenting?
- Complex logic adequately commented?
- Test coverage adequate for changes?

---

## Output Format

### Quality Gate Verdict: {GOAL_ID}

#### Verdict
**[APPROVE | REQUEST_CHANGES]**

#### Quality Score
[1-5] where:
- 5: Exemplary - could be used as reference implementation
- 4: Good - minor improvements possible but not blocking
- 3: Acceptable - achieves goal but has notable issues
- 2: Needs Work - significant issues that should be addressed
- 1: Reject - fundamental problems requiring rework

#### SOLID/DRY Assessment
| Principle | Pass/Concern |
|-----------|--------------|
| Single Responsibility | |
| Open/Closed | |
| Liskov Substitution | |
| Interface Segregation | |
| Dependency Inversion | |
| DRY | |

#### Architecture Assessment
- Layer conformance: [OK | VIOLATION: {details}]
- Coupling level: [Low | Medium | High]
- Healthcare constraints: [Respected | CONCERN: {details}]

#### Top Issues (if REQUEST_CHANGES)
1. **[BLOCKING]** {Issue description + specific fix suggestion}
2. **[IMPORTANT]** {Issue description + specific fix suggestion}
3. **[MINOR]** {Issue description + specific fix suggestion}

#### Rationale
[3-5 sentences explaining the verdict, highlighting what was done well and what needs improvement]

#### Suggested Refactoring (if applicable)
```{language}
// Before (problematic)
{code_snippet}

// After (suggested)
{improved_code_snippet}
```
```

## Integration with ACIS

### Trigger Condition

```javascript
const shouldTriggerQualityGate = (goal, verificationResult, flags) => {
  // Always trigger when metric achieved (unless explicitly skipped)
  if (verificationResult.status === 'achieved') {
    if (flags.includes('--skip-quality-gate')) return false;
    if (flags.includes('--skip-codex')) return false;
    return true;
  }
  return false;
};
```

### Response Handling

```javascript
const handleQualityGateResponse = (response, goal) => {
  if (response.verdict === 'APPROVE') {
    // Proceed to mark goal ACHIEVED
    goal.status = 'achieved';
    goal.quality_score = response.quality_score;
    goal.quality_gate = {
      passed: true,
      reviewed_at: new Date().toISOString(),
      score: response.quality_score
    };
  } else {
    // REQUEST_CHANGES - loop back to FIX phase
    goal.status = 'in_progress';
    goal.quality_gate = {
      passed: false,
      issues: response.top_issues,
      feedback: response.rationale
    };
    // Inject feedback into next FIX iteration
  }
};
```

### Progress File Update

When quality gate completes, update progress file:

```json
{
  "iterations": [...],
  "quality_gate": {
    "triggered_at": "2026-01-25T...",
    "verdict": "APPROVE|REQUEST_CHANGES",
    "quality_score": 4,
    "issues": [],
    "iterations_before_gate": 3
  }
}
```

## Flags

| Flag | Effect |
|------|--------|
| `--skip-quality-gate` | Skip Phase 4.5 entirely |
| `--skip-codex` | Skip all Codex delegations (includes quality gate) |
| `--quality-threshold=N` | Require quality score >= N to APPROVE (default: 3) |
