# Plugin Feedback File Template

Fallback mechanism for collecting plugin-wide recommendations when GitHub issue creation is not available.

## File Location

```
.acis/plugin-feedback/FEEDBACK-{YYYYMMDD}-{AUDIT_ID}.md
```

Example: `.acis/plugin-feedback/FEEDBACK-20260205-PR60.md`

## File Structure

```markdown
# ACIS Plugin Feedback Report

**Generated**: {TIMESTAMP}
**Project**: {PROJECT_NAME}
**Audit ID**: {AUDIT_ID}
**ACIS Version**: {ACIS_VERSION}

---

## Summary

| Metric | Value |
|--------|-------|
| Total Recommendations | {TOTAL_COUNT} |
| Plugin-Scope | {PLUGIN_COUNT} |
| Pending Submission | {PENDING_COUNT} |

---

## Recommendations

### REC-{ID}: {TITLE}

| Field | Value |
|-------|-------|
| Type | {TYPE} |
| Priority | {PRIORITY} |
| Status | pending |
| Affected Components | {COMPONENTS} |

**Problem**: {PROBLEM_STATEMENT}

**Root Cause**: {ROOT_CAUSE}

**Proposed Fix**: {FIX_SUMMARY}

**Evidence**:
- Goals: {GOAL_IDS}
- Impact: {IMPACT}

---

{REPEAT FOR EACH RECOMMENDATION}

---

## Submission Instructions

When GitHub access becomes available, submit these recommendations:

```bash
# Navigate to project root
cd {PROJECT_ROOT}

# Submit all pending feedback
/acis submit-feedback

# Or manually create issues
gh issue create --repo aivantage-consulting/claude-plugin-acis \
  --title "[Process Auditor] {TYPE}: {TITLE}" \
  --body-file .acis/plugin-feedback/FEEDBACK-{DATE}-{AUDIT_ID}.md \
  --label "process-auditor,{TYPE},{PRIORITY}"
```

---

## Aggregation

This file can be aggregated with other feedback files for batch submission:

```bash
# List all pending feedback files
find .acis/plugin-feedback -name "FEEDBACK-*.md" -type f

# Aggregate into single submission
/acis aggregate-feedback --output .acis/plugin-feedback/AGGREGATED.md
```
```

## Example Feedback File

```markdown
# ACIS Plugin Feedback Report

**Generated**: 2026-02-05T23:45:00Z
**Project**: CareAICompanion
**Audit ID**: AUDIT-20260205-PR60-EXTRACTION
**ACIS Version**: 2.7.0

---

## Summary

| Metric | Value |
|--------|-------|
| Total Recommendations | 3 |
| Plugin-Scope | 3 |
| Pending Submission | 3 |

---

## Recommendations

### REC-PR60-0001: Remove severity threshold from goal extraction

| Field | Value |
|-------|-------|
| Type | correction |
| Priority | high |
| Status | pending |
| Affected Components | commands/extract.md |

**Problem**: Low/medium severity items excluded from extraction, causing 60% of actionable issues to be missed.

**Root Cause**: Extraction severity threshold is miscalibrated for thorough PR remediation.

**Proposed Fix**: Extract ALL quantifiable issues regardless of severity. Use severity for prioritization, not inclusion.

**Evidence**:
- Goals: PR60-G5, PR60-G6, PR60-G7, PR60-G8, PR60-G9, PR60-G10
- Impact: User manually identified 6 additional goals

---

### REC-PR60-0002: Add framing language patterns to extraction

| Field | Value |
|-------|-------|
| Type | correction |
| Priority | medium |
| Status | pending |
| Affected Components | commands/extract.md, templates/extraction-patterns.md |

**Problem**: Issues framed as "Recommendation", "Note", or "Risk: Low" are not recognized as extractable issues.

**Root Cause**: Extraction pattern recognition is too narrow, missing common issue framing language.

**Proposed Fix**: Add extraction triggers for "Recommendation:", "Note:", "Risk: Low/Medium" patterns.

**Evidence**:
- Goals: PR60-G7, PR60-G8, PR60-G9
- Impact: 3 goals missed due to framing language

---

### REC-PR60-0003: Implement section-agnostic extraction

| Field | Value |
|-------|-------|
| Type | correction |
| Priority | medium |
| Status | pending |
| Affected Components | commands/extract.md |

**Problem**: Issues in "Performance Review", "Code Quality", "Specific Issues" sections are deprioritized.

**Root Cause**: Extraction logic treats certain sections as less important.

**Proposed Fix**: Treat all sections equally for extraction. Section should only affect lens categorization.

**Evidence**:
- Goals: PR60-G5 through PR60-G10
- Impact: All 6 missed goals were in non-primary sections

---

## Submission Instructions

When GitHub access becomes available, submit these recommendations:

```bash
cd /Users/umesh/AI_Products/aivantage/CareAICompanion

# Submit all pending feedback
/acis submit-feedback

# Or manually create issues
gh issue create --repo aivantage-consulting/claude-plugin-acis \
  --title "[Process Auditor] Correction: Remove severity threshold from goal extraction" \
  --body-file .acis/plugin-feedback/FEEDBACK-20260205-PR60-EXTRACTION.md \
  --label "process-auditor,correction,high-priority,extraction"
```
```

## Directory Structure

```
.acis/
├── plugin-feedback/
│   ├── FEEDBACK-20260205-PR60.md
│   ├── FEEDBACK-20260203-PR58.md
│   └── AGGREGATED.md (optional, for batch submission)
└── ...
```

## Cleanup After Submission

After recommendations are submitted as GitHub issues, update the feedback file:

```markdown
### REC-PR60-0001: Remove severity threshold from goal extraction

| Field | Value |
|-------|-------|
| Type | correction |
| Priority | high |
| Status | **submitted** |
| GitHub Issue | #42 |
| Submitted At | 2026-02-06T10:30:00Z |
```

Or archive the file:
```bash
mv .acis/plugin-feedback/FEEDBACK-20260205-PR60.md \
   .acis/plugin-feedback/archive/FEEDBACK-20260205-PR60.md
```
