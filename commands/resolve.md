# ACIS Resolve - Decision Resolution

You are executing the ACIS resolve command. This resolves pending decisions from a discovery manifest.

## Arguments

- `$ARGUMENTS` - Path to decision manifest JSON file (e.g., `docs/acis/decisions/DISC-2026-01-24-sync.json`)

## Purpose

After `/acis:discovery` surfaces decisions, some are **pending** (need resolution before implementation). This command:

1. Auto-approves decisions where CEO-Alpha and CEO-Beta **converged**
2. Prompts the user for decisions where they **diverged**
3. Updates the manifest with resolved decisions
4. Makes resolved decisions enforceable in remediation

## Workflow

### Step 1: Load Manifest

```bash
manifest_file="$ARGUMENTS"
if [ ! -f "$manifest_file" ]; then
  echo "ERROR: Manifest not found: $manifest_file"
  exit 1
fi

manifest=$(cat "$manifest_file")
pending_decisions=$(echo "$manifest" | jq '[.decisions[] | select(.status == "pending")]')
pending_count=$(echo "$pending_decisions" | jq 'length')
```

### Step 2: Categorize Pending Decisions

```
CONVERGED (auto-resolvable):
  CEO-Alpha and CEO-Beta recommend the same value
  → Can be auto-approved without human input

DIVERGED (needs human):
  CEO-Alpha and CEO-Beta recommend different values
  → Must present both perspectives and ask user
```

### Step 3: Auto-Approve Converged Decisions

For each converged decision:

```json
{
  "id": "DEC-SYNC-002",
  "status": "pending" → "resolved",
  "resolution": {
    "value": "{converged_recommendation}",
    "resolved_by": "auto-converged",
    "resolved_at": "{timestamp}",
    "rationale": "CEO-Alpha and CEO-Beta independently recommended {value}"
  }
}
```

### Step 4: Prompt for Diverged Decisions

For each diverged decision, use AskUserQuestion:

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  DECISION REQUIRED: {decision_name}                                          ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  {decision_description}                                                      ║
║                                                                              ║
║  Options: {allowed_values}                                                   ║
║                                                                              ║
║  CEO-ALPHA (AI-Native) recommends: {alpha_recommendation}                   ║
║  Rationale: {alpha_rationale}                                               ║
║                                                                              ║
║  CEO-BETA (Modern SWE) recommends: {beta_recommendation}                    ║
║  Rationale: {beta_rationale}                                                ║
║                                                                              ║
║  Impact on {persona}: {impact_statement}                                    ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

Options presented:
1. **{alpha_recommendation}** (CEO-Alpha: {brief})
2. **{beta_recommendation}** (CEO-Beta: {brief})
3. **Other** (provide custom value)
4. **Defer** (postpone decision)

### Step 5: Record Resolutions

```json
{
  "id": "DEC-SYNC-003",
  "status": "pending" → "resolved",
  "resolution": {
    "value": "{user_choice}",
    "resolved_by": "human",
    "resolved_at": "{timestamp}",
    "rationale": "{user_provided_or_selected_rationale}",
    "ceo_alpha_agreed": true/false,
    "ceo_beta_agreed": true/false
  }
}
```

### Step 6: Update Manifest

Write updated manifest with all resolutions:

```bash
# Backup original
cp "$manifest_file" "${manifest_file}.backup"

# Write updated manifest
jq '.decisions = $updated_decisions' \
   --argjson updated_decisions "$updated" \
   "$manifest_file" > "${manifest_file}.tmp"
mv "${manifest_file}.tmp" "$manifest_file"
```

### Step 7: Present Resolution Report

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  ACIS Decision Resolution Report                                             ║
║  Manifest: {manifest_file}                                                   ║
║  {timestamp}                                                                  ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  📊 SUMMARY                                                                  ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  Total Decisions:    8                                                       ║
║  Already Resolved:   3 (wired-in)                                           ║
║  Auto-Approved:      3 (CEO converged)                                      ║
║  Human Resolved:     2 (diverged, user chose)                               ║
║  Still Pending:      0                                                       ║
║                                                                              ║
║  ✅ RESOLVED THIS SESSION                                                    ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  DEC-SYNC-002: Conflict Resolution → CRDT (auto-converged)                  ║
║  DEC-SYNC-003: Sync Frequency → batched (user chose, CEO-Alpha agreed)      ║
║  DEC-ENC-002:  Key Rotation → weekly (auto-converged)                       ║
║  DEC-UI-001:   Sync Indicator → subtle (user chose)                         ║
║                                                                              ║
║  📋 MANIFEST STATUS                                                          ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  All decisions resolved. Manifest is ready for remediation.                 ║
║                                                                              ║
║  🎯 NEXT STEPS                                                               ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  /acis:remediate docs/acis/goals/SYNC-001.json \                            ║
║    --manifest docs/acis/decisions/DISC-2026-01-24-sync.json                 ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Flags

| Flag | Description |
|------|-------------|
| `--auto-only` | Only auto-approve converged decisions, skip diverged |
| `--force <id>` | Force resolution of specific decision with immediate prompt |
| `--defer <id>` | Defer specific decision without prompting |
| `--list` | List all pending decisions without resolving |
| `--json` | Output resolution report as JSON |

## Decision Status Flow

```
                    ┌──────────────────┐
                    │    Discovery     │
                    │  surfaces        │
                    │  decision        │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │    PENDING       │
                    │  (needs          │
                    │  resolution)     │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │ CONVERGED   │  │ DIVERGED    │  │ DEFERRED    │
    │ (auto)      │  │ (human)     │  │ (later)     │
    └──────┬──────┘  └──────┬──────┘  └─────────────┘
           │                │
           ▼                ▼
    ┌──────────────────────────────┐
    │          RESOLVED            │
    │  (enforceable in remediate)  │
    └──────────────────────────────┘
```

## Estimation Rules (CRITICAL)

**ACIS uses COMPLEXITY-based estimation, NEVER time-based estimation.**

When discussing effort for decisions or implementation:

### ❌ FORBIDDEN (Never Output)
- `"8h"`, `"24h"`, `"40h → 56h"`
- `"Total Effort: 40h"`
- Any numeric time estimate

### ✅ REQUIRED (Always Use)
- **Complexity Tier**: Tier 1 (Simple), Tier 2 (Moderate), Tier 3 (Complex)
- **What + Why**: Brief description of what's involved

## Examples

```bash
# Resolve all pending decisions in manifest
/acis:resolve docs/acis/decisions/DISC-2026-01-24-sync.json

# Only auto-approve converged, skip diverged
/acis:resolve docs/acis/decisions/DISC-sync.json --auto-only

# Force resolution of specific decision
/acis:resolve docs/acis/decisions/DISC-sync.json --force DEC-SYNC-003

# List pending decisions without resolving
/acis:resolve docs/acis/decisions/DISC-sync.json --list

# Defer a specific decision
/acis:resolve docs/acis/decisions/DISC-sync.json --defer DEC-UI-001
```

## Integration with Remediation

When remediation runs with `--manifest`:

```bash
/acis:remediate docs/acis/goals/SYNC-001.json \
  --manifest docs/acis/decisions/DISC-2026-01-24-sync.json
```

The resolved decisions are **binding**:
- Code must implement the resolved values
- Deviation from resolved decisions fails verification
- Decision rationale is included in commit messages
