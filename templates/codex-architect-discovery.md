# Codex Architect Discovery Template

Use this template when delegating to Codex Architect for ACIS goal discovery.

## Delegation Format

```
TASK: Analyze {GOAL_ID} for architectural implications and design tradeoffs.

EXPECTED OUTCOME: Architectural assessment with actionable recommendations.

MODE: Advisory

CONTEXT:
- Goal: {GOAL_DESCRIPTION}
- Affected files: {FILE_LIST}
- Current architecture: Three-layer (Foundation → Composition → Journey)
- Constraint: Offline-first, PHI-safe, HIPAA-compliant

CONSTRAINTS:
- Must respect Three-Layer Architecture boundaries
- Cannot introduce new external dependencies without justification
- Performance requirements: <200ms response for UI operations
- Must work offline-first

MUST DO:
- Identify architectural patterns affected by this goal
- Analyze tradeoffs of different implementation approaches
- Recommend optimal design considering maintainability
- Identify refactoring opportunities exposed by this goal
- Provide effort estimate (Quick/Short/Medium/Large)

MUST NOT DO:
- Over-engineer for hypothetical future needs
- Introduce unnecessary abstractions
- Ignore existing patterns in the codebase

OUTPUT FORMAT:
## Bottom Line
[1-2 sentence recommendation]

## Architectural Analysis
- **Affected Layers**: [Foundation/Composition/Journey]
- **Pattern Impact**: [which patterns are affected]
- **Coupling Analysis**: [dependencies introduced/removed]

## Implementation Options
1. **Option A**: [description]
   - Pros: [...]
   - Cons: [...]
   - Effort: [Quick/Short/Medium/Large]

2. **Option B**: [description]
   - Pros: [...]
   - Cons: [...]
   - Effort: [...]

## Recommendation
[Selected approach with justification]

## Refactoring Opportunities
- [Opportunity 1]
- [Opportunity 2]

## Metrics to Verify
- [Metric 1]: [command to measure]
- [Metric 2]: [command to measure]
```

## Variable Substitutions

| Variable | Source |
|----------|--------|
| `{GOAL_ID}` | `goal.id` |
| `{GOAL_DESCRIPTION}` | `goal.source.original_comment` |
| `{FILE_LIST}` | Files from detection command output |
| `{PATTERN}` | `goal.detection.pattern` |

## Integration with ACIS

The Architect's response feeds into:
1. `multi_perspective.discovery_results[codex-architect]`
2. `detection.verifiable_metrics` (adds suggested metrics)
3. `remediation.guidance` (refines strategy)
