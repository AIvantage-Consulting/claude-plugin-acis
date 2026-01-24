# ACIS Verify - Consensus Verification

You are executing the ACIS verify command. This runs consensus verification independently, without the full remediation pipeline.

## Arguments

- `$ARGUMENTS` - Path to goal JSON file (e.g., `docs/acis/goals/PR55-G1-math-random.json`)

## Purpose

Use this command to:
1. Re-verify a goal that was previously remediated
2. Check if manual changes meet the goal criteria
3. Get multi-agent verification without running remediation
4. Validate that external changes haven't caused regression

## Workflow

### Step 1: Load Goal and Metrics

```bash
goal_file="$ARGUMENTS"
goal=$(cat "$goal_file")
goal_id=$(echo "$goal" | jq -r '.id')
metrics=$(echo "$goal" | jq '.detection.verifiable_metrics // [.detection]')
```

### Step 2: Run Detection Commands

For each metric:

```bash
for metric in $(echo "$metrics" | jq -c '.[]'); do
  metric_id=$(echo "$metric" | jq -r '.metric_id // .pattern')
  command=$(echo "$metric" | jq -r '.command')
  expected=$(echo "$metric" | jq -r '.expected_value // .target.count')

  # Run detection command
  actual=$(eval "$command" 2>/dev/null || echo "error")

  # Compare to expected
  if [ "$actual" == "$expected" ]; then
    status="PASS"
  else
    status="FAIL"
  fi

  echo "$metric_id|$actual|$expected|$status"
done
```

### Step 3: Launch Verification Agents (Parallel)

All verification agents run **simultaneously**:

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
```

### Step 4: Collect Verdicts

Each agent returns:

```json
{
  "agent": "security-privacy",
  "verdict": "APPROVE | REQUEST_CHANGES | REJECT",
  "metrics_verified": [
    { "metric_id": "phi_exposure", "expected": 0, "actual": 0, "pass": true }
  ],
  "findings": ["All PHI patterns now encrypted"],
  "concerns": [],
  "recommendations": []
}
```

### Step 5: Apply Consensus Rules

```
Rule 1: ALL agents must APPROVE for goal to be verified
Rule 2: Any REJECT from security or architecture blocks verification
Rule 3: REQUEST_CHANGES requires additional remediation
```

```python
verdicts = [security, test, tech, mobile]

if any(v.verdict == "REJECT" for v in [security, tech]):
    consensus = "BLOCKED"
    reason = "Security or Architecture REJECTED"
elif all(v.verdict == "APPROVE" for v in verdicts):
    consensus = "VERIFIED"
elif any(v.verdict == "REQUEST_CHANGES" for v in verdicts):
    consensus = "NEEDS_WORK"
    reason = "Some agents requested changes"
else:
    consensus = "PARTIAL"
```

### Step 6: Update Goal Progress (if verified)

```json
{
  "progress": {
    "status": "achieved",
    "verified_at": "{timestamp}",
    "verification": {
      "consensus": "VERIFIED",
      "agents": {
        "security-privacy": "APPROVE",
        "test-lead": "APPROVE",
        "tech-lead": "APPROVE",
        "mobile-lead": "APPROVE"
      }
    }
  }
}
```

### Step 7: Present Verification Report

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  ACIS Verification Report: {goal-id}                                         ║
║  {timestamp}                                                                  ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  📊 METRICS                                                                  ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  ┌────────────────────────┬──────────┬──────────┬─────────┐                 ║
║  │ Metric                 │ Expected │ Actual   │ Status  │                 ║
║  ├────────────────────────┼──────────┼──────────┼─────────┤                 ║
║  │ Math.random count      │ 0        │ 0        │ ✅ PASS │                 ║
║  │ Test coverage          │ ≥80%     │ 92%      │ ✅ PASS │                 ║
║  │ Type errors            │ 0        │ 0        │ ✅ PASS │                 ║
║  └────────────────────────┴──────────┴──────────┴─────────┘                 ║
║                                                                              ║
║  👥 AGENT VERDICTS                                                           ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  security-privacy: ✅ APPROVE                                                ║
║    "PHI patterns verified secure. Encryption properly applied."             ║
║                                                                              ║
║  test-lead:        ✅ APPROVE                                                ║
║    "Coverage increased from 78% to 92%. All new paths tested."              ║
║                                                                              ║
║  tech-lead:        ✅ APPROVE                                                ║
║    "Architecture maintained. No layer violations introduced."                ║
║                                                                              ║
║  mobile-lead:      ✅ APPROVE                                                ║
║    "Offline scenarios verified. Builds pass on all platforms."              ║
║                                                                              ║
║  🎯 CONSENSUS: ✅ VERIFIED                                                   ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  All agents APPROVE. Goal {goal-id} is VERIFIED.                            ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

### If Not Verified

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  ACIS Verification Report: {goal-id}                                         ║
║  {timestamp}                                                                  ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  📊 METRICS                                                                  ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  ┌────────────────────────┬──────────┬──────────┬─────────┐                 ║
║  │ Metric                 │ Expected │ Actual   │ Status  │                 ║
║  ├────────────────────────┼──────────┼──────────┼─────────┤                 ║
║  │ Math.random count      │ 0        │ 3        │ ❌ FAIL │                 ║
║  │ Test coverage          │ ≥80%     │ 76%      │ ❌ FAIL │                 ║
║  └────────────────────────┴──────────┴──────────┴─────────┘                 ║
║                                                                              ║
║  👥 AGENT VERDICTS                                                           ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  security-privacy: ⚠️ REQUEST_CHANGES                                        ║
║    "3 instances of Math.random remain in packages/mobile/"                  ║
║                                                                              ║
║  test-lead:        ❌ REJECT                                                 ║
║    "Coverage dropped below threshold. New code paths untested."             ║
║                                                                              ║
║  🎯 CONSENSUS: ❌ NOT VERIFIED                                               ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  Reason: test-lead REJECTED - coverage below threshold                      ║
║                                                                              ║
║  🎯 NEXT STEPS                                                               ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  1. Fix remaining 3 Math.random instances                                   ║
║  2. Add tests for new code paths                                            ║
║  3. Run: /acis:remediate {goal-file}                                        ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Flags

| Flag | Description |
|------|-------------|
| `--quick` | Only run detection commands, skip agent verification |
| `--agents <list>` | Specify which agents to run (comma-separated) |
| `--skip-codex` | Skip any Codex-based verification |
| `--json` | Output verification report as JSON |
| `--update` | Update goal file with verification results |

## Examples

```bash
# Full consensus verification
/acis:verify docs/acis/goals/PR55-G1-math-random.json

# Quick metric check only
/acis:verify docs/acis/goals/PR55-G1-math-random.json --quick

# Verify with specific agents
/acis:verify docs/acis/goals/SECURITY-001.json --agents security-privacy,tech-lead

# JSON output for CI integration
/acis:verify docs/acis/goals/PR55-G1.json --json > verification-result.json

# Verify and update goal file
/acis:verify docs/acis/goals/PR55-G1.json --update
```

## Use Cases

1. **Post-manual-fix verification**: After fixing issues manually, verify with agents
2. **Regression checking**: Verify previously achieved goals still pass
3. **CI integration**: Run verification in CI pipeline with `--json`
4. **Selective verification**: Focus on specific agents with `--agents`
