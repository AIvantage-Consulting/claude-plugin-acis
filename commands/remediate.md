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
```

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

```
┌─────────────────────────────────────────────────────────────────┐
│                    RALPH-LOOP ITERATION                         │
└─────────────────────────────────────────────────────────────────┘

MEASURE    → Run detection command, get current count
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
CHECKPOINT → Update progress, report metrics
    │
    └────────────────────────────→ REPEAT
```

**5 Whys Triggers**:
- Iteration >= 3 and no progress
- Regression detected
- CRITICAL severity goal
- `--deep-5whys` flag

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
- `APPROVE` with quality score (1-5) → Mark goal ACHIEVED
- `REQUEST_CHANGES` with issues → Loop back to Phase 3 FIX

**Configuration**:
- `--quality-threshold=N`: Minimum score to pass (default: 3)
- `--skip-tier1-quality-gate`: Skip for Tier 1 (simple) goals
- Max rejections: 2 (then escalate to user)

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
