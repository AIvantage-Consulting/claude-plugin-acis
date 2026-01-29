# ACIS User Guide

## Automated Code Improvement System v2.5

ACIS is an LLM-powered system that transforms PR review comments into quantifiable, trackable remediation goals. The system features **decision-oriented discovery**, **dual-CEO validation**, **behavioral TDD**, **parallel remediation**, **swarm orchestration**, **quality gates**, and **observability traces**.

---

## Table of Contents

1. [Overview](#overview)
2. [Version History](#version-history)
3. [How ACIS Works](#how-acis-works)
4. [Using ACIS Commands](#using-acis-commands)
5. [Decision-Oriented Discovery](#decision-oriented-discovery)
6. [Dual-CEO Validation](#dual-ceo-validation)
7. [Decision Manifests](#decision-manifests)
8. [Multi-Perspective Discovery](#multi-perspective-discovery)
9. [Behavioral TDD](#behavioral-tdd)
10. [Ralph-Loop Remediation](#ralph-loop-remediation)
11. [Multi-Perspective 5 Whys](#multi-perspective-5-whys)
12. [Consensus Verification](#consensus-verification)
13. [Quality Gate](#quality-gate)
14. [Parallel Remediation](#parallel-remediation)
15. [Swarm Orchestration](#swarm-orchestration)
16. [ACIS Traces](#acis-traces)
17. [Goal File Structure](#goal-file-structure)
18. [Independently Verifiable Metrics](#independently-verifiable-metrics)
19. [Complexity Tiers](#complexity-tiers)
20. [Safety Rules](#safety-rules)
21. [Examples](#examples)
22. [Codex Integration](#codex-integration)

---

## Overview

### What is ACIS?

ACIS (Automated Code Improvement System) is a structured workflow for:

- **Extracting** quantifiable goals from PR review comments
- **Discovering** issues via 10+ parallel agent perspectives
- **Remediating** code issues systematically using behavioral TDD
- **Verifying** completion via multi-agent consensus with independently verifiable metrics

### Key Benefits

| Benefit | Description |
| ------- | ----------- |
| **Multi-Perspective** | 10+ agents analyze each goal from different angles |
| **Behavioral TDD** | Persona-driven acceptance tests before implementation |
| **Independently Verifiable** | Every metric can be verified by any agent |
| **Consensus-Driven** | 3/4 agent approval required with veto power for security |
| **Codex-Enhanced** | External perspectives from Architecture, UX, Algorithm experts |

---

## Version History

### v2.5.0 - Swarm Orchestration (2026-01-30)

**Multi-agent coordination using Claude Code's TeammateTool:**

| Feature | Description |
|---------|-------------|
| TeammateTool integration | Persistent agent teams with inbox-based communication |
| Self-organizing swarms | Workers claim tasks from shared queue automatically |
| Task dependencies | Auto-unblocking when dependencies complete |
| Graceful shutdown | Heartbeat monitoring with proper cleanup protocols |
| `--swarm` flag | Enable swarm mode for `/acis remediate-parallel` |
| Fallback support | Uses Task tool when TeammateTool unavailable |

**Requirements:** Claude Code v2.1.19+ for full swarm features.

### v2.4.0 - ACIS Traces (2026-01-28)

**Observability for user visibility and Process Auditor learning:**

| Feature | Description |
|---------|-------------|
| User-visible traces | `[ACIS:{loop}:{phase}]` prefix format for execution visibility |
| Structured traces | JSON-based traces for micro-decisions, knowledge gaps, skill applications |
| Trace types | lifecycle, decision, knowledge, skill, effectiveness, blocker |
| Dual storage | Project traces (`docs/acis/traces/`) and process traces (`.acis/traces/`) |
| Process Auditor integration | Traces consumed as hints for pattern detection and skill generation |

### v2.3.0 - Parallel Remediation (2026-01-28)

**Worktree-isolated parallel goal execution:**

| Feature | Description |
|---------|-------------|
| `/acis remediate-parallel` | New command for parallel goal remediation |
| Git worktree isolation | Each goal runs in isolated worktree protecting baseline |
| File-disjointness verification | Checks for file conflicts before parallelization |
| Atomic step commits | Fine-grained rollback capability |
| Integration branch merge | Sequential merge with conflict classification |
| History preservation | Tags archive work before squash to main |

### v2.2.0 - Quality Gate & Trust-but-Re-verify (2026-01-27)

**External code review and smart duplicate detection:**

| Feature | Description |
|---------|-------------|
| Quality Gate | Codex code review before marking goals achieved |
| Stuck Consultation | Codex problem-solving after 4+ stuck iterations |
| Trust but Re-verify | TTL-based re-verification (14-60 days based on confidence) |
| Change detection | Git change detection triggers mandatory re-check |
| Spot-check sampling | 10% random verification of previously achieved goals |
| Known resolutions registry | Intentional exceptions for verified exceptions |

### v2.1.0 - Decision-Oriented Discovery (2026-01-22)

**Proactive investigation with decision surfacing:**

| Feature | Description |
|---------|-------------|
| `/acis discovery` | Proactive investigation before implementation |
| Dual-CEO Validation | AI-Native + Modern SWE perspectives on decisions |
| Decision Manifests | Binding documents that enforce coherent code generation |
| Auto-resolution | Converged CEO recommendations auto-approved |
| Path Validation | Enforce relative paths, prevent `..` traversal |

### v2.0.0 - Initial Plugin Release (2026-01-19)

**Three-loop architecture with multi-agent consensus:**

| Feature | Description |
|---------|-------------|
| Three-loop architecture | Process → Discovery → Remediation loops |
| Multi-perspective discovery | 10+ agents analyze in parallel |
| Behavioral TDD | Persona-driven acceptance tests before code |
| Consensus verification | Independent metric verification with veto power |
| Process Auditor | Pattern analysis and dynamic skill generation |

---

## How ACIS Works

### Four-Phase Workflow (v2.0)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ACIS v2.0 Pipeline                               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐           ┌───────────────┐           ┌───────────────┐
│   PHASE 1     │           │   PHASE 2     │           │   PHASE 3     │
│   DISCOVERY   │──────────▶│  BEHAVIORAL   │──────────▶│  RALPH-LOOP   │
│               │           │     TDD       │           │               │
│ 10+ Parallel  │           │ Persona Tests │           │ MEASURE→FIX   │
│   Agents      │           │    FIRST      │           │    →VERIFY    │
└───────────────┘           └───────────────┘           └───────────────┘
        │                           │                           │
        │  Internal Agents          │  Given/When/Then          │  Until all
        │  + Codex Experts          │  Acceptance Tests         │  metrics pass
        │  + Web Search             │                           │
        │                           │                           │
        └───────────────────────────┴───────────────────────────┘
                                    │
                                    ▼
                          ┌───────────────┐
                          │   PHASE 4     │
                          │  CONSENSUS    │
                          │               │
                          │ Independent   │
                          │ Verification  │
                          │ by All Agents │
                          └───────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ ≥75% APPROVE + No Vetoes      │
                    │              │                │
                    │              ▼                │
                    │   GOAL ACHIEVED               │
                    └───────────────────────────────┘
```

#### Phase 1: MULTI-PERSPECTIVE DISCOVERY

10+ agents analyze the goal in parallel:

**Internal Agents**:
- `security-privacy` - PHI protection, HIPAA compliance
- `tech-lead` - Architecture patterns, design quality
- `test-lead` - Coverage gaps, test strategies
- `mobile-lead` - Platform compatibility, offline support
- `oracle` (end-user) - Persona impact, UX concerns
- `devops-lead` (operations) - Deployment, monitoring
- `oracle` (crash-resilience) - Failure modes, error handling
- `oracle` (performance) - Memory, CPU, battery
- `oracle` (refactoring) - Code quality opportunities

**Codex Delegations**:
- `Architect` - System design tradeoffs
- `Scope Analyst` (UX) - Persona journeys, accessibility
- `Code Reviewer` (Algorithm) - Efficiency, elegance
- `Security Analyst` - Hardening, threat model

**Web Search**:
- Best practices for {goal topic}

#### Phase 2: BEHAVIORAL TDD (Default ON)

Before any implementation:

1. Extract affected personas from discovery
2. Write Given/When/Then acceptance scenarios
3. Create behavioral test file
4. Run tests - expect FAIL (RED)

#### Phase 3: RALPH-LOOP REMEDIATION

Execute remediation loop:

1. MEASURE: Run ALL verifiable metrics
2. CHECK: If all pass → exit to Phase 4
3. ANALYZE: Identify files to fix
4. FIX: Apply TDD (RED → GREEN)
5. REPORT: Output iteration checkpoint
6. LOOP: Continue until target

#### Phase 4: CONSENSUS VERIFICATION (Default ON)

Multi-agent independent verification:

1. Launch verification agents in parallel
2. Each agent runs assigned metrics independently
3. Each agent returns APPROVE / REQUEST_CHANGES / REJECT
4. Consensus: ≥75% approve + no vetoes = ACHIEVED

---

## Decision-Oriented Discovery

### Overview

`/acis discovery "<topic>"` enables **proactive investigation** that surfaces decisions before implementation. Unlike reactive PR remediation, discovery investigates topics that haven't been implemented yet.

### Investigation Types

| Type | Purpose | Example |
|------|---------|---------|
| `feature` | New capability analysis | "offline voice commands for Brenda" |
| `refactor` | Code improvement opportunity | "consolidate encryption utilities" |
| `audit` | Security/compliance review | "PHI exposure risks in sync layer" |
| `what-if` | Hypothetical impact analysis | "what if we added multi-device sync" |
| `bug-hunt` | Proactive issue discovery | "race conditions in SyncEngine" |

### Discovery Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    /acis discovery "<topic>"                         │
└─────────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│   PHASE 1     │       │   PHASE 2     │       │   PHASE 3     │
│    SCOPE      │──────▶│  EXPLORE      │──────▶│   EXTRACT     │
│   ANALYSIS    │       │  10+ Agents   │       │  DECISIONS    │
└───────────────┘       └───────────────┘       └───────────────┘
        │                       │                       │
        └───────────────────────┴───────────────────────┘
                                │
                                ▼
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│   PHASE 4     │       │   PHASE 5     │       │   PHASE 6     │
│  DUAL-CEO     │──────▶│  CONVERGENCE  │──────▶│   MANIFEST    │
│  VALIDATION   │       │  DETECTION    │       │  GENERATION   │
└───────────────┘       └───────────────┘       └───────────────┘
```

### Decision Types

| Type | Description | Example |
|------|-------------|---------|
| **Wired-In** | Already implemented in code | `queue: QueuedOperation[]` uses in-memory array |
| **Inherited** | Must honor existing decisions | PHI encryption from ADR-003 |
| **Pending** | Requires resolution before implementation | Voice processing: on-device vs cloud |

### Decision Levels

| Level | Scope | Examples |
|-------|-------|----------|
| **Macro** | Architectural, system-wide | Sync strategy, encryption at rest, offline-first |
| **Micro** | Implementation detail | Retry count, timeout values, cache TTL |

### Value Framing

Every decision is framed in terms of value impact:

**End-User Value**:
- **UX**: User experience, cognitive load, accessibility
- **Performance**: Response times, battery life, data usage
- **Security**: PHI protection, authentication, privacy
- **Reliability**: Offline capability, sync confidence

**Operations Value**:
- **Cost**: Infrastructure, cloud services, storage
- **Monetization**: Business model enablers
- **Maintenance**: Long-term supportability, tech debt
- **Scalability**: Growth readiness, multi-tenancy

### Example Usage

```bash
# New feature discovery
/acis discovery "offline voice commands for Brenda" --type feature

# Security audit
/acis discovery "PHI exposure risks in sync layer" --type audit --depth deep

# Refactoring opportunity
/acis discovery "consolidate encryption utilities" --type refactor --scope packages/foundation

# What-if analysis
/acis discovery "what if we added real-time multi-device sync" --type what-if
```

---

## Dual-CEO Validation

### Overview

For every **pending decision**, two independent CEO agents provide recommendations. This creates productive tension between different value systems, surfacing important tradeoffs.

### The Two CEOs

| CEO | Agent | Focus | Bias |
|-----|-------|-------|------|
| **CEO-Alpha** | Codex (via claude-delegator) | AI leverage and optionality | Higher risk tolerance if disciplined |
| **CEO-Beta** | Claude Oracle (internal) | Simplicity and discipline | Lower risk, prefer proven patterns |

### CEO Analysis Framework

Both CEOs analyze through the same lenses:

**Modern SWE Discipline**:
| Dimension | Question |
|-----------|----------|
| Testability | How easy to test this decision's implementation? |
| Observability | How easy to monitor and debug? |
| Failure Modes | What can go wrong? How graceful is degradation? |
| Technical Debt | Does this create or pay down debt? |

**AI-Native Analysis**:
| Dimension | Question |
|-----------|----------|
| Pattern Clarity | How clear is this for AI to follow consistently? |
| Context Capture | Can this decision be captured in AI context windows? |
| Constraint Benefit | Does this create helpful constraints for AI? |
| Amplification Risk | What gets amplified if AI applies this pattern? |

### CEO Output Format

Each CEO provides:
1. **Recommendation**: The chosen option
2. **Confidence**: high / medium / low
3. **Primary Why**: One sentence - the core reason
4. **Full Analysis**: Modern SWE + AI-Native assessments
5. **Business Rationale**: Value creation, cost, risk tradeoffs
6. **Compound Effect**: What compounds over time (value or debt)?
7. **Dissent Point**: Counterargument if disagreeing with other CEO

### Convergence Detection

```
┌─────────────────────────────────────────────────────────────┐
│              CEO-Alpha Recommends: on-device                 │
│              CEO-Beta Recommends: on-device                  │
├─────────────────────────────────────────────────────────────┤
│                    ✅ CONVERGED                              │
│              Auto-resolvable: YES                            │
│              → Can be auto-approved                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              CEO-Alpha Recommends: hybrid                    │
│              CEO-Beta Recommends: time-based                 │
├─────────────────────────────────────────────────────────────┤
│                    ❌ DIVERGED                               │
│              Auto-resolvable: NO                             │
│              → Must surface to project owner                 │
└─────────────────────────────────────────────────────────────┘
```

### CEO Templates

Templates are in `${CLAUDE_PLUGIN_ROOT}/templates/`:
- `codex-ceo-alpha.md` - Codex delegation for AI-Native CEO
- `codex-ceo-beta.md` - Claude internal agent for Modern SWE CEO

---

## Decision Manifests

### Overview

A **Decision Manifest** is a binding document that captures all resolved decisions before implementation. It enforces coherence when AI generates code.

### Manifest Structure

```json
{
  "manifest_id": "DISC-2026-01-19-offline-voice",
  "topic": "Offline Voice Commands for Brenda",
  "investigation_type": "feature",
  "status": "resolved",

  "disciplines": {
    "items": [
      {
        "discipline": "offline-first",
        "principle": "All features must work without network",
        "test_command": "pnpm test --grep 'offline'",
        "violation_severity": "critical"
      }
    ]
  },

  "decisions": {
    "resolved": [...],
    "inherited": [...],
    "pending": [...]
  },

  "dependency_map": {...},
  "formal_tests": {...}
}
```

### Using Manifests with Remediation

```bash
# Bind remediation to manifest
/acis remediate docs/reviews/goals/VOICE-001.json \
  --manifest docs/manifests/DISC-2026-01-19-offline-voice.json
```

During remediation, the manifest enforces:
1. **Resolved decisions** must be followed exactly
2. **Inherited decisions** must be honored
3. **Disciplines** must be upheld (verified each iteration)
4. **Formal tests** must pass for each decision

### Decision Violation Detection

If code violates a resolved decision:

```markdown
## DECISION VIOLATION DETECTED

**Decision**: DEC-VOICE-001 (Voice Processing Location)
**Resolved Value**: on-device
**Violation Found**: `src/voice/transcriber.ts:45`
  → `await cloudAPI.transcribe(audio)` violates on-device decision

**Action Required**: Fix the violation or request decision revision.
```

### Resolving Decisions with `/acis resolve`

```bash
# Auto-resolve all converged, prompt for diverged
/acis resolve docs/manifests/DISC-2026-01-19-voice.json

# Only auto-resolve converged decisions
/acis resolve docs/manifests/DISC-2026-01-19-voice.json --auto-only

# Force resolution of specific decision
/acis resolve docs/manifests/DISC-2026-01-19-voice.json --force DEC-CACHE-001
```

### Auto-Resolution Example

When both CEOs agree:

```markdown
## Auto-Resolving: DEC-VOICE-001

**Decision**: Voice Processing Location
**CEO-Alpha Recommends**: on-device (confidence: high)
**CEO-Beta Recommends**: on-device (confidence: medium)
**Convergence**: ✅ Both agree

**Auto-approving** with resolution:
- Value: on-device
- Resolved by: auto-convergence
- Rationale: Both CEOs agree that on-device processing is optimal for PHI safety and simplicity.
```

### Manual Resolution Example

When CEOs diverge:

```markdown
## Owner Decision Required: DEC-CACHE-001

**Decision**: Cache Invalidation Strategy
**Options**: time-based | event-based | hybrid

### CEO-Alpha Recommends: hybrid
**Confidence**: high
**Primary Why**: Hybrid maximizes cache hit rate while ensuring data freshness.

### CEO-Beta Recommends: time-based
**Confidence**: medium
**Primary Why**: Simplicity compounds; time-based is predictable and easy to reason about.

### Agreement Areas
- Both agree caching is needed
- Both agree 5-minute max staleness is acceptable

### Disagreement Areas
- Whether event-based invalidation is worth the complexity

---

**Owner, please choose:**
1. `hybrid` (CEO-Alpha recommendation)
2. `time-based` (CEO-Beta recommendation)
3. `event-based` (neither recommended)
```

---

## Multi-Perspective Discovery

### Overview

Phase 1 launches 10+ agents in parallel to analyze each goal from different perspectives. This ensures comprehensive coverage of security, UX, performance, and architecture concerns.

### Internal Agents (via Task tool)

| Agent | Perspective | Focus Areas |
|-------|-------------|-------------|
| `security-privacy` | PHI Protection | HIPAA compliance, encryption, access control |
| `tech-lead` | Architecture | Design patterns, layer violations, maintainability |
| `test-lead` | Test Quality | Coverage gaps, test strategies, regression risks |
| `mobile-lead` | Platform | iOS/Android compatibility, offline support |
| `oracle` (end-user) | UX Impact | Persona journeys, accessibility, cognitive load |
| `devops-lead` | Operations | Deployment, monitoring, alerting, maintenance |
| `oracle` (crash-resilience) | Failure Modes | Error handling, recovery, graceful degradation |
| `oracle` (performance) | Efficiency | Memory, CPU, battery, latency |
| `oracle` (refactoring) | Code Quality | Refactor opportunities, tech debt |

### Codex Delegations (via claude-delegator)

| Expert | Delegation Template | Focus |
|--------|---------------------|-------|
| Architect | `templates/codex-architect-discovery.md` | System design, tradeoffs, refactoring |
| Scope Analyst (UX) | `templates/codex-ux-discovery.md` | Persona journeys, accessibility |
| Code Reviewer (Algorithm) | `templates/codex-algorithm-discovery.md` | Efficiency, elegance, Big-O |
| Security Analyst | `templates/codex-security-discovery.md` | Hardening, threat model, OWASP |

### Web Search

ACIS performs web searches for:
- `{goal topic} best practices 2026`
- Latest security advisories
- Deprecation notices

### Discovery Output

Each agent contributes to the refined goal:

```json
{
  "multi_perspective": {
    "discovery_results": {
      "security-privacy": {
        "findings": ["PHI exposure in sync queue"],
        "metrics_suggested": [{"metric_id": "phi_exposure", "command": "..."}],
        "behavioral_scenarios": ["Given offline sync..."]
      },
      "codex-architect": {
        "findings": ["Queue should use EncryptedStorageAdapter"],
        "refactoring_opportunities": ["Extract queue persistence layer"]
      }
    }
  }
}
```

### Running Discovery Only

```bash
/acis remediate docs/reviews/goals/PR56-CRIT-001.json --discovery-only
```

This runs Phase 1 only and outputs refinements without implementation.

---

## Behavioral TDD

### Philosophy

Behavioral TDD ensures fixes are validated from the **user's perspective**, not just technical correctness. Tests are written in Given/When/Then format for each affected persona.

### Personas

| Persona | Description | Key Concerns |
|---------|-------------|--------------|
| **Brenda** | Elderly patient (65+) | Large touch targets, simple flows, offline access |
| **David** | Adult caregiver | Remote monitoring, notifications, sync status |
| **Dr. Evans** | Healthcare provider | Data accuracy, audit trails, compliance |

### Acceptance Scenario Format

```gherkin
Feature: {GOAL_ID} - {Goal Description}

  Scenario: Brenda views medications during key rotation
    Given Brenda is using the app on her tablet
    And encryption key rotation is in progress
    When Brenda navigates to her medication list
    Then medications display without interruption
    And no PHI is exposed during the rotation
    And loading time remains under 200ms

  Scenario: David receives sync status notification
    Given David is monitoring Brenda's care remotely
    And Brenda's device has been offline for 2 hours
    When Brenda's device reconnects
    Then David receives a notification that sync completed
    And all vital signs are up to date
```

### Test File Structure

```typescript
// packages/mobile/src/__tests__/behavioral/PR56-CRIT-001.behavioral.spec.ts

describe('PR56-CRIT-001: Encrypted Sync Queue', () => {
  describe('Brenda medication lookup during key rotation', () => {
    beforeEach(async () => {
      // Given: Set up key rotation in progress
      await keyManager.startRotation();
    });

    it('displays medications without interruption', async () => {
      // When: Brenda views medications
      const medications = await medicationService.getMedications();

      // Then: Medications display correctly
      expect(medications).toHaveLength(3);
      expect(medications[0].name).toBe('Aspirin');
    });

    it('does not expose PHI during rotation', async () => {
      // Then: No PHI in logs or unencrypted storage
      const logs = await auditService.getRecentLogs();
      expect(logs).not.toContainPHI();
    });
  });
});
```

### Skipping Behavioral TDD

For simple pattern replacements where user impact is minimal:

```bash
/acis remediate docs/reviews/goals/PR55-G1-math-random.json --no-behavioral
```

---

## Ralph-Loop Remediation

### Overview

Ralph-Loop is a Sisyphus-style remediation cycle that runs until ALL verifiable metrics pass. Named after the persistent boulder-rolling metaphor, it never stops until the goal is achieved.

### Loop Structure

```
┌────────────────────────────────────────────────────────────┐
│                    RALPH-LOOP START                        │
└────────────────────────────────────────────────────────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │         MEASURE              │
              │  Run ALL verifiable_metrics  │
              │  Record current values       │
              └──────────────────────────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │          CHECK               │
              │  ALL metrics pass target?    │
              │                              │
              │  YES → Exit to Phase 4       │
              │  NO  → Continue              │
              └──────────────────────────────┘
                             │ NO
                             ▼
              ┌──────────────────────────────┐
              │         ANALYZE              │
              │  Identify files to fix       │
              │  Prioritize by impact        │
              └──────────────────────────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │           FIX                │
              │  Apply TDD cycle:            │
              │  1. Write/update tests       │
              │  2. Make minimal fix         │
              │  3. Run typecheck + tests    │
              └──────────────────────────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │         REPORT               │
              │  Output iteration checkpoint │
              │  Update progress.history     │
              └──────────────────────────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │          LOOP                │
              │  iteration < max_iterations? │
              │  stuck_count < 3?            │
              │                              │
              │  Continue → Back to MEASURE  │
              │  Stop → Output BLOCKED       │
              └──────────────────────────────┘
```

### Iteration Report Format

Each iteration outputs a checkpoint:

```markdown
## Iteration 5: PR56-CRIT-001

### Metrics
| Metric | Before | After | Target | Status |
|--------|--------|-------|--------|--------|
| unencrypted_queue_count | 1 | 0 | 0 | ✅ |
| phi_exposure_count | 0 | 0 | 0 | ✅ |
| test_coverage | 85% | 87% | 80% | ✅ |

### Changes
- `sync-engine.ts:81`: Replaced in-memory queue with EncryptedStorageAdapter
- `sync-engine.spec.ts`: Added 5 encryption tests

### Next
- All metrics pass → Proceeding to Consensus Verification
```

### Completion Promises

| Promise | Meaning |
|---------|---------|
| `<promise>GOAL_{id}_ACHIEVED</promise>` | All metrics pass, ready for consensus |
| `<promise>GOAL_{id}_BLOCKED</promise>` | Stuck for 3+ iterations |
| `<promise>GOAL_{id}_MAX_ITERATIONS</promise>` | Hit safety limit (default: 20) |
| `<promise>GOAL_{id}_CONSENSUS_FAILED</promise>` | Verification rejected by agents |

### Stuck Detection

If the same metric fails for 3 consecutive iterations:
1. Apply Multi-Perspective 5 Whys root cause analysis (see below)
2. Consider deferring to future work order
3. Output BLOCKED promise with explanation

---

## Multi-Perspective 5 Whys

### Overview

Multi-Perspective 5 Whys is an enhanced root cause analysis technique that spawns parallel 5 Whys investigations from different agent perspectives, then synthesizes them to find the deepest root cause. This ensures fixes address the true underlying issue, not just symptoms.

### When Multi-Perspective 5 Whys Triggers

| Trigger | Description |
|---------|-------------|
| **Complex issue** | Not obvious pattern replacement (requires understanding) |
| **Stuck** | Same metric failing for 2+ iterations |
| **Regression** | Fix caused other metrics to fail |
| **CRITICAL severity** | Always triggered for CRITICAL-severity goals |
| **Manual flag** | `--deep-5whys` forces for every fix |

### The Three Perspectives

Multi-Perspective 5 Whys uses three specialized agents in parallel:

| Agent | Perspective | Focus Question |
|-------|-------------|----------------|
| `security-privacy` | PHI/HIPAA compliance | Why does this create security risk? |
| `tech-lead` | Architecture/design | Why does this violate design principles? |
| `oracle` (crash-resilience) | Failure modes | Why could this cause system failure? |

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│              MULTI-PERSPECTIVE 5 WHYS                        │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ security-     │   │   tech-lead   │   │    oracle     │
│   privacy     │   │               │   │ (resilience)  │
│               │   │  WHY-1        │   │               │
│  WHY-1        │   │  WHY-2        │   │  WHY-1        │
│  WHY-2        │   │  WHY-3        │   │  WHY-2        │
│  WHY-3        │   │  WHY-4        │   │  WHY-3        │
│  WHY-4        │   │  WHY-5 (ROOT) │   │  WHY-4        │
│  WHY-5 (ROOT) │   │               │   │  WHY-5 (ROOT) │
└───────────────┘   └───────────────┘   └───────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                            ▼
                ┌───────────────────────┐
                │     SYNTHESIS         │
                │                       │
                │  • Convergence check  │
                │  • Deepest root cause │
                │  • Fix approach       │
                │  • Side effects       │
                └───────────────────────┘
```

### Convergence Types

After collecting WHY-5 root causes from all perspectives:

| Convergence | Meaning | Action |
|-------------|---------|--------|
| **CONVERGED** | All perspectives identify same root cause | Clear single fix |
| **PARTIAL** | 2+ perspectives agree, others differ | Primary fix + secondary safeguard |
| **DIVERGED** | All perspectives identify different causes | May need decomposition or deeper investigation |

### 5 Whys Agent Prompt Template

Each agent receives this prompt:

```
Analyze this problem from {PERSPECTIVE} perspective using 5 Whys:

PROBLEM: {metric_name} = {current_value} (target: {target_value})
FILE: {file_path}:{line_number}
GOAL: {goal_description}
CODE CONTEXT:
```{code_snippet}```

Perform 5 Whys Analysis from your perspective:

WHY-1: Why does this problem exist?
WHY-2: Why is that the case?
WHY-3: Why does that happen?
WHY-4: Why is that so?
WHY-5 (ROOT CAUSE): What is the fundamental reason?

Output:
1. Your 5 Whys chain
2. Root cause from {PERSPECTIVE} perspective
3. Suggested fix approach
4. Potential side effects to watch for
```

### Output Format

The synthesis produces this output:

```markdown
## Multi-Perspective 5 Whys Analysis

### Problem
Unencrypted sync queue (PR56-CRITICAL-001)
Metric: unencrypted_queue_count = 1 (target: 0)

### Perspective: security-privacy
- WHY-1: Sync queue stores PHI without encryption
- WHY-2: SyncEngine uses in-memory array instead of EncryptedStorageAdapter
- WHY-3: Original design prioritized simplicity over security
- WHY-4: No security review gate in initial implementation
- **WHY-5 (ROOT)**: Missing PHI-aware storage abstraction requirement

### Perspective: tech-lead
- WHY-1: Queue operations bypass Foundation layer storage
- WHY-2: SyncEngine directly manages persistence
- WHY-3: No clear separation between queue logic and storage
- WHY-4: Missing dependency injection for storage adapter
- **WHY-5 (ROOT)**: Architecture doesn't enforce storage abstraction

### Perspective: oracle (crash-resilience)
- WHY-1: Queue data lost on app crash
- WHY-2: In-memory storage has no persistence guarantee
- WHY-3: No transaction boundaries around queue operations
- WHY-4: Recovery scenario not designed for
- **WHY-5 (ROOT)**: Missing durability requirement in sync design

### Synthesis
**Convergence**: PARTIAL (security + architecture agree, resilience adds durability concern)
**Deepest Root Cause**: Architecture doesn't enforce PHI-aware storage abstraction
**Contributing Factors**: Missing durability requirement compounds security risk

### Recommended Fix Approach
1. Replace in-memory queue with EncryptedStorageAdapter
2. Add transaction boundaries for durability
3. Wire up via dependency injection to respect layer boundaries

### Side Effects to Monitor
| Perspective | Risk | Mitigation |
|-------------|------|------------|
| security-privacy | Key rotation during sync | Queue operations wait for rotation |
| tech-lead | Performance regression | Benchmark before/after |
| oracle | Migration of existing queue data | One-time migration on upgrade |
```

### Integration with FIX Phase

After Multi-Perspective 5 Whys completes:

1. **FIX phase uses "Recommended Fix Approach"** as guidance
2. **Each fix must address the synthesized root cause**, not just the symptom
3. **Side effects are monitored** in subsequent iterations
4. **Contributing factors** may spawn follow-up goals

### Example: Using --deep-5whys Flag

For thorough analysis on every fix (slower but more rigorous):

```bash
/acis remediate docs/reviews/goals/PR56-CRITICAL-001.json --deep-5whys
```

This forces Multi-Perspective 5 Whys even for simple pattern replacements, ensuring no root causes are missed.

---

## Consensus Verification

### Overview

Phase 4 launches verification agents in parallel. Each agent independently runs the metrics assigned to them and returns a verdict.

### Verification Agents

| Agent | Required Metrics | Veto Power |
|-------|-----------------|------------|
| `security-privacy` | phi_exposure_count, encryption_coverage | **YES** |
| `test-lead` | test_count, coverage_percent, regression_failures | NO |
| `tech-lead` | layer_violations, type_errors, lint_errors | **YES** |
| `mobile-lead` | ios_build, android_build, web_build | NO |
| `codex-architect` | design_quality_score, maintainability_index | NO |

### Verdict Types

| Verdict | Meaning |
|---------|---------|
| `APPROVE` | All assigned metrics pass |
| `REQUEST_CHANGES` | Minor issues, can be fixed quickly |
| `REJECT` | Critical issues, blocks completion |

### Consensus Rules

1. **Threshold**: ≥75% of agents must APPROVE (minimum 3/4)
2. **Veto Power**: `security-privacy` or `tech-lead` can block alone
3. **All Metrics**: Every metric must pass for goal to be ACHIEVED

### Consensus Output

```markdown
## Consensus Verification: PR56-CRIT-001

| Agent | Verdict | Metrics Verified | Notes |
|-------|---------|------------------|-------|
| security-privacy | APPROVE | phi=0, encryption=100% | PHI boundaries intact |
| test-lead | APPROVE | tests=15, coverage=87% | Coverage improved |
| tech-lead | APPROVE | layers=0, types=0 | Architecture clean |
| mobile-lead | APPROVE | iOS=✓, Android=✓ | Builds pass |

**Result**: 4/4 APPROVE → GOAL ACHIEVED
```

### Handling Rejections

If consensus fails:
1. Review the rejecting agent's notes
2. Apply fixes for the specific concerns
3. Re-run verification (not full remediation)

```bash
/acis verify docs/reviews/goals/PR56-CRIT-001.json
```

### Skipping Consensus

For low-risk changes (Tier 1 complexity):

```bash
/acis remediate docs/reviews/goals/PR55-G1-math-random.json --no-consensus
```

---

## Quality Gate

### Overview

The Quality Gate is an external code review phase that runs after metrics are achieved but before marking a goal as complete. It ensures code quality meets standards beyond just passing metrics.

### When Quality Gate Triggers

| Condition | Triggers Quality Gate |
|-----------|----------------------|
| Metric achieved | After VERIFY phase returns "achieved" |
| `--skip-quality-gate` flag | Skipped |
| `--skip-codex` flag | Skipped |
| Tier 1 goal with `--skip-tier1-quality-gate` | Skipped |

### Quality Gate Process

```
┌─────────────────────────────────────────────────────────────┐
│              VERIFY returns status: achieved                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     QUALITY GATE                             │
│                                                              │
│  1. Generate cumulative diff (all iterations squashed)       │
│  2. Compile file change summary                              │
│  3. Delegate to Codex with quality-gate template             │
│                                                              │
│  CODEX REVIEW:                                               │
│  • SOLID principles compliance                               │
│  • DRY principle adherence                                   │
│  • Algorithm quality assessment                              │
│  • Architecture conformance (three-layer)                    │
│  • Healthcare/HIPAA considerations                           │
│                                                              │
│  Returns: APPROVE or REQUEST_CHANGES + quality score         │
└─────────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
      ┌──────────┐                   ┌──────────────┐
      │ APPROVE  │                   │ REQUEST_     │
      │          │                   │ CHANGES      │
      │ → ACHIEVED│                  │ → Back to FIX│
      └──────────┘                   └──────────────┘
```

### Review Focus Areas

| Area | Criteria |
|------|----------|
| **Single Responsibility** | Each unit has one reason to change |
| **Open/Closed** | Open for extension, closed for modification |
| **Liskov Substitution** | Subtypes behave as expected |
| **Interface Segregation** | Minimal, focused interfaces |
| **Dependency Inversion** | Depend on abstractions |
| **DRY** | No duplicated logic, constants for magic values |
| **Architecture** | Foundation → Journey → Composition layer direction |

### Configuration

| Flag | Description |
|------|-------------|
| `--skip-quality-gate` | Skip quality gate entirely |
| `--quality-threshold=N` | Require quality score >= N (default: 3) |
| `--skip-tier1-quality-gate` | Skip for Tier 1 goals only |

### Max Rejections

After 2 quality gate rejections, the goal escalates to the user for manual review.

---

## Stuck Consultation

### Overview

When a goal is stuck (same metric failing for multiple iterations), ACIS can consult Codex for fresh problem-solving perspective.

### When Stuck Consultation Triggers

| Condition | Triggers Consultation |
|-----------|----------------------|
| Iteration count >= stuck_threshold (default: 4) | Yes |
| Last 3 iterations all not_achieved or partial | Yes |
| `--skip-codex` flag | Skipped |
| Recent progress made | Skipped |

### Consultation Process

1. **Compile iteration history** - What was tried and what failed
2. **Extract 5-WHYS synthesis** - Root cause analysis from all perspectives
3. **Delegate to Codex** - Problem-solving mode (not review mode)
4. **Receive guidance** - Alternative approach + implementation guidance
5. **Apply to next FIX** - Inject guidance into next iteration

### Configuration

| Flag | Description |
|------|-------------|
| `--stuck-threshold=N` | Trigger consultation after N iterations (default: 4) |
| `--force-consultation` | Force consultation regardless of iteration count |
| `--skip-codex` | Skip all Codex delegations |

### Max Consultations

Maximum 2 consultations per goal. After that, escalate to Loop 2 (Discovery) for re-analysis.

---

## Parallel Remediation

### Overview

`/acis remediate-parallel` enables multiple goals to be remediated simultaneously using git worktrees for isolation. Each goal runs in its own worktree with a dedicated agent, then results are merged via an integration branch.

### Command

```bash
/acis remediate-parallel --wo WO63 --goals "CRIT-001,CRIT-002,CRIT-003"
```

### Flags

| Flag | Description |
|------|-------------|
| `--wo <WO-ID>` | Work order identifier for batch naming |
| `--goals <list>` | Comma-separated goal IDs or glob pattern |
| `--dry-run` | Show execution plan without running |
| `--max-parallel N` | Maximum concurrent worktrees (default: 4) |
| `--step-size N` | Maximum files per atomic step (default: 3) |
| `--skip-squash` | Keep detailed commit history on main |
| `--resume <batch-id>` | Resume interrupted batch |
| `--force-parallel` | Bypass file conflict warnings |

### Five-Phase Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PHASE 0: SAFETY ANALYSIS                                                    │
│  • Load all goal files                                                       │
│  • Run detection commands to extract affected files                          │
│  • Build conflict matrix (file overlap between goals)                        │
│  • Graph-color to find disjoint parallel groups                              │
│  • Present plan and wait for confirmation                                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  PHASE 1: WORKTREE SETUP (per goal)                                          │
│  • git worktree add .acis-work/{goal-id} -b acis/{goal-id} main              │
│  • Decompose goal into steps (max 3 files per step)                          │
│  • Write step manifest to docs/acis/state/steps/{goal-id}/manifest.json      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  PHASE 2: PARALLEL EXECUTION (per goal, parallel)                            │
│  • Each goal runs in its worktree with dedicated agent                       │
│  • Per-step atomic commits: [WO63-CRIT-001-S01] detect: baseline             │
│  • Verification after each step                                              │
│  • Optional push to remote branch                                            │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  PHASE 3: INTEGRATION MERGE                                                  │
│  • git checkout -b acis/integrate-{WO}-batch-{NNN} main                      │
│  • Sequential merge each goal (ordered by priority)                          │
│  • Conflict classification: trivial → partial → semantic → unresolvable      │
│  • Post-merge verification with detection commands                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  PHASE 4: SQUASH TO MAIN + CLEANUP                                           │
│  • Preserve history with tags: acis/history/BATCH-{WO}-{NNN}                 │
│  • Squash merge to main (unless --skip-squash)                               │
│  • Cleanup worktrees for complete goals                                      │
│  • Generate merge report                                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Directory Structure

```
project/
├── .acis-work/                    # Worktrees root (git-ignored)
│   ├── WO63-CRIT-001-key-rotation/   # Goal 1 worktree
│   ├── WO63-CRIT-002-sync-queue/     # Goal 2 worktree
│   └── WO63-CRIT-003-phi-audit/      # Goal 3 worktree
├── docs/acis/
│   ├── state/
│   │   ├── steps/
│   │   │   ├── WO63-CRIT-001/manifest.json
│   │   │   └── WO63-CRIT-002/manifest.json
│   │   └── parallel/
│   │       ├── BATCH-WO63-001.json
│   │       └── worktree-registry.json
│   └── merge-reports/
│       ├── BATCH-WO63-001-report.json
│       └── BATCH-WO63-001-report.md
```

### Conflict Resolution

| Conflict Type | Detection | Action |
|---------------|-----------|--------|
| **Trivial** | Whitespace, import order only | Auto-resolve with git strategies |
| **Partial** | Some commits merge, some conflict | Cherry-pick clean commits, new goal for rest |
| **Semantic** | Logic conflicts between goals | Preserve worktree, attempt rebase, flag if fails |
| **Unresolvable** | Cannot merge without data loss | Preserve all work, generate report, notify user |

### History Preservation

Before squash to main, history is preserved via tags:
- `acis/history/BATCH-{WO}-{NNN}` - Integration branch state
- `acis/archive/{goal-id}` - Individual goal branches

To recover detailed history:
```bash
git log acis/history/BATCH-WO63-001
```

---

## Swarm Orchestration

### Overview

Swarm orchestration uses Claude Code's **TeammateTool** to coordinate persistent agent teams for parallel remediation and discovery tasks.

**Requirements:** Claude Code v2.1.19+ for TeammateTool. Falls back to Task tool when unavailable.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Team** | Named group of agents with one leader (orchestrator) |
| **Teammate** | Persistent agent with inbox for receiving messages |
| **Task Queue** | Shared work items with status and dependencies |
| **Inbox** | JSON file for inter-agent communication |

### Enabling Swarm Mode

```bash
# Use --swarm flag with remediate-parallel
/acis remediate-parallel docs/reviews/goals/*.json --swarm

# Force specific backend (tmux for visible panes)
/acis remediate-parallel docs/reviews/goals/*.json --swarm --backend=tmux
```

### Swarm vs Task-Based Parallel

| Feature | Task-Based (v2.3) | Swarm (v2.5) |
|---------|-------------------|--------------|
| Agent lifespan | Ephemeral | Persistent |
| Communication | State files | Inbox messages |
| Dependencies | Manual polling | Auto-unblocking |
| Visibility | Background | tmux/iTerm panes |
| Shutdown | Automatic | Graceful protocol |

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR (Leader)                     │
│  - Creates team and task queue                              │
│  - Spawns specialist workers                                │
│  - Monitors inbox for reports                               │
│  - Synthesizes results                                      │
│  - Initiates graceful shutdown                              │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   MEASURER      │  │     FIXER       │  │   VERIFIER      │
│  - Claims       │  │  - Claims FIX   │  │  - Claims       │
│    MEASURE      │  │    tasks when   │  │    VERIFY tasks │
│    tasks        │  │    unblocked    │  │    when ready   │
│  - Runs         │  │  - Applies      │  │  - Confirms     │
│    detection    │  │    5-Whys fix   │  │    target met   │
│  - Reports      │  │  - Reports      │  │  - Reports      │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### Task Dependencies

Tasks auto-unblock when dependencies complete:

```
MEASURE (task #1)           ← Worker claims, completes
    │
    ▼ (auto-unblocks)
FIX (task #2)               ← Worker claims when #1 done
    │
    ▼ (auto-unblocks)
VERIFY (task #3)            ← Worker claims when #2 done
    │
    ▼ (auto-unblocks)
QUALITY-GATE (task #4)      ← Worker claims when #3 done
```

### Self-Organizing Behavior

Workers follow this loop:
1. Call `TaskList()` to see available tasks
2. Find pending task with no owner, not blocked
3. Claim task (set owner)
4. Execute task
5. Mark complete
6. Report to orchestrator
7. Repeat until no tasks remain

### Visibility Backends

| Backend | Command | When Used |
|---------|---------|-----------|
| `in-process` | `--backend=in-process` | Default, fastest, invisible |
| `tmux` | `--backend=tmux` | Inside tmux, visible panes |
| `iterm2` | `--backend=iterm2` | iTerm2 on macOS, visible panes |
| `auto` | (default) | Auto-detect based on environment |

### Graceful Shutdown

```javascript
// Orchestrator sends shutdown request
Teammate({ operation: "requestShutdown", target_agent_id: "worker-1" })

// Worker acknowledges before exiting
Teammate({ operation: "approveShutdown", request_id: "shutdown-123" })

// After all approvals, orchestrator cleans up
Teammate({ operation: "cleanup" })
```

### Configuration

Add to `.acis-config.json`:

```json
{
  "swarm": {
    "enabled": true,
    "fallbackToTask": true,
    "maxParallelWorkers": 4,
    "backend": "auto"
  }
}
```

### Fallback Mode

When TeammateTool is unavailable (Claude Code < v2.1.19), ACIS automatically falls back to Task-based parallel remediation with state file coordination.

---

## ACIS Traces

### Overview

ACIS Traces provide dual-purpose observability:
1. **User Visibility**: Plain text traces showing execution progress
2. **Process Auditor Learning**: Structured traces for pattern detection

### User-Visible Traces

Format: `[ACIS:{loop}:{phase}] {message}`

```
[ACIS:outer:reflect] Analyzing 5 completed goals for patterns
[ACIS:middle:discover] Spawning 3 perspective agents in parallel
[ACIS:inner:5-whys] Security perspective: Root cause identified
[ACIS:inner:fix] Iteration 2: Applying fix to auth module
[ACIS:parallel:setup] Creating worktree for WO63-CRIT-001
```

### Trace Types

| Type | Purpose | Example Data |
|------|---------|--------------|
| **lifecycle** | Phase/stage transitions | start, end, spawn, complete |
| **decision** | Micro-decisions by AI | approach-choice, fix-ordering |
| **knowledge** | Knowledge gaps/applications | needed, applied, missing |
| **skill** | Skill usage/candidates | applied, candidate, ineffective |
| **effectiveness** | Workflow metrics | iterations_to_complete, backtrack_count |
| **blocker** | Progress blockers | knowledge_gap, dependency, conflict |

### Storage Locations

```
Project Traces (session-oriented):
  docs/acis/traces/
    SESSION-2026-01-28-103000/
      trace-log.jsonl          # All traces (JSON Lines)
      summary.md               # Human-readable summary

Process Traces (workflow-oriented):
  .acis/traces/
    decisions/                 # Micro-decisions per goal
    knowledge/                 # Knowledge gaps and applications
    skills/                    # Skill candidates and usage
    effectiveness/             # Workflow metrics
```

### Trace Schema

```json
{
  "trace_id": "T-WO63-0015",
  "timestamp": "2026-01-28T10:35:00Z",
  "session_id": "SESSION-2026-01-28-103000",
  "goal_id": "WO63-CRIT-001",
  "location": {
    "loop": "inner",
    "phase": "fix",
    "iteration": 2
  },
  "trace_type": "decision",
  "message": "Selected singleton pattern for key manager",
  "decision": {
    "category": "approach-choice",
    "decision": "Use singleton pattern for KeyManager",
    "reasoning": "Ensures single source of truth for key rotation state",
    "alternatives_considered": ["Factory pattern", "Dependency injection"],
    "confidence": "high"
  },
  "process_auditor_hints": {
    "pattern_candidate": true,
    "tags": ["design-pattern", "singleton", "key-management"]
  }
}
```

### Process Auditor Consumption

The Process Auditor reads traces to:
- **Identify skill candidates**: `process_auditor_hints.skill_candidate: true`
- **Detect patterns**: Recurring decision approaches
- **Measure effectiveness**: `effectiveness.assessment` across goals
- **Find knowledge gaps**: `knowledge.event: "missing"` frequency

---

## Independently Verifiable Metrics

### Philosophy

Every metric in ACIS v2.0 MUST be independently verifiable. This means:
- Any agent can run the command
- Output is deterministic
- Expected value is specific
- No subjective judgment required

### Metric Schema

```json
{
  "verifiable_metrics": [
    {
      "metric_id": "phi_exposure_count",
      "name": "PHI Exposure Count",
      "description": "Count of PHI fields exposed outside encrypted storage",
      "command": "grep -rn 'bloodPressure|heartRate' packages/ | grep -v '.spec.ts' | wc -l",
      "expected_value": 0,
      "comparison": "eq",
      "tolerance": 0,
      "verification_notes": "All agents run this command independently"
    },
    {
      "metric_id": "test_coverage",
      "name": "Test Coverage Percentage",
      "command": "pnpm test --coverage | grep 'All files' | awk '{print $4}'",
      "expected_value": 80,
      "comparison": "gte",
      "tolerance": 2,
      "verification_notes": "Must be at least 80%, tolerance of 2% for timing variations"
    }
  ]
}
```

### Comparison Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `eq` | Equals | `expected: 0, actual: 0` ✅ |
| `lte` | Less than or equal | `expected: 5, actual: 3` ✅ |
| `gte` | Greater than or equal | `expected: 80, actual: 85` ✅ |
| `lt` | Less than | `expected: 10, actual: 5` ✅ |
| `gt` | Greater than | `expected: 0, actual: 5` ✅ |
| `contains` | String contains | `expected: "PASS", actual: "All tests PASS"` ✅ |
| `not_contains` | String doesn't contain | `expected: "ERROR", actual: "Success"` ✅ |

### Tolerance

Some metrics have natural variation:
- Coverage percentages may fluctuate by 1-2%
- Timing-based metrics may vary slightly
- Set `tolerance` to allow acceptable variance

### Good vs Bad Metrics

**GOOD** (Independently Verifiable):
```json
{
  "metric_id": "unencrypted_storage",
  "command": "grep -rn 'AsyncStorage.setItem' packages/ | wc -l",
  "expected_value": 0,
  "comparison": "eq"
}
```

**BAD** (Subjective):
```json
{
  "metric_id": "code_quality",
  "command": "manual_review",
  "expected_value": "good",
  "comparison": "eq"
}
```

### Agent Metric Assignments

From `acis-perspectives.json`:

```json
{
  "consensus": {
    "verification_agents": [
      {
        "agent_id": "security-privacy",
        "required_metrics": ["phi_exposure_count", "encryption_coverage", "hipaa_violations"],
        "veto_power": true
      },
      {
        "agent_id": "test-lead",
        "required_metrics": ["test_count", "coverage_percent", "regression_failures"],
        "veto_power": false
      }
    ]
  }
}
```

---

## Codex Integration

### Overview

ACIS v2.0 integrates with Codex (via claude-delegator MCP) for external expert perspectives. These delegations run during Phase 1 Discovery.

### Available Experts

| Expert | Template | Use Case |
|--------|----------|----------|
| **Architect** | `codex-architect-discovery.md` | System design, refactoring opportunities |
| **Scope Analyst (UX)** | `codex-ux-discovery.md` | Persona impact, accessibility |
| **Code Reviewer (Algorithm)** | `codex-algorithm-discovery.md` | Efficiency, Big-O analysis |
| **Security Analyst** | `codex-security-discovery.md` | Hardening, HIPAA compliance |

### Delegation Format

All Codex delegations use the 7-section format:

```markdown
TASK: Analyze {GOAL_ID} from {PERSPECTIVE} perspective.

EXPECTED OUTCOME: {What success looks like}

MODE: Advisory

CONTEXT:
- Goal: {GOAL_DESCRIPTION}
- Affected code: {CODE_SNIPPET}
- Application: Healthcare companion app handling PHI

CONSTRAINTS:
- HIPAA compliance is non-negotiable
- Must support offline operation
- Must work on mobile devices

MUST DO:
- {Specific requirement 1}
- {Specific requirement 2}

MUST NOT DO:
- {Forbidden action 1}
- {Forbidden action 2}

OUTPUT FORMAT:
{Structured output template}
```

### Example: Architect Delegation

```markdown
TASK: Analyze PR56-CRIT-001 for architectural tradeoffs and refactoring.

EXPECTED OUTCOME: Implementation recommendation with effort estimate.

MODE: Advisory

CONTEXT:
- Goal: Encrypt sync queue with EncryptedStorageAdapter
- Current: In-memory queue in SyncEngine
- Architecture: Offline-first with Foundation/Composition/Journey layers

CONSTRAINTS:
- Must maintain Foundation layer isolation
- Must work offline
- Must not increase memory footprint significantly

MUST DO:
- Analyze current queue implementation
- Recommend migration path to encrypted storage
- Identify refactoring opportunities
- Estimate implementation effort

MUST NOT DO:
- Recommend approaches that break offline capability
- Suggest over-engineering for future requirements

OUTPUT FORMAT:
## Bottom Line
[Recommendation in 2-3 sentences]

## Architectural Analysis
[Current state, proposed change, tradeoffs]

## Refactoring Opportunities
[Code quality improvements discovered]

## Effort Estimate
[Quick/Short/Medium/Large with reasoning]
```

### Skipping Codex

For internal-only analysis:

```bash
/acis remediate docs/reviews/goals/PR56-CRIT-001.json --skip-codex
```

### Codex Response Integration

Codex responses feed into:
1. `multi_perspective.discovery_results[codex-{expert}]`
2. `behavioral.acceptance_scenarios` (from UX expert)
3. `detection.verifiable_metrics` (refined by all experts)
4. `consensus.verification_results[codex-{expert}]`

---

## Using ACIS Commands

ACIS provides seven slash commands:

| Command | Purpose |
|---------|---------|
| `/acis init` | Bootstrap ACIS for a new project |
| `/acis extract <PR>` | Extract goals from PR review comments |
| `/acis discovery "<topic>"` | Proactive investigation with decision surfacing |
| `/acis resolve <manifest>` | Auto-resolve converged decisions |
| `/acis remediate <goal-file>` | TDD remediation loop (single goal) |
| `/acis remediate-parallel <goals>` | Parallel remediation with worktree isolation |
| `/acis verify <goal-file>` | Run consensus verification only |
| `/acis audit` | Process Auditor (pattern analysis, skill generation) |
| `/acis status` | Show progress across all goals and manifests |

### `/acis extract <PR_NUMBER>`

Extracts goals from a PR's review comments.

```bash
/acis extract 55
```

**What it does:**

1. Runs `./scripts/extract-review-goals-llm.sh <PR_NUMBER>`
2. Fetches all PR review comments via GitHub API
3. Analyzes comments for quantifiable patterns
4. Creates goal files in `docs/reviews/goals/`
5. Measures baseline counts

**Output:**

- Goal JSON files: `docs/reviews/goals/PR<N>-G<X>-<name>.json`
- Summary of extracted goals with current counts

### `/acis discovery "<topic>"`

Proactively investigates a topic to surface decisions, generate specs, and find issues.

```bash
/acis discovery "offline voice commands for Brenda" --type feature
```

**What it does:**

1. Parses topic to determine investigation type
2. Launches 10+ agents in parallel to explore
3. Extracts macro/micro decisions from codebase
4. Gets dual-CEO recommendations for pending decisions
5. Detects convergence/divergence between CEOs
6. Generates decision manifest + supporting artifacts

**Flags:**

| Flag | Description |
|------|-------------|
| `--type <type>` | Investigation type: feature, refactor, audit, what-if, bug-hunt |
| `--scope <paths>` | Limit investigation to specific paths |
| `--depth <level>` | shallow, medium, deep (default: medium) |
| `--skip-codex` | Use internal agents only |
| `--output <artifacts>` | report, manifest, spec, goals, adr (default: all) |

**Output:**

```
docs/manifests/DISC-2026-01-19-{topic}.json  ← Binding decision manifest
docs/reports/DISC-2026-01-19-{topic}.md      ← Discovery report
docs/specs/{topic}.md                         ← Feature spec (if feature)
docs/reviews/goals/DISC-*.json               ← Goals (if issues found)
docs/architecture/decisions/ADR-XXX.md       ← ADR drafts (if architectural)
```

### `/acis resolve <manifest>`

Resolves pending decisions in a manifest.

```bash
/acis resolve docs/manifests/DISC-2026-01-19-voice.json
```

**What it does:**

1. Loads decision manifest
2. For each pending decision:
   - If CEOs converge → auto-approve
   - If CEOs diverge → prompt project owner
3. Updates manifest with resolved decisions
4. Outputs resolution summary

**Flags:**

| Flag | Description |
|------|-------------|
| `--auto-only` | Only auto-approve converged decisions, skip diverged |
| `--force <id>` | Force resolution of specific decision with owner input |

**Output:**

```markdown
## Resolution Summary: DISC-2026-01-19-voice

| Decision | CEOs | Resolution | Resolved By |
|----------|------|------------|-------------|
| DEC-VOICE-001 | ✅ Converged | on-device | auto-convergence |
| DEC-CACHE-001 | ❌ Diverged | time-based | project-owner |
| DEC-WAKE-001 | ✅ Converged | push-to-talk | auto-convergence |

**3 decisions resolved** (2 auto, 1 manual)
```

### `/acis remediate <goal-file>`

Remediates a specific goal using TDD.

```bash
/acis remediate docs/reviews/goals/PR55-G3-orchestrator-method-consistency.json
```

**What it does:**

1. Loads the goal file
2. Generates remediation loop prompt via `./scripts/generate-ralph-prompt.sh`
3. Executes TDD cycle:
   - MEASURE → CHECK → ANALYZE → FIX → REPORT → LOOP
4. Outputs completion promise when done

**Completion Promises:**

- `<promise>GOAL_<id>_ACHIEVED</promise>` - Target reached
- `<promise>GOAL_<id>_BLOCKED</promise>` - Stuck for 3+ iterations
- `<promise>GOAL_<id>_MAX_ITERATIONS</promise>` - Hit safety limit

### `/acis status`

Shows progress across all goals.

```bash
/acis status
```

**Output:**

```
| Goal ID           | Baseline | Current | Target | Status   |
|-------------------|----------|---------|--------|----------|
| PR55-G1-math-random | 5       | 0       | 0      | achieved |
| PR55-G2-uninitialized | 3    | 0       | 0      | achieved |
| PR55-G3-orchestrators | 16   | 0       | 0      | achieved |
```

---

## Goal File Structure

Goals are stored as JSON in `docs/reviews/goals/`.

### Complete Schema

```json
{
  "id": "PR55-G3-orchestrator-method-consistency",

  "source": {
    "reviewer": "acis-internal",
    "comment_id": "pr55-g2-followup",
    "pr_number": 55,
    "lens": "maintainability",
    "severity": "medium",
    "original_comment": "The review comment that identified this issue"
  },

  "detection": {
    "pattern": "regex-pattern",
    "pattern_description": "What this pattern finds",
    "command": "grep command to count instances",
    "search_paths": ["packages/mobile/src/services"],
    "file_types": ["*.ts", "*.tsx"],
    "exclusions": ["*.spec.ts", "*.test.ts", "*.mock.ts"]
  },

  "baseline": {
    "count": 16,
    "measured_at": "2026-01-08T02:00:00Z",
    "command_output": "Description of what was found"
  },

  "target": {
    "type": "zero",
    "count": 0,
    "allowed_exceptions": {
      "in_tests": true,
      "in_mocks": true,
      "in_comments": false,
      "patterns": ["initialize()", "resetInstance()"]
    }
  },

  "complexity": {
    "tier": 2,
    "reasoning": "Why this tier was assigned",
    "agents_required": ["tech-lead", "security-privacy"],
    "phases": {
      "analyze": ["tech-lead"],
      "design": ["tech-lead"],
      "implement": [],
      "verify": ["test-lead", "security-privacy"]
    },
    "requires_user_approval": true
  },

  "remediation": {
    "strategy": "refactor",
    "replacement": "What to use instead",
    "imports_required": [],
    "context_rules": [{ "when": "condition", "then": "action" }],
    "requires_tests": true,
    "five_whys_required": false,
    "manual_review_required": true,
    "guidance": "Step-by-step fix guidance"
  },

  "verification": {
    "command": "pnpm run test:unit -- --testPathPattern='PR55-G3'",
    "success_condition": "All tests pass",
    "parse_output": "pass/fail"
  },

  "progress": {
    "current_count": 0,
    "iterations": 6,
    "history": [
      {
        "iteration": 1,
        "timestamp": "2026-01-08T02:30:00Z",
        "phase": "MEASURE",
        "action": "Description of what was done",
        "count_before": 16,
        "count_after": 16
      }
    ],
    "status": "achieved"
  },

  "metadata": {
    "created_at": "2026-01-08T01:45:00Z",
    "updated_at": "2026-01-08T04:00:00Z",
    "deferred_to": null,
    "related_goals": ["PR55-G2-uninitialized-session"],
    "tags": ["maintainability", "session-management", "acis-achieved"]
  }
}
```

### Key Fields Explained

| Field             | Purpose                                                                                                            |
| ----------------- | ------------------------------------------------------------------------------------------------------------------ |
| `source.lens`     | Category: security, privacy, performance, maintainability, accessibility, architecture, testing, operational-costs |
| `source.severity` | Priority: critical, high, medium, low                                                                              |
| `target.type`     | Goal type: zero (eliminate), threshold (below N), reduction (reduce by %)                                          |
| `complexity.tier` | 1 = simple, 2 = moderate, 3 = architectural                                                                        |
| `progress.status` | pending, in_progress, achieved, blocked                                                                            |

---

## Complexity Tiers

ACIS categorizes goals by complexity to determine approach:

### Tier 1: Simple Pattern Replacement

- **Scope**: Single pattern, direct replacement
- **Examples**: Math.random → cryptoRandomNumber, console.log removal
- **Agents**: None required
- **Approval**: Not required

### Tier 2: Context-Aware Changes

- **Scope**: Pattern requires understanding context
- **Examples**: Adding validateAndRefreshToken() to PHI methods
- **Agents**: tech-lead, security-privacy
- **Approval**: Usually required

### Tier 3: Architectural Changes

- **Scope**: Cross-cutting concerns, new abstractions
- **Examples**: Adding type-safe wrappers, service refactoring
- **Agents**: Multiple leads, design review
- **Approval**: Always required

---

## Progress Tracking

### Iteration History

Every goal maintains a full history of iterations:

```json
{
  "history": [
    {
      "iteration": 1,
      "timestamp": "2026-01-08T02:30:00Z",
      "phase": "MEASURE",
      "action": "Counted 16 PHI methods without security checks",
      "count_before": null,
      "count_after": 16
    },
    {
      "iteration": 2,
      "timestamp": "2026-01-08T02:45:00Z",
      "phase": "IMPLEMENT [RED]",
      "action": "Created regression tests",
      "count_before": 16,
      "count_after": 16,
      "files_created": ["path/to/test.spec.ts"]
    },
    {
      "iteration": 3,
      "timestamp": "2026-01-08T03:00:00Z",
      "phase": "IMPLEMENT [GREEN]",
      "action": "Added security checks to all methods",
      "count_before": 16,
      "count_after": 0,
      "files_modified": ["path/to/orchestrator.ts"]
    }
  ]
}
```

### Phase Tags

| Phase               | Meaning                   |
| ------------------- | ------------------------- |
| `MEASURE`           | Running detection command |
| `ANALYZE`           | Identifying files to fix  |
| `DESIGN`            | Planning the fix approach |
| `IMPLEMENT [RED]`   | Writing failing tests     |
| `IMPLEMENT [GREEN]` | Making tests pass         |
| `VERIFY`            | Confirming completion     |

### Status Values

| Status        | Meaning                    |
| ------------- | -------------------------- |
| `pending`     | Goal created, not started  |
| `in_progress` | Actively being remediated  |
| `achieved`    | Target reached, tests pass |
| `blocked`     | Stuck, needs investigation |
| `deferred`    | Moved to future work order |

---

## Monitoring and Status

### View All Goals

```bash
/acis status
```

Or manually:

```bash
ls -la docs/reviews/goals/*.json
```

### Check Specific Goal Progress

Read the goal file directly:

```bash
cat docs/reviews/goals/PR55-G3-orchestrator-method-consistency.json | jq '.progress'
```

### View Goal History

```bash
cat docs/reviews/goals/PR55-G3-*.json | jq '.progress.history'
```

### Check Tags

Goals are tagged for filtering:

- `acis-pending` - Not started
- `acis-in-progress` - Being worked on
- `acis-achieved` - Completed
- `acis-blocked` - Needs attention

---

## Multi-Agent Integration

ACIS integrates with the project's multi-agent system:

### Agent Routing by Complexity

| Tier | Analyze Phase               | Design Phase            | Verify Phase                |
| ---- | --------------------------- | ----------------------- | --------------------------- |
| 1    | None                        | None                    | None                        |
| 2    | tech-lead                   | tech-lead               | test-lead, security-privacy |
| 3    | tech-lead, security-privacy | tech-lead, backend-lead | All leads                   |

### Agent Responsibilities

| Agent                | Role in ACIS                        |
| -------------------- | ----------------------------------- |
| `tech-lead`          | Reviews complexity, approves design |
| `security-privacy`   | Reviews security-related goals      |
| `test-lead`          | Reviews test coverage, verification |
| `accessibility-lead` | Reviews accessibility goals         |
| `docs-lead`          | Reviews documentation goals         |

---

## Safety Rules

ACIS enforces CLAUDE.md safety rules:

### Must Follow

1. **No test deletion** - Never remove tests to achieve goals
2. **No @ts-ignore** - Never suppress type errors
3. **No scope reduction** - Fix ALL instances, no shortcuts
4. **TDD required** - Each fix must maintain test coverage
5. **Multi-Perspective 5 Whys** - Required for CRITICAL goals, stuck iterations, or regressions
6. **Root cause synthesis** - Fixes must address synthesized root cause, not symptoms

### Iteration Limits

- Default maximum: 20 iterations per goal
- If stuck for 3+ iterations: Output BLOCKED promise
- Safety limit prevents infinite loops

### Verification Requirements

- All goal-specific regression tests must pass
- Detection command must return target count
- No new type errors introduced
- Test coverage maintained or increased

---

## Examples

### Example 1: Complete Goal Lifecycle

```bash
# 1. Extract goals from PR 55
/acis extract 55

# Output:
# Created 5 goals:
# - PR55-G1-math-random (baseline: 5, target: 0)
# - PR55-G2-uninitialized-session (baseline: 3, target: 0)
# ...

# 2. Remediate first goal
/acis remediate docs/reviews/goals/PR55-G1-math-random.json

# Output:
# Iteration 1: MEASURE - 5 instances found
# Iteration 2: ANALYZE - 3 production files identified
# Iteration 3: FIX - crypto.ts, auth.ts (3 instances)
# Iteration 4: FIX - session.ts (2 instances)
# Iteration 5: VERIFY - 0 instances remaining
# <promise>GOAL_PR55-G1-math-random_ACHIEVED</promise>

# 3. Check overall status
/acis status

# | Goal ID           | Baseline | Current | Target | Status   |
# |-------------------|----------|---------|--------|----------|
# | PR55-G1-math-random | 5       | 0       | 0      | achieved |
# | PR55-G2-uninitialized | 3    | 3       | 0      | pending  |
```

### Example 2: Security Goal with TDD

```bash
/acis remediate docs/reviews/goals/PR55-G3-orchestrator-method-consistency.json
```

**Iteration Flow:**

1. MEASURE: Count PHI methods without security checks (16 found)
2. ANALYZE: Identify 3 orchestrators with 16 methods
3. IMPLEMENT [RED]: Create `PR55-G3.*.spec.ts` with 17 failing tests
4. IMPLEMENT [GREEN]: Add `validateAndRefreshToken()` to all methods
5. VERIFY: All 17 tests pass
6. Complete: `<promise>GOAL_PR55-G3_ACHIEVED</promise>`

### Example 3: Goal File for Math.random Replacement

```json
{
  "id": "PR55-G1-math-random",
  "source": {
    "lens": "security",
    "severity": "high",
    "original_comment": "Math.random() is not cryptographically secure"
  },
  "detection": {
    "pattern": "Math\\.random\\(\\)",
    "command": "grep -rn 'Math.random' --include='*.ts' packages/",
    "exclusions": ["*.spec.ts", "*.test.ts"]
  },
  "target": {
    "type": "zero",
    "count": 0
  },
  "remediation": {
    "strategy": "replace",
    "replacement": "crypto.getRandomValues() or cryptoRandomNumber()",
    "guidance": "Use cryptographic random for security-sensitive operations"
  }
}
```

---

## File Locations

### Plugin Files (in `${CLAUDE_PLUGIN_ROOT}/`)

| File | Purpose |
|------|---------|
| `commands/acis.md` | Main ACIS slash command definition |
| `commands/acis-init.md` | Project bootstrapping command |
| `commands/acis-audit.md` | Process Auditor command |
| `schemas/acis-goal.schema.json` | Goal schema |
| `schemas/acis-decision-manifest.schema.json` | Manifest schema |
| `schemas/acis-decision.schema.json` | Decision schema |
| `templates/codex-ceo-alpha.md` | CEO-Alpha Codex template |
| `templates/codex-ceo-beta.md` | CEO-Beta Claude template |
| `templates/acis-discovery-report.md` | Discovery report template |
| `interview/` | Interview system for project bootstrapping |
| `audit/` | Process Auditor reflection and skill detection |
| `skill-templates/` | Templates for dynamically generated skills |
| `ralph-profiles/` | Ralph-loop execution profiles |

### Project Files (in project root)

| File | Purpose |
|------|---------|
| `.acis-config.json` | Project-specific ACIS configuration |
| `docs/reviews/goals/*.json` | Goal files |
| `docs/manifests/*.json` | Decision manifests |
| `docs/reports/*.md` | Discovery reports |
| `docs/audits/*.md` | Process Auditor reports |
| `skills/` | Dynamically generated skills (by Process Auditor) |

---

## Troubleshooting

### Goal Not Making Progress

1. Check if detection command is correct: `grep -rn '<pattern>' packages/`
2. Verify file exclusions aren't excluding relevant files
3. Check if instances are in unexpected locations
4. Apply 5 Whys analysis

### Tests Failing After Fix

1. Read the failing test to understand expectation
2. Check if fix changed behavior tests depend on
3. Create follow-up goal for test updates (e.g., PR55-G5)

### Goal Blocked

1. Review `progress.history` for patterns
2. Check `complexity.tier` - may need agent assistance
3. Consider deferring to dedicated work order

---

## Related Documentation

### Core Documentation
- [CLAUDE.md](../../CLAUDE.md) - AI governance rules
- [COO Verification Protocol](COO_VERIFICATION_PROTOCOL.md) - Review procedures
- [Work Order Governance](../work-orders/README.md) - Task management

### ACIS Schemas
- [Decision Manifest Schema](schemas/acis-decision-manifest.schema.json) - Binding document for discoveries
- [Decision Schema](schemas/acis-decision.schema.json) - Individual decision artifacts
- [Goal Schema](schemas/acis-v2-goal.schema.json) - Remediation goal structure

### ACIS Templates
- [CEO-Alpha Template](templates/codex-ceo-alpha.md) - Codex delegation for AI-Native CEO
- [CEO-Beta Template](templates/codex-ceo-beta.md) - Claude internal agent for Modern SWE CEO
- [Discovery Report Template](templates/acis-discovery-report.md) - Discovery output format

### Configuration
- [Perspectives Config](configs/acis-perspectives.json) - Agent and Codex expert configuration

---

## ACIS in Practice: WO-59 Case Study

WO-59 (Offline-First Architecture) demonstrated ACIS at scale:

### Goal Sources

| Source | Goals | Status |
|--------|-------|--------|
| PR #56 ACIS extraction | 18 | 16 achieved, 2 deferred |
| Phase B multi-agent discovery | 17 | 5 achieved, 12 tracked to future WOs |
| **Total** | **35** | **21 achieved, 14 planned** |

### Work Order Distribution

| Work Order | Focus | Goals | Priority |
|------------|-------|-------|----------|
| [WO-60](../work-orders/WO-60-OFFLINE-INFRASTRUCTURE.md) | Offline Infrastructure | 16 | HIGH |
| [WO-61](../work-orders/WO-61-OFFLINE-UX.md) | Offline UX Indicators | 1 | MEDIUM |
| [WO-62](../work-orders/WO-62-PERSONA-FEATURES.md) | Secondary Personas | 2 | MEDIUM |
| [Wave 3](../work-orders/WAVE-3-ROADMAP.md) | Platform 2.0 | 7 | FUTURE |

### Key Takeaways

1. **Multi-agent discovery amplifies ACIS**: 10 specialized agents found issues PR review missed
2. **Deferral tracking works**: Goals pre-deferred in Phase B are properly tracked to future WOs
3. **Wave terminology integrates**: ACIS goals can be tied to project milestones (Wave 2, Wave 3)
4. **Full ACIS JSON in WO docs**: Each future WO contains complete goal definitions for session continuity

### Goal Files Reference

| PR/Phase | Location |
|----------|----------|
| PR55 goals | `docs/reviews/goals/PR55-*.json` |
| PR56 goals | `docs/reviews/goals/PR56-*.json` |
| Phase B goals | `docs/work-orders/WO-59/phase-b-acis-goals.json` |
