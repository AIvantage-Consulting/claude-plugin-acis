# ACIS Status - Progress Dashboard

You are executing the ACIS status command. This displays progress across all goals, decision manifests, and audit cycles.

## Arguments

- `$ARGUMENTS` - Optional: filter by category (`goals`, `decisions`, `audits`) or goal pattern

## Workflow

### Step 1: Load Configuration

```bash
# Load .acis-config.json (or use defaults)
if [ -f ".acis-config.json" ]; then
  config=$(cat .acis-config.json)
  goals_dir=$(echo "$config" | jq -r '.paths.goals // "docs/acis/goals"')
  decisions_dir=$(echo "$config" | jq -r '.paths.decisions // "docs/acis/decisions"')
  audits_dir=$(echo "$config" | jq -r '.paths.audits // "docs/acis/audits"')
  state_dir=$(echo "$config" | jq -r '.paths.state // "docs/acis/state"')
  project_name=$(echo "$config" | jq -r '.projectName // "Unnamed Project"')
else
  goals_dir="docs/acis/goals"
  decisions_dir="docs/acis/decisions"
  audits_dir="docs/acis/audits"
  state_dir="docs/acis/state"
  project_name="Unnamed Project"
fi
```

### Step 2: Scan Goal Files

```bash
# Find all goal JSON files
find "$goals_dir" -name "*.json" -type f 2>/dev/null | while read -r goal_file; do
  # Extract goal metadata
  goal_id=$(jq -r '.id' "$goal_file")
  status=$(jq -r '.progress.status // "pending"' "$goal_file")
  baseline=$(jq -r '.baseline.count // "?"' "$goal_file")
  current=$(jq -r '.progress.current_count // "?"' "$goal_file")
  target=$(jq -r '.target.count // 0' "$goal_file")
  iterations=$(jq -r '.progress.iterations // 0' "$goal_file")

  echo "$goal_id|$status|$baseline|$current|$target|$iterations"
done
```

### Step 3: Run Live Detection Commands

For each goal that is NOT achieved, run its detection command to get live counts:

```bash
for goal_file in "$goals_dir"/*.json; do
  status=$(jq -r '.progress.status // "pending"' "$goal_file")
  if [ "$status" != "achieved" ]; then
    detection_cmd=$(jq -r '.detection.command' "$goal_file")
    if [ "$detection_cmd" != "null" ] && [ -n "$detection_cmd" ]; then
      live_count=$(eval "$detection_cmd" 2>/dev/null || echo "error")
      # Update display with live count
    fi
  fi
done
```

### Step 4: Scan Decision Manifests

```bash
# Find all decision manifest files
find "$decisions_dir" -name "*.json" -type f 2>/dev/null | while read -r manifest_file; do
  manifest_id=$(jq -r '.id' "$manifest_file")
  topic=$(jq -r '.topic' "$manifest_file")
  decisions_count=$(jq -r '.decisions | length' "$manifest_file")
  pending_count=$(jq -r '[.decisions[] | select(.status == "pending")] | length' "$manifest_file")
  resolved_count=$((decisions_count - pending_count))

  echo "$manifest_id|$topic|$decisions_count|$resolved_count|$pending_count"
done
```

### Step 5: Check Audit History

```bash
# Find recent audit reports
ls -t "$audits_dir"/AUDIT-*.md 2>/dev/null | head -5 | while read -r audit_file; do
  audit_date=$(basename "$audit_file" .md | sed 's/AUDIT-//')
  # Extract summary from audit if possible
  echo "$audit_date|$audit_file"
done
```

### Step 6: Present Dashboard

Output in this format:

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  ACIS Status Dashboard - {project_name}                                      ║
║  {timestamp}                                                                  ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  📊 GOALS OVERVIEW                                                           ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  ✅ Achieved: 12     🔄 In Progress: 3     ⏳ Pending: 5     ❌ Blocked: 1   ║
║                                                                              ║
║  GOAL DETAILS                                                                ║
║  ┌────────────────────────┬──────────┬──────────┬────────┬──────┬───────┐  ║
║  │ Goal ID                │ Status   │ Baseline │ Current│Target│ Iters │  ║
║  ├────────────────────────┼──────────┼──────────┼────────┼──────┼───────┤  ║
║  │ PR55-G1-math-random    │ ✅ done  │ 47       │ 0      │ 0    │ 5     │  ║
║  │ PR55-G2-uninit-session │ ✅ done  │ 12       │ 0      │ 0    │ 3     │  ║
║  │ WO59-CRIT-001          │ 🔄 wip   │ 8        │ 2      │ 0    │ 7     │  ║
║  │ WO59-HIGH-002          │ ⏳ pend  │ 15       │ 15     │ 0    │ 0     │  ║
║  └────────────────────────┴──────────┴──────────┴────────┴──────┴───────┘  ║
║                                                                              ║
║  📋 DECISION MANIFESTS                                                       ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  ┌─────────────────────────────────────┬──────────┬──────────┬─────────┐    ║
║  │ Manifest                            │ Resolved │ Pending  │ Total   │    ║
║  ├─────────────────────────────────────┼──────────┼──────────┼─────────┤    ║
║  │ DISC-2026-01-19-offline-sync        │ 4        │ 1        │ 5       │    ║
║  │ DISC-2026-01-20-phi-encryption      │ 3        │ 0        │ 3       │    ║
║  └─────────────────────────────────────┴──────────┴──────────┴─────────┘    ║
║                                                                              ║
║  🔍 RECENT AUDITS                                                            ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  • 2026-01-22: 3 goals analyzed, 1 skill generated                          ║
║  • 2026-01-19: 5 goals analyzed, 2 skills generated                          ║
║                                                                              ║
║  🎯 NEXT ACTIONS                                                             ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  1. /acis:remediate docs/acis/goals/WO59-CRIT-001.json (in progress)        ║
║  2. /acis:resolve docs/acis/decisions/DISC-...-sync.json (1 pending)        ║
║  3. /acis:remediate docs/acis/goals/WO59-HIGH-002.json (next priority)      ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Filtering Options

### `/acis:status goals`

Show only goals table with expanded details:
- Include detection command for each
- Include last iteration timestamp
- Include assignee/owner if tracked

### `/acis:status decisions`

Show only decision manifests with full decision list:
- Expand each manifest to show individual decisions
- Show wired-in vs pending vs inherited breakdown

### `/acis:status audits`

Show audit history with details:
- List all audit reports chronologically
- Show skills generated per audit
- Show process improvements applied

### `/acis:status <pattern>`

Filter goals/decisions by pattern:
```
/acis:status PR55    → Show only PR55-* goals
/acis:status CRIT    → Show only *-CRIT-* goals
/acis:status WO59    → Show only WO59-* goals
```

## Status Codes

| Code | Symbol | Meaning |
|------|--------|---------|
| `achieved` | ✅ | Target reached, verified |
| `in_progress` | 🔄 | Currently being remediated |
| `pending` | ⏳ | Not yet started |
| `blocked` | ❌ | Requires external input |
| `deferred` | ⏸️ | Postponed to future WO |

## Live Mode

When `--live` flag is passed:
- Run all detection commands in real-time
- Show spinner while running
- Highlight any count changes from last recorded

```bash
/acis:status --live
```

## JSON Output

When `--json` flag is passed:
- Output machine-readable JSON instead of formatted table
- Useful for CI/CD integration

```json
{
  "timestamp": "2026-01-24T10:30:00Z",
  "project": "CareAICompanion",
  "goals": {
    "total": 21,
    "achieved": 12,
    "in_progress": 3,
    "pending": 5,
    "blocked": 1,
    "items": [...]
  },
  "decisions": {
    "total": 8,
    "resolved": 7,
    "pending": 1,
    "items": [...]
  },
  "audits": {
    "total": 2,
    "skills_generated": 3,
    "items": [...]
  }
}
```

## Examples

```bash
# Full dashboard
/acis:status

# Goals only, with live detection
/acis:status goals --live

# Filter by work order
/acis:status WO59

# JSON output for CI
/acis:status --json

# Decisions only
/acis:status decisions
```
