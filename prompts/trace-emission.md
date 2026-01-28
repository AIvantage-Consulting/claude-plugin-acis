# ACIS Trace Emission Guidelines

This document defines how ACIS commands and agents should emit traces for user visibility and Process Auditor learning.

## Trace Verbosity

ACIS uses a **moderate verbosity** level - more than minimal status updates but less than full debug output.

### User-Visible Traces

Format: `[ACIS:{loop}:{phase}] {message}`

Examples:
```
[ACIS:outer:reflect] Analyzing 5 completed goals for patterns
[ACIS:middle:discover] Spawning 3 perspective agents in parallel
[ACIS:inner:5-whys] Security perspective: Root cause identified
[ACIS:inner:fix] Iteration 2: Applying fix to auth module
[ACIS:parallel:setup] Creating worktree for WO63-CRIT-001
```

### When to Emit User Traces

| Event | Trace Level | Example |
|-------|-------------|---------|
| Phase start/end | Always | `[ACIS:inner:measure] Starting baseline measurement` |
| Agent spawn | Always | `[ACIS:middle:discover] Spawning security-privacy agent` |
| Decision made | If significant | `[ACIS:inner:fix] Chose singleton pattern over factory` |
| Iteration count | Always | `[ACIS:inner:verify] Iteration 3 of 10` |
| Verification result | Always | `[ACIS:inner:verify] Target NOT achieved (12 → 8, target: 0)` |
| Escalation | Always | `[ACIS:inner:stuck] Escalating to Codex consultation` |
| Error/blocker | Always | `[ACIS:parallel:merge] Semantic conflict detected` |

## Structured Trace Emission

### Trace File Locations

```
Project Traces (user/session oriented):
  ${config.paths.traces}/
    SESSION-{YYYY-MM-DD}-{HHmmss}/
      trace-log.jsonl          # All traces for session (JSON Lines)
      summary.md               # Human-readable session summary

Process Traces (workflow effectiveness oriented):
  ${config.paths.processTraces}/
    decisions/
      {goal-id}-decisions.jsonl   # Micro-decisions per goal
    knowledge/
      knowledge-gaps.jsonl        # Knowledge gaps encountered
      knowledge-applied.jsonl     # Knowledge successfully used
    skills/
      skill-candidates.jsonl      # Potential skill patterns
      skill-applications.jsonl    # Existing skill usage
    effectiveness/
      {goal-id}-metrics.json      # Per-goal effectiveness
      workflow-metrics.jsonl      # Overall workflow metrics
```

### Trace Emission Protocol

#### 1. Session Initialization

At session start, create trace session:

```bash
# Create session directory
SESSION_ID="SESSION-$(date +%Y-%m-%d-%H%M%S)"
SESSION_DIR="${config.paths.traces}/${SESSION_ID}"
mkdir -p "${SESSION_DIR}"

# Initialize trace log
echo '{"trace_id":"T-INIT-0000","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","trace_type":"lifecycle","lifecycle":{"event":"start"},"message":"ACIS session started"}' > "${SESSION_DIR}/trace-log.jsonl"
```

#### 2. Lifecycle Traces

Emit at phase/stage boundaries:

```json
{
  "trace_id": "T-WO63-0001",
  "timestamp": "2026-01-28T10:30:00Z",
  "session_id": "SESSION-2026-01-28-103000",
  "goal_id": "WO63-CRIT-001",
  "location": {
    "loop": "inner",
    "phase": "5-whys",
    "stage": "security-perspective",
    "iteration": 1
  },
  "trace_type": "lifecycle",
  "message": "Starting 5-Whys security analysis",
  "lifecycle": {
    "event": "start",
    "to": { "phase": "5-whys", "stage": "security-perspective" }
  }
}
```

#### 3. Decision Traces

Emit when AI makes significant choices:

```json
{
  "trace_id": "T-WO63-0015",
  "timestamp": "2026-01-28T10:35:00Z",
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
    "confidence": "high",
    "context_factors": ["Existing singleton usage in auth module", "State consistency requirement"]
  },
  "process_auditor_hints": {
    "pattern_candidate": true,
    "tags": ["design-pattern", "singleton", "key-management"]
  }
}
```

#### 4. Knowledge Traces

Emit when knowledge is needed/applied:

```json
{
  "trace_id": "T-WO63-0020",
  "timestamp": "2026-01-28T10:40:00Z",
  "goal_id": "WO63-CRIT-001",
  "location": {
    "loop": "inner",
    "phase": "fix"
  },
  "trace_type": "knowledge",
  "message": "Applied IndexedDB encryption knowledge",
  "knowledge": {
    "event": "applied",
    "domain": "web-crypto-api",
    "topic": "IndexedDB encryption with SubtleCrypto",
    "source": "MDN documentation + existing EncryptedStore implementation"
  },
  "files_involved": ["src/storage/encrypted-store.ts"]
}
```

#### 5. Skill Traces

Emit when skills are used or identified:

```json
{
  "trace_id": "T-WO63-0025",
  "timestamp": "2026-01-28T10:45:00Z",
  "goal_id": "WO63-CRIT-001",
  "location": {
    "loop": "inner",
    "phase": "fix"
  },
  "trace_type": "skill",
  "message": "Skill candidate identified: HIPAA key rotation pattern",
  "skill": {
    "event": "candidate",
    "skill_name": "HIPAA-compliant key rotation",
    "pattern_match": "Rotating encryption keys with audit trail",
    "effectiveness": "effective"
  },
  "process_auditor_hints": {
    "skill_candidate": true,
    "tags": ["hipaa", "encryption", "key-rotation", "audit-trail"]
  }
}
```

#### 6. Effectiveness Traces

Emit metrics about workflow performance:

```json
{
  "trace_id": "T-WO63-0030",
  "timestamp": "2026-01-28T11:00:00Z",
  "goal_id": "WO63-CRIT-001",
  "location": {
    "loop": "inner",
    "phase": "verify"
  },
  "trace_type": "effectiveness",
  "message": "Goal achieved in 3 iterations (better than baseline)",
  "effectiveness": {
    "metric": "iterations_to_complete",
    "value": 3,
    "baseline": 5,
    "assessment": "better",
    "contributing_factors": ["Early Codex consultation", "Clear detection command"]
  },
  "process_auditor_hints": {
    "process_improvement": true
  }
}
```

#### 7. Blocker Traces

Emit when progress is blocked:

```json
{
  "trace_id": "T-WO63-0018",
  "timestamp": "2026-01-28T10:38:00Z",
  "goal_id": "WO63-CRIT-001",
  "location": {
    "loop": "inner",
    "phase": "fix",
    "iteration": 2
  },
  "trace_type": "blocker",
  "severity": "warn",
  "message": "Blocked by missing type definitions for crypto-util",
  "blocker": {
    "blocker_type": "dependency",
    "description": "crypto-util package lacks TypeScript definitions",
    "resolution_attempted": "Checked DefinitelyTyped, no @types/crypto-util",
    "resolved": true,
    "resolution_method": "Created local type declarations in src/types/crypto-util.d.ts"
  },
  "files_involved": ["src/types/crypto-util.d.ts"]
}
```

## Integration with Commands

### In Command Markdown Files

Commands should reference trace emission at appropriate points:

```markdown
## Execution

### Phase 1: Measure
1. ORCHESTRATOR: Emit lifecycle trace (phase=measure, event=start)
2. ORCHESTRATOR: Spawn verify agent
3. AGENT: Execute detection command
4. ORCHESTRATOR: Emit lifecycle trace (phase=measure, event=end)
```

### In Agent Prompts

Agents should be instructed to report trace-worthy events:

```markdown
## Reporting Requirements

When you make decisions, report:
- What you decided
- Why you chose this approach
- What alternatives you considered
- Your confidence level

This enables trace emission for Process Auditor learning.
```

## Process Auditor Consumption

The Process Auditor reads traces from `${config.paths.processTraces}/` to:

1. **Identify Skill Candidates**: Look for `process_auditor_hints.skill_candidate: true`
2. **Detect Patterns**: Analyze `decision` traces for recurring approaches
3. **Measure Effectiveness**: Aggregate `effectiveness` traces to spot improvements
4. **Find Knowledge Gaps**: Track `knowledge.event: "missing"` to prioritize documentation

### Trace Aggregation Queries

```bash
# Find all skill candidates from recent goals
grep '"skill_candidate":true' ${config.paths.processTraces}/decisions/*.jsonl

# Count iterations to completion
jq -s '[.[] | select(.effectiveness.metric == "iterations_to_complete")] | group_by(.goal_id) | map({goal: .[0].goal_id, iterations: .[0].effectiveness.value})' ${config.paths.processTraces}/effectiveness/*.jsonl

# Find unresolved blockers
jq 'select(.trace_type == "blocker" and .blocker.resolved == false)' ${config.paths.traces}/*/trace-log.jsonl
```

## Trace ID Format

Format: `T-{WO_PREFIX}-{SEQUENCE}`

- `WO_PREFIX`: First 4 chars of work order (e.g., "WO63")
- `SEQUENCE`: 4-digit sequence within session (0001, 0002, ...)

Special prefixes:
- `T-INIT-*`: Session initialization
- `T-ORCH-*`: Orchestrator-level traces
- `T-BATCH-*`: Parallel batch operations
