# ACIS Critical Review Report Template

Template for generating health reports from `/acis:critical-review` command.

---

```
+============================================================================+
|  ACIS CRITICAL REVIEW: {SCOPE_DESCRIPTION}                                  |
|  Date: {DATE}  |  Depth: {DEPTH}  |  ACIS v{VERSION}                       |
+============================================================================+
|                                                                              |
|  OVERALL HEALTH: {OVERALL_GRADE}                                            |
|  Density: {OVERALL_DENSITY}/kLOC  |  {FILE_COUNT} files  |  {LOC} LOC      |
|                                                                              |
+------------------------------------------------------------------------------+
|                                                                              |
|  PER-LENS HEALTH SCORES                                                     |
|  -------------------------------------------------------------------------- |
|                                                                              |
|  Lens               Grade  Density   Crit  High  Med   Low   Findings       |
|  ─────────────────  ─────  ────────  ────  ────  ────  ────  ────────       |
|  {LENS_NAME}        {GRD}  {DENS}    {C}   {H}   {M}   {L}   {TOTAL}       |
|  ...                                                                         |
|                                                                              |
|  * Security/Privacy lenses weighted 2x in overall grade                     |
|                                                                              |
+------------------------------------------------------------------------------+
|                                                                              |
|  CRITICAL & HIGH FINDINGS ({CRIT_HIGH_COUNT})                               |
|  -------------------------------------------------------------------------- |
|                                                                              |
|  [{SEV}] {FINDING_ID}: {DESCRIPTION}                                        |
|    File: {FILE}:{LINE}                                                       |
|    Lens: {LENS}  |  Source: {SOURCE}                                        |
|    Fix:  {RECOMMENDATION}                                                   |
|                                                                              |
|  ...                                                                         |
|                                                                              |
+------------------------------------------------------------------------------+
|                                                                              |
|  CROSS-PERSPECTIVE CORRELATIONS ({CORRELATION_COUNT})                       |
|  (Findings surfaced by multiple perspectives)                               |
|  -------------------------------------------------------------------------- |
|                                                                              |
|  Group: {FINDING_IDS}                                                        |
|    Perspectives: {PERSPECTIVE_LIST}                                          |
|    Escalated: {YES/NO} ({REASON})                                           |
|                                                                              |
|  ...                                                                         |
|                                                                              |
+------------------------------------------------------------------------------+
|                                                                              |
|  POSITIVE PATTERNS OBSERVED                                                 |
|  -------------------------------------------------------------------------- |
|                                                                              |
|  + {POSITIVE_PATTERN_DESCRIPTION}                                           |
|    ({LENS}, observed in {FILES})                                             |
|                                                                              |
|  ...                                                                         |
|                                                                              |
+------------------------------------------------------------------------------+
|                                                                              |
|  COMPARISON ({TREND})  [only with --compare]                                |
|  -------------------------------------------------------------------------- |
|                                                                              |
|  Previous: {PREV_DATE}  Grade: {PREV_GRADE} -> {CURR_GRADE}                |
|  New findings: {NEW}  |  Resolved: {RESOLVED}  |  Persistent: {PERSIST}    |
|                                                                              |
|  Per-Lens Trend:                                                             |
|    {LENS}: {PREV_GRADE} -> {CURR_GRADE} ({TREND})                           |
|                                                                              |
+------------------------------------------------------------------------------+
|                                                                              |
|  NEXT STEPS                                                                 |
|  -------------------------------------------------------------------------- |
|                                                                              |
|  1. Fix {CRITICAL_COUNT} critical findings immediately                      |
|  2. Address {HIGH_COUNT} high-severity findings in next sprint              |
|  3. Run /acis:discovery on low-grade lenses for deeper investigation        |
|  4. Re-run with --compare to track improvement:                             |
|     /acis:critical-review {SCOPE} --compare {THIS_FINDINGS_PATH}            |
|                                                                              |
|  Generate remediation goals:                                                 |
|     /acis:critical-review {SCOPE} --generate-goals --severity high          |
|                                                                              |
+============================================================================+
|  Report: {REPORT_PATH}                                                       |
|  Findings: {FINDINGS_JSON_PATH}                                             |
|  Goals: {GOALS_COUNT} generated  [only with --generate-goals]               |
+============================================================================+
```

## Grade Scale Reference

| Grade | Density (per kLOC) | Interpretation |
|-------|-------------------|----------------|
| A | 0-5 | Excellent — minimal issues |
| B | 6-15 | Good — minor improvements possible |
| C | 16-30 | Acceptable — notable issues to address |
| D | 31-60 | Needs Work — significant issues |
| F | 61+ | Critical — requires immediate attention |

## Density Formula

```
Per-lens density = sum(severity_weights) / lines_in_scope * 1000

Severity weights (from assessment-lenses.json):
  critical = 100
  high     = 50
  medium   = 20
  low      = 5

Overall = weighted average of per-lens densities
  (security and privacy lenses weighted 2x)
```

## Conditional Sections

- **Cross-Perspective Correlations**: Only shown at `--depth medium` or `--depth deep`
- **Comparison**: Only shown with `--compare <path>`
- **Goals Generated**: Only shown with `--generate-goals`
- **Codex Findings**: Agent source shows "codex" only at `--depth deep`

## JSON Output (--json flag)

When `--json` is specified, output the raw findings JSON (conforming to `critical-review-findings.schema.json`) instead of this ASCII report.
