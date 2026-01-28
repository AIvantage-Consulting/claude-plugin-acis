# ACIS Parallel Remediation Implementation Plan

## Overview

This document specifies the implementation of worktree-isolated parallel remediation with integration branch strategy, coordinated naming conventions, and atomic step tracking.

---

## 1. Namespace & Naming Conventions

### 1.1 Core Naming Patterns

All names follow a hierarchical namespace coordinated with existing ACIS conventions:

```
Existing ACIS Patterns:
  Goal ID:     WO63-CRIT-001-key-rotation
               └─┬─┘└──┬──┘└┬┘ └────┬────┘
                 │     │    │       └── slug (kebab-case)
                 │     │    └── sequence number
                 │     └── severity (CRIT/HIGH/MED/LOW)
                 └── work order ID

New Parallel Patterns:
  Batch ID:    BATCH-WO63-001
  Step ID:     WO63-CRIT-001-S01
  Branch:      acis/WO63-CRIT-001-key-rotation
  Worktree:    .acis-work/WO63-CRIT-001-key-rotation/
  Integration: acis/integrate-WO63-batch-001
```

### 1.2 Complete Naming Schema

| Entity | Pattern | Example |
|--------|---------|---------|
| **Goal ID** | `{WO}-{SEV}-{NUM}-{slug}` | `WO63-CRIT-001-key-rotation` |
| **Step ID** | `{goal-id}-S{NN}` | `WO63-CRIT-001-S01` |
| **Batch ID** | `BATCH-{WO}-{NNN}` | `BATCH-WO63-001` |
| **Goal Branch** | `acis/{goal-id}` | `acis/WO63-CRIT-001-key-rotation` |
| **Integration Branch** | `acis/integrate-{WO}-batch-{NNN}` | `acis/integrate-WO63-batch-001` |
| **Worktree Path** | `.acis-work/{goal-id}/` | `.acis-work/WO63-CRIT-001-key-rotation/` |
| **Step Commit** | `[{step-id}] {action}: {description}` | `[WO63-CRIT-001-S01] detect: baseline 47 instances` |
| **Archive Tag** | `acis/archive/{goal-id}` | `acis/archive/WO63-CRIT-001-key-rotation` |
| **Batch History Tag** | `acis/history/{batch-id}` | `acis/history/BATCH-WO63-001` |

### 1.3 Directory Structure

```
project-root/
├── .acis-work/                              # Worktrees root (git-ignored)
│   ├── WO63-CRIT-001-key-rotation/          # Goal worktree
│   │   └── (full project checkout)
│   ├── WO63-HIGH-002-math-random/           # Goal worktree
│   │   └── (full project checkout)
│   └── WO63-MED-003-console-log/            # Goal worktree
│       └── (full project checkout)
│
├── docs/acis/                               # ACIS artifacts root
│   ├── goals/                               # Goal definitions
│   │   ├── WO63-CRIT-001-key-rotation.json
│   │   ├── WO63-HIGH-002-math-random.json
│   │   └── WO63-MED-003-console-log.json
│   │
│   ├── state/                               # Runtime state
│   │   ├── STATE.md                         # Global state
│   │   ├── progress/                        # Goal progress
│   │   │   ├── WO63-CRIT-001-key-rotation.json
│   │   │   └── WO63-HIGH-002-math-random.json
│   │   └── parallel/                        # Parallel execution state
│   │       ├── BATCH-WO63-001.json          # Batch state
│   │       ├── BATCH-WO63-001.lock          # Batch lock file
│   │       └── worktree-registry.json       # Active worktrees
│   │
│   ├── steps/                               # Step decomposition
│   │   ├── WO63-CRIT-001-key-rotation/
│   │   │   ├── manifest.json                # Step manifest
│   │   │   ├── S01-detect.json              # Step state
│   │   │   ├── S02-fix-auth.json
│   │   │   └── S03-fix-utils.json
│   │   └── WO63-HIGH-002-math-random/
│   │       └── manifest.json
│   │
│   └── merge-reports/                       # Merge history
│       ├── BATCH-WO63-001-report.json
│       └── BATCH-WO63-001-report.md
│
└── .gitignore                               # Must include .acis-work/
```

---

## 2. Schema Definitions

### 2.1 Batch State Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "parallel-batch.schema.json",
  "title": "ACIS Parallel Batch State",

  "properties": {
    "batch_id": {
      "type": "string",
      "pattern": "^BATCH-[A-Z0-9]+-[0-9]{3}$",
      "example": "BATCH-WO63-001"
    },
    "work_order": {
      "type": "string",
      "description": "Parent work order ID"
    },
    "created_at": {
      "type": "string",
      "format": "date-time"
    },
    "status": {
      "type": "string",
      "enum": ["planning", "executing", "merging", "verifying", "complete", "failed", "partial"]
    },

    "baseline": {
      "type": "object",
      "properties": {
        "commit": { "type": "string" },
        "branch": { "type": "string", "default": "main" },
        "verified_clean": { "type": "boolean" }
      }
    },

    "goals": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "goal_id": { "type": "string" },
          "priority": { "type": "integer" },
          "status": {
            "type": "string",
            "enum": ["pending", "worktree_created", "executing", "complete", "failed", "partial"]
          },
          "worktree_path": { "type": "string" },
          "branch": { "type": "string" },
          "steps_total": { "type": "integer" },
          "steps_complete": { "type": "integer" },
          "affected_files": {
            "type": "array",
            "items": { "type": "string" }
          }
        }
      }
    },

    "parallel_groups": {
      "type": "array",
      "description": "Goals grouped by file disjointness",
      "items": {
        "type": "object",
        "properties": {
          "group_id": { "type": "integer" },
          "goals": { "type": "array", "items": { "type": "string" } },
          "can_parallelize": { "type": "boolean" },
          "conflicts_with_groups": { "type": "array", "items": { "type": "integer" } }
        }
      }
    },

    "integration": {
      "type": "object",
      "properties": {
        "branch": { "type": "string" },
        "base_commit": { "type": "string" },
        "current_commit": { "type": "string" },
        "goals_merged": { "type": "array", "items": { "type": "string" } },
        "goals_pending": { "type": "array", "items": { "type": "string" } },
        "verification_status": {
          "type": "string",
          "enum": ["pending", "running", "passed", "failed"]
        }
      }
    },

    "merge_to_main": {
      "type": "object",
      "properties": {
        "strategy": { "type": "string", "enum": ["squash", "merge", "rebase"] },
        "status": { "type": "string", "enum": ["pending", "complete", "failed"] },
        "commit": { "type": "string" },
        "squashed_at": { "type": "string", "format": "date-time" }
      }
    },

    "history_preservation": {
      "type": "object",
      "properties": {
        "integration_tag": { "type": "string" },
        "goal_tags": { "type": "array", "items": { "type": "string" } },
        "retention_days": { "type": "integer", "default": 30 }
      }
    }
  }
}
```

### 2.2 Step Manifest Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "step-manifest.schema.json",
  "title": "ACIS Goal Step Manifest",

  "properties": {
    "goal_id": { "type": "string" },
    "decomposition_strategy": {
      "type": "string",
      "enum": ["by_file", "by_module", "by_pattern", "by_severity", "custom"]
    },
    "max_files_per_step": { "type": "integer", "default": 3 },
    "verification_mode": {
      "type": "string",
      "enum": ["after_each_step", "after_each_file", "batch"]
    },

    "steps": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["step_id", "action", "description"],
        "properties": {
          "step_id": {
            "type": "string",
            "pattern": "^[A-Z0-9-]+-S[0-9]{2}$",
            "example": "WO63-CRIT-001-S01"
          },
          "order": { "type": "integer" },
          "action": {
            "type": "string",
            "enum": ["detect", "analyze", "fix", "test", "verify", "cleanup"]
          },
          "description": { "type": "string" },
          "scope": {
            "type": "object",
            "properties": {
              "files": { "type": "array", "items": { "type": "string" } },
              "modules": { "type": "array", "items": { "type": "string" } },
              "patterns": { "type": "array", "items": { "type": "string" } }
            }
          },
          "verification": {
            "type": "object",
            "properties": {
              "command": { "type": "string" },
              "expected_before": {},
              "expected_after": {},
              "comparison": { "type": "string", "enum": ["eq", "lt", "lte", "gt", "gte"] }
            }
          },
          "commit": {
            "type": "object",
            "properties": {
              "message_template": { "type": "string" },
              "include_metrics": { "type": "boolean", "default": true }
            }
          },
          "dependencies": {
            "type": "array",
            "items": { "type": "string" },
            "description": "Step IDs that must complete first"
          },
          "rollback": {
            "type": "object",
            "properties": {
              "strategy": { "type": "string", "enum": ["git_reset", "git_revert", "manual"] },
              "commands": { "type": "array", "items": { "type": "string" } }
            }
          }
        }
      }
    },

    "execution_state": {
      "type": "object",
      "properties": {
        "current_step": { "type": "string" },
        "steps_completed": { "type": "array", "items": { "type": "string" } },
        "steps_failed": { "type": "array", "items": { "type": "string" } },
        "commits": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "step_id": { "type": "string" },
              "commit_hash": { "type": "string" },
              "committed_at": { "type": "string", "format": "date-time" },
              "metric_before": {},
              "metric_after": {},
              "files_changed": { "type": "array", "items": { "type": "string" } }
            }
          }
        }
      }
    }
  }
}
```

### 2.3 Merge Report Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "merge-report.schema.json",
  "title": "ACIS Batch Merge Report",

  "properties": {
    "batch_id": { "type": "string" },
    "started_at": { "type": "string", "format": "date-time" },
    "completed_at": { "type": "string", "format": "date-time" },

    "integration_branch": {
      "type": "object",
      "properties": {
        "name": { "type": "string" },
        "base_commit": { "type": "string" },
        "final_commit": { "type": "string" },
        "total_commits": { "type": "integer" }
      }
    },

    "goal_merges": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "goal_id": { "type": "string" },
          "status": {
            "type": "string",
            "enum": ["merged", "partial", "conflict", "skipped"]
          },
          "merge_type": {
            "type": "string",
            "enum": ["regular", "cherry_pick", "rebase"]
          },
          "commits_merged": { "type": "integer" },
          "commits_total": { "type": "integer" },
          "conflict_details": {
            "type": "object",
            "properties": {
              "type": { "type": "string", "enum": ["trivial", "partial", "semantic", "unresolvable"] },
              "files": { "type": "array", "items": { "type": "string" } },
              "conflicting_goal": { "type": "string" },
              "resolution": { "type": "string" }
            }
          },
          "metric_progress": {
            "type": "object",
            "properties": {
              "before": {},
              "after": {},
              "target": {}
            }
          }
        }
      }
    },

    "verification": {
      "type": "object",
      "properties": {
        "detection_commands_passed": { "type": "boolean" },
        "tests_passed": { "type": "boolean" },
        "build_passed": { "type": "boolean" },
        "failures": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "type": { "type": "string" },
              "message": { "type": "string" },
              "goal_id": { "type": "string" }
            }
          }
        }
      }
    },

    "squash_to_main": {
      "type": "object",
      "properties": {
        "status": { "type": "string", "enum": ["success", "failed", "skipped"] },
        "commit": { "type": "string" },
        "message": { "type": "string" }
      }
    },

    "summary": {
      "type": "object",
      "properties": {
        "goals_complete": { "type": "integer" },
        "goals_partial": { "type": "integer" },
        "goals_failed": { "type": "integer" },
        "new_goals_created": { "type": "array", "items": { "type": "string" } },
        "worktrees_cleaned": { "type": "integer" },
        "worktrees_preserved": { "type": "integer" }
      }
    }
  }
}
```

---

## 3. Workflow Specification

### 3.1 Phase 0: Planning & Safety Check

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 0: PARALLEL SAFETY ANALYSIS                                           │
└─────────────────────────────────────────────────────────────────────────────┘

Input: Goal IDs to remediate in parallel
Output: Parallel execution plan with disjoint groups

Steps:
  1. LOAD GOALS
     for goal_id in $GOAL_IDS:
       goal = read_goal_file("${config.paths.goals}/${goal_id}.json")
       goals[goal_id] = goal

  2. EXTRACT AFFECTED FILES
     for goal_id, goal in goals:
       files = []
       files += goal.detection.search_paths
       files += run_detection_and_extract_files(goal.detection.primary_command)
       affected_files[goal_id] = files

  3. BUILD CONFLICT MATRIX
     for goal_a in goals:
       for goal_b in goals:
         if goal_a != goal_b:
           overlap = affected_files[goal_a] ∩ affected_files[goal_b]
           if overlap:
             conflicts[goal_a][goal_b] = overlap

  4. COMPUTE PARALLEL GROUPS
     groups = graph_coloring(conflicts)  # Disjoint sets

  5. OUTPUT PLAN
     write_batch_state("${config.paths.state}/parallel/BATCH-${WO}-${NNN}.json")
     present_plan_to_user()
```

### 3.2 Phase 1: Worktree Setup

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: WORKTREE ISOLATION                                                  │
└─────────────────────────────────────────────────────────────────────────────┘

For each goal in current parallel group:

  1. CREATE WORKTREE
     git worktree add .acis-work/${goal_id} -b acis/${goal_id} main

  2. VERIFY WORKTREE
     cd .acis-work/${goal_id}
     git status  # Should be clean
     git log -1  # Should match main HEAD

  3. REGISTER WORKTREE
     update worktree-registry.json:
       {
         "goal_id": "${goal_id}",
         "worktree_path": ".acis-work/${goal_id}",
         "branch": "acis/${goal_id}",
         "created_at": "${timestamp}",
         "status": "active"
       }

  4. CREATE STEP MANIFEST
     decompose_goal_into_steps(goal)
     write_step_manifest("${config.paths.state}/steps/${goal_id}/manifest.json")
```

### 3.3 Phase 2: Parallel Execution

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: PARALLEL STEP EXECUTION                                             │
└─────────────────────────────────────────────────────────────────────────────┘

For each goal (in parallel via separate agents):

  AGENT CONTEXT:
    - Working directory: .acis-work/${goal_id}/
    - Branch: acis/${goal_id}
    - State file: ${config.paths.state}/steps/${goal_id}/manifest.json

  For each step in manifest.steps:

    1. CHECK DEPENDENCIES
       if step.dependencies not all complete:
         wait or fail

    2. EXECUTE STEP
       run step.action with step.scope

    3. VERIFY STEP
       result = run(step.verification.command)
       if result != step.verification.expected_after:
         mark_step_failed(step)
         decide: retry | skip | abort

    4. COMMIT STEP
       git add ${step.scope.files}
       git commit -m "[${step.step_id}] ${step.action}: ${step.description}

       Metric: ${before} → ${after} (target: ${target})"

    5. UPDATE STATE
       update manifest.execution_state:
         - steps_completed += step.step_id
         - commits += { step_id, commit_hash, metrics }

    6. CHECKPOINT
       push to origin (optional, for recovery)
       git push origin acis/${goal_id}
```

### 3.4 Phase 3: Integration Branch Merge

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: INTEGRATION BRANCH ASSEMBLY                                         │
└─────────────────────────────────────────────────────────────────────────────┘

1. CREATE INTEGRATION BRANCH
   git checkout -b acis/integrate-${WO}-batch-${NNN} main

2. MERGE GOAL BRANCHES (sequential, preserve atomic history)
   for goal_id in batch.goals (ordered by priority):

     attempt_merge:
       git merge acis/${goal_id} --no-ff -m "Merge ${goal_id}"

     if CONFLICT:
       conflict_type = classify_conflict()

       switch conflict_type:
         case TRIVIAL:
           auto_resolve()
           continue_merge()

         case PARTIAL:
           git merge --abort
           cherry_pick_successful_steps()
           create_new_goal_for_remaining_steps()

         case SEMANTIC:
           preserve_worktree()
           attempt_rebase_and_retry()
           if still_fails:
             flag_for_human_review()

         case UNRESOLVABLE:
           preserve_all_work()
           generate_conflict_report()
           notify_user()

     verify_after_merge:
       run detection_command for goal
       if regression:
         git revert HEAD
         investigate()

3. VERIFY INTEGRATION BRANCH
   run_all_detection_commands()
   run_tests()
   run_build()

   if any_failure:
     bisect_to_find_cause()
     # Atomic history preserved, can identify exact commit
```

### 3.5 Phase 4: Squash to Main

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: SQUASH TO MAIN + CLEANUP                                            │
└─────────────────────────────────────────────────────────────────────────────┘

1. FINAL VERIFICATION
   cd (back to main worktree)
   git checkout acis/integrate-${WO}-batch-${NNN}
   run_full_verification_suite()

   if PASS:
     proceed_to_squash()
   else:
     abort_and_report()

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

4. CLEANUP WORKTREES
   for goal_id in batch.goals:
     if goal.status == complete:
       git worktree remove .acis-work/${goal_id}
       git branch -d acis/${goal_id}
     else:
       # Preserve for debugging
       log("Preserving worktree for ${goal_id}: status=${goal.status}")

   git branch -d acis/integrate-${WO}-batch-${NNN}

5. GENERATE REPORT
   write_merge_report("${config.paths.state}/merge-reports/BATCH-${WO}-${NNN}-report.json")
   write_merge_report_md("${config.paths.state}/merge-reports/BATCH-${WO}-${NNN}-report.md")

6. UPDATE GOAL STATUS
   for goal_id in batch.goals:
     if goal.status == complete:
       update goal.progress.status = "achieved"
       update goal.achievement_verification = { ... }
```

---

## 4. Command Interface

### 4.1 New Command: `/acis:remediate-parallel`

```bash
# Basic parallel execution
/acis:remediate-parallel WO63-CRIT-001 WO63-HIGH-002 WO63-MED-003

# With explicit work order context
/acis:remediate-parallel --wo WO63 --goals CRIT-001,HIGH-002,MED-003

# Dry run - show plan without executing
/acis:remediate-parallel WO63-CRIT-001 WO63-HIGH-002 --dry-run

# Force parallel (ignore conflict warnings)
/acis:remediate-parallel WO63-CRIT-001 WO63-HIGH-002 --force-parallel

# Resume existing batch
/acis:remediate-parallel --resume BATCH-WO63-001

# Status of running batch
/acis:remediate-parallel --status BATCH-WO63-001
```

### 4.2 Flags

| Flag | Description |
|------|-------------|
| `--wo <id>` | Work order context |
| `--goals <list>` | Comma-separated goal suffixes |
| `--dry-run` | Show plan without executing |
| `--force-parallel` | Ignore file conflict warnings |
| `--resume <batch-id>` | Resume existing batch |
| `--status <batch-id>` | Show batch status |
| `--max-parallel <n>` | Limit concurrent worktrees (default: 4) |
| `--step-size <n>` | Max files per step (default: 3) |
| `--preserve-worktrees` | Don't cleanup worktrees after success |
| `--skip-squash` | Leave as merge commits on main |
| `--push-branches` | Push goal branches to origin for backup |

---

## 5. Files to Create/Modify

### 5.1 New Files

| File | Description |
|------|-------------|
| `schemas/parallel-batch.schema.json` | Batch state schema |
| `schemas/step-manifest.schema.json` | Step decomposition schema |
| `schemas/merge-report.schema.json` | Merge report schema |
| `commands/remediate-parallel.md` | Parallel remediation command |
| `ralph-profiles/parallel-remediation.json` | Ralph loop profile |
| `templates/step-manifest-template.json` | Step manifest example |
| `templates/batch-state-template.json` | Batch state example |

### 5.2 Modified Files

| File | Changes |
|------|---------|
| `commands/remediate.md` | Add `--parallel` flag that delegates to remediate-parallel |
| `schemas/acis-goal.schema.json` | Add `parallel_execution` and `step_decomposition` fields |
| `schemas/project-config.schema.json` | Add `paths.steps`, `paths.parallel`, `paths.merge-reports` |

---

## 6. Implementation Order

| Phase | Task | Priority |
|-------|------|----------|
| **1** | Create schemas (batch, step, merge-report) | High |
| **2** | Create `remediate-parallel.md` command | High |
| **3** | Create `parallel-remediation.json` ralph profile | High |
| **4** | Update project-config schema with new paths | Medium |
| **5** | Update goal schema with parallel fields | Medium |
| **6** | Create template files | Low |
| **7** | Update main remediate.md with --parallel delegation | Low |

---

## 7. Safety Guarantees

| Guarantee | How Achieved |
|-----------|--------------|
| **Baseline never corrupted** | All work in worktrees, main only receives verified squashes |
| **Atomic rollback** | Each step is one commit, can `git reset` |
| **Conflict visibility** | Full atomic history in integration branch |
| **Cherry-pick viable** | Regular merges to integration, not squash |
| **Debugging possible** | Tags preserve all history for 30 days |
| **No overwrite collisions** | File disjointness check before parallelizing |
| **Recovery from any point** | State files checkpoint every step |

---

## 8. Example Session

```
$ /acis:remediate-parallel WO63-CRIT-001-key-rotation WO63-HIGH-002-math-random WO63-MED-003-console-log

╔══════════════════════════════════════════════════════════════════════════════╗
║  PARALLEL REMEDIATION PLAN: BATCH-WO63-001                                   ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  📋 GOALS ANALYZED: 3                                                        ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  WO63-CRIT-001-key-rotation                                                  ║
║    Files: src/auth/keys.ts, src/crypto/rotation.ts                          ║
║    Steps: 4 (detect → fix-keys → fix-rotation → verify)                     ║
║                                                                              ║
║  WO63-HIGH-002-math-random                                                   ║
║    Files: src/utils/random.ts, src/session/token.ts, src/cache/id.ts        ║
║    Steps: 5 (detect → fix-utils → fix-session → fix-cache → verify)         ║
║                                                                              ║
║  WO63-MED-003-console-log                                                    ║
║    Files: src/logging/*.ts                                                   ║
║    Steps: 3 (detect → fix-logging → verify)                                 ║
║                                                                              ║
║  🔍 CONFLICT ANALYSIS                                                        ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  ✓ No file conflicts detected                                                ║
║  ✓ All 3 goals can run in parallel                                          ║
║                                                                              ║
║  📊 EXECUTION PLAN                                                           ║
║  ─────────────────────────────────────────────────────────────────────────── ║
║                                                                              ║
║  Parallel Group 1: [CRIT-001, HIGH-002, MED-003]                            ║
║  Worktrees: 3                                                                ║
║  Integration: acis/integrate-WO63-batch-001                                 ║
║  Final: Squash to main                                                       ║
║                                                                              ║
║  Proceed? [Y/n]                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

*Document Version: 1.0*
*Last Updated: 2026-01-28*
