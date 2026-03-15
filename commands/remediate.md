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



#### Phase 0 PRE-CHECK: REJECTED GOAL GUARD (v2.15)

Before any processing, check if the goal has been rejected by the challenge phase:

```bash
goal_status=$(jq -r '.progress.status // "pending"' "${goal_file}")
if [ "$goal_status" = "rejected" ]; then
  echo "SKIPPED: Goal $(jq -r '.id' "${goal_file}") has status 'rejected' (challenge phase)."
  echo "  Technical: $(jq -r '.challenge.technical_reasoning // "N/A"' "${goal_file}")"
  echo "  Strategic: $(jq -r '.challenge.strategic_reasoning // "N/A"' "${goal_file}")"
  echo "  To re-evaluate: re-run /acis extract with --skip-challenge to bypass, or wait for /acis challenge-review (future v2.16+)."
  exit 0
fi
```

#### Phase 0.0: LEGACY MIGRATION (v2.14)

Before any processing, detect and migrate legacy goal files to v2.14 schema:

```bash
# Check if goal needs migration
goal_file="$ARGUMENTS"
schema_version=$(jq -r '.schema_version // "legacy"' "${goal_file}")
if [ "$schema_version" = "legacy" ]; then
  echo "LEGACY MIGRATION: Upgrading goal $(jq -r '.id' "${goal_file}") to schema v2.14"

  # Auto-populate required fields with defaults
  jq '. + {
    "schema_version": "2.14"
  } | .progress += {
    "iteration_episodes": (.progress.iteration_episodes // []),
    "complexity_evidence": (.progress.complexity_evidence // []),
    "checkpoint": (.progress.checkpoint // {"phase": "init", "iteration": 0, "critical_decisions": [], "active_constraints": [], "files_modified_cumulative": [], "metric_snapshot": {}, "next_action": "Begin remediation"}),
    "architectural_constraints": (.progress.architectural_constraints // []),
    "five_whys_analyses": (.progress.five_whys_analyses // [])
  }' "${goal_file}" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "${goal_file}"

  echo "LEGACY MIGRATION: Complete. Goal now conforms to v2.14 schema."
fi
```

**Migration is idempotent** — if fields already exist, `// []` preserves them.

Skip with `--skip-migration` if goal is known to be v2.14.

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

#### Phase 0.3.1: FUNCTIONAL CHECK DRY-RUN VALIDATION

If `detection.functional_checks[]` is present in the goal file:

For each check in `detection.functional_checks[]`:

1. **Validate command exists**: `command` field must be non-empty (≥5 chars)
2. **Validate Bash 3.2 compatibility**: Scan command for forbidden constructs:
   - `declare -A`, `mapfile`, `readarray`, `${var,,}`, `${var^^}`, `shopt -s globstar` → ABORT
3. **Execute dry-run**: Run command, capture exit code and output
   - **NOTE**: Functional checks are EXPECTED to fail before the fix is applied
   - If command fails: LOG as `INFO: Functional check '{check_id}' fails pre-fix (expected)`
   - If command succeeds: LOG as `INFO: Functional check '{check_id}' already passes pre-fix`
   - If command produces stderr indicating missing binary/tool: ABORT with "Functional check '{check_id}' requires unavailable tool: {stderr}"
4. **Validate parse_type compatibility**:
   - `exit_code`: No additional validation needed
   - `stdout`: `expected_output` must be set
   - `boolean`: Output must be parseable as `true|false|0|1`

If any ABORT condition is met: ABORT remediation with full error trace.

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


#### Phase 0.5: COMPLEXITY GUARD (v2.14 — Decomposition Guards)

After cross-field validation, evaluate goal complexity to detect over-scoped goals:

| Check | Threshold | Evidence Type | Action |
|-------|-----------|---------------|--------|
| Affected files > 5 | 5 files | `file_count_exceeded` | Suggest decomposition |
| Detection commands > 3 | 3 commands | `detection_command_count` | Warn: goal too broad |
| Tier 1 + files > 3 | Tier 1 & 3+ files | `scope_creep` | Recommend Tier 2 |
| Tier 2 + files > 8 | Tier 2 & 8+ files | `scope_creep` | Recommend Tier 3 |

```bash
# Complexity guard evaluation
affected_file_count=$(eval "${detection_cmd}" 2>/dev/null | grep -oE '[^ ]+\.[a-z]+' | sort -u | wc -l | tr -d ' ')
detection_cmd_count=$(jq '[.detection.verifiable_metrics[].command] | length' "${goal_file}")
current_tier=$(jq -r '.complexity.tier // 1' "${goal_file}")

evidence_type=""
recommendation=""

if [ "$affected_file_count" -gt 5 ]; then
  evidence_type="file_count_exceeded"
  recommendation="decompose"
elif [ "$detection_cmd_count" -gt 3 ]; then
  evidence_type="detection_command_count"
  recommendation="decompose"
elif [ "$current_tier" -eq 1 ] && [ "$affected_file_count" -gt 3 ]; then
  evidence_type="scope_creep"
  recommendation="escalate_tier"
elif [ "$current_tier" -eq 2 ] && [ "$affected_file_count" -gt 8 ]; then
  evidence_type="scope_creep"
  recommendation="escalate_tier"
fi

if [ -n "$evidence_type" ]; then
  # Record complexity evidence
  jq --arg etype "$evidence_type" --arg rec "$recommendation" \
     --arg tier "$current_tier" --arg files "$affected_file_count" \
    '.progress.complexity_evidence += [{
      "evidence_id": ("ce-" + (.progress.complexity_evidence | length + 1 | tostring | if length < 3 then "0" * (3 - length) + . else . end)),
      "iteration": 0,
      "type": $etype,
      "details": "Pre-remediation complexity guard detected \($etype)",
      "values": {"threshold": (if $etype == "file_count_exceeded" then 5 elif $etype == "detection_command_count" then 3 else 3 end), "actual": ($files | tonumber)},
      "recommendation": $rec,
      "original_tier": ($tier | tonumber),
      "recommended_tier": (if $rec == "escalate_tier" then ([$tier | tonumber + 1, 3] | min) else ($tier | tonumber) end)
    }]' "${goal_file}" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "${goal_file}"

  echo ""
  echo "⚠️  COMPLEXITY GUARD: ${evidence_type} detected"
  echo "    Affected files: ${affected_file_count}"
  echo "    Current tier: ${current_tier}"
  echo "    Recommendation: ${recommendation}"
  echo ""
  echo "    Options: [D] Decompose  [E] Escalate tier  [C] Continue (override)"
fi
```

Skip with `--skip-complexity-guard`.

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
VERIFY     → If target reached AND no functional_checks → exit loop → Phase 4
    │
    ▼
FUNCTIONAL → If target reached AND functional_checks present:
    │         Run each check.command
    │         If ANY blocking check fails → "false positive detection"
    │           Record in achievement_verification.false_positive_flags[]
    │           Continue to FIX (do not exit loop)
    │         If ALL blocking checks pass → exit loop → Phase 4
    │         Advisory check failures → LOG warning, do not block
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


#### Expanded RALPH-LOOP (v2.14 — Harness Engineering)

The RALPH-LOOP iteration now includes 6 additional steps for learning persistence:

```
MEASURE → STUCK-CHECK → VERIFY → FUNCTIONAL
  │ (if not achieved or false positive)
  ▼
CONSTRAINT-SYNTHESIS (T5)   → Extract constraint from functional failure
  │
  ▼
5-WHYS → 5-WHYS-RECORDING (T6) → Persist structured result
  │
  ▼
AGENT-BRIEF (T2)            → Build tactical brief for fix agent
  │
  ▼
FIX → INVARIANT → CHECKPOINT
  │
  ▼
CHECKPOINT-WRITE (T4)       → Persist recovery state
  │
  ▼
EPISODE-SYNTHESIS (T1)      → Compress iteration into episode
  │
  ▼
COMPLEXITY-ESCALATION (T3)  → Check if tier should increase
  │
  ▼
REPEAT
```

##### CONSTRAINT-SYNTHESIS (T5: Constraint Propagation)

After FUNCTIONAL check fails (false positive detected), extract the constraint:

```bash
# Extract constraint from functional failure
if [ "$false_positive" = "true" ]; then
  constraint_count=$(jq '.progress.architectural_constraints | length' "${goal_file}")
  constraint_id=$(printf "ac-%03d" $((constraint_count + 1)))

  jq --arg cid "$constraint_id" --arg iter "$iteration" \
     --arg desc "Functional check failed: ${failed_check_id}" \
     --argjson files "$affected_files_json" \
    '.progress.architectural_constraints += [{
      "constraint_id": $cid,
      "discovered_at_iteration": ($iter | tonumber),
      "source": "functional_failure",
      "description": $desc,
      "affected_files": $files,
      "must_do": [],
      "must_not": [],
      "confidence": 0.8,
      "status": "active"
    }]' "${goal_file}" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "${goal_file}"
fi
```

##### 5-WHYS-RECORDING (T6: Structured 5-Whys Storage)

After 5 Whys analysis, persist the structured result:

```bash
# Persist 5-Whys analysis
analysis_count=$(jq '.progress.five_whys_analyses | length' "${goal_file}")
analysis_id=$(printf "5w-%03d" $((analysis_count + 1)))

jq --arg aid "$analysis_id" --arg iter "$iteration" \
   --arg trigger "$stuck_trigger" --arg problem "$problem" \
   --arg w1 "$why1" --arg w2 "$why2" --arg w3 "$why3" \
   --arg w4 "$why4" --arg w5 "$why5" \
   --arg root "$root_cause" --arg plan "$fix_plan" \
  '.progress.five_whys_analyses += [{
    "analysis_id": $aid,
    "iteration": ($iter | tonumber),
    "trigger": $trigger,
    "problem": $problem,
    "why1": $w1, "why2": $w2, "why3": $w3, "why4": $w4, "why5": $w5,
    "root_cause": $root,
    "fix_plan": $plan,
    "perspectives": [],
    "convergence": "moderate",
    "yielded_constraints": []
  }]' "${goal_file}" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "${goal_file}"
```

##### AGENT-BRIEF (T2: Kernel/Worker Split)

Build a focused tactical brief for the fix agent instead of passing full context:

```bash
# Build tactical brief from episodes + constraints
tactical_brief=$(jq '{
  goal_id: .id,
  target: .target,
  current_iteration: .progress.iterations,
  last_episode: (.progress.iteration_episodes | last),
  active_constraints: [.progress.architectural_constraints[] | select(.status == "active")],
  recent_5whys: (.progress.five_whys_analyses | last),
  focus_files: (.progress.checkpoint.files_modified_cumulative // []),
  next_action: (.progress.checkpoint.next_action // "Apply fix based on discovery recommendations")
}' "${goal_file}")
```

The orchestrator passes this brief (not the full goal) to the fix agent. Full goal is available as fallback.

##### CHECKPOINT-WRITE (T4: Compaction-Resilient Checkpoints)

After each FIX + INVARIANT, persist recovery state:

```bash
# Write checkpoint (single object, latest state)
jq --arg phase "ralph" --arg iter "$iteration" \
   --arg ep_id "$last_episode_id" --arg next "$next_action" \
   --argjson decisions "$critical_decisions_json" \
   --argjson constraints "$active_constraint_ids_json" \
   --argjson files "$cumulative_files_json" \
   --argjson metrics "$metric_snapshot_json" \
  '.progress.checkpoint = {
    "phase": $phase,
    "iteration": ($iter | tonumber),
    "last_episode_id": $ep_id,
    "critical_decisions": $decisions,
    "active_constraints": $constraints,
    "files_modified_cumulative": $files,
    "metric_snapshot": $metrics,
    "next_action": $next
  }' "${goal_file}" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "${goal_file}"
```

##### EPISODE-SYNTHESIS (T1: Episodic Memory)

After fix+verify, compress the iteration into an episode record:

```bash
# Synthesize episode (max 10 episodes, older ones compressed to 1-line summaries)
episode_count=$(jq '.progress.iteration_episodes | length' "${goal_file}")
episode_id=$(printf "ep-%03d" $((episode_count + 1)))

# If at cap (10), compress oldest episode to summary
if [ "$episode_count" -ge 10 ]; then
  jq '.progress.iteration_episodes = [
    (.progress.iteration_episodes[0] | {episode_id, iteration, approach: (.approach[:50] + "..."), outcome, timestamp}),
    .progress.iteration_episodes[1:][]
  ]' "${goal_file}" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "${goal_file}"
fi

jq --arg eid "$episode_id" --arg iter "$iteration" \
   --arg approach "$approach_taken" --arg outcome "$fix_outcome" \
   --argjson files "$modified_files_json" \
   --arg before "$metric_before" --arg after "$metric_after" \
   --arg next_rec "$next_recommendation" \
  '.progress.iteration_episodes += [{
    "episode_id": $eid,
    "iteration": ($iter | tonumber),
    "approach": $approach,
    "files_modified": $files,
    "outcome": $outcome,
    "metric_delta": {"before": ($before | tonumber), "after": ($after | tonumber)},
    "functional_results": [],
    "constraints_discovered": [],
    "next_recommendation": $next_rec,
    "timestamp": (now | todate)
  }]' "${goal_file}" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "${goal_file}"
```

##### COMPLEXITY-ESCALATION (T3: Decomposition Guards)

After each iteration, check if complexity tier should increase:

```bash
# Check escalation rules
iterations_done=$(jq '.progress.iterations' "${goal_file}")
current_tier=$(jq '.complexity.tier // 1' "${goal_file}")
episode_failures=$(jq '[.progress.iteration_episodes[] | select(.outcome == "failure" or .outcome == "regression")] | length' "${goal_file}")
files_touched=$(jq '.progress.checkpoint.files_modified_cumulative | length' "${goal_file}")

should_escalate="false"
evidence_type=""

# Rule: 3+ failures at current tier → escalate
if [ "$episode_failures" -ge 3 ] && [ "$current_tier" -lt 3 ]; then
  should_escalate="true"
  evidence_type="stuck_pattern"
fi

# Rule: Files growing beyond tier scope
if [ "$current_tier" -eq 1 ] && [ "$files_touched" -gt 3 ]; then
  should_escalate="true"
  evidence_type="scope_creep"
elif [ "$current_tier" -eq 2 ] && [ "$files_touched" -gt 8 ]; then
  should_escalate="true"
  evidence_type="scope_creep"
fi

if [ "$should_escalate" = "true" ]; then
  recommended_tier=$((current_tier + 1))
  [ "$recommended_tier" -gt 3 ] && recommended_tier=3

  # Record evidence
  ce_count=$(jq '.progress.complexity_evidence | length' "${goal_file}")
  ce_id=$(printf "ce-%03d" $((ce_count + 1)))

  jq --arg ceid "$ce_id" --arg iter "$iterations_done" \
     --arg etype "$evidence_type" --arg ctier "$current_tier" \
     --arg rtier "$recommended_tier" \
    '.progress.complexity_evidence += [{
      "evidence_id": $ceid,
      "iteration": ($iter | tonumber),
      "type": $etype,
      "details": "Runtime escalation: \($etype) at iteration \($iter)",
      "recommendation": "escalate_tier",
      "original_tier": ($ctier | tonumber),
      "recommended_tier": ($rtier | tonumber)
    }]' "${goal_file}" > "${goal_file}.tmp" && mv "${goal_file}.tmp" "${goal_file}"

  echo "⚠️  COMPLEXITY ESCALATION: Recommending Tier ${current_tier} → Tier ${recommended_tier} (${evidence_type})"
  echo "    Options: [E] Escalate  [C] Continue at current tier"
fi
```

Skip escalation checks with `--skip-complexity-escalation` or cap with `--max-tier N`.

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
| `--skip-complexity-guard` | Skip Phase 0.5 complexity guard |
| `--skip-complexity-escalation` | Skip runtime complexity escalation in RALPH-LOOP |
| `--max-tier N` | Cap maximum tier for escalation (1, 2, or 3) |
| `--skip-episodes` | Skip episode synthesis (T1) in RALPH-LOOP |
| `--skip-constraints` | Skip constraint propagation (T5) in RALPH-LOOP |
| `--skip-migration` | Skip Phase 0.0 legacy migration (trust goal is v2.14) |
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

## Achievement Recording with Functional Checks

When a goal is achieved and `detection.functional_checks[]` was present:

1. Set `achievement_verification.method` to `"detection_and_functional"`
2. Record all functional check results in `achievement_verification.functional_check_results[]`:
   ```json
   {
     "check_id": "{check_id}",
     "passed": true,
     "exit_code": 0,
     "stdout": "{output}",
     "severity": "blocking",
     "timestamp": "{iso}"
   }
   ```
3. If any `false_positive_flags` were recorded during the loop, include them in `achievement_verification.false_positive_flags[]`
4. Set `achievement_verification.confidence` based on:
   - All blocking checks passed, no false positives → `"high"`
   - All blocking checks passed, some false positives during loop → `"medium"`
   - Only advisory checks failed → `"medium"`

When no `functional_checks` exist: behavior is unchanged (use existing `method` values).

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
