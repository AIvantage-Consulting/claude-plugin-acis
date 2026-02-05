# /acis pre-commit-review - Quick Design Review Before Commit

Run a quick design/architecture review on staged changes before committing. This provides an independent pair of eyes to catch design issues early.

## Trigger

User invokes `/acis pre-commit-review` with optional flags:
- `--strict` - BLOCK verdict prevents commit (exit code 1)
- `--skip-codex` - Use internal heuristics only (faster, less thorough)
- `--quiet` - Only show output if WARN or BLOCK

## Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                   /acis pre-commit-review                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────┐
            │  STEP 1: Check Staged Changes   │
            │  git diff --staged --name-only  │
            └─────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
        No changes                      Has changes
              │                               │
              ▼                               ▼
    ┌─────────────────┐           ┌─────────────────────┐
    │ Exit with       │           │ STEP 2: Get diff    │
    │ helpful message │           │ Truncate if >500    │
    └─────────────────┘           └─────────────────────┘
                                              │
                                              ▼
                                  ┌─────────────────────┐
                                  │ STEP 3: Load config │
                                  │ (.acis-config.json) │
                                  └─────────────────────┘
                                              │
                              ┌───────────────┴───────────────┐
                              │                               │
                      --skip-codex                    Use Codex
                              │                               │
                              ▼                               ▼
                    ┌─────────────────┐           ┌─────────────────────┐
                    │ STEP 4a:        │           │ STEP 4b: Delegate   │
                    │ Heuristic mode  │           │ to Codex            │
                    └─────────────────┘           └─────────────────────┘
                              │                               │
                              └───────────────┬───────────────┘
                                              │
                                              ▼
                                  ┌─────────────────────┐
                                  │ STEP 5: Display     │
                                  │ verdict & findings  │
                                  └─────────────────────┘
                                              │
                                              ▼
                                  ┌─────────────────────┐
                                  │ Exit code:          │
                                  │ 0: PASS or WARN     │
                                  │ 1: BLOCK (--strict) │
                                  └─────────────────────┘
```

## Step 1: Check for Staged Changes

Run:
```bash
git diff --staged --name-only
```

**If empty:**
```
╔══════════════════════════════════════════════╗
║  No staged changes to review                  ║
╠══════════════════════════════════════════════╣
║                                              ║
║  Stage files first:                          ║
║    git add <files>                           ║
║                                              ║
║  Then run:                                   ║
║    /acis pre-commit-review                   ║
║                                              ║
╚══════════════════════════════════════════════╝
```

## Step 2: Get Staged Diff

```bash
git diff --staged
```

**Line count and truncation:**
- Count lines with `git diff --staged | wc -l`
- If >500 lines, truncate and warn:

```
⚠ Large diff (847 lines). Reviewing first 500 lines.
  Consider splitting into smaller commits.
```

## Step 3: Load Project Context

If `.acis-config.json` exists, extract:
- `architectureModel` - Layer structure to validate
- `compliance` - Security/compliance requirements
- `platform` - Platform constraints

If no config exists, proceed with generic review.

## Step 4a: Heuristic Mode (--skip-codex)

When Codex is unavailable or skipped, apply basic heuristics:

| Heuristic | Detection | Verdict |
|-----------|-----------|---------|
| Large commit | >10 files staged | WARN |
| Large single file | >300 lines in one file | WARN |
| Layer violation | Import from higher layer (detected via path patterns) | WARN |
| Test file changes only | Only `*.test.*` or `*.spec.*` files | PASS (auto) |

**Heuristic output format:**
```
╔══════════════════════════════════════════════╗
║  ACIS Pre-Commit Review (Heuristic Mode)     ║
║  Files: 12 | Lines: 156                      ║
╠══════════════════════════════════════════════╣
║  VERDICT: WARN ⚠                             ║
╠══════════════════════════════════════════════╣
║  [H1] Large commit                           ║
║       12 files may be too many for one commit║
║       Consider splitting by concern          ║
╚══════════════════════════════════════════════╝
```

## Step 4b: Codex Delegation

Load the delegation template from `${CLAUDE_PLUGIN_ROOT}/templates/codex-pre-commit-review.md`.

**Template variables:**
- `{STAGED_FILES}` - List of staged file paths
- `{STAGED_DIFF}` - The diff content (truncated if needed)
- `{FILE_COUNT}` - Number of staged files
- `{LINE_COUNT}` - Total lines changed
- `{ARCHITECTURE_MODEL}` - From config (or "unknown")
- `{COMPLIANCE}` - From config (or "none specified")

**Delegation call:**
```typescript
mcp__codex__codex({
  prompt: "[filled template]",
  "developer-instructions": "[contents of template]",
  sandbox: "read-only",
  cwd: "${PROJECT_ROOT}"
})
```

## Step 5: Display Results

### PASS Verdict
```
╔══════════════════════════════════════════════╗
║  ACIS Pre-Commit Review                      ║
║  Files: 3 | Lines: 67                        ║
╠══════════════════════════════════════════════╣
║  VERDICT: PASS ✓                             ║
║  No design concerns. Ready to commit.        ║
╚══════════════════════════════════════════════╝
```

### WARN Verdict
```
╔══════════════════════════════════════════════╗
║  ACIS Pre-Commit Review                      ║
║  Files: 2 | Lines: 89                        ║
╠══════════════════════════════════════════════╣
║  VERDICT: WARN ⚠                             ║
╠══════════════════════════════════════════════╣
║  [W1] Dependency Direction                   ║
║       File: src/services/Auth.ts:34          ║
║       Issue: Service importing UI component  ║
║       Suggestion: Extract to shared/types    ║
╠══════════════════════════════════════════════╣
║  This is advisory feedback. You may proceed. ║
╚══════════════════════════════════════════════╝
```

### BLOCK Verdict (requires --strict to enforce)
```
╔══════════════════════════════════════════════╗
║  ACIS Pre-Commit Review                      ║
║  Files: 4 | Lines: 234                       ║
╠══════════════════════════════════════════════╣
║  VERDICT: BLOCK ✗                            ║
╠══════════════════════════════════════════════╣
║  [B1] SOLID Violation - SRP                  ║
║       File: src/core/UserManager.ts          ║
║       Issue: Class handles auth, DB, and UI  ║
║       Suggestion: Split into 3 services      ║
║                                              ║
║  [B2] Layer Breach                           ║
║       File: src/foundation/api.ts:12         ║
║       Issue: Foundation imports from Journey ║
║       Suggestion: Move shared types down     ║
╠══════════════════════════════════════════════╣
║  --strict mode: Commit blocked.              ║
║  Fix issues or run without --strict.         ║
╚══════════════════════════════════════════════╝
```

## Exit Codes

| Verdict | Normal Mode | --strict Mode |
|---------|-------------|---------------|
| PASS | 0 | 0 |
| WARN | 0 | 0 |
| BLOCK | 0 | 1 |

## Comparison: Pre-Commit Review vs Quality Gate

| Aspect | Pre-Commit Review | Quality Gate (Phase 4.5) |
|--------|-------------------|--------------------------|
| **Trigger** | Before git commit | After goal metric achieved |
| **Scope** | Staged changes only | Cumulative goal diff |
| **Depth** | Quick (<30 sec) | Thorough (full SOLID checklist) |
| **Verdict** | PASS/WARN/BLOCK | APPROVE/REQUEST_CHANGES |
| **Blocking** | Non-blocking default | Blocks goal completion |
| **When** | Every commit | ACIS remediation workflow only |

## Integration Notes

- Works standalone without `.acis-config.json`
- Respects `pluginDefaults.skipCodex` from config
- Can be triggered via PreToolUse hook (see install-hooks.sh)

## Flags Reference

| Flag | Effect |
|------|--------|
| `--strict` | Exit code 1 on BLOCK (default: 0) |
| `--skip-codex` | Use heuristics only |
| `--quiet` | Only show output if WARN or BLOCK |
