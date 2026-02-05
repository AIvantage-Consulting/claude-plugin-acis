# /acis genesis - Vision to System Architecture Command

Transform vague product ideas into structured system architectures through systematic multi-agent analysis.

**GENESIS** = Generative Engineering for New Ideas → System Extraction from Scratch

## Trigger

User invokes `/acis genesis` command with optional flags:
- `--skip-architecture-gate`: Skip Gate 2 architecture checkpoint
- `--skip-final-gate`: Skip Gate 4 final review
- `--output <path>`: Custom output path (default: `docs/genesis/`)
- `--resume`: Resume from previous incomplete session

## Purpose

GENESIS fills the gap between "idea" and "documentation that `/acis init` can consume". It transforms vague visions into:
- Bounded problem statements
- Detailed persona analysis
- User journey maps
- Domain event models
- Competitive/similar system analysis
- Subsystem architecture proposals
- Architecture Decision Records (ADRs)
- GTM positioning insights

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           /acis genesis                                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
╔═══════════════════════════════════════════════════════════════════════════════╗
║  GATE 0: VISION BOUNDING INTERVIEW (Mandatory)                                 ║
║  ─────────────────────────────────────────────────────────────────────────     ║
║  • Full interview BEFORE any analysis                                          ║
║  • Produces: docs/genesis/VISION_BOUNDED.md                                    ║
║  • Must be READY to proceed                                                    ║
╚═══════════════════════════════════════════════════════════════════════════════╝
                                    │
                                    ▼ (If READY)
                    ┌───────────────────────────────────┐
                    │     LAYER 1: PARALLEL ANALYSIS    │
                    │     (4 agents run simultaneously)  │
                    ├───────────────────────────────────┤
                    │  ┌─────────┐  ┌─────────┐        │
                    │  │ PERSONA │  │ JOURNEY │        │
                    │  │ ANALYST │  │ MAPPER  │        │
                    │  └─────────┘  └─────────┘        │
                    │  ┌─────────┐  ┌─────────┐        │
                    │  │  EVENT  │  │ SIMILAR │        │
                    │  │ STORMER │  │ SYSTEMS │        │
                    │  └─────────┘  └─────────┘        │
                    └───────────────────────────────────┘
                                    │
                                    ▼
╔═══════════════════════════════════════════════════════════════════════════════╗
║  GATE 1: ANALYSIS VALIDATION (Mandatory)                                       ║
║  ─────────────────────────────────────────────────────────────────────────     ║
║  • Present persona findings → User confirms/adjusts                            ║
║  • Present journey maps → User confirms/adjusts                                ║
║  • Present similar systems → User adds/removes                                 ║
║  • Present domain events → User confirms/adjusts                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
                                    │
                                    ▼
                    ┌───────────────────────────────────┐
                    │     LAYER 2: SYNTHESIS AGENT      │
                    │                                   │
                    │  Proposes:                        │
                    │  • Candidate subsystems           │
                    │  • Boundary definitions           │
                    │  • Build vs Buy decisions         │
                    │  • Communication patterns         │
                    └───────────────────────────────────┘
                                    │
                                    ▼
╔═══════════════════════════════════════════════════════════════════════════════╗
║  GATE 2: ARCHITECTURE CHECKPOINT (Recommended - skip with flag)                ║
║  ─────────────────────────────────────────────────────────────────────────     ║
║  • "I'm proposing these subsystems: [list]. Thoughts?"                        ║
║  • "Build vs Buy recommendations: [matrix]. Agree?"                           ║
║  • User can: Approve / Redirect / Add constraints                              ║
╚═══════════════════════════════════════════════════════════════════════════════╝
                                    │
                                    ▼
                    ┌───────────────────────────────────┐
                    │     LAYER 3: CHALLENGE            │
                    │     (4 reviewers in parallel)     │
                    ├───────────────────────────────────┤
                    │  ┌──────────┐  ┌───────────┐     │
                    │  │ SECURITY │  │SCALABILITY│     │
                    │  │ REVIEWER │  │ REVIEWER  │     │
                    │  └──────────┘  └───────────┘     │
                    │  ┌───────────┐  ┌──────────┐     │
                    │  │ACCESSIBIL│  │   COST   │     │
                    │  │ITY REVIEW│  │ REVIEWER │     │
                    │  └───────────┘  └──────────┘     │
                    └───────────────────────────────────┘
                                    │
                                    ▼
╔═══════════════════════════════════════════════════════════════════════════════╗
║  GATE 3: DUAL-CEO SUPPORTED DECISIONS (Mandatory)                              ║
║  ─────────────────────────────────────────────────────────────────────────     ║
║                                                                                ║
║  STEP 1: Dual-CEO Review (automated)                                          ║
║  ┌─────────────────────┐  ┌─────────────────────┐                             ║
║  │  CEO-ALPHA          │  │  CEO-BETA           │                             ║
║  │  (AI-Native)        │  │  (Modern SWE)       │                             ║
║  │                     │  │                     │                             ║
║  │  "Move fast, AI can │  │  "Ship quality,     │                             ║
║  │   handle edge cases │  │   technical debt    │                             ║
║  │   later"            │  │   compounds"        │                             ║
║  └─────────────────────┘  └─────────────────────┘                             ║
║                                                                                ║
║  STEP 2: Present to Human                                                      ║
║  ┌────────────────────────────────────────────────────────────────┐           ║
║  │ FOR ALIGNED DECISIONS (quick rubber-stamp):                    │           ║
║  │ "Both CEOs recommend: [decision]"                              │           ║
║  │ [Approve] [Override]                                           │           ║
║  ├────────────────────────────────────────────────────────────────┤           ║
║  │ FOR CONFLICTED DECISIONS (human decides):                      │           ║
║  │ CEO-Alpha: "[perspective]"                                     │           ║
║  │ CEO-Beta: "[perspective]"                                      │           ║
║  │ [Choose Alpha] [Choose Beta] [Custom Decision]                 │           ║
║  └────────────────────────────────────────────────────────────────┘           ║
╚═══════════════════════════════════════════════════════════════════════════════╝
                                    │
                                    ▼
                    ┌───────────────────────────────────┐
                    │     LAYER 4: ARBITRATION          │
                    │                                   │
                    │  Constrained by user decisions:   │
                    │  • Resolve remaining conflicts    │
                    │  • Generate ADRs                  │
                    │  • Produce final architecture     │
                    └───────────────────────────────────┘
                                    │
                                    ▼
╔═══════════════════════════════════════════════════════════════════════════════╗
║  GATE 4: FINAL REVIEW (Recommended - skip with flag)                           ║
║  ─────────────────────────────────────────────────────────────────────────     ║
║  • "Here's the complete architecture proposal"                                ║
║  • "Here are the ADRs documenting decisions"                                  ║
║  • "Ready to proceed to /acis init?"                                          ║
║  • User can: Approve / Request changes / Restart from specific gate            ║
╚═══════════════════════════════════════════════════════════════════════════════╝
                                    │
                                    ▼
                    ┌───────────────────────────────────┐
                    │     OUTPUT: docs/genesis/         │
                    │                                   │
                    │  • VISION_BOUNDED.md              │
                    │  • ARCHITECTURE_DRAFT.md          │
                    │  • SUBSYSTEMS_DRAFT.md            │
                    │  • PERSONAS_DRAFT.md              │
                    │  • JOURNEYS_DRAFT.md              │
                    │  • EVENTS_DRAFT.md                │
                    │  • SIMILAR_SYSTEMS_ANALYSIS.md    │
                    │  • GTM_POSITIONING.md             │
                    │  • adrs/ADR-001-*.md              │
                    └───────────────────────────────────┘
```

---

## Gate 0: Vision Bounding Interview

**THIS GATE IS MANDATORY.** A vague one-liner leads to cascading bad assumptions.

### 0.1 Load Interview System

```javascript
// Load interview question bank
Read "${CLAUDE_PLUGIN_ROOT}/interview/genesis-vision-interview.json"
```

### 0.2 Conduct Interview

Use `AskUserQuestion` tool for each question. The interview has 4 phases:

| Phase | Questions | Purpose |
|-------|-----------|---------|
| **1. Problem Space** | G1-G5 | What problem? Who? How solved today? Cost? Timing? |
| **2. Solution Vision** | G6-G10 | Unique insight? Founder fit? Success? Anti-scope? Core feature? |
| **3. Constraints** | G11-G15 | Platform? Compliance? Budget? Timeline? Existing assets? |
| **4. Inspiration** | G16-G18 | Admire? Hate? Competitors? |

### 0.3 Red Flag Detection

During interview, detect red flags and handle appropriately:

| Red Flag | Severity | Action |
|----------|----------|--------|
| Problem too vague | **STOP** | Cannot proceed - need specific problem |
| Target user "everyone" | **STOP** | Cannot proceed - need specific user |
| No anti-scope defined | **STOP** | Cannot proceed - need explicit exclusions |
| Multiple core features | **STOP** | Cannot proceed - force prioritization |
| "Better UX" as insight | **WARN** | Weak differentiation - probe deeper |
| No timing insight | **WARN** | Risky - competitors may have failed |
| Overly ambitious 1-year | **WARN** | Scope creep risk - reality check |
| No competitors | **PROBE** | Either naive or blue ocean - investigate |

### 0.4 Assess Readiness

After interview, assess each criterion:

| Criterion | High | Medium | Low |
|-----------|------|--------|-----|
| Problem Clarity | Specific + quantified + clear target | Identified but needs refinement | Vague or "everyone" |
| Solution Clarity | Clear insight + focused scope + anti-scope | Good direction, some ambiguity | No differentiation or unfocused |
| Constraint Clarity | Clear platform, compliance, budget, timeline | Some defined, others unclear | Unrealistic or none |

### 0.5 Readiness Verdict

| Verdict | Criteria | Action |
|---------|----------|--------|
| **READY** | All High or Medium | Proceed to Layer 1 |
| **NEEDS_CLARIFICATION** | One or more Low | Return specific questions, iterate |
| **NOT_READY** | Multiple Low or critical red flags | Cannot proceed, explain why |

### 0.6 Generate VISION_BOUNDED.md

Use template `${CLAUDE_PLUGIN_ROOT}/templates/genesis/VISION_BOUNDED.md` to generate output:

```bash
mkdir -p docs/genesis
# Generate VISION_BOUNDED.md from interview responses
```

---

## Layer 1: Parallel Analysis

**CRITICAL**: All 4 agents run **simultaneously** in a single Task message block.

### 1.1 Spawn Parallel Agents

```javascript
// SINGLE message with 4 Task tool calls (parallel execution)
Task({
  prompt: "Analyze personas for [project] based on @docs/genesis/VISION_BOUNDED.md",
  subagent_type: "genesis-persona-analyst"
})
Task({
  prompt: "Map user journeys for [project] based on @docs/genesis/VISION_BOUNDED.md",
  subagent_type: "genesis-journey-mapper"
})
Task({
  prompt: "Identify domain events for [project] based on @docs/genesis/VISION_BOUNDED.md",
  subagent_type: "genesis-event-stormer"
})
Task({
  prompt: "Analyze similar systems for [project] based on @docs/genesis/VISION_BOUNDED.md",
  subagent_type: "genesis-similar-systems-analyst"
})
```

### 1.2 Agent Outputs

| Agent | Output File | Content |
|-------|-------------|---------|
| Persona Analyst | `docs/genesis/PERSONAS_DRAFT.md` | Personas, needs, accessibility, tech comfort |
| Journey Mapper | `docs/genesis/JOURNEYS_DRAFT.md` | User flows, touchpoints, pain points |
| Event Stormer | `docs/genesis/EVENTS_DRAFT.md` | Domain events, commands, aggregates |
| Similar Systems | `docs/genesis/SIMILAR_SYSTEMS_ANALYSIS.md` | Patterns: ADOPT/ADAPT/AVOID/INNOVATE |

---

## Gate 1: Analysis Validation

**THIS GATE IS MANDATORY.** Validate analysis before synthesis.

### 1.1 Present Findings

Present each agent's findings to user using `AskUserQuestion`:

```
╔═══════════════════════════════════════════════════════════════════╗
║  PERSONA ANALYSIS                                                  ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  Identified Personas:                                              ║
║  1. {Name} (Primary) - {brief description}                        ║
║  2. {Name} (Secondary) - {brief description}                      ║
║                                                                    ║
║  Is this accurate?                                                 ║
║  [Approve] [Add persona] [Modify] [Remove one]                    ║
╚═══════════════════════════════════════════════════════════════════╝
```

Repeat for:
- Journey Maps: "Here are the key user journeys. Missing any?"
- Similar Systems: "Here are the systems I'll analyze. Add/remove?"
- Domain Events: "Here are the domain events. Make sense?"

### 1.2 Incorporate Feedback

If user modifies findings, update the corresponding `_DRAFT.md` file before proceeding.

---

## Layer 2: Synthesis

### 2.1 Spawn Synthesis Agent

```javascript
Task({
  prompt: `Synthesize architecture proposal for [project].
    Inputs:
    - @docs/genesis/VISION_BOUNDED.md
    - @docs/genesis/PERSONAS_DRAFT.md
    - @docs/genesis/JOURNEYS_DRAFT.md
    - @docs/genesis/EVENTS_DRAFT.md
    - @docs/genesis/SIMILAR_SYSTEMS_ANALYSIS.md

    Apply Elite Architect Questions:
    1. Abstraction Level - Is each subsystem at the right level?
    2. Business Boundaries - Do boundaries align with capabilities?
    3. Communication Patterns - Appropriate for relationship?
    4. Build vs Buy - Wardley Map positioning?`,
  subagent_type: "genesis-synthesis-agent"
})
```

### 2.2 Synthesis Output

| Output | Content |
|--------|---------|
| `docs/genesis/SUBSYSTEMS_DRAFT.md` | Candidate subsystems with reasoning |
| `docs/genesis/ARCHITECTURE_DRAFT.md` | Boundary definitions, interaction patterns |
| Build vs Buy matrix | Embedded in architecture |

---

## Gate 2: Architecture Checkpoint (Recommended)

**Skip with `--skip-architecture-gate` flag.**

### 2.1 Present Architecture

```
╔═══════════════════════════════════════════════════════════════════╗
║  ARCHITECTURE PROPOSAL                                             ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  Proposed Subsystems:                                              ║
║  1. {Subsystem} - {brief purpose} [BUILD]                         ║
║  2. {Subsystem} - {brief purpose} [BUY]                           ║
║  3. {Subsystem} - {brief purpose} [BUILD]                         ║
║                                                                    ║
║  Key Boundaries:                                                   ║
║  • {Boundary 1}                                                    ║
║  • {Boundary 2}                                                    ║
║                                                                    ║
║  [Approve] [Redirect subsystem] [Add constraint] [Discuss]        ║
╚═══════════════════════════════════════════════════════════════════╝
```

### 2.2 Handle Feedback

- **Approve**: Proceed to Layer 3
- **Redirect**: Update SUBSYSTEMS_DRAFT.md, re-run synthesis
- **Add constraint**: Note constraint for Layer 3 reviewers
- **Discuss**: Open-ended conversation, then re-ask

---

## Layer 3: Challenge Reviewers

### 3.1 Spawn Parallel Reviewers

```javascript
// SINGLE message with 4 Task tool calls (parallel execution)
Task({
  prompt: "Challenge [project] architecture from security/privacy perspective",
  subagent_type: "genesis-security-reviewer"
})
Task({
  prompt: "Challenge [project] architecture from scalability perspective",
  subagent_type: "genesis-scalability-reviewer"
})
Task({
  prompt: "Challenge [project] architecture from accessibility perspective for target users",
  subagent_type: "genesis-accessibility-reviewer"
})
Task({
  prompt: "Challenge [project] architecture from cost/budget perspective",
  subagent_type: "genesis-cost-reviewer"
})
```

### 3.2 Reviewer Outputs

Each reviewer produces:
- Concerns (with severity: Critical/High/Medium/Low)
- Suggested mitigations
- Tradeoff implications

---

## Gate 3: Dual-CEO Supported Decisions

**THIS GATE IS MANDATORY.** Human is supported, not overwhelmed.

### 3.1 Dual-CEO Review (Automated)

For each concern from Layer 3 reviewers, get both CEO perspectives:

| CEO | Perspective | Typical Stance |
|-----|-------------|----------------|
| **CEO-Alpha** (AI-Native) | Move fast, iterate, AI handles edge cases | "Ship it, improve with data" |
| **CEO-Beta** (Modern SWE) | Quality first, tech debt compounds | "Get it right, rework expensive" |

Use templates:
- `${CLAUDE_PLUGIN_ROOT}/templates/codex-ceo-alpha.md`
- `${CLAUDE_PLUGIN_ROOT}/templates/codex-ceo-beta.md`

### 3.2 Classify Decisions

| Classification | Criteria | Human Effort |
|----------------|----------|--------------|
| **ALIGNED** | Both CEOs agree | Quick rubber-stamp |
| **CONFLICTED** | CEOs disagree | Human decides |

### 3.3 Present Aligned Decisions

For each ALIGNED decision:

```
╔═══════════════════════════════════════════════════════════════════╗
║  ALIGNED RECOMMENDATION                                            ║
╠═══════════════════════════════════════════════════════════════════╣
║  Issue: {concern from reviewer}                                    ║
║                                                                    ║
║  Both CEOs recommend: {decision}                                   ║
║  Rationale: {brief explanation}                                    ║
║                                                                    ║
║  [Approve] [Override with custom decision]                         ║
╚═══════════════════════════════════════════════════════════════════╝
```

### 3.4 Present Conflicted Decisions

For each CONFLICTED decision:

```
╔═══════════════════════════════════════════════════════════════════╗
║  DECISION REQUIRED                                                 ║
╠═══════════════════════════════════════════════════════════════════╣
║  Issue: {concern from reviewer}                                    ║
║                                                                    ║
║  CEO-Alpha (AI-Native):                                            ║
║  "{perspective + recommendation}"                                  ║
║                                                                    ║
║  CEO-Beta (Modern SWE):                                            ║
║  "{perspective + recommendation}"                                  ║
║                                                                    ║
║  [Choose Alpha] [Choose Beta] [Custom Decision]                    ║
╚═══════════════════════════════════════════════════════════════════╝
```

### 3.5 Record Decisions

All decisions (ALIGNED approvals, CONFLICTED choices) are recorded for the Arbitrator.

---

## Layer 4: Arbitration

### 4.1 Spawn Arbitrator Agent

```javascript
Task({
  prompt: `Produce final architecture for [project].

    Inputs:
    - @docs/genesis/ARCHITECTURE_DRAFT.md
    - @docs/genesis/SUBSYSTEMS_DRAFT.md
    - Layer 3 reviewer concerns
    - Gate 3 user decisions (binding)

    Tasks:
    1. Resolve any remaining conflicts (constrained by user decisions)
    2. Generate ADRs for each significant decision
    3. Validate subsystem abstraction levels
    4. Produce final architecture proposal
    5. Generate GTM positioning insights`,
  subagent_type: "genesis-arbitrator-agent"
})
```

### 4.2 ADR Generation

For each significant decision, generate an ADR:

```markdown
# ADR-001: {Title}

## Status: Proposed

## Context
{What led to this decision}

## Decision
{The decision made}

## Rationale
{Why this decision - including CEO perspectives if relevant}

## Consequences
+ {Positive}
+ {Positive}
- {Negative}
- {Negative}

## User Decision Reference
{If from Gate 3: "User chose [Alpha/Beta/Custom] at Gate 3"}
```

### 4.3 Arbitrator Outputs

| Output | Content |
|--------|---------|
| `docs/genesis/ARCHITECTURE_DRAFT.md` | Final architecture (updated) |
| `docs/genesis/adrs/ADR-001-*.md` | Architecture Decision Records |
| `docs/genesis/GTM_POSITIONING.md` | Go-to-market insights from similar systems |

---

## Gate 4: Final Review (Recommended)

**Skip with `--skip-final-gate` flag.**

### 4.1 Present Complete Package

```
╔═══════════════════════════════════════════════════════════════════╗
║  GENESIS COMPLETE                                                  ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  Generated Documents:                                              ║
║  • VISION_BOUNDED.md         - Bounded problem/solution           ║
║  • ARCHITECTURE_DRAFT.md     - System architecture                ║
║  • SUBSYSTEMS_DRAFT.md       - Subsystem definitions              ║
║  • PERSONAS_DRAFT.md         - User personas                      ║
║  • JOURNEYS_DRAFT.md         - User journeys                      ║
║  • EVENTS_DRAFT.md           - Domain events                      ║
║  • SIMILAR_SYSTEMS.md        - Competitive analysis               ║
║  • GTM_POSITIONING.md        - Go-to-market insights              ║
║  • adrs/                     - {N} Architecture Decision Records  ║
║                                                                    ║
║  Ready to proceed to /acis init --from-genesis?                   ║
║                                                                    ║
║  [Proceed to init] [Review specific document] [Restart from gate] ║
╚═══════════════════════════════════════════════════════════════════╝
```

### 4.2 Handle Feedback

- **Proceed**: Run `/acis init --from-genesis docs/genesis/`
- **Review**: Open specific document for discussion
- **Restart**: Go back to specified gate (0, 1, 2, or 3)

---

## Integration with /acis init

After GENESIS completes:

```bash
/acis init --from-genesis docs/genesis/
```

This extracts from GENESIS output to create `.acis-config.json`:

| GENESIS Output | Config Field |
|----------------|--------------|
| VISION_BOUNDED.md | `vision.*`, `projectName` |
| PERSONAS_DRAFT.md | `personas` |
| ARCHITECTURE_DRAFT.md | `architectureModel` |
| Constraints section | `compliance`, `platform` |

---

## State Management

GENESIS saves state after each gate to enable resume:

```
docs/genesis/
├── .genesis-state.json    # Current gate, decisions, flags
├── VISION_BOUNDED.md
├── PERSONAS_DRAFT.md
├── JOURNEYS_DRAFT.md
├── EVENTS_DRAFT.md
├── SIMILAR_SYSTEMS_ANALYSIS.md
├── SUBSYSTEMS_DRAFT.md
├── ARCHITECTURE_DRAFT.md
├── GTM_POSITIONING.md
└── adrs/
    ├── ADR-001-*.md
    └── ADR-002-*.md
```

### .genesis-state.json

```json
{
  "projectName": "{name}",
  "currentGate": 2,
  "completedGates": [0, 1],
  "gateDecisions": {
    "gate1": {
      "personasApproved": true,
      "personasModified": false,
      "journeysApproved": true,
      "similarSystemsAdded": ["Product X"]
    },
    "gate3": {
      "alignedDecisions": [...],
      "conflictedDecisions": [...]
    }
  },
  "flags": {
    "skipArchitectureGate": false,
    "skipFinalGate": false
  },
  "startedAt": "{ISO timestamp}",
  "lastUpdatedAt": "{ISO timestamp}"
}
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Interview red flag (STOP) | Explain, ask clarifying questions, cannot proceed |
| Interview red flag (WARN) | Warn but continue, note in VISION_BOUNDED.md |
| Agent timeout | Retry with fresh agent, max 2 retries |
| User abandons | Save state, offer resume with `--resume` |
| Gate rejection | Allow restart from any previous gate |

---

## Version

- GENESIS Framework: v1.0.0
- Part of ACIS v2.6.0
