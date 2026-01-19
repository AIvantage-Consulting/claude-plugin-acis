# Codex Algorithm Discovery Template

Use this template for algorithm elegance and efficiency analysis.

## Delegation Format

```
TASK: Analyze {GOAL_ID} for algorithmic elegance and computational efficiency.

EXPECTED OUTCOME: Algorithm assessment with optimization recommendations.

MODE: Advisory

CONTEXT:
- Goal: {GOAL_DESCRIPTION}
- Affected code: {CODE_SNIPPET}
- Runtime environment: React Native (iOS/Android), Node.js
- Performance constraints: <200ms UI response, battery-conscious

CONSTRAINTS:
- Must work on mobile devices with limited CPU/memory
- Battery efficiency is critical (healthcare app used daily)
- Must handle offline data sets
- PHI data must never be logged or exposed

MUST DO:
- Analyze time complexity (Big-O)
- Analyze space complexity
- Identify computational hotspots
- Recommend more elegant solutions if applicable
- Consider edge cases and boundary conditions
- Verify mathematical correctness

MUST NOT DO:
- Premature optimization at cost of readability
- Ignore battery/memory constraints
- Recommend algorithms that don't work offline

OUTPUT FORMAT:
## Algorithm Analysis

### Current Implementation
- **Time Complexity**: O(?)
- **Space Complexity**: O(?)
- **Hotspots**: [identified bottlenecks]

### Correctness Verification
- **Edge Cases**: [list of edge cases to handle]
- **Boundary Conditions**: [min/max values, empty inputs]
- **Mathematical Properties**: [invariants that must hold]

## Elegance Assessment

### Code Quality
- **Readability**: [1-5 score with notes]
- **Maintainability**: [1-5 score with notes]
- **Expressiveness**: [1-5 score with notes]

### Improvement Opportunities
1. [Improvement 1]
   - Current: [what exists]
   - Proposed: [what could be better]
   - Benefit: [why it's better]

## Optimization Recommendations

### Quick Wins (No complexity change)
- [Optimization 1]
- [Optimization 2]

### Algorithmic Improvements (Complexity change)
- **Current**: O(n²) → **Proposed**: O(n log n)
- **Trade-off**: [space vs time, readability vs performance]

## Metrics to Verify
- **Performance Metric**: [command to measure]
  - Expected: [target value]
  - Tolerance: [acceptable range]

## Test Scenarios for Edge Cases
1. Empty input: [expected behavior]
2. Single element: [expected behavior]
3. Maximum size: [expected behavior]
4. Duplicate values: [expected behavior]
```

## Integration with ACIS

The Algorithm response feeds into:
1. `detection.verifiable_metrics` (performance metrics)
2. `behavioral.acceptance_scenarios` (edge case tests)
3. `remediation.guidance` (optimization strategy)
