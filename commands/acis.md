# ACIS v2.1 - Automated Code Improvement System

You are executing the Automated Code Improvement System (ACIS) v2.1 workflow with:
- **Decision-oriented discovery** (surface macro/micro decisions before implementation)
- **Dual-CEO validation** (independent recommendations from AI-Native + Modern SWE perspectives)
- **Multi-perspective discovery** (10+ agents in parallel)
- **Behavioral TDD** (persona-driven acceptance tests) - ON by default
- **Consensus verification** (independently verifiable metrics) - ON by default
- **Codex integration** for Architecture, UX, Algorithm, Security, and CEO-Alpha perspectives
- **Dynamic Skill Generation** (Process Auditor extracts reusable patterns into Skills)

## Project Configuration

ACIS loads project-specific configuration from `.acis-config.json` in the project root.
Use `/acis init` to create this file interactively.

If no config exists, ACIS uses sensible defaults:
- `goalsDirectory`: "docs/reviews/goals"
- `compliance`: []
- `personas`: []
- `architectureModel`: "custom"
- `vision`: {} (empty)
- `platform`: { "web": true }

### Config Loading
1. Read `.acis-config.json` from project root
2. If not found, prompt user to run `/acis init`
3. Merge with defaults for any missing fields
4. Make config available as `${config.X}` variables
5. **Apply pluginDefaults automatically** (see below)

### Plugin Defaults (Auto-Applied Flags)

When `.acis-config.json` contains `pluginDefaults`, these flags are applied automatically. Override flags work in the **opposite direction**:

| Config Setting | Default Behavior | Override Flag |
|----------------|------------------|---------------|
| `skipCodex: false` (plugin installed) | Codex delegations enabled | `--skip-codex` to disable |
| `skipCodex: true` (plugin missing) | Codex delegations disabled | `--use-codex` to enable |
| `skipRalphLoop: false` (plugin installed) | Ralph-loop enabled | `--skip-ralph-loop` to disable |
| `skipRalphLoop: true` (plugin missing) | Standard loops used | `--use-ralph-loop` to enable |

**Principle**: Defaults match plugin availability. Override flags go the opposite direction.

**Examples**:
- Plugins installed, config has `"skipCodex": false`:
  - `/acis discovery "topic"` → uses Codex
  - `/acis discovery "topic" --skip-codex` → skips Codex

- Plugins missing, config has `"skipCodex": true`:
  - `/acis discovery "topic"` → skips Codex (auto)
  - `/acis discovery "topic" --use-codex` → attempts to use Codex

**Why this exists**: `/acis init` detects plugin availability and sets appropriate defaults. This prevents repeated errors from missing dependencies while allowing explicit overrides when needed.

### Context Management Architecture

ACIS uses a **fresh-agent-per-task** pattern to prevent context rot in nested loops.

#### The Problem
- Inner loops inherit context from outer loops
- Quality degrades as context fills (especially >50%)
- Accumulated context causes "completion mode" behavior

#### The Solution: State Files + Fresh Agents

**State Files** (in `.acis/` directory):
| File | Purpose |
|------|---------|
| `STATE.md` | Global position, decisions, blockers |
| `progress/{goal-id}.json` | Per-goal iteration history |
| `discovery/{goal-id}.md` | Multi-perspective analysis results |

**Fresh Agent Pattern**:
```
Orchestrator (15% context) → spawns → Fresh Agent (100% context)
                          ← returns ← Results to state files
```

Each agent receives context via **@-file injection**, not accumulation:
```
Task(
  prompt="Fix goal...
    Goal: @docs/reviews/goals/PR55-G3.json
    State: @.acis/STATE.md
    Progress: @.acis/progress/PR55-G3.json",
  subagent_type="acis-fix-agent"
)
```

#### Context Budget Discipline

| Agent Role | Max Context | Enforcement |
|------------|-------------|-------------|
| Orchestrator | 15% | Spawn agents, never expand |
| Fix Agent | 50% | Checkpoint at limit, return partial |
| Verify Agent | 12% | Quick verification only |
| Discovery Agent | 50% | Single perspective focus |

#### Parallel Multi-Perspective Execution

All independent perspectives run **simultaneously** via multiple Task calls in one message:

```
# These run in PARALLEL (same message):
Task(prompt="Security analysis...", subagent_type="security-privacy")
Task(prompt="Architecture review...", subagent_type="tech-lead")
Task(prompt="Test coverage...", subagent_type="test-lead")
mcp__codex__codex(prompt="CEO-Alpha...", sandbox="read-only")
mcp__codex__codex(prompt="CEO-Beta...", sandbox="read-only")
```

**Full architecture**: See `${CLAUDE_PLUGIN_ROOT}/docs/CONTEXT_MANAGEMENT_PROPOSAL.md`

## Arguments

- `$ARGUMENTS` - Command and flags

## Commands

| Command | Description |
|---------|-------------|
| `init` | Bootstrap ACIS for a new project (interview or doc extraction) |
| `extract <PR>` | Extract goals from PR review comments |
| `discovery "<topic>"` | Proactive investigation: surface decisions, generate specs, find issues |
| `resolve <manifest>` | Resolve pending decisions (auto-approve if CEOs converge, prompt if diverge) |
| `remediate <goal-file>` | Full pipeline: Discovery → Behavioral TDD → Ralph-Loop → Consensus |
| `status` | Show progress across all goals and manifests |
| `verify <goal-file>` | Run consensus verification only |
| `audit` | Process Auditor: analyze patterns, generate skills, improve ACIS itself |

## Subcommand Routing

### `/acis init`
Delegates to `${CLAUDE_PLUGIN_ROOT}/commands/acis-init.md`

Bootstraps ACIS for a new project:
- Extracts project context from existing docs (vision.md, prd.md, etc.)
- OR conducts BA/PM-style interview if no docs exist
- Generates `.acis-config.json` with personas, compliance, architecture

### `/acis audit`
Delegates to `${CLAUDE_PLUGIN_ROOT}/commands/acis-audit.md`

Process Auditor (Loop 1 - Outermost):
- PAUSE: Halt active work, establish audit scope
- REFLECT: Analyze completed remediation cycles
- LEARN: Identify reinforcements, corrections, skill candidates
- APPLY: Generate skills, apply process improvements
- DOCUMENT: Generate audit report

## Flags

### For `remediate` (Defaults: behavioral=ON, consensus=ON)

| Flag | Description |
|------|-------------|
| `--no-behavioral` | Skip behavioral TDD phase (persona scenarios) |
| `--no-consensus` | Skip multi-agent consensus verification |
| `--skip-codex` | Skip Codex delegations (use internal agents only) |
| `--use-codex` | Override `pluginDefaults.skipCodex` and use Codex |
| `--force-codex` | **REQUIRE Codex** - Error if unavailable (ensures external validation) |
| `--skip-ralph-loop` | Use standard loops instead of ralph-loop |
| `--use-ralph-loop` | Override `pluginDefaults.skipRalphLoop` and use ralph-loop |
| `--force-ralph-loop` | **REQUIRE ralph-loop** - Error if unavailable (ensures persistent execution) |
| `--force-full` | Shorthand for `--force-codex --force-ralph-loop` (maximum quality mode) |
| `--discovery-only` | Run Phase 1 only, output refinements |
| `--max-iterations N` | Maximum ralph-loop iterations (default: 20) |
| `--manifest <file>` | Bind to decision manifest (enforce resolved decisions) |
| `--deep-5whys` | Force multi-perspective 5 Whys for every fix (slower, more thorough) |
| `--fresh-agents` | Use fresh-agent-per-task pattern (default: ON) |
| `--parallel-discovery` | Run all discovery perspectives in parallel (default: ON) |

**Enforcement Flags** (`--force-*`):
- `--force-codex`: Requires Codex MCP to be available. Errors immediately if not configured. Use this when external expert validation is critical (security-sensitive goals, architectural changes).
- `--force-ralph-loop`: Requires ralph-wiggum plugin. Errors immediately if not installed. Use this when goal MUST be achieved (cannot accept partial results).
- `--force-full`: Maximum quality mode. Ensures both external validation AND persistent execution.

### For `discovery`

| Flag | Description |
|------|-------------|
| `--type <type>` | Investigation type: feature, refactor, audit, what-if, bug-hunt |
| `--scope <paths>` | Limit investigation to specific paths (comma-separated) |
| `--depth <level>` | shallow, medium, deep (default: medium) |
| `--skip-codex` | Skip Codex delegations (internal agents only) |
| `--use-codex` | Override `pluginDefaults.skipCodex` and use Codex |
| `--force-codex` | **REQUIRE Codex** - Error if unavailable |
| `--parallel` | Run all perspectives in parallel (default: ON) |
| `--output <artifacts>` | report, manifest, spec, goals, adr (default: all) |

### For `resolve`

| Flag | Description |
|------|-------------|
| `--auto-only` | Only auto-approve converged decisions, skip diverged |
| `--force <decision-id>` | Force resolution of specific decision with owner input |

## Workflow: `/acis remediate <goal-file>`

### Phase 0: ORCHESTRATOR INITIALIZATION

The remediation workflow is driven by a **thin orchestrator** (15% context budget) that spawns fresh agents:

```
1. Read goal file: @{goal-file-path}
2. Initialize state: .acis/STATE.md (or create if missing)
3. Initialize progress: .acis/progress/{goal-id}.json
4. Check enforcement flags: --force-codex, --force-ralph-loop
5. Validate plugins available if enforced
```

**State Initialization** (create `.acis/STATE.md` if not exists):
```markdown
# ACIS State

## Current Position
- activeGoal: {goal-id}
- loop: discovery | remediation | verification
- iteration: 1
- status: in-progress
```

### Phase 1: MULTI-PERSPECTIVE DISCOVERY (Parallel Waves)

Launch ALL discovery agents **simultaneously** via multiple Task/Codex calls in a single message.

**Wave 1: Internal Agents + Codex (ALL IN PARALLEL)**

All these calls are made in a **SINGLE message** to run concurrently:

```
# WAVE 1 - ALL PARALLEL (one message, multiple tool calls)

# Internal Agents (via Task tool)
Task(
  prompt="Analyze goal {GOAL_ID} from security/PHI perspective.
    Goal: @{goal-file}
    Focus: PHI exposure, HIPAA compliance, encryption gaps
    Output: Findings, metrics to verify, behavioral scenarios",
  subagent_type="security-privacy"
)

Task(
  prompt="Analyze goal {GOAL_ID} from architecture perspective.
    Goal: @{goal-file}
    Focus: Layer violations, design patterns, technical debt
    Output: Findings, metrics to verify, behavioral scenarios",
  subagent_type="tech-lead"
)

Task(
  prompt="Analyze goal {GOAL_ID} from testing perspective.
    Goal: @{goal-file}
    Focus: Coverage gaps, test strategies, regression risks
    Output: Findings, metrics to verify, behavioral scenarios",
  subagent_type="test-lead"
)

Task(
  prompt="Analyze goal {GOAL_ID} from mobile/offline perspective.
    Goal: @{goal-file}
    Focus: Platform compatibility, offline resilience, sync issues
    Output: Findings, metrics to verify, behavioral scenarios",
  subagent_type="mobile-lead"
)

Task(
  prompt="Analyze goal {GOAL_ID} from end-user/persona perspective.
    Goal: @{goal-file}
    Config: @.acis-config.json (for personas)
    Focus: Impact on Brenda/David/Dr.Evans, UX concerns
    Output: Findings, metrics to verify, behavioral scenarios",
  subagent_type="oracle"
)

Task(
  prompt="Analyze goal {GOAL_ID} from operations perspective.
    Goal: @{goal-file}
    Focus: Deployment, monitoring, maintenance burden
    Output: Findings, metrics to verify, behavioral scenarios",
  subagent_type="devops-lead"
)

Task(
  prompt="Analyze goal {GOAL_ID} from crash-resilience perspective.
    Goal: @{goal-file}
    Focus: Failure modes, error handling, recovery paths
    Output: Findings, metrics to verify, behavioral scenarios",
  subagent_type="oracle"
)

# Codex Delegations (via mcp__codex__codex) - ALSO IN SAME MESSAGE
mcp__codex__codex(
  prompt="Architect: Analyze goal {GOAL_ID} for design tradeoffs.
    Goal: {goal content}
    Output: Design concerns, alternatives, recommendation",
  developer-instructions="Read @${CLAUDE_PLUGIN_ROOT}/templates/codex-architect-discovery.md",
  sandbox="read-only"
)

mcp__codex__codex(
  prompt="UX Analyst: Analyze goal {GOAL_ID} for persona impact.
    Goal: {goal content}
    Personas: {from config}
    Output: UX concerns, accessibility issues, journey impacts",
  developer-instructions="Read @${CLAUDE_PLUGIN_ROOT}/templates/codex-ux-discovery.md",
  sandbox="read-only"
)

mcp__codex__codex(
  prompt="Algorithm Expert: Analyze goal {GOAL_ID} for efficiency.
    Goal: {goal content}
    Output: Algorithm concerns, performance recommendations",
  developer-instructions="Read @${CLAUDE_PLUGIN_ROOT}/templates/codex-algorithm-discovery.md",
  sandbox="read-only"
)

mcp__codex__codex(
  prompt="Security Analyst: Analyze goal {GOAL_ID} for hardening.
    Goal: {goal content}
    Output: Threat model, attack vectors, hardening recommendations",
  developer-instructions="Read @${CLAUDE_PLUGIN_ROOT}/templates/codex-security-discovery.md",
  sandbox="read-only"
)

# Web Search - ALSO IN SAME MESSAGE
WebSearch(query="{goal topic} best practices 2026")
```

**Wave 2: CEO Validation (Parallel after Wave 1 completes)**

After Wave 1 results collected, launch CEOs **simultaneously**:

```
# WAVE 2 - CEO VALIDATION (one message, two tool calls)

mcp__codex__codex(
  prompt="CEO-Alpha: Evaluate goal {GOAL_ID} findings.
    Goal: {goal content}
    Discovery Findings: {synthesized from Wave 1}
    Output: AI-Native perspective, recommendation, confidence",
  developer-instructions="Read @${CLAUDE_PLUGIN_ROOT}/templates/codex-ceo-alpha.md",
  sandbox="read-only"
)

mcp__codex__codex(
  prompt="CEO-Beta: Evaluate goal {GOAL_ID} findings.
    Goal: {goal content}
    Discovery Findings: {synthesized from Wave 1}
    Output: Modern SWE perspective, recommendation, confidence",
  developer-instructions="Read @${CLAUDE_PLUGIN_ROOT}/templates/codex-ceo-beta.md",
  sandbox="read-only"
)
```

**Degraded Mode**: If `--skip-codex` or Codex unavailable:
- Skip all `mcp__codex__codex` calls
- Log: "Running in degraded mode - no external expert validation"
- Continue with internal agents only

**Output**: Write discovery results to `.acis/discovery/{goal-id}.md`:
- Synthesized findings from all perspectives
- Enhanced `detection.verifiable_metrics`
- Populated `behavioral.acceptance_scenarios`
- Updated `remediation.guidance`
- CEO convergence status

### Phase 2: BEHAVIORAL TDD (Default ON)

Skip with `--no-behavioral`.

1. **Extract Personas**: From discovery results, identify affected personas
2. **Create Acceptance Scenarios**: Given/When/Then format
3. **Write Behavioral Tests**: Create test file before implementation
4. **Run Tests**: Expect FAIL (RED phase)

```typescript
// Example: packages/mobile/src/__tests__/behavioral/WO63-CRIT-001.behavioral.spec.ts
describe('Brenda medication lookup during key rotation', () => {
  given('key rotation is in progress', () => {
    when('Brenda views her medications', () => {
      then('medications display without interruption', () => { ... });
      and('no PHI is exposed during rotation', () => { ... });
    });
  });
});
```

### Phase 3: RALPH-LOOP (Sisyphus Remediation with Fresh Agents)

Each iteration spawns **fresh agents** to prevent context rot:

```
ORCHESTRATOR (15% context max) LOOP:
│
├── 1. SPAWN VERIFY AGENT (fresh, 12% context)
│   Task(
│     prompt="Verify goal status.
│       Goal: @{goal-file}
│       Progress: @.acis/progress/{goal-id}.json
│       Run detection commands, report current values.",
│     subagent_type="acis-verify-agent"
│   )
│   → Returns: { status, currentValue, targetValue, details }
│
├── 2. CHECK: If status == "achieved" → exit loop, go to Phase 4
│
├── 3. [If trigger met] SPAWN 5-WHYS AGENTS (parallel, fresh)
│   # All in single message for parallel execution
│   Task(prompt="5 Whys from security perspective...", subagent_type="security-privacy")
│   Task(prompt="5 Whys from architecture perspective...", subagent_type="tech-lead")
│   Task(prompt="5 Whys from resilience perspective...", subagent_type="oracle")
│   → Returns: Synthesized root cause + fix approach
│
├── 4. SPAWN FIX AGENT (fresh, 50% context)
│   Task(
│     prompt="Execute fix iteration {N}.
│       Goal: @{goal-file}
│       State: @.acis/STATE.md
│       Progress: @.acis/progress/{goal-id}.json
│       Discovery: @.acis/discovery/{goal-id}.md
│
│       Previous iterations in Progress file.
│       Apply fix based on Discovery recommendations.
│       Return: { result: success|partial|blocked, filesModified, notes }",
│     subagent_type="acis-fix-agent"
│   )
│   → Returns: Iteration result
│
├── 5. UPDATE STATE FILES
│   - Append iteration to .acis/progress/{goal-id}.json
│   - Update .acis/STATE.md with position
│   - Commit changes if result == success
│
├── 6. REPORT: Output iteration checkpoint
│
└── 7. LOOP: Continue until achieved OR max_iterations OR blocked
```

**Fresh Agent Benefits**:
- Each fix agent gets **100% fresh context** (no inherited rot)
- Previous iterations communicated via **progress file** (not context accumulation)
- Orchestrator stays **thin** (15% context) - coordinates, doesn't do heavy work
- If agent hits 50% context → returns `partial` result → orchestrator spawns new fresh agent

**Ralph-Loop Integration** (if `--force-ralph-loop` or plugin available):
```
ralph_loop(
  prompt="/acis remediate {goal-file} --internal-iteration",
  max_iterations=20,
  completion_check="grep 'GOAL_.*_ACHIEVED' .acis/STATE.md"
)
```

**Standard Loop Fallback** (if ralph-loop unavailable):
- Same fresh-agent pattern without persistent execution
- May need manual continuation if context exhausted
- Log: "Running in single-shot mode - may require continuation"

### Phase 3.5: MULTI-PERSPECTIVE 5 WHYS (Root Cause Analysis)

**Triggers** (when ANY apply):
1. **Complex issue**: Not obvious pattern replacement (requires understanding)
2. **Stuck**: Same metric failing for 2+ iterations
3. **Regression**: Fix caused other metrics to fail
4. **CRITICAL severity**: Always trigger for CRITICAL goals
5. **Manual**: `--deep-5whys` flag forces for all fixes

**Perspectives** (parallel via Task tool):
| Agent | Focus | Root Cause Lens |
|-------|-------|-----------------|
| `security-privacy` | PHI/HIPAA compliance | Why does this create security risk? |
| `tech-lead` | Architecture/design | Why does this violate design principles? |
| `oracle` (crash-resilience) | Failure modes | Why could this cause system failure? |

**5 Whys Agent Prompt**:
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

**Synthesis Algorithm**:
```
1. Collect WHY-5 from all perspectives
2. Analyze convergence:
   - CONVERGED: All perspectives identify same root cause
   - PARTIAL: 2+ perspectives agree, others differ
   - DIVERGED: All perspectives identify different root causes

3. Determine fix approach:
   - CONVERGED → Clear single fix
   - PARTIAL → Primary fix + secondary safeguard
   - DIVERGED → May need decomposition or deeper investigation
```

**Output Format**:
```markdown
## Multi-Perspective 5 Whys Analysis

### Problem
{problem description}

### Perspective: security-privacy
- WHY-1: {answer}
- WHY-2: {answer}
- WHY-3: {answer}
- WHY-4: {answer}
- **WHY-5 (ROOT)**: {security root cause}

### Perspective: tech-lead
- WHY-1: {answer}
- WHY-2: {answer}
- WHY-3: {answer}
- WHY-4: {answer}
- **WHY-5 (ROOT)**: {architecture root cause}

### Perspective: oracle (crash-resilience)
- WHY-1: {answer}
- WHY-2: {answer}
- WHY-3: {answer}
- WHY-4: {answer}
- **WHY-5 (ROOT)**: {resilience root cause}

### Synthesis
**Convergence**: [CONVERGED | PARTIAL | DIVERGED]
**Deepest Root Cause**: {synthesized root cause}
**Contributing Factors**: {from divergent perspectives}

### Recommended Fix Approach
{approach that addresses all perspective concerns}

### Side Effects to Monitor
| Perspective | Risk | Mitigation |
|-------------|------|------------|
| security-privacy | {risk} | {mitigation} |
| tech-lead | {risk} | {mitigation} |
| oracle | {risk} | {mitigation} |
```

**Integration with FIX Phase**:
After Multi-Perspective 5 Whys completes:
1. FIX phase uses "Recommended Fix Approach" as guidance
2. Each fix must address the synthesized root cause
3. Side effects are monitored in subsequent iterations

**Iteration Report Format**:
```markdown
## Iteration {N}: {GOAL_ID}

### Metrics
| Metric | Before | After | Target | Status |
|--------|--------|-------|--------|--------|
| {metric_id} | {before} | {after} | {target} | ✅/❌ |

### Changes
- {file}:{line}: {description}

### Next
- {what to fix next}
```

### Phase 4: CONSENSUS VERIFICATION (Default ON, Parallel Fresh Agents)

Skip with `--no-consensus`.

Launch ALL verification agents **simultaneously** (single message, multiple Task calls):

```
# ALL VERIFICATION AGENTS IN PARALLEL (one message)

Task(
  prompt="Verify goal {GOAL_ID} from security perspective.
    Goal: @{goal-file}
    Required Metrics: phi_exposure_count, encryption_coverage
    Run detection commands independently. Return APPROVE/REQUEST_CHANGES/REJECT.",
  subagent_type="security-privacy"
)

Task(
  prompt="Verify goal {GOAL_ID} from testing perspective.
    Goal: @{goal-file}
    Required Metrics: test_count, coverage_percent, regression_failures
    Run detection commands independently. Return APPROVE/REQUEST_CHANGES/REJECT.",
  subagent_type="test-lead"
)

Task(
  prompt="Verify goal {GOAL_ID} from architecture perspective.
    Goal: @{goal-file}
    Required Metrics: layer_violations, type_errors, lint_errors
    Run detection commands independently. Return APPROVE/REQUEST_CHANGES/REJECT.",
  subagent_type="tech-lead"
)

Task(
  prompt="Verify goal {GOAL_ID} from mobile/platform perspective.
    Goal: @{goal-file}
    Required Metrics: ios_build, android_build, web_build
    Run detection commands independently. Return APPROVE/REQUEST_CHANGES/REJECT.",
  subagent_type="mobile-lead"
)

# Codex Architect (if not --skip-codex)
mcp__codex__codex(
  prompt="Architect: Verify goal {GOAL_ID} implementation quality.
    Goal: {goal content}
    Changes Made: {summary of fixes}
    Required Metrics: design_quality_score, maintainability_index
    Return: APPROVE/REQUEST_CHANGES/REJECT with rationale.",
  developer-instructions="You are a Senior Architect. Verify changes meet design standards.",
  sandbox="read-only"
)
```

**Verification Agents**:
| Agent | Required Metrics | Veto Power |
|-------|-----------------|------------|
| security-privacy | phi_exposure_count, encryption_coverage | YES |
| test-lead | test_count, coverage_percent, regression_failures | NO |
| tech-lead | layer_violations, type_errors, lint_errors | YES |
| mobile-lead | ios_build, android_build, web_build | NO |
| codex-architect | design_quality_score, maintainability_index | NO |

**Consensus Rules**:
- Threshold: 75% of agents must APPROVE (3/4 minimum)
- Veto: security-privacy or tech-lead can block alone
- All metrics MUST pass for goal to be ACHIEVED

**Output**:
```markdown
## Consensus Verification: {GOAL_ID}

| Agent | Verdict | Metrics Verified | Notes |
|-------|---------|------------------|-------|
| security-privacy | APPROVE | phi=0, encryption=100% | PHI boundaries intact |
| test-lead | APPROVE | tests=15, coverage=87% | Coverage improved |
| tech-lead | APPROVE | layers=0, types=0 | Architecture clean |
| mobile-lead | APPROVE | iOS=✓, Android=✓ | Builds pass |

**Result**: 4/4 APPROVE → GOAL ACHIEVED
```

## Completion Promises

| Promise | Meaning |
|---------|---------|
| `<promise>GOAL_{id}_ACHIEVED</promise>` | All metrics pass, consensus reached |
| `<promise>GOAL_{id}_BLOCKED</promise>` | Stuck for 3+ iterations |
| `<promise>GOAL_{id}_CONSENSUS_FAILED</promise>` | Verification rejected |
| `<promise>GOAL_{id}_MAX_ITERATIONS</promise>` | Hit safety limit |

## Safety Rules (CLAUDE.md Enforcement)

1. **No test deletion** - Never remove tests to achieve goals
2. **No @ts-ignore** - Never suppress type errors
3. **No scope reduction** - Fix ALL instances
4. **TDD required** - Behavioral tests FIRST
5. **Multi-Perspective 5 Whys** - Required for CRITICAL goals, stuck iterations, or regressions (see Phase 3.5)
6. **Independent verification** - Each agent runs metrics independently
7. **Veto respected** - Security/Architecture vetoes block completion
8. **Root cause synthesis** - Fixes must address synthesized root cause, not symptoms

## Schema References

- Goal schema: `${CLAUDE_PLUGIN_ROOT}/schemas/acis-goal.schema.json`
- Perspectives config: `${CLAUDE_PLUGIN_ROOT}/configs/acis-perspectives.json`
- Codex templates: `${CLAUDE_PLUGIN_ROOT}/templates/codex-*.md`
- Ralph profiles: `${CLAUDE_PLUGIN_ROOT}/ralph-profiles/`
- Skill templates: `${CLAUDE_PLUGIN_ROOT}/skill-templates/`

## Example Usage

```bash
# Full pipeline (behavioral + consensus ON by default)
/acis remediate docs/reviews/goals/WO63-CRIT-001-key-rotation.json

# Skip behavioral TDD (for simple pattern replacements)
/acis remediate docs/reviews/goals/WO63-MED-002-notifications.json --no-behavioral

# Discovery only (no implementation)
/acis remediate docs/reviews/goals/WO63-HIGH-001-layer-violations.json --discovery-only

# Internal agents only (no Codex)
/acis remediate docs/reviews/goals/WO63-HIGH-002-voice-perf.json --skip-codex

# Run consensus verification on already-implemented goal
/acis verify docs/reviews/goals/WO63-CRIT-001-key-rotation.json

# Check status of all goals
/acis status
```

## Multi-Perspective Discovery Agent Prompts

When spawning discovery agents, use these prompts:

### Internal Agents
```
Analyze goal {GOAL_ID} from {PERSPECTIVE} perspective.

Goal: {GOAL_DESCRIPTION}
Pattern: {DETECTION_PATTERN}
Files: {AFFECTED_FILES}

Focus areas: {FOCUS_AREAS}

Output:
1. Key findings from your perspective
2. Additional metrics to verify (command + expected value)
3. Behavioral scenarios to test (Given/When/Then)
4. Refinements to remediation strategy
```

### Codex Delegations
Use templates from `${CLAUDE_PLUGIN_ROOT}/templates/codex-{expert}-discovery.md`

### Web Search
```
Search: "{goal topic} best practices 2026"
Extract: Latest recommendations, security advisories, deprecation notices
```

## Independently Verifiable Metrics

Every metric MUST be independently verifiable:

```json
{
  "metric_id": "phi_exposure_count",
  "name": "PHI Exposure Count",
  "command": "grep -rn 'bloodPressure|heartRate' packages/ | grep -v '.spec.ts' | wc -l",
  "expected_value": 0,
  "comparison": "eq",
  "tolerance": 0,
  "verification_notes": "All agents run this command independently"
}
```

**Requirements**:
1. Command must be deterministic (same output for same codebase)
2. Command must be runnable by any agent
3. Expected value must be specific (not "improved" or "better")
4. Tolerance must be explicit (usually 0 for critical metrics)

---

## Workflow: `/acis discovery "<topic>"`

Proactive investigation that surfaces decisions before implementation, ensuring AI-generated code is coherent and discipline-bound.

### Why Decision-Oriented Discovery?

AI-generated code is often poor quality because macro/micro decisions are made implicitly and fragmented across files. Discovery surfaces these decisions BEFORE implementation, creating a binding manifest.

### Phase 1: SCOPE ANALYSIS

Parse the topic to determine:
1. **Investigation Type**: feature | refactor | audit | what-if | bug-hunt
2. **Relevant Codebase Areas**: packages, files, components
3. **Investigation Boundaries**: what's in/out of scope

### Phase 2: MULTI-PERSPECTIVE EXPLORATION (Parallel Fresh Agents)

Launch ALL exploration agents **simultaneously** (single message, multiple Task/Codex calls):

```
# WAVE 1 - ALL EXPLORATION AGENTS IN PARALLEL (one message)

# Internal Agents (via Task tool) - Each gets 100% fresh context
Task(
  prompt="Explore topic '{TOPIC}' from security/PHI perspective.
    Scope: @.acis/discovery-scope.md
    Config: @.acis-config.json
    Focus: Surface existing PHI decisions, identify pending security decisions
    Output: Wired-in decisions, pending decisions, issues, opportunities",
  subagent_type="security-privacy"
)

Task(
  prompt="Explore topic '{TOPIC}' from architecture perspective.
    Scope: @.acis/discovery-scope.md
    Focus: Surface existing architecture decisions, identify design patterns
    Output: Wired-in decisions, pending decisions, dependencies, tradeoffs",
  subagent_type="tech-lead"
)

Task(
  prompt="Explore topic '{TOPIC}' from testing perspective.
    Scope: @.acis/discovery-scope.md
    Focus: Surface testing strategy decisions, coverage implications
    Output: Test approach decisions, coverage gaps, test scaffolds needed",
  subagent_type="test-lead"
)

Task(
  prompt="Explore topic '{TOPIC}' from mobile/offline perspective.
    Scope: @.acis/discovery-scope.md
    Focus: Platform decisions, offline strategy implications
    Output: Platform decisions, sync considerations, offline requirements",
  subagent_type="mobile-lead"
)

Task(
  prompt="Explore topic '{TOPIC}' from end-user/persona perspective.
    Scope: @.acis/discovery-scope.md
    Config: @.acis-config.json (for personas)
    Focus: UX decisions affecting Brenda/David/Dr.Evans
    Output: Persona impacts, UX decisions, journey implications",
  subagent_type="oracle"
)

Task(
  prompt="Explore topic '{TOPIC}' from operations perspective.
    Scope: @.acis/discovery-scope.md
    Focus: Operations decisions, deployment, monitoring
    Output: Operational decisions, cost implications, maintenance burden",
  subagent_type="devops-lead"
)

Task(
  prompt="Explore topic '{TOPIC}' from crash-resilience perspective.
    Scope: @.acis/discovery-scope.md
    Focus: Failure handling decisions, recovery strategies
    Output: Resilience decisions, failure modes, recovery requirements",
  subagent_type="oracle"
)

# Codex Delegations (via mcp__codex__codex) - ALSO IN SAME MESSAGE
mcp__codex__codex(
  prompt="Architect: Explore topic '{TOPIC}' for design decisions.
    Scope: {scope content}
    Output: Architecture decisions, tradeoffs, recommendations",
  developer-instructions="Read @${CLAUDE_PLUGIN_ROOT}/templates/codex-architect-discovery.md",
  sandbox="read-only"
)

mcp__codex__codex(
  prompt="UX Analyst: Explore topic '{TOPIC}' for persona decisions.
    Scope: {scope content}
    Personas: {from config}
    Output: UX decisions, accessibility decisions, journey impacts",
  developer-instructions="Read @${CLAUDE_PLUGIN_ROOT}/templates/codex-ux-discovery.md",
  sandbox="read-only"
)

mcp__codex__codex(
  prompt="Algorithm Expert: Explore topic '{TOPIC}' for algorithm decisions.
    Scope: {scope content}
    Output: Algorithm decisions, efficiency tradeoffs, optimization opportunities",
  developer-instructions="Read @${CLAUDE_PLUGIN_ROOT}/templates/codex-algorithm-discovery.md",
  sandbox="read-only"
)

mcp__codex__codex(
  prompt="Security Analyst: Explore topic '{TOPIC}' for security decisions.
    Scope: {scope content}
    Output: Security decisions, threat model, hardening requirements",
  developer-instructions="Read @${CLAUDE_PLUGIN_ROOT}/templates/codex-security-discovery.md",
  sandbox="read-only"
)
```

**Focus Areas**:
- Surfacing existing decisions (wired-in)
- Identifying decisions that need to be made (pending)
- Mapping dependencies and tradeoffs
- Finding issues and opportunities

**Codex Delegations**:
10. `Architect` - System design decisions
11. `Scope Analyst` (UX) - Persona impact decisions
12. `Code Reviewer` (Algorithm) - Algorithm decisions
13. `Security Analyst` - Security hardening decisions

### Phase 3: DECISION EXTRACTION

For each decision surfaced:

```json
{
  "id": "DEC-SYNC-001",
  "name": "Offline Sync Strategy",
  "level": "macro | micro",
  "status": "wired-in | pending | inherited",
  "specification": {
    "current_value": "queue-and-flush",
    "allowed_values": ["queue-and-flush", "immediate", "scheduled"]
  },
  "value_framing": {
    "category": "end-user | operations",
    "dimension": "ux | performance | security | cost | ...",
    "impact_statement": "This affects Brenda's data reliability..."
  }
}
```

### Phase 4: DUAL-CEO VALIDATION (Parallel)

For each **pending** decision, get independent recommendations:

**CEO-Alpha (Codex)**: AI-Native Engineering CEO
- Template: `${CLAUDE_PLUGIN_ROOT}/templates/codex-ceo-alpha.md`
- Focus: How does this decision leverage or constrain AI capabilities?

**CEO-Beta (Claude Oracle)**: Modern SWE Discipline CEO
- Template: `${CLAUDE_PLUGIN_ROOT}/templates/codex-ceo-beta.md`
- Focus: How does this decision uphold engineering principles?

Both analyze through:
- **Modern SWE Lens**: Testability, observability, failure modes, tech debt
- **AI-Native Lens**: Pattern clarity, context capture, constraint benefit, amplification risk
- **Business Lens**: Value creation, cost, risk, compound effect

### Phase 5: CONVERGENCE DETECTION

```
If CEO-Alpha.recommendation == CEO-Beta.recommendation:
  → convergence.converged = true
  → convergence.auto_resolvable = true
  → Decision ready for auto-approval

If CEO-Alpha.recommendation != CEO-Beta.recommendation:
  → convergence.converged = false
  → convergence.auto_resolvable = false
  → Must surface to project owner
  → Capture both dissent points
```

### Phase 6: MANIFEST & ARTIFACT GENERATION

**Output**: Decision Manifest + Supporting Artifacts

```
docs/manifests/DISC-2026-01-19-{topic}.json  <- Binding document
docs/reports/DISC-2026-01-19-{topic}.md      <- Discovery report
docs/specs/{topic}.md                         <- Feature spec (if feature)
docs/reviews/goals/DISC-*.json               <- Goal files (if issues found)
docs/architecture/decisions/ADR-XXX.md       <- ADR drafts (if architecture)
```

---

## Workflow: `/acis resolve <manifest>`

Resolve pending decisions in a manifest.

### Auto-Resolution (CEOs Converged)

When both CEOs recommend the same option:

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

[Decision updated in manifest]
```

### Manual Resolution (CEOs Diverged)

When CEOs disagree, surface to owner:

```markdown
## Owner Decision Required: DEC-CACHE-001

**Decision**: Cache Invalidation Strategy
**Options**: time-based | event-based | hybrid

### CEO-Alpha Recommends: hybrid
**Confidence**: high
**Primary Why**: Hybrid maximizes cache hit rate while ensuring data freshness.
**Dissent**: Time-based alone risks stale data; event-based alone has complexity.

### CEO-Beta Recommends: time-based
**Confidence**: medium
**Primary Why**: Simplicity compounds; time-based is predictable and easy to reason about.
**Dissent**: Hybrid adds complexity for marginal benefit; events are hard to trace.

### Agreement Areas
- Both agree caching is needed
- Both agree 5-minute max staleness is acceptable

### Disagreement Areas
- Whether event-based invalidation is worth the complexity
- How much cache hit rate matters for battery life

---

**Owner, please choose:**
1. `hybrid` (CEO-Alpha recommendation)
2. `time-based` (CEO-Beta recommendation)
3. `event-based` (neither recommended)

Your rationale will be captured in the manifest.
```

### Resolution Commands

```bash
# Resolve all decisions (auto + prompt for diverged)
/acis resolve docs/manifests/DISC-2026-01-19-voice.json

# Only auto-resolve converged, skip diverged
/acis resolve docs/manifests/DISC-2026-01-19-voice.json --auto-only

# Force resolution of specific decision
/acis resolve docs/manifests/DISC-2026-01-19-voice.json --force DEC-CACHE-001
```

---

## Decision Manifest Integration with Remediation

After discovery and resolution, bind the manifest to remediation:

```bash
/acis remediate docs/reviews/goals/VOICE-001.json \
  --manifest docs/manifests/DISC-2026-01-19-voice.json
```

During remediation, the manifest enforces:
1. **Resolved decisions** must be followed exactly
2. **Inherited decisions** must be honored
3. **Disciplines** must be upheld (verified each iteration)
4. **Formal tests** must pass for each decision

If code violates a resolved decision, ralph-loop blocks with:

```markdown
## DECISION VIOLATION DETECTED

**Decision**: DEC-VOICE-001 (Voice Processing Location)
**Resolved Value**: on-device
**Violation Found**: `src/voice/transcriber.ts:45`
  → `await cloudAPI.transcribe(audio)` violates on-device decision

**Action Required**: Fix the violation or request decision revision.
```

---

## Engineering Disciplines

Every manifest includes disciplines that MUST be upheld:

```json
{
  "disciplines": {
    "items": [
      {
        "discipline": "offline-first",
        "principle": "All features must work without network",
        "test_command": "pnpm test --grep 'offline'",
        "violation_severity": "critical"
      },
      {
        "discipline": "phi-encryption",
        "principle": "All PHI encrypted at rest and in transit",
        "test_command": "grep -rn 'bloodPressure|heartRate' packages/ | grep -v encrypt | wc -l",
        "violation_severity": "critical"
      }
    ]
  }
}
```

---

## Formal Tests Per Decision

Every decision requires formal specification tests:

```json
{
  "tests": {
    "specification_tests": [
      {
        "test_id": "DEC-VOICE-001-T1",
        "given": "Voice processing configured as on-device",
        "when": "Brenda says 'Show my medications'",
        "then": "Zero network requests made for transcription",
        "status": "pending"
      }
    ],
    "invariant_tests": [
      {
        "invariant": "PHI never sent to cloud voice services",
        "test_command": "grep -rn 'voiceAPI.send' packages/ | grep -v encrypt | wc -l"
      }
    ]
  }
}
```

---

## Schema References (Discovery)

- Decision Manifest: `${CLAUDE_PLUGIN_ROOT}/schemas/acis-decision-manifest.schema.json`
- Individual Decision: `${CLAUDE_PLUGIN_ROOT}/schemas/acis-decision.schema.json`
- Goal Schema: `${CLAUDE_PLUGIN_ROOT}/schemas/acis-goal.schema.json`
- CEO-Alpha Template: `${CLAUDE_PLUGIN_ROOT}/templates/codex-ceo-alpha.md`
- CEO-Beta Template: `${CLAUDE_PLUGIN_ROOT}/templates/codex-ceo-beta.md`
- Discovery Report Template: `${CLAUDE_PLUGIN_ROOT}/templates/acis-discovery-report.md`
- Interview System: `${CLAUDE_PLUGIN_ROOT}/interview/`
- Audit System: `${CLAUDE_PLUGIN_ROOT}/audit/`

---

## Example Usage

```bash
# Proactive feature discovery
/acis discovery "offline voice commands for Brenda" --type feature

# Refactoring opportunity analysis
/acis discovery "consolidate encryption utilities" --type refactor --scope packages/foundation

# Security audit
/acis discovery "PHI exposure risks in sync layer" --type audit --depth deep

# What-if architectural analysis
/acis discovery "what if we added real-time multi-device sync" --type what-if

# Bug hunting in specific area
/acis discovery "race conditions in SyncEngine" --type bug-hunt --scope packages/mobile/src/foundation

# Resolve decisions after discovery
/acis resolve docs/manifests/DISC-2026-01-19-offline-voice.json

# Remediate with manifest binding
/acis remediate docs/reviews/goals/VOICE-001.json --manifest docs/manifests/DISC-2026-01-19-offline-voice.json

# Check status of all manifests and goals
/acis status
```

---

## CEO Perspectives Summary

| Aspect | CEO-Alpha (Codex) | CEO-Beta (Claude) |
|--------|-------------------|-------------------|
| **Focus** | AI leverage and optionality | Simplicity and discipline |
| **Risk** | Higher (if disciplined) | Lower (prefer proven) |
| **Complexity** | Investment if it pays off | Cost until proven |
| **AI View** | Tool to maximize | Tool requiring guardrails |
| **Principle** | "Amplify the good" | "Simplicity compounds" |

Both share:
- Modern SWE discipline (testability, observability, failure-first)
- AI-native awareness (pattern clarity, context capture)
- Business grounding (value creation, compound effects)

The productive tension between them surfaces important tradeoffs.
