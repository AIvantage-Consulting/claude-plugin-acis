# Codex Stuck Consultation - Iteration Escalation

Use this template when delegating to Codex for **consultation** (not review) when the inner loop is struggling to achieve a goal after multiple iterations. This is a **problem-solving consultation**, not a code review.

## When Triggered

- Goal has NOT been achieved after 3-5 iterations
- Internal 5-WHYS and FIX cycles are not making progress
- Need external perspective to unblock

## Purpose Distinction

| Quality Gate (Phase 4.5) | Stuck Consultation |
|--------------------------|-------------------|
| After metric achieved | When metric NOT achieved |
| Reviews completed work | Helps solve problem |
| Quality assessment | Problem-solving assistance |
| APPROVE/REQUEST_CHANGES | Suggested approach + code |

## Delegation Format

```markdown
TASK: Consultation to unblock goal {GOAL_ID} stuck after {ITERATION_COUNT} iterations

EXPECTED OUTCOME: Fresh perspective on root cause + concrete solution approach

MODE: Advisory (consultation, not implementation)

## Goal Context

- **Goal ID**: {GOAL_ID}
- **Goal Summary**: {GOAL_DESCRIPTION}
- **Severity**: {SEVERITY}
- **Detection Command**: `{DETECTION_COMMAND}`
- **Target Value**: {TARGET_VALUE}
- **Current Value**: {CURRENT_VALUE} (not improving)

## Application Context

- **Application**: Healthcare companion app (offline-first, HIPAA-compliant)
- **Architecture**: Three-layer (Foundation → Journey → Composition)
- **Constraints**: PHI encryption, offline operation, SOLID+DRY principles

## What We've Tried

### Iteration History

{ITERATION_SUMMARY}

| Iteration | Approach | Result | Why It Didn't Work |
|-----------|----------|--------|-------------------|
| 1 | {approach_1} | {result_1} | {analysis_1} |
| 2 | {approach_2} | {result_2} | {analysis_2} |
| 3 | {approach_3} | {result_3} | {analysis_3} |
| ... | ... | ... | ... |

### Internal 5-WHYS Analysis (Latest)

**Security Perspective Root Cause**: {security_root_cause}
**Architecture Perspective Root Cause**: {architecture_root_cause}
**Resilience Perspective Root Cause**: {resilience_root_cause}
**Convergence Status**: {CONVERGED | PARTIAL | DIVERGED}

### Relevant Code Context

```{language}
{RELEVANT_CODE_SNIPPETS}
```

### Current Blockers

{BLOCKER_DESCRIPTION}

---

## Consultation Questions

We need your fresh perspective on:

1. **Root Cause Diagnosis**: What are we missing? Is our 5-WHYS analysis correct or are we chasing symptoms?

2. **Alternative Approach**: Given what we've tried, what different approach would you suggest?

3. **Design Pattern**: Is there a design pattern (SOLID-aligned) that better fits this problem?

4. **Architectural Consideration**: Are we fighting against the architecture? Should the solution be at a different layer?

5. **Healthcare/Offline Constraint**: Are we properly accounting for offline-first and PHI constraints?

---

## Output Format

### Consultation Response: {GOAL_ID}

#### Diagnosis

**Our 5-WHYS Assessment**: [Agree | Partially Agree | Disagree]

**What We're Missing**:
[Specific insight about what the internal analysis overlooked]

**Actual Root Cause** (if different):
[Your assessment of the true root cause]

#### Recommended Approach

**Strategy**: [Brief description of recommended approach]

**Why This Will Work**:
[Explanation of why this approach addresses the root cause]

**Why Previous Attempts Failed**:
[Specific reason the tried approaches didn't work]

#### Implementation Guidance

**Step 1**: {First concrete step}
```{language}
{code_snippet_or_pseudocode}
```

**Step 2**: {Second concrete step}
```{language}
{code_snippet_or_pseudocode}
```

**Step 3**: {Third concrete step}
```{language}
{code_snippet_or_pseudocode}
```

#### Design Pattern Recommendation

**Pattern**: {Pattern name, e.g., Strategy, Factory, Observer}
**Why It Fits**: [How this pattern solves the problem while respecting SOLID]
**Example Application**:
```{language}
{pattern_implementation_sketch}
```

#### Architecture Alignment

**Correct Layer**: {Foundation | Journey | Composition}
**Dependency Direction**: {What should depend on what}
**Integration Points**: {Where this connects to existing code}

#### Healthcare Considerations

- **PHI Impact**: {How solution handles PHI}
- **Offline Behavior**: {How solution works offline}
- **Audit Trail**: {Any logging/audit considerations}

#### Confidence Level

[High | Medium | Low] - {Brief rationale}

#### Caveats/Risks

- {Risk 1 and mitigation}
- {Risk 2 and mitigation}
```

## Integration with ACIS

### Trigger Condition

```javascript
const shouldTriggerStuckConsultation = (goal, iteration, flags) => {
  const threshold = flags['--stuck-threshold'] || 4; // default: 4 iterations

  // Check if we're stuck (not making progress)
  const recentIterations = goal.progress.slice(-3);
  const noProgress = recentIterations.every(i =>
    i.result === 'not_achieved' || i.result === 'partial'
  );

  if (iteration >= threshold && noProgress) {
    if (flags.includes('--skip-codex')) return false;
    return true;
  }
  return false;
};
```

### Response Handling

```javascript
const handleStuckConsultation = (response, goal, progressFile) => {
  // Record consultation in progress
  progressFile.stuck_consultation = {
    triggered_at: new Date().toISOString(),
    iteration_when_triggered: goal.current_iteration,
    diagnosis: response.diagnosis,
    recommended_approach: response.recommended_approach,
    confidence: response.confidence
  };

  // Inject guidance into next FIX iteration
  goal.next_fix_guidance = {
    source: 'codex_consultation',
    approach: response.recommended_approach,
    steps: response.implementation_guidance,
    pattern: response.design_pattern
  };

  // Continue to next FIX iteration with fresh guidance
  // (don't reset iteration count - track total effort)
};
```

### Progress File Update

When stuck consultation completes, update progress file:

```json
{
  "iterations": [...],
  "stuck_consultations": [
    {
      "triggered_at_iteration": 4,
      "timestamp": "2026-01-25T...",
      "diagnosis_agreed": false,
      "new_root_cause": "...",
      "recommended_approach": "...",
      "confidence": "high",
      "subsequent_iterations": 2,
      "resolved": true
    }
  ]
}
```

## Flags

| Flag | Effect |
|------|--------|
| `--stuck-threshold=N` | Trigger consultation after N iterations (default: 4) |
| `--skip-codex` | Skip all Codex delegations (includes consultation) |
| `--force-consultation` | Force consultation regardless of iteration count |

## Escalation Path

```
Iteration 1-3: Internal 5-WHYS + FIX
                    ↓ (not achieved)
Iteration 4: Stuck Consultation triggered
                    ↓ (Codex provides guidance)
Iteration 5-6: FIX with Codex guidance
                    ↓ (still not achieved)
Iteration 7: Second consultation OR escalate to Loop 2 (re-discovery)
```

## Prompt Compactness Note

For efficiency, the actual prompt sent to Codex should be condensed. The full template above is for documentation. The actual delegation prompt should:

1. Include goal summary (1-2 lines)
2. Include iteration history (table format)
3. Include 5-WHYS synthesis (3 bullet points)
4. Include relevant code (minimal, focused snippets)
5. Ask specific questions

Target: ~500-800 tokens for context, leaving room for response.
