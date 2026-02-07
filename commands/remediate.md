# ACIS Remediate - Full TDD Remediation Pipeline

You are executing the ACIS remediate command. This runs the full remediation pipeline: Discovery → Behavioral TDD → Ralph-Loop → Consensus Verification.

## Arguments

- `$ARGUMENTS` - Path to goal JSON file (e.g., `docs/acis/goals/PR55-G1-math-random.json`)

## Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ACIS REMEDIATION PIPELINE                                │
└─────────────────────────────────────────────────────────────────────────────┘

Phase 0: ORCHESTRATOR INIT     Load config, validate paths, check plugins
           │
           ▼
Phase 1: DISCOVERY             Multi-perspective analysis (parallel agents)
           │                   + Dual-CEO validation
           ▼
Phase 2: BEHAVIORAL TDD        Extract personas → Create acceptance scenarios
           │                   → Write behavioral tests → Expect FAIL (RED)
           ▼
Phase 3: RALPH-LOOP           MEASURE → VERIFY → FIX → CHECK (repeat)
           │                   + Multi-perspective 5 Whys when stuck
           │                   + Codex stuck consultation if 4+ iterations
           ▼
Phase 4: CONSENSUS            Independent verification by multiple agents
           │                   All must APPROVE for goal achievement
           ▼
Phase 4.5: QUALITY-GATE       Codex reviews cumulative changes (SOLID+DRY)
           │                   APPROVE or REQUEST_CHANGES
           ▼
       COMPLETE               Update goal status, generate report
```

## Phase Details

### Phase 0: ORCHESTRATOR INITIALIZATION

```
1. Load config: Read .acis-config.json
2. VALIDATE PATHS: Run path validation (MUST pass)
3. Check for nested paths: Warn if found
4. Read goal file: @{goal-file-path}
5. Initialize state: ${config.paths.state}/STATE.md
6. Initialize progress: ${config.paths.state}/progress/{goal-id}.json
7. Check enforcement flags: --force-codex, --force-ralph-loop
8. Validate plugins available if enforced
9. Load state transition matrix: ${CLAUDE_PLUGIN_ROOT}/configs/state-transitions.json
10. Record initial state hash: SHA-256 of goal file (for hash chain verification)
```

#### Phase 0.1: INTENT CONTRACT CAPTURE

Before any analysis begins, capture the user's intent:

1. Present: "What is your goal for this remediation? (1-2 sentences)"
2. Record user's verbatim statement as `intent.user_statement`
3. Generate system interpretation: what the pipeline will do, in plain language
4. Present interpretation to user: "I understand this as: {interpretation}. Correct?"
5. Record success criteria: list of verification commands that prove delivery
6. Save intent contract to `${config.paths.state}/intent/{goal-id}.json`
7. User must confirm before proceeding (or clarify → re-interpret, max 2 rounds)

#### Phase 0.2: TIER 1 FAST-PATH CHECK

If ALL of these conditions are met, activate fast-path (skip Phases 1, 2, 4, 4.5):
- `complexity.tier == 1`
- `remediation.strategy` is `replace` or `remove`
- Single metric in `detection.verifiable_metrics` (length == 1)
- `source.severity` is NOT `critical`

Fast-path pipeline: **MEASURE → FIX (max 5 iterations) → VERIFY (detection + lint + typecheck) → REPORT**

User can override with `--no-fast-path` to force full pipeline.

If fast-path NOT activated, proceed to Phase 0.3.

#### Phase 0.3: DETECTION COMMAND DRY-RUN VALIDATION

Before entering the pipeline, validate ALL detection commands will work:

For each command in `detection.primary_command` and `detection.verifiable_metrics[].command`:

1. **Execute in subshell**: Run command, capture exit code, stdout, stderr
2. **Validate exit code**: Must be 0. If non-zero → ABORT with error: "Detection command failed with exit code {code}: {stderr}"
3. **Validate stderr**: Must be empty. If non-empty → WARN: "Detection command produced stderr: {stderr}"
4. **Validate stdout**: Must be non-empty. If empty → ABORT: "Detection command produced no output"
5. **Validate output format**: Parse stdout according to `parse_type`:
   - `integer`: Must match `^-?[0-9]+$`
   - `float`: Must match `^-?[0-9]+\.?[0-9]*$`
   - `boolean`: Must match `^(true|false|0|1)$`
   - `percentage`: Must match `^[0-9]+\.?[0-9]*%?$`
   If format mismatch → ABORT: "Detection command output '{output}' does not match expected parse_type '{type}'"
6. **Validate Bash 3.2 compatibility**: Scan command for forbidden constructs:
   - `declare -A` → ABORT
   - `mapfile` or `readarray` → ABORT
   - `${var,,}` or `${var^^}` → ABORT
   - `shopt -s globstar` → ABORT

If ANY validation fails: ABORT remediation with full error trace. Do NOT proceed.

#### Phase 0.4: CROSS-FIELD VALIDATION

Validate referential integrity across goal fields:

1. `target.primary_metric` MUST exist in `detection.verifiable_metrics[].metric_id`
   - If not found → ABORT: "target.primary_metric '{id}' not found in verifiable_metrics"
2. Each entry in `consensus.veto_agents[]` MUST exist in `multi_perspective.verification_agents[].agent_id`
   - If not found → ABORT: "veto_agent '{id}' not found in verification_agents"
3. Each persona in `behavioral.personas[]` MUST exist in `.acis-config.json` personas (if config has personas)
   - If not found → WARN: "Persona '{name}' not defined in project config"
4. If `--manifest` flag provided, validate no circular dependencies among decisions:
   - Build dependency graph from decision manifest
   - Run topological sort; if cycle detected → ABORT: "Circular dependency in decisions: {cycle}"

#### Phase 0.6: HASH CHAIN INITIALIZATION

1. Compute SHA-256 hash of the goal file contents
2. Record as `integrity.chain[0]`: `{ phase: "init", hash: "{sha256}", timestamp: "{iso}" }`
3. Store in progress file at `${config.paths.state}/progress/{goal-id}.json`
4. After each subsequent phase completion, recompute goal file hash and append to chain
5. If hash changes unexpectedly (goal file modified outside ACIS): WARN user: "Goal file modified outside pipeline. Hash mismatch: expected {expected}, got {actual}. Continue? [y/N]"

### Phase 1: MULTI-PERSPECTIVE DISCOVERY

Launch ALL discovery agents **simultaneously**:

**Wave 1**: Internal Agents + Codex (ALL PARALLEL)
- security-privacy, tech-lead, test-lead, mobile-lead
- oracle (persona), devops-lead, oracle (resilience)
- Codex: Architect, UX, Algorithm, Security

**Wave 2**: CEO Validation (PARALLEL after Wave 1)
- CEO-Alpha: AI-Native perspective
- CEO-Beta: Modern SWE perspective

**Output**: Discovery results to `${config.paths.state}/discovery/{goal-id}.md`

### Phase 2: BEHAVIORAL TDD (Default ON)

1. **Extract Personas**: Identify affected personas from discovery
2. **Create Acceptance Scenarios**: Given/When/Then format
3. **Write Behavioral Tests**: Create test file BEFORE implementation
4. **Run Tests**: Expect FAIL (RED phase)

```typescript
// Example behavioral test
describe('Medication Reminder Security', () => {
  it('encrypts all PHI fields when stored offline', async () => {
    // Given: Brenda's medication list with PHI
    // When: Data is stored offline
    // Then: All PHI fields are encrypted
  });
});
```

### Phase 3: RALPH-LOOP (Surgical Fixing)

#### State Transition Enforcement

Before entering Phase 3, validate state transition:
1. Load `${CLAUDE_PLUGIN_ROOT}/configs/state-transitions.json`
2. Check current state allows transition to `ralph_loop`
3. If ILLEGAL → ABORT: "ILLEGAL STATE TRANSITION: {current} → ralph_loop"
4. Update state and append to hash chain

```
┌─────────────────────────────────────────────────────────────────┐
│                    RALPH-LOOP ITERATION                         │
└─────────────────────────────────────────────────────────────────┘

MEASURE    → Run detection command, get current count
    │
    ▼
STUCK-CHECK → Algorithmic stuck detection (see below)
    │
    ▼
VERIFY     → If target reached → exit loop → Phase 4
    │
    ▼
5-WHYS     → If stuck (3+ iterations) → Multi-perspective analysis
    │
    ▼
FIX        → Apply minimal, surgical fix (1-3 files per iteration)
    │
    ▼
INVARIANT  → Run safety invariant checks (MUST pass before checkpoint)
    │
    ▼
CHECKPOINT → Update progress, report metrics, append hash chain
    │
    └────────────────────────────→ REPEAT
```

#### Automatic Stuck Detection (After MEASURE)

After each MEASURE, analyze the last 3 measurement values to detect stuck patterns:

| Pattern | Condition | Action |
|---------|-----------|--------|
| **PLATEAU** | Last 3 values identical | HARD_STUCK → Auto-escalate to Codex consultation |
| **REGRESSION** | Current value worse than previous | Auto-trigger 5-WHYs root cause analysis |
| **DIMINISHING_RETURNS** | Delta < 2 for last 3 iterations | WARN user: "Progress slowing. Continue or escalate?" |

This replaces the fixed iteration threshold with algorithmic criteria.

**5 Whys Triggers** (updated):
- Algorithmic stuck detection: PLATEAU or REGRESSION
- Iteration >= 3 and no progress
- CRITICAL severity goal
- `--deep-5whys` flag

#### Safety Invariant Checks (Between FIX and CHECKPOINT)

After each FIX, before CHECKPOINT, run invariant checks from `${CLAUDE_PLUGIN_ROOT}/configs/safety-invariants.json`:

1. For each invariant defined:
   a. Run the `pre_command` (already captured before FIX) and `post_command` (after FIX)
   b. Compare values according to `comparison` rule
   c. If invariant VIOLATED:
      - `revert_and_abort`: Run `git checkout -- .` to revert changes, then ABORT iteration
      - `warn_and_retry`: Log violation, WARN user, allow one retry of the FIX step
2. All invariants must pass before CHECKPOINT proceeds
3. Invariant results recorded in progress file for audit trail

### Phase 4: CONSENSUS VERIFICATION

Launch verification agents **in parallel**:

```
security-privacy  → APPROVE/REQUEST_CHANGES/REJECT
tech-lead         → APPROVE/REQUEST_CHANGES/REJECT
test-lead         → APPROVE/REQUEST_CHANGES/REJECT
mobile-lead       → APPROVE/REQUEST_CHANGES/REJECT
```

**Consensus Rules**:
- ALL agents must APPROVE for goal to be achieved
- Any REJECT from security/architecture blocks completion
- REQUEST_CHANGES requires another iteration

### Phase 4.5: QUALITY-GATE (Codex Review)

When goal metric is achieved (Phase 4 passes), delegate to Codex for code quality review before marking ACHIEVED.

**Trigger**: Phase 4 returns `status === 'achieved'` AND NOT `--skip-quality-gate`

**Template**: `${CLAUDE_PLUGIN_ROOT}/templates/codex-quality-gate.md`

**Review Focus**:
- SOLID principles (Single Responsibility, Open/Closed, Liskov, Interface Segregation, DI)
- DRY principle (no duplication, constants for magic values)
- Algorithm quality (correct approach, edge cases)
- Architecture conformance (three-layer, dependency direction)
- Healthcare/HIPAA considerations (PHI encryption, offline safety)

**Output**:
- `APPROVE` with quality score (computed via rubric) → Mark goal ACHIEVED
- `REQUEST_CHANGES` with issues → Loop back to Phase 3 FIX

**Configuration**:
- `--quality-threshold=N`: Minimum score to pass (default: 3)
- `--skip-tier1-quality-gate`: Skip for Tier 1 (simple) goals
- Max rejections: 2 (then escalate to user)

### Phase FINAL: INTENT VERIFICATION

After quality gate passes (or is skipped), before marking ACHIEVED:

1. Load intent contract from `${config.paths.state}/intent/{goal-id}.json`
2. Run ALL success criteria verification commands from the contract
3. Present results to user:

```
╔═══════════════════════════════════════════════════════════════╗
║  INTENT VERIFICATION: {goal-id}                               ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  You asked for: {user_statement}                              ║
║  We interpreted: {system_interpretation}                      ║
║                                                               ║
║  Success Criteria:                                            ║
║  ✅ {criterion_1}: PASS ({actual} {comparison} {expected})    ║
║  ✅ {criterion_2}: PASS ({actual} {comparison} {expected})    ║
║  ❌ {criterion_3}: FAIL ({actual} != {expected})              ║
║                                                               ║
║  Overall: {pass_count}/{total_count} criteria met             ║
╚═══════════════════════════════════════════════════════════════╝
```

4. If ALL criteria met → mark ACHIEVED
5. If ANY criteria failed → present to user: "Not all intent criteria met. Mark as achieved anyway? [y/N]"
6. User confirmation required for ACHIEVED status

#### Hash Chain Finalization

1. Compute final SHA-256 hash of goal file
2. Append final entry to integrity chain
3. Verify chain completeness: all phases present, no gaps
4. Record in progress file

### Stuck Consultation (Within Phase 3)

When stuck for multiple iterations, optionally consult Codex for problem-solving guidance.

**Trigger**:
- Iteration >= stuck_threshold (default: 4)
- Last 3 iterations all not_achieved or partial
- NOT `--skip-codex`

**Template**: `${CLAUDE_PLUGIN_ROOT}/templates/codex-stuck-consultation.md`

**Purpose**: Problem-solving consultation (help mode), NOT code review

**Output**: Alternative approach, implementation guidance, design pattern recommendation

**Configuration**:
- `--stuck-threshold=N`: Trigger after N iterations (default: 4)
- `--force-consultation`: Force regardless of iteration count
- Max consultations per goal: 2

## Flags

| Flag | Description |
|------|-------------|
| `--no-behavioral` | Skip behavioral TDD phase (for simple patterns) |
| `--no-consensus` | Skip multi-agent consensus verification |
| `--skip-codex` | Skip Codex delegations (internal agents only) |
| `--use-codex` | Override `pluginDefaults.skipCodex` |
| `--force-codex` | **REQUIRE Codex** - Error if unavailable |
| `--skip-ralph-loop` | Use standard loops instead of ralph-loop |
| `--use-ralph-loop` | Override `pluginDefaults.skipRalphLoop` |
| `--force-ralph-loop` | **REQUIRE ralph-loop** - Error if unavailable |
| `--force-full` | Shorthand for `--force-codex --force-ralph-loop` |
| `--discovery-only` | Run Phase 1 only, output refinements |
| `--max-iterations N` | Maximum ralph-loop iterations (default: 20) |
| `--manifest <file>` | Bind to decision manifest (enforce resolved decisions) |
| `--deep-5whys` | Force multi-perspective 5 Whys for every fix |
| `--fresh-agents` | Use fresh-agent-per-task pattern (default: ON) |
| `--parallel-discovery` | Run discovery perspectives in parallel (default: ON) |
| `--skip-quality-gate` | Skip Phase 4.5 quality gate (Codex review) |
| `--quality-threshold=N` | Require quality score >= N to pass (default: 3) |
| `--skip-tier1-quality-gate` | Skip quality gate for Tier 1 (simple) goals only |
| `--stuck-threshold=N` | Trigger Codex consultation after N iterations (default: 4) |
| `--force-consultation` | Force Codex consultation regardless of iteration count |
| `--no-fast-path` | Disable Tier 1 fast-path, force full pipeline |
| `--skip-intent` | Skip intent contract capture (Phase 0.1) |
| `--skip-dry-run` | Skip detection command dry-run validation (Phase 0.3) |
| `--force-state-transition` | Bypass state machine enforcement (use with caution) |
| `--skip-invariants` | Skip safety invariant checks between FIX and CHECKPOINT |

## Output Report

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  ACIS Remediation Complete: {goal-id}                                        ║
║  {timestamp}                                                                  ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  📊 METRICS                                                                  ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  ┌────────────────┬──────────┬─────────┬────────┬─────────┐                 ║
║  │ Metric         │ Baseline │ Current │ Target │ Status  │                 ║
║  ├────────────────┼──────────┼─────────┼────────┼─────────┤                 ║
║  │ Math.random    │ 47       │ 0       │ 0      │ ✅      │                 ║
║  │ Test coverage  │ 78%      │ 92%     │ 80%    │ ✅      │                 ║
║  └────────────────┴──────────┴─────────┴────────┴─────────┘                 ║
║                                                                              ║
║  🔄 ITERATIONS: 5                                                            ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  Iter 1: 47 → 32 (-15) | Fixed: SessionManager.ts, AuthService.ts           ║
║  Iter 2: 32 → 18 (-14) | Fixed: OfflineQueue.ts, SyncEngine.ts              ║
║  Iter 3: 18 → 8 (-10)  | Fixed: CacheManager.ts, StorageAdapter.ts          ║
║  Iter 4: 8 → 3 (-5)    | Fixed: TestUtils.ts (mocks updated)                ║
║  Iter 5: 3 → 0 (-3)    | Fixed: Legacy files in packages/mobile/           ║
║                                                                              ║
║  ✅ CONSENSUS VERIFICATION                                                   ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  security-privacy: APPROVE (PHI patterns verified secure)                   ║
║  tech-lead:        APPROVE (Architecture maintained)                         ║
║  test-lead:        APPROVE (Coverage increased to 92%)                       ║
║  mobile-lead:      APPROVE (Offline scenarios pass)                          ║
║                                                                              ║
║  🎯 RESULT: GOAL ACHIEVED                                                    ║
║                                                                              ║
║  📁 Files Modified: 12                                                       ║
║     packages/foundation/security/SessionManager.ts                           ║
║     packages/foundation/auth/AuthService.ts                                  ║
║     packages/mobile/src/services/sync/OfflineQueue.ts                        ║
║     ... (full list in progress file)                                         ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Safety Rules

1. **No test deletion** - Never remove tests to achieve goals
2. **No @ts-ignore** - Never suppress type errors
3. **No scope reduction** - Fix ALL instances
4. **TDD required** - Behavioral tests FIRST (unless `--no-behavioral`)
5. **5 Whys required** - For CRITICAL goals, stuck iterations, regressions
6. **Independent verification** - Each agent runs metrics independently
7. **Veto respected** - Security/Architecture vetoes block completion

## Examples

```bash
# Full pipeline (behavioral + consensus ON by default)
/acis:remediate docs/acis/goals/WO63-CRIT-001-key-rotation.json

# Skip behavioral TDD (for simple pattern replacements)
/acis:remediate docs/acis/goals/WO63-MED-002-console-log.json --no-behavioral

# Discovery only (no implementation)
/acis:remediate docs/acis/goals/WO63-HIGH-001-layer-violations.json --discovery-only

# Internal agents only (no Codex)
/acis:remediate docs/acis/goals/WO63-HIGH-002-voice-perf.json --skip-codex

# Force maximum quality mode
/acis:remediate docs/acis/goals/SECURITY-001.json --force-full

# Bind to decision manifest
/acis:remediate docs/acis/goals/SYNC-001.json --manifest docs/acis/decisions/DISC-sync.json

# Limit iterations for quick check
/acis:remediate docs/acis/goals/TEST-001.json --max-iterations 5
```

## Integration

After remediation:
- `/acis:status` - See updated progress
- `/acis:verify <goal>` - Re-run consensus if needed
- `/acis:audit` - Triggers after N goals achieved (process improvement)
