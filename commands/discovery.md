# ACIS Discovery - Multi-Perspective Investigation

You are executing the ACIS discovery command. This performs proactive, multi-perspective investigation that surfaces decisions before implementation.

## Arguments

- `$ARGUMENTS` - Topic to investigate in quotes (e.g., `"offline data sync"`, `"authentication flow"`)

## Purpose

AI-generated code is often poor quality because macro/micro decisions are made implicitly and fragmented across files. Discovery surfaces these decisions BEFORE implementation, creating a binding manifest that ensures coherent, discipline-bound code.

## Workflow

### Phase 1: SCOPE ANALYSIS

Parse the topic to determine:

1. **Investigation Type**:
   - `feature`: New functionality investigation
   - `refactor`: Existing code restructuring
   - `audit`: Quality/compliance assessment
   - `what-if`: Exploratory scenario analysis
   - `bug-hunt`: Root cause investigation

2. **Relevant Codebase Areas**:
   - Packages/modules affected
   - Components involved
   - Dependencies at play

3. **Investigation Boundaries**:
   - What's in scope
   - What's explicitly out of scope

Write scope to: `${config.paths.state}/discovery-scope.md`

### Phase 2: MULTI-PERSPECTIVE EXPLORATION (Parallel Fresh Agents)

Launch ALL exploration agents **simultaneously** (single message, multiple Task/Codex calls):

**Internal Agents (via Task tool)**:

| Agent | Focus | Output |
|-------|-------|--------|
| security-privacy | PHI decisions, security patterns | Wired-in + pending decisions |
| tech-lead | Architecture decisions, design patterns | Dependencies, tradeoffs |
| test-lead | Testing strategy, coverage | Test approach decisions |
| mobile-lead | Platform decisions, offline strategy | Sync considerations |
| oracle (persona) | UX decisions, journey impacts | Persona effects |
| devops-lead | Operations, deployment, monitoring | Cost implications |
| oracle (resilience) | Failure handling, recovery | Failure modes |

**Codex Delegations (if available)**:

| Expert | Template | Focus |
|--------|----------|-------|
| Architect | `codex-architect-discovery.md` | System design decisions |
| UX Analyst | `codex-ux-discovery.md` | Persona impact decisions |
| Algorithm Expert | `codex-algorithm-discovery.md` | Efficiency tradeoffs |
| Security Analyst | `codex-security-discovery.md` | Threat model, hardening |

**Web Search**: `"{topic} best practices 2026"`

### Phase 3: DECISION EXTRACTION

For each decision surfaced, categorize:

```json
{
  "id": "DEC-{CATEGORY}-{NUMBER}",
  "name": "Decision Name",
  "level": "macro | micro",
  "status": "wired-in | pending | inherited",
  "specification": {
    "current_value": "current approach",
    "allowed_values": ["option1", "option2", "option3"]
  },
  "value_framing": {
    "category": "end-user | operations",
    "dimension": "ux | performance | security | cost",
    "impact_statement": "This affects [persona]'s [journey]..."
  },
  "source_agent": "which agent surfaced this"
}
```

**Decision Types**:
- **Wired-in**: Already decided and implemented in codebase
- **Pending**: Needs to be decided before proceeding
- **Inherited**: Follows from a higher-level decision

### Phase 4: DUAL-CEO VALIDATION (Parallel)

For each **pending** decision, get independent recommendations:

**CEO-Alpha**: AI-Native Engineering CEO
- How does this decision leverage or constrain AI capabilities?
- Pattern clarity, context capture, amplification risk

**CEO-Beta**: Modern SWE Discipline CEO
- How does this decision uphold engineering principles?
- Testability, observability, failure modes, tech debt

### Phase 5: CONVERGENCE DETECTION

```
If CEO-Alpha.recommendation == CEO-Beta.recommendation:
  → Auto-resolvable (no human needed)
  → Mark for auto-approval in resolve phase

If CEO-Alpha.recommendation != CEO-Beta.recommendation:
  → Must surface to project owner
  → Capture both dissent points
  → Requires human judgment
```

### Phase 6: MANIFEST & ARTIFACT GENERATION

**Output Files**:

| File | Location | Contents |
|------|----------|----------|
| Discovery Report | `${config.paths.discovery}/DISC-{date}-{topic}.md` | Full analysis |
| Decision Manifest | `${config.paths.decisions}/DISC-{date}-{topic}.json` | Structured decisions |
| Spec Draft | `${config.paths.discovery}/SPEC-{date}-{topic}.md` | Implementation spec |
| Goal Suggestions | `${config.paths.goals}/` | Optional goal files |
| ADR Draft | `${config.paths.discovery}/ADR-{date}-{topic}.md` | Architecture Decision Record |

## Flags

| Flag | Description |
|------|-------------|
| `--type <type>` | Investigation type: feature, refactor, audit, what-if, bug-hunt |
| `--scope <paths>` | Limit investigation to specific paths (comma-separated) |
| `--depth <level>` | shallow (quick scan), medium (default), deep (thorough) |
| `--skip-codex` | Skip Codex delegations (internal agents only) |
| `--use-codex` | Override `pluginDefaults.skipCodex` |
| `--force-codex` | Require Codex (error if unavailable) |
| `--parallel` | Run all perspectives in parallel (default: ON) |
| `--output <artifacts>` | Comma-separated: report, manifest, spec, goals, adr (default: all) |
| `--no-ceo` | Skip Dual-CEO validation phase |

## Output Report Format

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  ACIS Discovery Report: "{topic}"                                            ║
║  Type: {investigation_type} | Depth: {depth} | {timestamp}                   ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  📍 SCOPE                                                                    ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║  In Scope:  packages/foundation/*, packages/mobile/src/services/sync/*      ║
║  Out Scope: tests, mocks, UI components                                      ║
║                                                                              ║
║  🔒 WIRED-IN DECISIONS (Already Decided)                                     ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  DEC-SYNC-001: Offline Sync Strategy = "queue-and-flush"                    ║
║  DEC-ENC-001:  PHI Encryption = "SQLCipher with AES-256"                    ║
║  DEC-ARCH-001: Three-Layer Architecture = "Foundation → Composition → UX"  ║
║                                                                              ║
║  ⏳ PENDING DECISIONS (Need Resolution)                                      ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  DEC-SYNC-002: Conflict Resolution Strategy                                  ║
║    Options: last-write-wins | crdt | manual-merge                           ║
║    CEO-Alpha: CRDT (AI coherence benefit)                                   ║
║    CEO-Beta:  CRDT (deterministic, testable)                                ║
║    Status: ✅ CONVERGED → Auto-resolvable                                   ║
║                                                                              ║
║  DEC-SYNC-003: Sync Frequency                                                ║
║    Options: immediate | batched | scheduled                                  ║
║    CEO-Alpha: Batched (context efficiency)                                  ║
║    CEO-Beta:  Immediate (user expectation)                                  ║
║    Status: ❌ DIVERGED → Needs human decision                                ║
║                                                                              ║
║  📊 FINDINGS BY PERSPECTIVE                                                  ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  Security:     3 findings | 2 decisions | 1 goal suggestion                 ║
║  Architecture: 5 findings | 3 decisions | 2 goal suggestions                ║
║  Testing:      2 findings | 1 decision  | 0 goal suggestions                ║
║  Mobile:       4 findings | 2 decisions | 1 goal suggestion                 ║
║  Personas:     2 findings | 1 decision  | 0 goal suggestions                ║
║                                                                              ║
║  🎯 NEXT STEPS                                                               ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  1. /acis:resolve docs/acis/decisions/DISC-2026-01-24-sync.json             ║
║     (Resolve pending decisions - 1 converged, 1 diverged)                   ║
║                                                                              ║
║  2. Review goal suggestions (4 suggested)                                   ║
║     docs/acis/goals/DISC-SYNC-*.json                                        ║
║                                                                              ║
║  📁 Files Generated:                                                         ║
║    docs/acis/discovery/DISC-2026-01-24-sync.md (this report)                ║
║    docs/acis/decisions/DISC-2026-01-24-sync.json (decision manifest)        ║
║    docs/acis/discovery/SPEC-2026-01-24-sync.md (implementation spec)        ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Estimation Rules (CRITICAL)

**ACIS uses COMPLEXITY-based estimation, NEVER time-based estimation.**

When estimating effort for decisions, goals, or implementation work:

### ❌ FORBIDDEN (Never Output)
- `"8h"`, `"24h"`, `"40h → 56h"`
- `"2 hours"`, `"3 days"`, `"1 week"`
- `"Effort: 8 hours"`
- `"Total Effort: 40h"`
- Any numeric time estimate

### ✅ REQUIRED (Always Use)
- **Complexity Tier**: Tier 1 (Simple), Tier 2 (Moderate), Tier 3 (Complex)
- **Effort Category**: Quick / Short / Medium / Large
- **What + Why**: Brief description of what's involved and why it's that complexity

### Complexity Tier Definitions

| Tier | Category | What It Means |
|------|----------|---------------|
| **1** | Quick/Short | Single file, pattern replacement, clear fix |
| **2** | Medium | Multi-file, requires understanding, some decisions |
| **3** | Large | Architecture impact, multiple components, significant decisions |

### Example Output
```
DEC-SYNC-002: Conflict Resolution Strategy
  Complexity: Tier 2 (Medium) - Multi-file change across sync layer,
              requires CRDT library integration and conflict UI
```

## Examples

```bash
# Basic discovery on a topic
/acis:discovery "offline data synchronization"

# Feature investigation with deep analysis
/acis:discovery "voice-first medication reminders" --type feature --depth deep

# Refactor scoped to specific packages
/acis:discovery "error handling patterns" --type refactor --scope "packages/foundation/*"

# Audit without Codex
/acis:discovery "PHI exposure audit" --type audit --skip-codex

# Bug hunt with forced full analysis
/acis:discovery "session initialization race condition" --type bug-hunt --force-codex

# Generate only manifest and spec
/acis:discovery "authentication flow" --output manifest,spec
```

## Integration with Other Commands

After discovery:
1. **Resolve**: `/acis:resolve <manifest>` - Resolve pending decisions
2. **Extract**: Goals may be suggested in discovery output
3. **Remediate**: Use manifest to bind remediation to resolved decisions

```bash
# Full workflow
/acis:discovery "offline sync" --type feature
/acis:resolve docs/acis/decisions/DISC-2026-01-24-sync.json
/acis:remediate docs/acis/goals/SYNC-001.json --manifest docs/acis/decisions/DISC-2026-01-24-sync.json
```
