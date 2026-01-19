# ACIS - Automated Code Improvement System

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PR CODE REVIEW                                │
│  Codex, Claude, Gemini, Human reviewers submit comments             │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   PHASE 1: LLM-POWERED EXTRACTION                   │
│  ┌─────────────┐    ┌─────────────────┐    ┌──────────────────┐    │
│  │ GitHub API  │───▶│ Claude (LLM)    │───▶│ Goal JSON Files  │    │
│  │ PR Comments │    │ Analyzes text,  │    │ Quantifiable     │    │
│  │ + Diff      │    │ extracts goals  │    │ targets          │    │
│  └─────────────┘    └─────────────────┘    └──────────────────┘    │
│                              │                                      │
│                    Uses prompts from:                               │
│                    ${CLAUDE_PLUGIN_ROOT}/prompts/                   │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   PHASE 2-6: AGENT-ENHANCED REMEDIATION             │
│  ┌─────────────┐    ┌─────────────────┐    ┌──────────────────┐    │
│  │ Goal File   │───▶│ Complexity      │───▶│ Agent Router     │    │
│  │ M1-xyz.json │    │ Classifier      │    │                  │    │
│  └─────────────┘    └────────┬────────┘    └────────┬─────────┘    │
│                              │                       │              │
│                    ┌─────────┴─────────┐            │              │
│                    │                   │            │              │
│              Tier 1 (Simple)    Tier 2-3 (Complex)  │              │
│                    │                   │            │              │
│                    ▼                   ▼            │              │
│              Standard Loop      Multi-Agent ◄───────┘              │
│              (single LLM)       Orchestration                      │
│                                                                    │
│  TIER 1 WORKFLOW:              TIER 2-3 WORKFLOW:                  │
│  1. MEASURE (grep)             1. MEASURE (grep)                   │
│  2. ANALYZE (LLM)              2. ANALYZE (specialist agents)      │
│  3. FIX (LLM)                  3. DESIGN (tech-lead + approval)    │
│  4. VERIFY (tests)             4. IMPLEMENT (LLM with constraints) │
│  5. REPORT                     5. VERIFY (test-lead + reviewer)    │
│                                6. REPORT                           │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      COMPLETION PROMISES                            │
│  <promise>GOAL_M1-xyz_ACHIEVED</promise>  ← Success                │
│  <promise>GOAL_M1-xyz_BLOCKED</promise>   ← Needs human help       │
│  <promise>GOAL_M1-xyz_MAX_ITERATIONS</promise> ← Safety limit      │
└─────────────────────────────────────────────────────────────────────┘
```

## Complexity Tiers & Agent Routing

Goals are classified into complexity tiers that determine the workflow:

### Tier 1: Simple Pattern Replacement

- **Characteristics**: Mechanical grep-and-replace, single correct solution
- **Example**: `Math.random()` → `crypto.randomUUID()`
- **Workflow**: Standard ralph-loop (single LLM agent)
- **Agents**: None (main LLM handles entirely)

### Tier 2: Moderate Context-Aware

- **Characteristics**: Multiple valid approaches, requires domain understanding
- **Example**: Error handling patterns, validation logic
- **Workflow**: Ralph-loop + specialized review agents
- **Agents**: 1-2 specialists based on lens (e.g., `security-privacy`, `test-lead`)

### Tier 3: Complex Architectural

- **Characteristics**: Lifecycle management, cross-cutting concerns, design decisions
- **Example**: Session initialization patterns, offline-first architecture
- **Workflow**: Full multi-agent orchestration with user approval gates
- **Agents**: Multiple specialists in phased workflow

### Agent Routing Matrix

| Lens            | Tier 1 | Tier 2             | Tier 3                                      |
| --------------- | ------ | ------------------ | ------------------------------------------- |
| security        | -      | security-privacy   | security-privacy + tech-lead                |
| architecture    | -      | tech-lead          | tech-lead + mobile-lead + backend-lead      |
| maintainability | -      | tech-lead          | tech-lead + code-reviewer                   |
| testing         | -      | test-lead          | test-lead + integration-orchestrator        |
| accessibility   | -      | accessibility-lead | accessibility-lead + web-lead + mobile-lead |
| privacy         | -      | security-privacy   | security-privacy + backend-lead             |

## Where LLM is Used

| Phase | Component       | LLM Usage                                                                                       |
| ----- | --------------- | ----------------------------------------------------------------------------------------------- |
| 1     | Goal Extraction | Claude analyzes review comments, identifies quantifiable patterns, generates detection commands |
| 2-6   | Remediation     | Claude orchestrates agents based on complexity tier                                             |
| All   | Decision Making | Claude decides which files to fix, what replacement is appropriate, when to stop                |

## File Structure

### Plugin Structure (`${CLAUDE_PLUGIN_ROOT}/`)

```
acis/
├── .claude-plugin/
│   └── plugin.json                      # Plugin manifest
├── commands/
│   ├── acis.md                          # Main ACIS command
│   ├── acis-init.md                     # Project bootstrapping
│   └── acis-audit.md                    # Process Auditor
├── schemas/
│   ├── acis-goal.schema.json            # Goal JSON schema
│   ├── acis-decision.schema.json        # Decision schema
│   └── acis-decision-manifest.schema.json # Manifest schema
├── configs/
│   ├── assessment-lenses.json           # Multi-lens patterns
│   └── acis-perspectives.json           # Agent perspectives
├── prompts/
│   └── extract-goals-from-review.prompt.md  # LLM extraction prompt
├── templates/
│   ├── codex-*.md                       # Codex delegation templates
│   └── remediation-loop.prompt.md       # Ralph-loop template
├── interview/
│   ├── interview-flow.md                # Interview orchestration
│   ├── question-bank.json               # Phased questions
│   └── artifact-templates/              # Generated doc templates
├── audit/
│   ├── audit-flow.md                    # Process Auditor flow
│   ├── reflection-prompts.md            # Reflection phase prompts
│   ├── skill-detection.md               # Skill extraction criteria
│   └── audit-report.template.md         # Audit report template
├── skill-templates/
│   └── skill-template.md                # Template for generated skills
├── ralph-profiles/
│   ├── process-auditor.json             # Loop 1 (Outermost)
│   ├── discovery-orchestrator.json      # Loop 2 (Middle)
│   └── behavioral-tdd.json              # Loop 3 (Innermost)
└── docs/
    ├── ACIS_ARCHITECTURE.md             # This file
    └── ACIS_USER_GUIDE.md               # User guide
```

### Project Structure (in project root)

```
project/
├── .acis-config.json                    # Project-specific config (from /acis init)
├── docs/
│   ├── reviews/goals/                   # Goal files
│   │   └── PR55-G1-xxx.json             # Example goal file
│   ├── manifests/                       # Decision manifests
│   ├── reports/                         # Discovery reports
│   └── audits/                          # Process Auditor reports
└── skills/                              # Dynamically generated skills

.ralph-prompts/
└── M1-math-random.prompt.md             # Generated ralph-loop prompt

.claude/commands/
└── acis.md                              # /acis slash command
```

## Usage

### Method 1: Slash Command (Recommended)

```bash
# Extract goals from PR using LLM
/acis extract 55

# Remediate a specific goal
/acis remediate docs/reviews/goals/M1-math-random.json

# Check status of all goals
/acis status
```

### Method 2: Manual Scripts

```bash
# Step 1: Generate extraction prompt
./scripts/extract-review-goals-llm.sh 55

# Step 2: (In Claude) Analyze the prompt and create goal files

# Step 3: Generate ralph-loop prompt
./scripts/generate-ralph-prompt.sh --goal-file docs/reviews/goals/M1-math-random.json

# Step 4: Run ralph-loop
/ralph-loop "$(cat .ralph-prompts/M1-math-random.prompt.md)" \
  --completion-promise "GOAL_M1-math-random_ACHIEVED" \
  --max-iterations 15
```

### Method 3: Full Orchestration

```bash
# Extract all goals from PR and generate prompts
./scripts/orchestrate-remediation.sh --pr 55

# Then run ralph-loop for each goal
```

## Integration Points

### 1. GitHub Actions Trigger (Future)

```yaml
on:
  pull_request_review:
    types: [submitted]

jobs:
  extract-goals:
    runs-on: ubuntu-latest
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          command: /acis extract ${{ github.event.pull_request.number }}
```

### 2. Multi-Reviewer Aggregation

- Comments from Codex, Claude, Gemini tagged by reviewer
- LLM deduplicates overlapping concerns
- Priority based on severity × reviewer count

### 3. Progress Tracking

- Each goal tracks iterations and progress
- Dashboard shows overall improvement velocity
- Alerts when goals are blocked

## Design Principles

1. **LLM for Intelligence, Scripts for Scaffolding**

   - Shell scripts handle data fetching, file I/O, orchestration
   - Claude handles semantic understanding, code generation, decisions

2. **Quantifiable Over Qualitative**

   - Every goal must have a measurable target
   - Grep command to verify progress
   - No subjective "improved" claims

3. **Iterative Until Complete**

   - Ralph-loop ensures persistence
   - Safety limits prevent infinite loops
   - Blocked state triggers human review

4. **TDD-First Remediation**

   - Each fix maintains test coverage
   - Typecheck + lint gates
   - No shortcuts allowed (CLAUDE.md enforced)

5. **Specialized Agents for Complex Goals** (NEW)
   - Route Tier 2-3 goals to domain specialists
   - Parallel agent execution where possible
   - User approval gates before implementation

---

## Multi-Agent Workflow (Tier 2-3)

For complex goals, ACIS orchestrates specialized agents in a phased workflow:

### Phase 2: ANALYZE (Parallel Agents)

```
┌─────────────────────────────────────────────────────────────────┐
│ Task tool invocations (parallel where independent):             │
│                                                                 │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│ │ tech-lead    │  │ security-    │  │ test-lead    │          │
│ │              │  │ privacy      │  │              │          │
│ │ Analyze      │  │ Identify     │  │ Assess test  │          │
│ │ architecture │  │ security     │  │ coverage     │          │
│ │ implications │  │ concerns     │  │ gaps         │          │
│ └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│        │                 │                 │                   │
│        └─────────────────┴─────────────────┘                   │
│                          │                                     │
│                          ▼                                     │
│              ┌───────────────────────┐                        │
│              │ Aggregate findings    │                        │
│              │ into design brief     │                        │
│              └───────────────────────┘                        │
└─────────────────────────────────────────────────────────────────┘
```

**Agent Prompts for ANALYZE Phase:**

```markdown
## tech-lead Agent Prompt

Analyze the following goal for architectural implications:

- Goal: {goal.id}
- Pattern: {goal.detection.pattern}
- Files affected: {list from grep}
- Lens: {goal.source.lens}

Provide:

1. Architectural components affected
2. Cross-cutting concerns
3. Recommended approach (with trade-offs)
4. Files that need coordinated changes
```

### Phase 3: DESIGN (User Approval Gate)

```
┌─────────────────────────────────────────────────────────────────┐
│ tech-lead Agent (sequential, requires ANALYZE output):          │
│                                                                 │
│ Input: Aggregated analysis from Phase 2                        │
│                                                                 │
│ Output:                                                        │
│ ┌─────────────────────────────────────────────────────────┐    │
│ │ DESIGN PROPOSAL                                          │    │
│ │                                                          │    │
│ │ Option A: [approach] - Pros/Cons                        │    │
│ │ Option B: [approach] - Pros/Cons                        │    │
│ │                                                          │    │
│ │ Recommended: Option [X]                                  │    │
│ │ Implementation sequence:                                 │    │
│ │   1. File A: [change]                                   │    │
│ │   2. File B: [change]                                   │    │
│ │   3. ...                                                │    │
│ └─────────────────────────────────────────────────────────┘    │
│                          │                                     │
│                          ▼                                     │
│              ┌───────────────────────┐                        │
│              │ USER APPROVAL GATE    │                        │
│              │ (AskUserQuestion)     │                        │
│              └───────────────────────┘                        │
└─────────────────────────────────────────────────────────────────┘
```

### Phase 4: IMPLEMENT (Main LLM with Constraints)

The main LLM implements the approved design:

```
┌─────────────────────────────────────────────────────────────────┐
│ Main LLM Implementation (constrained by approved design):       │
│                                                                 │
│ For each file in implementation sequence:                      │
│   1. Read current file state                                   │
│   2. Apply change per design specification                     │
│   3. Maintain minimal diff                                     │
│   4. Update related tests                                      │
│                                                                 │
│ Constraints:                                                   │
│ - MUST follow approved approach (no deviations)               │
│ - MUST NOT expand scope beyond design                         │
│ - MUST maintain backward compatibility unless specified       │
└─────────────────────────────────────────────────────────────────┘
```

### Phase 5: VERIFY (Parallel Review Agents)

```
┌─────────────────────────────────────────────────────────────────┐
│ Task tool invocations (parallel):                               │
│                                                                 │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│ │ test-lead    │  │ code-reviewer│  │ [lens-agent] │          │
│ │              │  │              │  │              │          │
│ │ Verify test  │  │ Review code  │  │ Verify lens- │          │
│ │ coverage     │  │ quality      │  │ specific     │          │
│ │ maintained   │  │ and patterns │  │ requirements │          │
│ └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│        │                 │                 │                   │
│        └─────────────────┴─────────────────┘                   │
│                          │                                     │
│                          ▼                                     │
│              ┌───────────────────────┐                        │
│              │ All agents approve?   │                        │
│              │ Yes → Phase 6         │                        │
│              │ No  → Back to Phase 4 │                        │
│              └───────────────────────┘                        │
└─────────────────────────────────────────────────────────────────┘
```

### Phase 6: REPORT

Update goal JSON with:

- Agent findings from each phase
- Design decisions made
- Implementation details
- Verification results

### Phase 7: CONTINUATION (User Choice Gate)

After a goal is achieved/blocked, ACIS presents continuation options to the user:

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONTINUATION FLOW                             │
│                                                                 │
│  Goal Completed                                                 │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ DISCOVER NEXT OPTIONS                                    │   │
│  │                                                          │   │
│  │ 1. Check related_goals in completed goal JSON            │   │
│  │ 2. Scan docs/reviews/goals/ for pending goals            │   │
│  │ 3. Sort by: severity > deferred_from > created_at        │   │
│  └─────────────────────────────────────────────────────────┘   │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ PRESENT USER CHOICES (AskUserQuestion)                   │   │
│  │                                                          │   │
│  │ "Goal X achieved. What next?"                            │   │
│  │                                                          │   │
│  │ ○ Continue with related goal Y (deferred from X)         │   │
│  │ ○ Pick from N other pending goals                        │   │
│  │ ○ Review progress summary                                │   │
│  │ ○ Stop for now                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ EXECUTE USER CHOICE                                      │   │
│  │                                                          │   │
│  │ - "Continue with Y" → Start Phase 1 for goal Y          │   │
│  │ - "Pick from others" → Show goal list, user selects     │   │
│  │ - "Review progress" → Show /acis status summary         │   │
│  │ - "Stop" → End with summary of session                  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

**Continuation Priority Rules:**

| Priority | Condition                                    | Action                        |
| -------- | -------------------------------------------- | ----------------------------- |
| 1        | Goal has `related_goals` with status=pending | Offer as primary option       |
| 2        | Goal was `deferred_from` another goal        | Offer to return to parent     |
| 3        | Other goals with same `pr_number`            | Group as "PR cleanup" option  |
| 4        | Goals with severity=high                     | Offer as high-priority        |
| 5        | Oldest pending goals                         | Include in "other goals" list |

**Example Continuation Prompt:**

```
✓ PR55-G2-uninitialized-session ACHIEVED

What would you like to do next?

┌─────────────────────────────────────────────────────────────┐
│ Related Work                                                 │
│ ○ Continue with PR55-G3-orchestrator-method-consistency     │
│   (deferred Option D refactor from PR55-G2)                 │
│   Tier 2 | maintainability | medium severity                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Other Options                                                │
│ ○ Pick from 3 other pending goals                           │
│ ○ Review overall progress (/acis status)                    │
│ ○ Stop for now                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Example: Tier 3 Goal Execution

Goal: `PR55-G2-uninitialized-session` (session lifecycle management)

```bash
# Phase 1: MEASURE
$ grep -rn 'new.*Orchestrator()' packages/mobile/src | wc -l
# Result: 12 instantiations

# Phase 2: ANALYZE (parallel agents)
$ claude task --agent tech-lead "Analyze session initialization patterns..."
$ claude task --agent security-privacy "Review authentication flow..."
$ claude task --agent test-lead "Assess test coverage for session lifecycle..."

# Phase 3: DESIGN (with user approval)
$ claude task --agent tech-lead "Propose design for session initialization..."
# [User reviews and approves Option B: Lazy initialization]

# Phase 4: IMPLEMENT
# Main LLM implements lazy init pattern per approved design

# Phase 5: VERIFY (parallel agents)
$ claude task --agent test-lead "Verify session tests cover new patterns..."
$ claude task --agent code-reviewer "Review implementation quality..."

# Phase 6: REPORT
# Update PR55-G2-uninitialized-session.json with results
```
