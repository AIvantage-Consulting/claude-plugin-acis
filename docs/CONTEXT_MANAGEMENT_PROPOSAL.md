# ACIS Context Management Architecture

## Problem Statement

ACIS's three-loop architecture suffers from:
1. **Context Accumulation**: Inner loops inherit context from outer loops
2. **Context Rot**: Quality degrades as context fills (especially >50%)
3. **No Fresh Starts**: Subagents resume with accumulated context
4. **Sequential Bottleneck**: Multi-perspective analysis runs serially

## Solution: GSD-Inspired Context Isolation

Based on patterns from the Get-Shit-Done (GSD) framework, we propose:

1. **Fresh Agent Per Task** - Never resume, always spawn with injected context
2. **Context Budget Discipline** - Orchestrators use <15%, subagents get 100%
3. **State Files** - Persistent memory across agent boundaries
4. **Wave-Based Parallelism** - Pre-computed dependencies, parallel execution
5. **Forced Codex Delegation** - External perspectives via Codex MCP

---

## ACIS Loop Architecture (Revised)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  LOOP 1: PROCESS AUDITOR (Orchestrator-Only, <15% context)                      │
│  - Reads: .acis/STATE.md, .acis/AUDIT_HISTORY.md                               │
│  - Spawns: Fresh audit-analyzer agents (100% context each)                      │
│  - Writes: .acis/AUDIT.md, skills/, process adjustments                        │
│  - Ralph Profile: process-auditor                                               │
│                                                                                  │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │  LOOP 2: DISCOVERY ORCHESTRATOR (<15% context)                            │  │
│  │  - Reads: .acis/STATE.md, .acis/GOALS.md, goal-file.json                 │  │
│  │  - Spawns: Fresh discovery agents in PARALLEL (100% context each)         │  │
│  │  - Writes: .acis/DISCOVERY.md, .acis/DECISIONS.md                         │  │
│  │  - Ralph Profile: discovery-orchestrator                                   │  │
│  │                                                                           │  │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │  │
│  │  │  LOOP 3: REMEDIATION EXECUTOR (<15% context orchestrator)           │  │  │
│  │  │  - Reads: .acis/STATE.md, goal-file.json, .acis/DISCOVERY.md       │  │  │
│  │  │  - Spawns: Fresh fix-agent per iteration (100% context)             │  │  │
│  │  │  - Writes: .acis/PROGRESS.md, goal status updates                   │  │  │
│  │  │  - Ralph Profile: behavioral-tdd                                    │  │  │
│  │  │                                                                     │  │  │
│  │  │  ORCHESTRATOR (thin) → spawns → FRESH FIX AGENT (full context)      │  │  │
│  │  │           ↓                              ↓                          │  │  │
│  │  │  Collect result ← ── ── ── ── ── ── ─ Returns status + changes      │  │  │
│  │  │           ↓                                                         │  │  │
│  │  │  Update .acis/PROGRESS.md                                           │  │  │
│  │  │           ↓                                                         │  │  │
│  │  │  spawn FRESH VERIFY AGENT (100% context)                            │  │  │
│  │  │           ↓                                                         │  │  │
│  │  │  If not achieved → spawn FRESH FIX AGENT with PROGRESS.md context   │  │  │
│  │  │                                                                     │  │  │
│  │  └─────────────────────────────────────────────────────────────────────┘  │  │
│  │                                                                           │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## State Files (.acis/ Directory)

### 1. STATE.md - Global Position (Read First, Always)

```markdown
# ACIS State

## Current Position
- **Active Goal**: PR55-G3-orchestrator-consistency
- **Loop**: 3 (Remediation)
- **Iteration**: 4 of 20
- **Status**: fix-in-progress

## Accumulated Decisions
- Use Fastify validation middleware (from discovery)
- Prefer composition over inheritance (from CEO consensus)
- PHI fields must use EncryptedString type (architectural constraint)

## Blockers
- None

## Recent Completions
| Goal | Iterations | Completed |
|------|------------|-----------|
| PR55-G1 | 3 | 2026-01-19T10:30:00Z |
| PR55-G2 | 5 | 2026-01-19T11:45:00Z |

## Session Continuity
Last action: Fix agent iteration 3 completed, verification pending
Resume from: Spawn verify agent with PROGRESS.md context
```

### 2. PROGRESS.md - Per-Goal Iteration History

```markdown
# Goal: PR55-G3-orchestrator-consistency

## Iteration History

### Iteration 1
- **Agent**: fix-agent (fresh spawn)
- **Action**: Added validation to 3 orchestrators
- **Result**: Partial - 2 of 5 files fixed
- **Commit**: abc123
- **Context Used**: 42%

### Iteration 2
- **Agent**: fix-agent (fresh spawn)
- **Action**: Fixed remaining 2 orchestrators, discovered 1 more
- **Result**: Partial - 4 of 6 files fixed
- **Commit**: def456
- **Context Used**: 38%

### Iteration 3
- **Agent**: fix-agent (fresh spawn)
- **Previous Context**: Read iterations 1-2 from this file
- **Action**: Fixed final 2 files
- **Result**: All instances fixed
- **Commit**: ghi789
- **Context Used**: 35%

## Current Measurement
- Detection command: `grep -rn 'Math\.random' packages/ | wc -l`
- Current value: 0
- Target value: 0
- Status: VERIFICATION PENDING
```

### 3. DISCOVERY.md - Multi-Perspective Analysis Results

```markdown
# Discovery: PR55-G3-orchestrator-consistency

## Perspectives Analyzed (Parallel)

### Security Perspective (security-privacy agent)
- **Risk**: Math.random is predictable, enables session hijacking
- **Recommendation**: Use crypto.randomUUID() or SecureRandom
- **Confidence**: HIGH

### Architecture Perspective (Codex Architect)
- **Pattern**: Inconsistent random generation across layers
- **Recommendation**: Centralize in Foundation layer utility
- **Confidence**: HIGH

### UX Perspective (Codex UX)
- **Impact**: None visible to user
- **Recommendation**: N/A
- **Confidence**: N/A

## CEO Consensus (Codex Delegation)

### CEO-Alpha (AI-Native)
- **Verdict**: MUST FIX - Security vulnerability
- **Approach**: Create SecureId utility in foundation
- **Effort**: Small

### CEO-Beta (Modern SWE)
- **Verdict**: MUST FIX - Standard practice
- **Approach**: Use crypto.randomUUID() inline
- **Effort**: Trivial

### Convergence
- **Status**: CONVERGED on must-fix
- **Divergence**: Implementation approach (utility vs inline)
- **Resolution**: User chose: Inline crypto.randomUUID() for simplicity

## Final Decision
Replace Math.random() with crypto.randomUUID() inline in all files.
```

---

## Fresh Agent Per Task Pattern

### Principle: Never Resume, Always Inject Context

```markdown
## BAD: Accumulated Context
Agent A runs discovery → 45% context
Agent A runs fix → 75% context (quality degrading)
Agent A runs verify → 90% context (rushing to complete)
Agent A runs fix again → 95% context (minimal effort)

## GOOD: Fresh Agent Per Task
Orchestrator (15%) → spawns Discovery Agent (100% fresh)
                   ← Returns DISCOVERY.md
Orchestrator (18%) → spawns Fix Agent (100% fresh, reads DISCOVERY.md)
                   ← Returns PROGRESS.md update
Orchestrator (21%) → spawns Verify Agent (100% fresh, reads PROGRESS.md)
                   ← Returns verification status
Orchestrator (24%) → spawns Fix Agent (100% fresh, reads PROGRESS.md)
```

### Implementation: Task Tool with Context Injection

```markdown
## Orchestrator spawns Fix Agent:

Task(
  prompt="""
Execute fix for goal PR55-G3.

## Context (Injected)
Goal: @docs/reviews/goals/PR55-G3-orchestrator-consistency.json
State: @.acis/STATE.md
Progress: @.acis/PROGRESS.md
Discovery: @.acis/DISCOVERY.md

## Instructions
1. Read PROGRESS.md for previous iterations
2. Continue from where last iteration stopped
3. Apply fix using discovery recommendations
4. Update PROGRESS.md with this iteration
5. Return status: SUCCESS | PARTIAL | BLOCKED
""",
  subagent_type="acis-fix-agent"
)
```

### Context Budget Enforcement

| Agent Role | Max Context | Behavior at Limit |
|------------|-------------|-------------------|
| Orchestrator | 15% | Spawn more subagents, never expand |
| Fix Agent | 50% | Checkpoint, return partial results |
| Verify Agent | 30% | Quick verification only |
| Discovery Agent | 50% | Focus on assigned perspective |
| Codex Delegation | N/A | External, unlimited |

---

## Parallel Multi-Perspective Execution

### Discovery Phase: 10+ Perspectives in Parallel

```markdown
## Orchestrator spawns ALL perspectives in ONE message:

Task(prompt="Security perspective for goal G3...", subagent_type="security-privacy")
Task(prompt="Test coverage for goal G3...", subagent_type="test-lead")
Task(prompt="Architecture review for goal G3...", subagent_type="tech-lead")
Task(prompt="Accessibility impact for goal G3...", subagent_type="accessibility-lead")
Task(prompt="Mobile platform impact for goal G3...", subagent_type="mobile-lead")

## PLUS Codex delegations (also parallel):

mcp__codex__codex(prompt="Architect perspective...", sandbox="read-only")
mcp__codex__codex(prompt="UX perspective...", sandbox="read-only")
mcp__codex__codex(prompt="Security perspective...", sandbox="read-only")
mcp__codex__codex(prompt="Algorithm perspective...", sandbox="read-only")

## All 10+ run simultaneously
## Orchestrator collects all results
## Writes synthesized DISCOVERY.md
```

### CEO Validation: Parallel Codex Delegations

```markdown
## Orchestrator spawns BOTH CEOs in ONE message:

mcp__codex__codex(
  prompt="CEO-Alpha (AI-Native perspective)...",
  developer-instructions="@templates/codex-ceo-alpha.md",
  sandbox="read-only"
)

mcp__codex__codex(
  prompt="CEO-Beta (Modern SWE perspective)...",
  developer-instructions="@templates/codex-ceo-beta.md",
  sandbox="read-only"
)

## Both run simultaneously
## Orchestrator compares verdicts
## If converged: Auto-approve
## If diverged: Prompt user for resolution
```

---

## Forced Codex and Ralph-Loop Integration

### Codex: External Expert Perspective (REQUIRED)

```markdown
## Discovery MUST include Codex delegations:

For EVERY discovery phase:
1. Internal agents (parallel): security, test, arch, accessibility, mobile
2. Codex agents (parallel): Architect, UX, Algorithm, Security
3. CEO validation (parallel): CEO-Alpha, CEO-Beta

## Skip Codex = DEGRADED MODE
- Warn user: "Running without external expert validation"
- Still functional but reduced confidence
- Mark in DISCOVERY.md: "Codex: SKIPPED (degraded mode)"
```

### Ralph-Loop: Persistent Execution (REQUIRED)

```markdown
## Remediation MUST use ralph-loop:

/ralph-loop /acis remediate PR55-G3 --max-iterations 20

## Ralph-loop provides:
1. Persistent execution across context limits
2. Automatic continuation after compaction
3. State preservation via .ralph-prompts/
4. Goal achievement guarantee

## Skip ralph-loop = SINGLE-SHOT MODE
- Limited to one context window
- May not achieve goal
- Mark in STATE.md: "Ralph-Loop: SKIPPED (single-shot mode)"
```

---

## ACIS Agent Registry

| Agent | Role | Context Budget | Spawned By |
|-------|------|----------------|------------|
| `acis-orchestrator` | Coordinate loops, spawn agents | 15% | User command |
| `acis-discovery-agent` | Single perspective analysis | 50% | Orchestrator |
| `acis-fix-agent` | Apply code fixes | 50% | Orchestrator |
| `acis-verify-agent` | Run detection commands | 30% | Orchestrator |
| `acis-audit-agent` | Process analysis | 50% | Orchestrator |
| `codex-architect` | External architecture review | N/A | Orchestrator (Codex) |
| `codex-ux` | External UX analysis | N/A | Orchestrator (Codex) |
| `codex-security` | External security analysis | N/A | Orchestrator (Codex) |
| `codex-algorithm` | External algorithm analysis | N/A | Orchestrator (Codex) |
| `codex-ceo-alpha` | AI-Native CEO perspective | N/A | Orchestrator (Codex) |
| `codex-ceo-beta` | Modern SWE CEO perspective | N/A | Orchestrator (Codex) |

---

## State File Lifecycle

```
/acis remediate goal.json
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│ ORCHESTRATOR (fresh, 15% budget)                                │
│                                                                 │
│ 1. Read .acis/STATE.md (position, decisions, blockers)         │
│ 2. Read goal.json (target, detection command)                   │
│ 3. Check: Is this a continuation? Read .acis/PROGRESS.md       │
│                                                                 │
│ 4. DISCOVERY PHASE (if not cached):                            │
│    ├─ Spawn 5 internal agents (parallel, 100% each)            │
│    ├─ Spawn 4 Codex agents (parallel, external)                │
│    ├─ Collect all results                                       │
│    └─ Write .acis/DISCOVERY.md                                  │
│                                                                 │
│ 5. CEO VALIDATION (parallel Codex):                            │
│    ├─ Spawn CEO-Alpha + CEO-Beta                               │
│    ├─ Compare verdicts                                         │
│    └─ Update .acis/DISCOVERY.md with consensus                 │
│                                                                 │
│ 6. FIX PHASE:                                                   │
│    ├─ Spawn acis-fix-agent (100% fresh)                        │
│    │   - Reads: goal.json, STATE.md, PROGRESS.md, DISCOVERY.md │
│    │   - Applies fix based on discovery recommendations         │
│    │   - Updates PROGRESS.md with iteration details             │
│    │   - Returns: SUCCESS | PARTIAL | BLOCKED                   │
│    │                                                            │
│    ├─ Spawn acis-verify-agent (100% fresh)                     │
│    │   - Reads: goal.json, PROGRESS.md                         │
│    │   - Runs detection command                                 │
│    │   - Returns: ACHIEVED | NOT_ACHIEVED | ERROR               │
│    │                                                            │
│    └─ If NOT_ACHIEVED and iterations < max:                    │
│        └─ Loop: Spawn fresh fix-agent with updated PROGRESS.md │
│                                                                 │
│ 7. Update .acis/STATE.md with final status                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Implementation Checklist

### Phase 1: State Files
- [ ] Create `.acis/` directory structure
- [ ] Define STATE.md schema
- [ ] Define PROGRESS.md schema (per-goal)
- [ ] Define DISCOVERY.md schema
- [ ] Update acis.md to read/write state files

### Phase 2: Fresh Agent Pattern
- [ ] Create `acis-orchestrator` agent (thin, <15% context)
- [ ] Create `acis-fix-agent` agent (context injection pattern)
- [ ] Create `acis-verify-agent` agent
- [ ] Create `acis-discovery-agent` agent
- [ ] Update remediate command to use orchestrator pattern

### Phase 3: Parallel Execution
- [ ] Implement parallel internal agent spawning
- [ ] Implement parallel Codex delegations
- [ ] Implement CEO dual-validation
- [ ] Update discovery command for parallel execution

### Phase 4: Codex/Ralph Enforcement
- [ ] Add `--force-codex` flag (error if Codex unavailable)
- [ ] Add `--force-ralph-loop` flag (error if ralph-wiggum unavailable)
- [ ] Mark degraded mode clearly in state files
- [ ] Warn user when running in degraded mode

### Phase 5: Integration
- [ ] Create ralph-profiles for new orchestrator pattern
- [ ] Update audit command for fresh-agent pattern
- [ ] Test full three-loop execution
- [ ] Document context budget expectations

---

## Expected Outcomes

| Metric | Before | After |
|--------|--------|-------|
| Context per fix iteration | 60-90% (accumulated) | 35-50% (fresh) |
| Quality at iteration 5 | Degraded | Consistent |
| Parallel perspectives | 0 (sequential) | 10+ simultaneous |
| External validation | Optional | Required (degraded mode if skipped) |
| Loop isolation | None | Full (via state files) |
| Continuation reliability | Poor (context rot) | Excellent (ralph-loop) |

---

## References

- GSD Framework: `/Users/umesh/AI_Projects/CC_GSD`
- ACIS Current: `/Users/umesh/AI_Products/aivantage/claude-plugins/acis`
- Ralph-Wiggum Plugin: `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/ralph-wiggum/`
- Codex MCP: claude-delegator

---

*Created: 2026-01-19*
*Status: PROPOSAL - Pending Implementation*
