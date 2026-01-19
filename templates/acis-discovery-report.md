# ACIS Discovery Report Template

Template for generating discovery reports from `/acis discovery` command.

---

# ACIS Discovery Report: {TOPIC}

**Manifest ID**: {MANIFEST_ID}
**Discovery Type**: {TYPE} (feature | refactor | audit | what-if | bug-hunt)
**Created**: {CREATED_AT}
**Status**: {STATUS}

---

## Executive Summary

{2-3 sentence summary of what was discovered, key decisions surfaced, and recommended path forward}

---

## Investigation Scope

### Areas Explored
| Package/Path | Files Analyzed | Key Components |
|--------------|----------------|----------------|
| {path} | {count} | {components} |

### Perspectives Consulted

**Internal Agents**:
- [ ] security-privacy: {summary}
- [ ] tech-lead: {summary}
- [ ] test-lead: {summary}
- [ ] mobile-lead: {summary}
- [ ] oracle (end-user): {summary}
- [ ] devops-lead (operations): {summary}
- [ ] oracle (crash-resilience): {summary}
- [ ] oracle (performance): {summary}
- [ ] oracle (refactoring): {summary}

**Codex Delegations**:
- [ ] Architect: {summary}
- [ ] Scope Analyst (UX): {summary}
- [ ] Code Reviewer (Algorithm): {summary}
- [ ] Security Analyst: {summary}

**Web Search**:
- {search_query_1}: {key_finding}
- {search_query_2}: {key_finding}

---

## Key Findings

### Finding 1: {FINDING_TITLE}
**Severity**: {critical | high | medium | low}
**Category**: {security | architecture | ux | performance | operations}

{Description of finding}

**Evidence**:
```
{code snippet or grep output}
```

**Impact**: {Who/what is affected}
**Recommendation**: {What to do about it}

### Finding 2: {FINDING_TITLE}
...

---

## Decision Inventory

### Summary

| Category | Wired-In | Inherited | Pending | Total |
|----------|----------|-----------|---------|-------|
| Macro | {n} | {n} | {n} | {n} |
| Micro | {n} | {n} | {n} | {n} |
| **Total** | {n} | {n} | {n} | {n} |

### Wired-In Decisions (Existing in Codebase)

| ID | Name | Level | Value | Location |
|----|------|-------|-------|----------|
| {DEC-XXX-001} | {name} | macro/micro | {current_value} | {file:line} |

### Inherited Decisions (Must Honor)

| ID | Name | Source | Value | Implication |
|----|------|--------|-------|-------------|
| {DEC-XXX-001} | {name} | {ADR/codebase} | {value} | {what this means for implementation} |

### Pending Decisions (Require Resolution)

| ID | Name | Level | Options | CEO Convergence | Action |
|----|------|-------|---------|-----------------|--------|
| {DEC-XXX-001} | {name} | macro | {opt1, opt2} | ✅ Converged | Auto-approve |
| {DEC-XXX-002} | {name} | micro | {opt1, opt2, opt3} | ❌ Diverged | Owner decision |

---

## Decision Details (Pending)

### {DEC-XXX-001}: {DECISION_NAME}

**Level**: macro | micro
**Binding**: hard | soft
**Options**: {option1} | {option2} | {option3}

#### Value Framing
- **Category**: end-user | operations
- **Dimension**: {ux | performance | security | cost | ...}
- **Impact Statement**: {Plain English impact}
- **Personas Affected**: {Brenda, David, Dr. Evans}

#### CEO-Alpha Recommendation (Codex)
**Recommends**: {option}
**Confidence**: {high | medium | low}
**Primary Why**: {one sentence}

<details>
<summary>Full Analysis</summary>

**Modern SWE Analysis**:
- Testability: {assessment}
- Observability: {assessment}
- Failure Modes: {assessment}
- Technical Debt: {assessment}

**AI-Native Analysis**:
- Pattern Clarity: {assessment}
- Context Capture: {assessment}
- Constraint Benefit: {assessment}
- Amplification Risk: {assessment}

**Business Rationale**: {rationale}
**Compound Effect**: {effect}
</details>

#### CEO-Beta Recommendation (Claude)
**Recommends**: {option}
**Confidence**: {high | medium | low}
**Primary Why**: {one sentence}

<details>
<summary>Full Analysis</summary>

**Modern SWE Analysis**:
- Testability: {assessment}
- Observability: {assessment}
- Failure Modes: {assessment}
- Technical Debt: {assessment}

**AI-Native Analysis**:
- Pattern Clarity: {assessment}
- Context Capture: {assessment}
- Constraint Benefit: {assessment}
- Amplification Risk: {assessment}

**Business Rationale**: {rationale}
**Compound Effect**: {effect}
</details>

#### Convergence Analysis
- **Converged**: ✅ Yes | ❌ No
- **Agreement Areas**: {list}
- **Disagreement Areas**: {list}
- **Resolution Guidance**: {guidance}

#### Required Tests
1. {test description} - Status: pending
2. {test description} - Status: pending

---

## Dependency Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    DECISION DEPENDENCY MAP: {TOPIC}                         │
└─────────────────────────────────────────────────────────────────────────────┘

{ASCII diagram showing decision dependencies}

LEGEND:
  ───► enables (A must exist for B)
  ◄──► tension (tradeoff between A and B)
  ─ ─► conflicts (A and B cannot coexist)

MACRO DECISIONS: {list}
MICRO DECISIONS: {list}
```

### Dependency Constraints

| Constraint Type | From | To | Implication |
|-----------------|------|-----|-------------|
| depends_on | {DEC-A} | {DEC-B} | {implication} |
| enables | {DEC-A} | {DEC-B} | {implication} |
| tension | {DEC-A} | {DEC-B} | {tradeoff description} |

---

## Engineering Disciplines

These disciplines MUST be upheld during implementation:

| Discipline | Principle | Verification Command | Violation Severity |
|------------|-----------|---------------------|-------------------|
| offline-first | All features work without network | `pnpm test --grep 'offline'` | critical |
| phi-encryption | All PHI encrypted at rest and in transit | `grep -rn 'bloodPressure\|heartRate' packages/ \| grep -v encrypt \| wc -l` | critical |
| testability | All decisions have formal tests | `pnpm test --coverage` | high |
| observability | All operations are traceable | `grep -rn 'logger\.' packages/` | medium |

---

## Formal Tests Required

### Decision Specification Tests

| Decision | Test ID | Given | When | Then | Status |
|----------|---------|-------|------|------|--------|
| {DEC-XXX-001} | {T1} | {context} | {action} | {outcome} | pending |

### Invariant Tests

| Invariant | Command | Expected |
|-----------|---------|----------|
| No PHI in logs | `grep -rn 'log.*bloodPressure' packages/` | 0 |
| All features work offline | `pnpm test --grep 'offline'` | All pass |

---

## Generated Artifacts

| Artifact Type | Path | Description |
|---------------|------|-------------|
| Decision Manifest | `docs/manifests/{MANIFEST_ID}.json` | Binding document for implementation |
| Feature Spec | `docs/specs/{topic}.md` | (if feature type) |
| Goal Files | `docs/reviews/goals/DISC-*` | Actionable remediation items |
| ADR Draft | `docs/architecture/decisions/ADR-XXX.md` | (if architecture decisions) |

---

## Recommended Next Steps

### Immediate (Before Implementation)

1. [ ] **Resolve pending decisions**: Run `/acis resolve {MANIFEST_ID}`
   - {n} decisions auto-approved (CEOs converged)
   - {n} decisions require owner input

2. [ ] **Review inherited decisions**: Confirm these are still valid
   - {list of inherited decisions to review}

3. [ ] **Create missing tests**: {n} decision tests pending
   - Run `/acis test-scaffold {MANIFEST_ID}`

### Implementation Phase

4. [ ] **Bind manifest to remediation**:
   ```bash
   /acis remediate docs/reviews/goals/DISC-001.json --manifest docs/manifests/{MANIFEST_ID}.json
   ```

5. [ ] **Verify discipline compliance** after each iteration

### Post-Implementation

6. [ ] **Update manifest status** to `implemented`
7. [ ] **Archive decision artifacts** to project documentation

---

## Appendix: Raw Agent Outputs

<details>
<summary>security-privacy findings</summary>

{full agent output}
</details>

<details>
<summary>tech-lead findings</summary>

{full agent output}
</details>

<details>
<summary>Codex Architect findings</summary>

{full agent output}
</details>

{... other agents ...}

---

**Report Generated**: {TIMESTAMP}
**ACIS Version**: 2.0
**Manifest**: `docs/manifests/{MANIFEST_ID}.json`
