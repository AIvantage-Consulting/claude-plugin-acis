---
name: swarm-orchestration
description: Multi-agent orchestration using Claude Code's TeammateTool. Use when coordinating parallel specialists, running swarm-based remediation, or any task benefiting from persistent agent teams with inbox-based coordination.
requires: TeammateTool (Claude Code v2.1.19+)
fallback: Task tool with run_in_background
---

# ACIS Swarm Orchestration

Multi-agent orchestration for parallel remediation, discovery, and verification using Claude Code's TeammateTool.

---

## Feature Availability

**Required:** Claude Code v2.1.19+ with TeammateTool enabled

**Detection:** Check if `~/.claude/teams/` directory operations work:
```bash
# If this succeeds, TeammateTool is available
Teammate({ operation: "discoverTeams" })
```

**Fallback:** When TeammateTool is unavailable, ACIS uses Task tool with `run_in_background: true` for parallel execution.

---

## Primitives

| Primitive | What It Is | ACIS Use Case |
|-----------|-----------|---------------|
| **Team** | Named group of agents with one leader | Remediation batch, discovery session |
| **Teammate** | Persistent agent in team with inbox | Specialist reviewer, verifier, fixer |
| **Task** | Work item with status and dependencies | Individual goal, verification step |
| **Inbox** | JSON file for inter-agent messages | Findings, status updates, blockers |

### File Structure

```
~/.claude/teams/acis-{batch-id}/
├── config.json              # Team metadata
└── inboxes/
    ├── orchestrator.json    # Leader inbox
    ├── fixer-1.json         # Goal fixer inbox
    └── verifier-1.json      # Verifier inbox

~/.claude/tasks/acis-{batch-id}/
├── 1.json                   # Goal remediation task
├── 2.json                   # Verification task
└── 3.json                   # Quality gate task
```

---

## ACIS Integration Patterns

### Pattern 1: Parallel Goal Remediation

Replace sequential worktree-based remediation with swarm workers:

```javascript
// 1. Create remediation team
Teammate({
  operation: "spawnTeam",
  team_name: "acis-batch-WO63-001",
  description: "Parallel remediation of WO63 goals"
})

// 2. Create tasks from goals (with dependencies)
TaskCreate({
  subject: "Remediate WO63-CRIT-001",
  description: "Fix hardcoded API keys",
  activeForm: "Fixing API keys..."
})
TaskCreate({
  subject: "Verify WO63-CRIT-001",
  description: "Run detection command, confirm 0 keys",
  activeForm: "Verifying..."
})
TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })

// 3. Spawn specialist workers
Task({
  team_name: "acis-batch-WO63-001",
  name: "fixer-1",
  subagent_type: "acis:acis-fix-agent",
  prompt: `
    Claim task #1. Apply 5-Whys analysis, implement fix.
    Commit with [RED]/[GREEN] tags.
    Mark complete, send summary to orchestrator.
  `,
  run_in_background: true
})

Task({
  team_name: "acis-batch-WO63-001",
  name: "verifier-1",
  subagent_type: "acis:acis-verify-agent",
  prompt: `
    Wait for task #2 to unblock.
    Run detection command, compare to target.
    Send verification result to orchestrator.
  `,
  run_in_background: true
})
```

### Pattern 2: Multi-Perspective Discovery Swarm

Persistent specialists for deep investigation:

```javascript
// Team for discovery session
Teammate({
  operation: "spawnTeam",
  team_name: "acis-discovery-offline-voice"
})

// Spawn perspective specialists
const perspectives = [
  { name: "security", type: "security-privacy", focus: "PHI/HIPAA compliance" },
  { name: "architect", type: "tech-lead", focus: "Architecture patterns" },
  { name: "ux", type: "ux-advocate", focus: "User experience impact" },
  { name: "ops", type: "ops-reliability", focus: "Operational concerns" }
];

// Spawn all in parallel (single message)
for (const p of perspectives) {
  Task({
    team_name: "acis-discovery-offline-voice",
    name: p.name,
    subagent_type: `acis:${p.type}`,
    prompt: `
      Analyze "offline voice commands" from ${p.focus} perspective.
      Surface decisions, risks, and requirements.
      Send structured findings to orchestrator via Teammate write.
    `,
    run_in_background: true
  })
}

// Orchestrator synthesizes findings from all inboxes
```

### Pattern 3: Consensus Verification Council

Multiple verifiers must agree before goal is marked achieved:

```javascript
Teammate({
  operation: "spawnTeam",
  team_name: "acis-verify-council-WO63-CRIT-001"
})

// Three independent verifiers
Task({
  team_name: "acis-verify-council-WO63-CRIT-001",
  name: "metric-verifier",
  subagent_type: "acis:acis-verify-agent",
  prompt: "Run detection command, verify metric meets target. Vote PASS/FAIL.",
  run_in_background: true
})

Task({
  team_name: "acis-verify-council-WO63-CRIT-001",
  name: "regression-verifier",
  subagent_type: "general-purpose",
  prompt: "Run test suite, check for regressions. Vote PASS/FAIL.",
  run_in_background: true
})

Task({
  team_name: "acis-verify-council-WO63-CRIT-001",
  name: "quality-verifier",
  subagent_type: "acis:acis-verify-agent",
  prompt: "Review code changes for SOLID/DRY compliance. Vote PASS/FAIL.",
  run_in_background: true
})

// Consensus: All must vote PASS for goal to be ACHIEVED
// Any FAIL triggers investigation
```

### Pattern 4: Process Auditor Swarm

Parallel trace analysis:

```javascript
Teammate({
  operation: "spawnTeam",
  team_name: "acis-audit-session"
})

// Pattern detector workers
Task({
  team_name: "acis-audit-session",
  name: "repetition-detector",
  subagent_type: "general-purpose",
  prompt: "Scan traces for repeated patterns (5+ occurrences). Report to orchestrator.",
  run_in_background: true
})

Task({
  team_name: "acis-audit-session",
  name: "blocker-analyzer",
  subagent_type: "general-purpose",
  prompt: "Analyze blocker traces, identify systemic issues. Report to orchestrator.",
  run_in_background: true
})

Task({
  team_name: "acis-audit-session",
  name: "skill-generator",
  subagent_type: "general-purpose",
  prompt: "Wait for pattern reports. Generate skill candidates meeting all criteria.",
  run_in_background: true
})
```

---

## TeammateTool Operations Reference

### Team Lifecycle

```javascript
// Create team
Teammate({ operation: "spawnTeam", team_name: "acis-{id}" })

// Spawn teammate into team
Task({ team_name: "acis-{id}", name: "worker", ... })

// Message teammate
Teammate({ operation: "write", target_agent_id: "worker", value: "..." })

// Broadcast to all
Teammate({ operation: "broadcast", name: "orchestrator", value: "..." })

// Request shutdown
Teammate({ operation: "requestShutdown", target_agent_id: "worker" })

// Cleanup (after all shutdowns approved)
Teammate({ operation: "cleanup" })
```

### Task Dependencies

```javascript
// Create dependent tasks
TaskCreate({ subject: "Step 1: Measure" })       // #1
TaskCreate({ subject: "Step 2: Fix" })           // #2
TaskCreate({ subject: "Step 3: Verify" })        // #3
TaskCreate({ subject: "Step 4: Quality Gate" }) // #4

// Set up pipeline
TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })
TaskUpdate({ taskId: "3", addBlockedBy: ["2"] })
TaskUpdate({ taskId: "4", addBlockedBy: ["3"] })

// Tasks auto-unblock as dependencies complete
```

---

## Fallback Mode (Task Tool)

When TeammateTool is unavailable, use Task with background execution:

```javascript
// Instead of:
Teammate({ operation: "spawnTeam", team_name: "..." })
Task({ team_name: "...", name: "worker", ... })

// Use:
Task({
  subagent_type: "acis:acis-fix-agent",
  description: "Remediate goal",
  prompt: "...",
  run_in_background: true  // Non-blocking parallel execution
})

// Coordination via state files instead of inboxes:
// - ${config.paths.state}/progress/{goal-id}.json
// - ${config.paths.parallel}/BATCH-{id}.json
```

### Fallback Limitations

| Feature | TeammateTool | Task Fallback |
|---------|--------------|---------------|
| Persistent agents | ✓ | ✗ (ephemeral) |
| Inbox messaging | ✓ | ✗ (state files) |
| Task dependencies | ✓ (auto-unblock) | ✗ (manual check) |
| Graceful shutdown | ✓ | ✗ |
| Visibility (tmux/iTerm) | ✓ | ✗ |

---

## Configuration

Add to `.acis-config.json`:

```json
{
  "swarm": {
    "enabled": true,
    "fallbackToTask": true,
    "maxParallelWorkers": 4,
    "backend": "auto",
    "teamNamePrefix": "acis"
  }
}
```

| Setting | Default | Description |
|---------|---------|-------------|
| `enabled` | `true` | Enable swarm orchestration |
| `fallbackToTask` | `true` | Use Task tool if TeammateTool unavailable |
| `maxParallelWorkers` | `4` | Max concurrent workers per team |
| `backend` | `"auto"` | `auto`, `tmux`, `iterm2`, `in-process` |
| `teamNamePrefix` | `"acis"` | Prefix for team names |

---

## Version Detection

ACIS detects TeammateTool availability at runtime:

```javascript
function isTeammateToolAvailable() {
  try {
    // Attempt discovery - if it works, TeammateTool exists
    const result = Teammate({ operation: "discoverTeams" });
    return !result.error;
  } catch {
    return false;
  }
}

// Usage in commands
if (isTeammateToolAvailable() && config.swarm.enabled) {
  // Use swarm orchestration
} else if (config.swarm.fallbackToTask) {
  // Use Task tool fallback
} else {
  // Error: swarm required but unavailable
}
```

---

## Upgrade Path

When upgrading Claude Code to v2.1.19+:

1. **Automatic detection** - ACIS will detect TeammateTool availability
2. **No config changes needed** - Swarm features auto-enable
3. **Verify with** - `/acis status --swarm-check`

---

## Best Practices

### 1. Name Teams Descriptively
```javascript
// Good
team_name: "acis-remediate-WO63-batch-001"
team_name: "acis-discovery-offline-voice"

// Bad
team_name: "team1"
```

### 2. Always Cleanup
```javascript
// Proper shutdown sequence
for (const worker of workers) {
  Teammate({ operation: "requestShutdown", target_agent_id: worker })
}
// Wait for all shutdown_approved messages
Teammate({ operation: "cleanup" })
```

### 3. Use Task Dependencies
Let the system manage unblocking rather than polling.

### 4. Check Inboxes for Results
```bash
cat ~/.claude/teams/acis-{id}/inboxes/orchestrator.json | jq '.'
```

### 5. Handle Worker Failures
Workers have 5-minute heartbeat timeout. Build retry logic into prompts.

---

## References

- [Claude Code Swarm Orchestration](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)
- [TeammateTool Discovery](https://gist.github.com/kieranklaassen/d2b35569be2c7f1412c64861a219d51f)
- Claude Code v2.1.19+ documentation (when available)
