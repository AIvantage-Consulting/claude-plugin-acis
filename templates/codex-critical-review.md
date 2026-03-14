# Codex Critical Review - Area-Level Code Quality Assessment

Use this template when delegating to Codex for deep code quality analysis during `/acis:critical-review --depth deep`. This is an **area-level assessment** that evaluates code health across a scope, not a per-commit review.

## When Triggered

- `/acis:critical-review` with `--depth deep` (not `--skip-codex`)
- After T1 pattern detection has surfaced initial findings
- Scope files and T1 findings are provided as context

## Delegation Format

```markdown
TASK: Critical code quality review of {SCOPE_DESCRIPTION} for health assessment

EXPECTED OUTCOME: Structured findings with severity, file:line locations, and per-area health grade (A-F)

MODE: Advisory (read-only)

## Scope Context

- **Scope**: {SCOPE_DESCRIPTION}
- **Files**: {FILE_COUNT} files, {LOC} lines of code
- **T1 Findings Already Detected**: {T1_FINDING_COUNT} issues across {LENS_COUNT} lenses

## T1 Findings Summary

{T1_FINDINGS_TABLE}

## Representative Code Samples

{CODE_SAMPLES}

---

## Review Focus Areas

### 1. SOLID Principles

| Principle | Question |
|-----------|----------|
| **S**ingle Responsibility | Does each class/module have one reason to change? |
| **O**pen/Closed | Can behavior be extended without modifying existing code? |
| **L**iskov Substitution | Do subtypes behave as expected when substituted? |
| **I**nterface Segregation | Are interfaces minimal and focused? |
| **D**ependency Inversion | Do high-level modules depend on abstractions? |

### 2. DRY (Don't Repeat Yourself)

- Duplicated logic across files that should be abstracted
- Copy-paste code that will diverge over time
- Magic numbers/strings that need constants

### 3. Algorithm Quality

- Correct algorithmic approach for the problem
- Unnecessary O(n^2) or worse when O(n) is possible
- Edge case handling
- Data structure choices

### 4. Architecture Conformance

- Layer boundaries respected (Foundation -> Journey -> Composition if applicable)
- Dependency direction correct (lower layers never import higher)
- Coupling level between modules
- Cohesion within modules

### 5. Error Handling & Resilience

- Empty catch blocks or swallowed errors
- Missing error propagation
- Silent failures that hide bugs
- Recovery paths for failure scenarios

---

## Output Format (MANDATORY)

Return findings as structured data:

### Health Grade: {SCOPE}

**Grade**: [A | B | C | D | F]

**Grade Rationale**: {1-2 sentences explaining the grade}

### Findings

For each issue found:

| # | Severity | File:Line | Description | Recommendation |
|---|----------|-----------|-------------|----------------|
| 1 | {critical/high/medium/low} | {file}:{line} | {description} | {fix suggestion} |

### Positive Patterns Observed

List good practices found in the codebase:
1. {positive pattern and where observed}

### Summary Assessment

| Area | Assessment |
|------|------------|
| SOLID Compliance | {Good / Mixed / Poor} |
| DRY Compliance | {Good / Mixed / Poor} |
| Algorithm Quality | {Good / Mixed / Poor} |
| Architecture Conformance | {Good / Mixed / Poor} |
| Error Handling | {Good / Mixed / Poor} |

### Recommendations

Top 3 improvements ranked by impact:
1. {highest impact recommendation}
2. {second highest}
3. {third highest}
```

## Integration with Critical Review

### How Findings Are Consumed

Codex findings are merged into the unified findings list with:
- `source: "agent-codex"`
- `agent_id: "codex-code-reviewer"`
- Severity and locations preserved from Codex output
- Positive patterns added to the `positive_patterns` array

### Deduplication

Codex findings that match existing T1 findings (same file + overlapping line range) are **merged** rather than duplicated:
- The T1 finding gets the Codex recommendation attached
- The Codex perspective is added to the finding's `perspectives` array
- Severity is escalated if Codex rates higher than T1

### Grade Integration

The Codex grade contributes to the overall health score as a weighted perspective alongside T1 density scores and internal agent assessments.
