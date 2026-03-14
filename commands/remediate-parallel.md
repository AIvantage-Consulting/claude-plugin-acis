# ACIS Remediate Parallel - Worktree-Isolated Parallel Remediation

You are executing the ACIS remediate-parallel command. This runs multiple goals in parallel using git worktrees for isolation, then merges via an integration branch.

## Arguments

- `$ARGUMENTS` - Goal IDs to remediate in parallel, space-separated
  - Example: `WO63-CRIT-001-key-rotation WO63-HIGH-002-math-random WO63-MED-003-console-log`
  - Or: `--wo WO63 --goals CRIT-001,HIGH-002,MED-003`

## Schema References

- **Batch State**: `${CLAUDE_PLUGIN_ROOT}/schemas/parallel-batch.schema.json`
- **Step Manifest**: `${CLAUDE_PLUGIN_ROOT}/schemas/step-manifest.schema.json`
- **Merge Report**: `${CLAUDE_PLUGIN_ROOT}/schemas/merge-report.schema.json`

## Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│              ACIS PARALLEL REMEDIATION PIPELINE                              │
└─────────────────────────────────────────────────────────────────────────────┘

Phase 0: SAFETY ANALYSIS      Analyze file conflicts, compute parallel groups
           │
           ▼
Phase 1: WORKTREE SETUP       Create isolated worktrees per goal
           │
           ▼
Phase 2: PARALLEL EXECUTION   Run remediation in each worktree (parallel agents)
           │                  Atomic step commits, verification after each
           ▼
Phase 3: INTEGRATION MERGE    Sequential merge to integration branch
           │                  Preserve atomic history, handle conflicts
           ▼
Phase 4: SQUASH TO MAIN       Final verification → squash merge → cleanup
           │
           ▼
       COMPLETE               Generate report, update goal status
```

## Naming Conventions

All names follow ACIS hierarchical namespace:

| Entity | Pattern | Example |
|--------|---------|---------|
| **Batch ID** | `BATCH-{WO}-{NNN}` | `BATCH-WO63-001` |
| **Step ID** | `{goal-id}-S{NN}` | `WO63-CRIT-001-S01` |
| **Goal Branch** | `acis/{goal-id}` | `acis/WO63-CRIT-001-key-rotation` |
| **Integration Branch** | `acis/integrate-{WO}-batch-{NNN}` | `acis/integrate-WO63-batch-001` |
| **Worktree Path** | `.acis-work/{goal-id}/` | `.acis-work/WO63-CRIT-001-key-rotation/` |
| **Step Commit** | `[{step-id}] {action}: {description}` | `[WO63-CRIT-001-S01] fix: replace Math.random in auth` |

## Phase Details

### Phase 0: PARALLEL SAFETY ANALYSIS

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 0: PARALLEL SAFETY ANALYSIS                                           │
└─────────────────────────────────────────────────────────────────────────────┘

1. LOAD GOALS
   for goal_id in $ARGUMENTS:
     goal = read_goal_file("${config.paths.goals}/${goal_id}.json")
     goals[goal_id] = goal

2. EXTRACT AFFECTED FILES (for each goal)
   Run detection command
   Parse output to extract file paths
   Store in affected_files[goal_id]

3. BUILD CONFLICT MATRIX
   for goal_a in goals:
     for goal_b in goals:
       if goal_a != goal_b:
         overlap = affected_files[goal_a] ∩ affected_files[goal_b]
         if overlap:
           conflicts[goal_a][goal_b] = overlap

4. COMPUTE PARALLEL GROUPS
   Use graph coloring to find disjoint sets
   Groups with no file overlap can run in parallel

5. PRESENT PLAN TO USER
   Show conflict analysis
   Show parallel groups
   Wait for confirmation (unless --yes)

6. CREATE BATCH STATE
   Write ${config.paths.state}/parallel/BATCH-{WO}-{NNN}.json
   Write lock file
```

**Output**: Parallel execution plan with safety verification

### Phase 1: WORKTREE SETUP

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: WORKTREE ISOLATION                                                  │
└─────────────────────────────────────────────────────────────────────────────┘

For each goal in current parallel group:

1. CREATE WORKTREE
   git worktree add .acis-work/${goal_id} -b acis/${goal_id} main

2. VERIFY WORKTREE
   cd .acis-work/${goal_id}
   git status  # Must be clean
   git log -1  # Must match main HEAD

3. REGISTER WORKTREE
   Update worktree-registry.json

4. DECOMPOSE INTO STEPS
   Analyze goal scope
   Break into atomic steps (max 3 files per step)
   Write ${config.paths.steps}/${goal_id}/manifest.json
```

**Worktree Directory**: `.acis-work/` (git-ignored, ephemeral)

### Phase 2: PARALLEL EXECUTION

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: PARALLEL STEP EXECUTION                                             │
└─────────────────────────────────────────────────────────────────────────────┘

For each goal (in parallel via separate Task agents):

  AGENT CONTEXT:
    - Working directory: .acis-work/${goal_id}/
    - Branch: acis/${goal_id}
    - Manifest: ${config.paths.steps}/${goal_id}/manifest.json

  For each step in manifest.steps:

    1. CHECK DEPENDENCIES
       Wait for dependent steps to complete

    2. EXECUTE STEP
       Apply fix according to step.action and step.scope

    3. VERIFY STEP
       Run step.verification.command
       Compare result to step.verification.expected_after

    3.5. FUNCTIONAL CHECK (if goal has detection.functional_checks[])
         Run each functional check command
         If ANY blocking check fails → mark step as NEEDS_REWORK
         If all blocking checks pass → proceed to commit
         Advisory failures → log warning in step manifest

    4. COMMIT STEP (atomic, with metrics)
       git add ${step.scope.files}
       git commit -m "[${step.step_id}] ${step.action}: ${step.description}

       Metric: ${before} → ${after} (target: ${target})"

    5. UPDATE STATE
       Mark step complete in manifest
       Record commit hash and metrics

    5.5. INCREMENT ITERATION COUNTER
         Update goal JSON: progress.iterations += 1
         Record step metrics in progress.metrics_history[]:
           { iteration: N, timestamp: ISO, metrics: { step_id, before, after, target } }
         Stage and amend last commit to include updated goal JSON:
           jq '.progress.iterations += 1' "${goal_file}" > tmp && mv tmp "${goal_file}"
           git add "${goal_file}"
           git commit --amend --no-edit

    6. CHECKPOINT (optional, for recovery)
       git push origin acis/${goal_id}  # If --push-branches
```

**Step Size**: Default 3 files max per step (configurable via `--step-size`)

### Phase 3: INTEGRATION BRANCH MERGE

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: INTEGRATION BRANCH ASSEMBLY                                         │
└─────────────────────────────────────────────────────────────────────────────┘

1. CREATE INTEGRATION BRANCH
   git checkout -b acis/integrate-${WO}-batch-${NNN} main

2. MERGE GOAL BRANCHES (sequential, preserve atomic history)
   for goal_id in batch.goals (ordered by priority):

     2.1. PRE-MERGE DIVERGENCE CHECK (regression-aware conflict detection)
          For each file in next_goal.affected_files:
            worktree_hash = git hash-object .acis-work/${goal_id}/${file}
            integration_hash = git show HEAD:${file} | git hash-object --stdin
            if worktree_hash != integration_hash AND file was modified by a previous merge:
              DIVERGENCE DETECTED:
                - File: ${file}
                - Worktree base: ${worktree_base_commit}
                - Integration HEAD: ${integration_head}
                - Modified by: ${previous_goal_id} (merged earlier)
              CLASSIFY RISK:
                HIGH_RISK: Previous merge changed file semantics (not just formatting)
                  → Require sequential rebase of ${goal_id} onto integration HEAD
                  → Re-run step verification after rebase
                LOW_RISK: Previous merge only changed unrelated sections
                  → Proceed with merge, monitor for conflicts
              LOG: "DIVERGENCE: ${file} modified by ${previous_goal_id}, ${goal_id} worktree has stale version"

     ATTEMPT MERGE:
       git merge acis/${goal_id} --no-ff -m "Merge ${goal_id}"

     IF CONFLICT → CLASSIFY AND HANDLE:

       TRIVIAL (whitespace, import order):
         Auto-resolve using git merge strategies
         Continue merge

       PARTIAL (some commits clean):
         Abort merge
         Cherry-pick successful step commits
         Create new goal for remaining work

       SEMANTIC (logic conflicts):
         Preserve worktree for debugging
         Attempt rebase and retry
         If still fails → flag for human review

       UNRESOLVABLE:
         Preserve all work
         Generate detailed conflict report
         Notify user, skip this goal

     VERIFY AFTER EACH MERGE:
       Run goal's detection command
       If regression detected → git revert HEAD → investigate
       Run goal's functional_checks (if present)
       If blocking functional check fails → git revert HEAD → investigate

     2.2. POST-MERGE DIVERGENCE UPDATE
          Update affected_files index for subsequent merges:
            merged_files = git diff --name-only HEAD~1 HEAD
            for each remaining goal in batch.goals:
              overlap = remaining_goal.affected_files ∩ merged_files
              if overlap:
                remaining_goal.divergence_risk[${goal_id}] = overlap
                LOG: "POST-MERGE: ${remaining_goal_id} has ${#overlap} files diverged by ${goal_id}"

3. VERIFY INTEGRATION BRANCH
   Run ALL detection commands
   Run test suite
   Run build

   If any failure:
     git bisect to find causing commit
     (Atomic history enables precise identification)
```

**Key Principle**: Regular merges (not squash) to integration branch preserve atomic history for debugging.

### Phase 4: SQUASH TO MAIN + CLEANUP

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: SQUASH TO MAIN + CLEANUP                                            │
└─────────────────────────────────────────────────────────────────────────────┘

1. FINAL VERIFICATION
   Checkout integration branch
   Run full verification suite:
     - Detection commands for all goals
     - Functional checks for all goals with detection.functional_checks[]
     - Test suite
     - Build

   If PASS (all detection + functional + tests + build) → proceed
   If FAIL → abort and report (include which functional checks failed)

2. PRESERVE HISTORY (before squashing)
   git tag acis/history/BATCH-${WO}-${NNN} acis/integrate-${WO}-batch-${NNN}

   for goal_id in batch.goals:
     git tag acis/archive/${goal_id} acis/${goal_id}

3. SQUASH MERGE TO MAIN
   git checkout main
   git merge --squash acis/integrate-${WO}-batch-${NNN}
   git commit -m "[ACIS] ${BATCH_ID}: ${goal_count} goals remediated

   Goals:
   - ${goal_1_id}: ${goal_1_summary}
   - ${goal_2_id}: ${goal_2_summary}
   ...

   Total: ${files_changed} files, ${insertions}+, ${deletions}-"

4. AUTOMATIC WORKTREE CLEANUP
   for goal_id in batch.goals:
     if goal.status == 'achieved':
       # Achieved goals: auto-cleanup
       git worktree remove .acis-work/${goal_id}
       git branch -d acis/${goal_id}
       log("Cleaned up worktree: ${goal_id} (achieved)")
     elif goal.status == 'blocked':
       # Blocked goals: prompt user
       AskUserQuestion: "Goal ${goal_id} is blocked. Keep worktree for debugging?"
       if user_says_keep:
         log("Preserving worktree for debugging: ${goal_id}")
       else:
         git worktree remove .acis-work/${goal_id}
         git branch -d acis/${goal_id}
         log("Cleaned up blocked worktree: ${goal_id}")
     else:
       # Other states (deferred, in_progress): preserve
       log("Preserving worktree: ${goal_id} (status: ${goal.status})")

   # Prune stale worktree references
   git worktree prune

   git branch -d acis/integrate-${WO}-batch-${NNN}

5. GENERATE REPORT
   Write ${config.paths.merge-reports}/BATCH-${WO}-${NNN}-report.json
   Write ${config.paths.merge-reports}/BATCH-${WO}-${NNN}-report.md

6. UPDATE GOAL STATUS
   Mark complete goals as 'achieved'
   Record achievement_verification
```

## Flags

| Flag | Description |
|------|-------------|
| `--wo <id>` | Work order context |
| `--goals <list>` | Comma-separated goal suffixes (with `--wo`) |
| `--dry-run` | Show plan without executing |
| `--yes` | Skip confirmation prompt |
| `--force-parallel` | Ignore file conflict warnings |
| `--resume <batch-id>` | Resume existing batch |
| `--status <batch-id>` | Show batch status |
| `--max-parallel <n>` | Limit concurrent worktrees (default: 4) |
| `--step-size <n>` | Max files per step (default: 3) |
| `--preserve-worktrees` | Don't cleanup worktrees after success |
| `--cleanup` | Manual worktree sweep: remove all achieved worktrees, prompt for blocked, prune stale refs |
| `--skip-squash` | Leave as merge commits on main (no squash) |
| `--push-branches` | Push goal branches to origin for backup |
| `--skip-tests` | Skip test suite during verification |
| `--skip-build` | Skip build during verification |

## Conflict Resolution Strategies

| Type | Detection | Resolution |
|------|-----------|------------|
| **TRIVIAL** | Whitespace, import order only | Auto-resolve |
| **PARTIAL** | Some commits merge, some conflict | Cherry-pick clean commits, new goal for rest |
| **SEMANTIC** | Logic conflicts between goals | Rebase attempt → human review |
| **UNRESOLVABLE** | Cannot merge without data loss | Preserve work, notify user |

## Safety Guarantees

| Guarantee | How Achieved |
|-----------|--------------|
| **Baseline never corrupted** | All work in worktrees, main only receives verified squashes |
| **Atomic rollback** | Each step is one commit, can `git reset` |
| **Conflict visibility** | Full atomic history in integration branch |
| **Cherry-pick viable** | Regular merges to integration, not squash |
| **Debugging possible** | Tags preserve all history for 30 days |
| **No overwrite collisions** | File disjointness check before parallelizing |
| **Recovery from any point** | State files checkpoint every step |

## Output Report

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  PARALLEL REMEDIATION COMPLETE: BATCH-WO63-001                               ║
║  {timestamp}                                                                  ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  📋 BATCH SUMMARY                                                            ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  Goals Processed: 3                                                          ║
║  ├── Complete:    3 ✅                                                       ║
║  ├── Partial:     0                                                          ║
║  └── Failed:      0                                                          ║
║                                                                              ║
║  📊 PER-GOAL RESULTS                                                         ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  WO63-CRIT-001-key-rotation                                                  ║
║    Steps: 4/4 ✅ | Commits: 4 | Files: 6 | Metric: 12 → 0                   ║
║    Merge: regular                                                            ║
║                                                                              ║
║  WO63-HIGH-002-math-random                                                   ║
║    Steps: 5/5 ✅ | Commits: 5 | Files: 8 | Metric: 47 → 0                   ║
║    Merge: regular                                                            ║
║                                                                              ║
║  WO63-MED-003-console-log                                                    ║
║    Steps: 3/3 ✅ | Commits: 3 | Files: 4 | Metric: 23 → 0                   ║
║    Merge: regular                                                            ║
║                                                                              ║
║  🔀 MERGE RESULTS                                                            ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  Integration: acis/integrate-WO63-batch-001                                  ║
║  Total Commits: 12 (atomic history preserved)                                ║
║  Conflicts: 0                                                                ║
║  Final Merge: Squash to main                                                 ║
║                                                                              ║
║  ✅ VERIFICATION                                                             ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  Detection Commands: PASS (all 3 goals verified)                             ║
║  Test Suite:         PASS (2847 tests, 0 failures)                           ║
║  Build:              PASS                                                    ║
║                                                                              ║
║  📁 TOTAL CHANGES                                                            ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  Files Modified: 18                                                          ║
║  Insertions:     +342                                                        ║
║  Deletions:      -287                                                        ║
║                                                                              ║
║  🏷️ HISTORY PRESERVED                                                        ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  Tag: acis/history/BATCH-WO63-001                                            ║
║  Goal Archives: 3 tags created                                               ║
║  Retention: 30 days                                                          ║
║                                                                              ║
║  🧹 CLEANUP                                                                  ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  Worktrees Removed: 3                                                        ║
║  Branches Deleted: 4 (3 goal + 1 integration)                                ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Examples

```bash
# Basic parallel execution (3 goals)
/acis:remediate-parallel WO63-CRIT-001-key-rotation WO63-HIGH-002-math-random WO63-MED-003-console-log

# With work order context
/acis:remediate-parallel --wo WO63 --goals CRIT-001,HIGH-002,MED-003

# Dry run - show plan without executing
/acis:remediate-parallel WO63-CRIT-001 WO63-HIGH-002 --dry-run

# Force parallel even with conflicts (risky)
/acis:remediate-parallel WO63-CRIT-001 WO63-HIGH-002 --force-parallel

# Resume interrupted batch
/acis:remediate-parallel --resume BATCH-WO63-001

# Check batch status
/acis:remediate-parallel --status BATCH-WO63-001

# Limit concurrency for resource-constrained environments
/acis:remediate-parallel WO63-CRIT-001 WO63-HIGH-002 WO63-MED-003 --max-parallel 2

# Smaller atomic steps for fine-grained tracking
/acis:remediate-parallel WO63-CRIT-001 --step-size 1

# Keep worktrees for post-mortem debugging
/acis:remediate-parallel WO63-CRIT-001 WO63-HIGH-002 --preserve-worktrees

# Push branches to origin for backup/collaboration
/acis:remediate-parallel WO63-CRIT-001 WO63-HIGH-002 --push-branches
```

## Related Commands

- `/acis:remediate <goal>` - Single goal remediation (standard)
- `/acis:status` - View overall ACIS status
- `/acis:verify <goal>` - Re-run verification for a goal

## Files

| File | Purpose |
|------|---------|
| `${config.paths.state}/parallel/BATCH-*.json` | Batch state |
| `${config.paths.state}/parallel/worktree-registry.json` | Active worktrees |
| `${config.paths.steps}/${goal-id}/manifest.json` | Step decomposition |
| `${config.paths.merge-reports}/BATCH-*-report.json` | Merge report (JSON) |
| `${config.paths.merge-reports}/BATCH-*-report.md` | Merge report (human-readable) |
