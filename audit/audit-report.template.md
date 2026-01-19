# ACIS Process Auditor Report

**Audit ID**: AUDIT-{TIMESTAMP}
**Date**: {DATE}
**Project**: {PROJECT_NAME}
**Scope**: {GOAL_COUNT} goals since {LAST_AUDIT_DATE}

---

## Executive Summary

{2-3 sentence summary: goals analyzed, key patterns found, skills generated}

### Quick Stats

| Metric | Value |
|--------|-------|
| Goals Analyzed | {GOAL_COUNT} |
| Achieved | {ACHIEVED_COUNT} ({ACHIEVED_PCT}%) |
| Pending | {PENDING_COUNT} ({PENDING_PCT}%) |
| Failed | {FAILED_COUNT} ({FAILED_PCT}%) |
| Avg Iterations | {AVG_ITERATIONS} |
| Skills Generated | {SKILLS_GENERATED} |
| Skills Deprecated | {SKILLS_DEPRECATED} |

---

## Goal Distribution

### By Category

| Category | Count | Avg Iterations | Quick Wins |
|----------|-------|----------------|------------|
| Security | {N} | {avg} | {quick_wins} |
| Architecture | {N} | {avg} | {quick_wins} |
| UX | {N} | {avg} | {quick_wins} |
| Performance | {N} | {avg} | {quick_wins} |
| Operations | {N} | {avg} | {quick_wins} |

### By Effort

| Effort Level | Count | Percentage |
|--------------|-------|------------|
| Quick Wins (1-2 iter) | {N} | {pct}% |
| Moderate (3-5 iter) | {N} | {pct}% |
| Hard Problems (6+ iter) | {N} | {pct}% |

---

## Reinforcements (Keep Doing)

Patterns that worked well and should be continued.

### {REINFORCEMENT_1_TITLE}

**Pattern**: {description}
**Evidence**: Goals {goal_ids}
**Impact**: {time_saved or quality_improved}

**Recommendation**: {how to apply more consistently}

### {REINFORCEMENT_2_TITLE}

...

---

## Corrections (Need to Change)

Patterns that caused friction or should be improved.

### {CORRECTION_1_TITLE}

**Problem**: {description}
**Evidence**: Goals {goal_ids}
**Impact**: {time_wasted or rework_caused}

**Root Cause**: {why this happened}
**Proposed Fix**: {specific change}
**Status**: {applied | pending_approval | rejected}

### {CORRECTION_2_TITLE}

...

---

## Skills Generated

Skills extracted from repeated patterns this audit.

### {SKILL_1_NAME}

| Attribute | Value |
|-----------|-------|
| Location | `skills/{skill-name}/SKILL.md` |
| Pattern Frequency | {N} occurrences |
| Estimated ROI | {X}% time savings |
| Origin Goals | {goal_ids} |
| Trigger Phrase | "{trigger}" |

**Steps**:
1. {step_1}
2. {step_2}
3. {step_3}

### {SKILL_2_NAME}

...

---

## Skills Deprecated

Skills that are no longer providing value.

| Skill | Reason | Action Taken |
|-------|--------|--------------|
| {skill_name} | {reason} | Archived to `skills/.archive/` |

---

## Skill Candidates Rejected

Patterns that were evaluated but didn't meet all criteria.

| Pattern | Frequency | Rejection Reason |
|---------|-----------|------------------|
| {pattern} | {N} | {criterion failed} |

---

## Detection Command Effectiveness

### High Performers

Commands with 100% accuracy (no false positives/negatives).

| Command | Goals Used | Accuracy |
|---------|------------|----------|
| `{command}` | {N} | 100% |

### Needs Improvement

Commands that had issues.

| Command | Issue | Recommendation |
|---------|-------|----------------|
| `{command}` | {false_positive/negative} | {improvement} |

---

## 5 Whys Analysis Depth

| Depth | Count | Success Rate |
|-------|-------|--------------|
| WHY-1/2 (shallow) | {N} | {pct}% |
| WHY-3/4 (moderate) | {N} | {pct}% |
| WHY-5 (deep) | {N} | {pct}% |

**Observation**: {correlation between depth and fix quality}

---

## Process Adjustments Applied

Changes made to ACIS configuration based on this audit.

| Adjustment Type | Description | File Modified |
|-----------------|-------------|---------------|
| {type} | {description} | `{file}` |

---

## Metrics Trends

Compared to previous audit (if available).

| Metric | Previous | Current | Change |
|--------|----------|---------|--------|
| Avg Iterations | {prev} | {curr} | {delta} |
| Quick Win % | {prev}% | {curr}% | {delta} |
| Skills Active | {prev} | {curr} | {delta} |

---

## Next Steps

### Before Next Audit

1. [ ] Review and approve pending corrections
2. [ ] Test newly generated skills
3. [ ] Monitor flagged detection commands

### Audit Trigger

- **Threshold**: {auditThreshold} goals
- **Current Count**: 0
- **Next Audit**: After {auditThreshold} more goal completions

---

## Appendix: Goal Details

<details>
<summary>Goals Analyzed ({GOAL_COUNT})</summary>

| Goal ID | Status | Iterations | Category |
|---------|--------|------------|----------|
| {goal_id} | {status} | {iter} | {category} |
...

</details>

<details>
<summary>Raw Pattern Data</summary>

```json
{
  "patterns": {
    "step_sequences": [...],
    "fix_types": {...},
    "detection_commands": {...}
  }
}
```

</details>

---

**Report Generated**: {FULL_TIMESTAMP}
**ACIS Version**: {VERSION}
**Audit Duration**: {DURATION_MINUTES} minutes
