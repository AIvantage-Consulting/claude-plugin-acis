# ACIS Implement Parallel - Build Subsystems from GENESIS Specs

You are executing the ACIS implement-parallel command. This builds new subsystems in parallel using git worktrees, driven by GENESIS architecture output. It bridges the gap between conceptual architecture (GENESIS) and running code.

## Arguments

- `$ARGUMENTS` - Flags and options for implementation execution

## Key Differences from remediate-parallel

| Aspect | `remediate-parallel` | `implement-parallel` |
|--------|---------------------|---------------------|
| **Input** | Goal JSON files (detection commands) | GENESIS output directory (`docs/genesis/`) |
| **Nature** | Fix existing code (reduce violations) | Build new code (create subsystems) |
| **Detection** | Pattern count → target (usually 0) | File/module existence + tests pass |
| **Decomposition** | By affected files | By subsystem boundaries |
| **Verification** | Detection command passes | Build succeeds, tests pass, API surface exists |
| **Naming** | `BATCH-{WO}-{NNN}` | `IMPL-{project}-{NNN}` |
| **State schema** | `parallel-batch.schema.json` | `implementation-batch.schema.json` |

## Schema References

- **Implementation Spec**: `${CLAUDE_PLUGIN_ROOT}/schemas/implementation-spec.schema.json`
- **Implementation Batch**: `${CLAUDE_PLUGIN_ROOT}/schemas/implementation-batch.schema.json`
- **Step Manifest**: `${CLAUDE_PLUGIN_ROOT}/schemas/step-manifest.schema.json` (reused)
- **Merge Report**: `${CLAUDE_PLUGIN_ROOT}/schemas/merge-report.schema.json` (reused)
- **GENESIS Conversion Template**: `${CLAUDE_PLUGIN_ROOT}/templates/genesis-to-specs.md`
- **Implementation Preferences**: `${CLAUDE_PLUGIN_ROOT}/interview/implementation-preferences.json`

## Naming Conventions

| Entity | Pattern | Example |
|--------|---------|---------|
| **Batch ID** | `IMPL-{project}-{NNN}` | `IMPL-careai-001` |
| **Spec ID** | `SPEC-{subsystem}` | `SPEC-auth-service` |
| **Step ID** | `SPEC-{subsystem}-S{NN}` | `SPEC-auth-service-S01` |
| **Branch** | `acis/impl/{spec-id}` | `acis/impl/SPEC-auth-service` |
| **Integration** | `acis/integrate-impl-{project}-{NNN}` | `acis/integrate-impl-careai-001` |
| **Worktree** | `.acis-work/impl/{spec-id}/` | `.acis-work/impl/SPEC-auth-service/` |
| **Step Commit** | `[{step-id}] impl: {description}` | `[SPEC-auth-service-S01] impl: create directory structure and types` |

## Flags

| Flag | Description |
|------|-------------|
| `--genesis <path>` | Path to GENESIS output directory (default: `docs/genesis/`) |
| `--specs-only` | Generate implementation specs without executing |
| `--dry-run` | Show plan without executing |
| `--yes` | Skip confirmation prompts |
| `--max-parallel <n>` | Limit concurrent worktrees (default: 4) |
| `--resume <batch-id>` | Resume existing implementation batch |
| `--status <batch-id>` | Show batch status |
| `--skip-tests` | Skip test verification during implementation |
| `--subsystems <list>` | Implement only specific subsystems (comma-separated) |
| `--preserve-worktrees` | Don't cleanup worktrees after success |
| `--cleanup` | Manual worktree sweep |
| `--skip-interview` | Skip preference interview (use saved or defaults) |

## Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│              ACIS PARALLEL IMPLEMENTATION PIPELINE                           │
└─────────────────────────────────────────────────────────────────────────────┘

Phase 0: SPEC EXTRACTION        Parse GENESIS output → implementation specs
           │
           ▼
Phase 0.1: PREFERENCES INTERVIEW  Collect "what" and "how" preferences
           │                       (skipped with --skip-interview or saved prefs)
           ▼
Phase 0.5: DEPENDENCY ANALYSIS  Build dependency graph, topological sort
           │
           ▼
Phase 1: WORKTREE SETUP         Create isolated worktrees per spec
           │
           ▼
Phase 2: PARALLEL IMPLEMENTATION Build subsystems in parallel worktrees
           │                     Atomic commits per step, verification
           ▼
Phase 3: INTEGRATION MERGE      Sequential merge by dependency order
           │                     Cross-subsystem integration tests
           ▼
Phase 4: SQUASH TO MAIN         Final verification → squash merge → cleanup
           │
           ▼
       COMPLETE                  Generate report, update spec status
```

## Phase Details

### Phase 0: SPEC EXTRACTION

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 0: SPEC EXTRACTION FROM GENESIS                                       │
└─────────────────────────────────────────────────────────────────────────────┘

1. LOCATE GENESIS OUTPUT
   genesis_dir="${ARGUMENTS.genesis || 'docs/genesis/'}"

   Required files:
   - ${genesis_dir}/SUBSYSTEMS_DRAFT.md
   - ${genesis_dir}/ARCHITECTURE_DRAFT.md

   Optional files:
   - ${genesis_dir}/ADR-*.md
   - ${genesis_dir}/JOURNEYS_DRAFT.md
   - ${genesis_dir}/PERSONAS_DRAFT.md

2. VALIDATE GENESIS DIRECTORY
   if [ ! -d "$genesis_dir" ]; then
     echo "ERROR: GENESIS directory not found: $genesis_dir"
     echo "Run /acis:genesis first, or specify --genesis <path>"
     exit 1
   fi

   if [ ! -f "${genesis_dir}/SUBSYSTEMS_DRAFT.md" ]; then
     echo "ERROR: SUBSYSTEMS_DRAFT.md not found in $genesis_dir"
     echo "This file is required for spec extraction."
     exit 1
   fi

3. EXTRACT SPECS
   Read the GENESIS conversion template:
   @${CLAUDE_PLUGIN_ROOT}/templates/genesis-to-specs.md

   For each subsystem in SUBSYSTEMS_DRAFT.md:
   - Generate spec_id: SPEC-{kebab-case-name}
   - Extract subsystem description
   - Cross-reference ARCHITECTURE_DRAFT.md for boundaries
   - Cross-reference ADRs for constraints
   - Cross-reference JOURNEYS_DRAFT.md for acceptance criteria
   - Determine complexity tier
   - Generate implementation-spec JSON

4. APPLY SUBSYSTEM FILTER (if --subsystems provided)
   Filter specs to only include named subsystems

5. WRITE SPEC FILES
   spec_dir="${config.paths.state}/impl-specs"
   mkdir -p "$spec_dir"

   For each spec:
     Write ${spec_dir}/${spec_id}.json
     Validate against implementation-spec.schema.json

6. PRESENT SPECS TO USER
   Display table:
   ╔══════════════════════════════════════════════════════════════════════════╗
   ║  IMPLEMENTATION SPECS EXTRACTED                                         ║
   ╠══════════════════════════════════════════════════════════════════════════╣
   ║                                                                         ║
   ║  Spec ID              Subsystem        Tier  Dependencies  Files        ║
   ║  ────────────────────  ───────────────  ────  ────────────  ─────        ║
   ║  SPEC-auth-service     Auth Service     2     none          5            ║
   ║  SPEC-sync-engine      Sync Engine      3     auth-service  8            ║
   ║  SPEC-offline-store    Offline Store    2     none          4            ║
   ║                                                                         ║
   ╚══════════════════════════════════════════════════════════════════════════╝

   If --specs-only: EXIT here (specs written, no execution)
   If --dry-run: Show full plan, then EXIT

   Otherwise:
   AskUserQuestion: "Proceed with implementation?"
   Options: [Proceed, Modify specs first, Cancel]
```

### Phase 0.1: IMPLEMENTATION PREFERENCES INTERVIEW

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 0.1: IMPLEMENTATION PREFERENCES ("WHAT" + "HOW")                      │
└─────────────────────────────────────────────────────────────────────────────┘

This phase collects user preferences that govern WHAT gets built and HOW
code is written. Every "how" preference becomes an enforceable check that
BLOCKS non-compliant steps. This is NOT optional governance — it is
systemic enforcement baked into the pipeline.

SKIP CONDITIONS:
  - If --skip-interview flag: use saved preferences from .acis-config.json
    or fall back to defaults from the question bank
  - If --resume: load preferences from existing batch state
  - If .acis-config.json has implementationPreferences: ask user
    "Use saved preferences? [Yes / Modify / Start fresh]"

1. LOAD QUESTION BANK
   Read @${CLAUDE_PLUGIN_ROOT}/interview/implementation-preferences.json

2. AUTO-DETECT DEFAULTS
   Run autoDetection.checks (Bash 3.2 compatible) to pre-fill:
   - platform.language (from tsconfig.json / jsconfig.json)
   - platform.packageManager (from lock files)
   - platform.testFramework (from package.json devDependencies)
   - codingStyle.semicolons (from .eslintrc)
   - codingStyle.quoteStyle (from .prettierrc)
   - platform.monorepo (from workspace config)

   Pre-fill detected values as question defaults.

3. RUN INTERVIEW PHASES
   For each phase (1-5) in the question bank:
     For each question in phase.questions:
       Use AskUserQuestion with:
         - question: question.question
         - header: question.header
         - options: question.options (label + description)
         - multiSelect: (question.type == "multi")

       Store answer in implementation_preferences object

       If answer triggers follow-ups (question.followUps):
         Ask follow-up questions via AskUserQuestion

   Phase 1: WHAT to build — scope, MVP, priorities, stubs, feature flags
   Phase 2: HOW — coding style, naming, organization, imports, exports
   Phase 3: HOW — error handling, logging, debug tracing
   Phase 4: HOW — SOLID adherence, DRY strategy, testing approach
   Phase 5: HOW — platform, package manager, test framework, extra config

4. BUILD ENFORCEMENT RULESET
   From the collected "how" preferences, build the enforcement ruleset:

   For each preference in [codingStyle, errorHandling, logging, debugging,
                           designPrinciples, testing, platform]:
     Look up the corresponding check in enforcement.preferenceChecks
     Substitute the user's chosen value to get the concrete check command
     Store as: { check_id, shell_command_or_agent_review, pass_condition, fix_instruction }

   The enforcement ruleset is stored in the batch state and executed
   after EVERY step commit in Phase 2.

5. CONFIRM AND STORE
   Display summary of collected preferences:
   ╔══════════════════════════════════════════════════════════════════════════╗
   ║  IMPLEMENTATION PREFERENCES                                            ║
   ╠══════════════════════════════════════════════════════════════════════════╣
   ║                                                                        ║
   ║  WHAT TO BUILD:                                                        ║
   ║    MVP Scope:     All subsystems                                       ║
   ║    Priority:      Dependency order                                     ║
   ║    Stubs:         Interface stubs for deferred                         ║
   ║    Feature Flags: Environment variables                                ║
   ║    Deliverables:  Code + Tests + Types                                 ║
   ║                                                                        ║
   ║  HOW TO BUILD (enforced after every step):                             ║
   ║    File Naming:   kebab-case                    [ENFORCED]             ║
   ║    Code Org:      Feature-based                 [ENFORCED]             ║
   ║    Imports:       Path aliases (@/)             [ENFORCED]             ║
   ║    Exports:       Named exports only            [ENFORCED]             ║
   ║    Errors:        Typed error classes            [ENFORCED]             ║
   ║    Logging:       Structured (pino/winston)     [ENFORCED]             ║
   ║    Tracing:       Boundary tracing              [ENFORCED]             ║
   ║    SOLID:         Pragmatic                     [ENFORCED]             ║
   ║    DRY:           Rule of three                 [ENFORCED]             ║
   ║    Testing:       Test alongside                [ENFORCED]             ║
   ║    Language:      TypeScript (strict)           [ENFORCED]             ║
   ║                                                                        ║
   ║  Enforcement: ALL "how" preferences are verified after each step.      ║
   ║  Violations BLOCK the step — agents must fix before commit.            ║
   ║                                                                        ║
   ╚══════════════════════════════════════════════════════════════════════════╝

   Store in batch state: batch.implementation_preferences
   Optionally save to .acis-config.json for reuse:
     AskUserQuestion: "Save preferences for future runs?"
     Options: [Yes, No]
```

### Phase 0.5: DEPENDENCY ANALYSIS

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 0.5: DEPENDENCY ANALYSIS                                              │
└─────────────────────────────────────────────────────────────────────────────┘

1. BUILD DEPENDENCY GRAPH
   For each spec:
     Read spec.boundary.dependencies
     Add edges: dependency → dependent

2. DETECT CYCLES
   If cycle detected:
     echo "ERROR: Circular dependency detected:"
     echo "  SPEC-A → SPEC-B → SPEC-C → SPEC-A"
     echo "Fix dependencies in spec files before proceeding."
     exit 1

3. TOPOLOGICAL SORT
   Compute build order using topological sort
   Store in batch.dependency_graph.topological_order

4. COMPUTE PARALLEL GROUPS
   Level 0: Specs with no dependencies (roots)
   Level 1: Specs whose dependencies are all in Level 0
   Level N: Specs whose dependencies are all in Levels 0..N-1

   Each level = one parallel group (can execute simultaneously)

5. PRESENT PARALLEL GROUPS TO USER
   ╔══════════════════════════════════════════════════════════════════════════╗
   ║  IMPLEMENTATION ORDER                                                    ║
   ╠══════════════════════════════════════════════════════════════════════════╣
   ║                                                                         ║
   ║  Group 1 (parallel):                                                    ║
   ║    SPEC-auth-service, SPEC-offline-store                                ║
   ║                                                                         ║
   ║  Group 2 (parallel, after Group 1):                                     ║
   ║    SPEC-sync-engine, SPEC-api-client                                    ║
   ║                                                                         ║
   ║  Group 3 (after Group 2):                                               ║
   ║    SPEC-app-shell                                                       ║
   ║                                                                         ║
   ╚══════════════════════════════════════════════════════════════════════════╝

6. CREATE BATCH STATE
   Generate batch_id: IMPL-{project_name}-{NNN}
   Write ${config.paths.state}/parallel/IMPL-{project}-{NNN}.json
   Validate against implementation-batch.schema.json
```

### Phase 1: WORKTREE SETUP (Reused from remediate-parallel)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: WORKTREE ISOLATION                                                  │
└─────────────────────────────────────────────────────────────────────────────┘

For each spec in current parallel group:

1. CREATE WORKTREE
   git worktree add .acis-work/impl/${spec_id} -b acis/impl/${spec_id} main

2. VERIFY WORKTREE
   cd .acis-work/impl/${spec_id}
   git status  # Must be clean
   git log -1  # Must match main HEAD

3. REGISTER WORKTREE
   Update ${config.paths.state}/parallel/worktree-registry.json

4. DECOMPOSE INTO STEPS
   Analyze spec scope:
   - Step 1: Create directory structure
   - Step 2: Create type definitions / interfaces
   - Step 3-N: Implement core logic (one step per major file/module)
   - Step N+1: Create tests
   - Step N+2: Wire up exports / public API

   Write step manifest: ${config.paths.state}/steps/${spec_id}/manifest.json
   Validate against step-manifest.schema.json
```

### Phase 2: PARALLEL IMPLEMENTATION

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: PARALLEL SUBSYSTEM IMPLEMENTATION                                   │
└─────────────────────────────────────────────────────────────────────────────┘

For each parallel group (sequential between groups):
  For each spec in group (parallel via separate Task agents):

    AGENT CONTEXT:
      - Working directory: .acis-work/impl/${spec_id}/
      - Branch: acis/impl/${spec_id}
      - Spec: @${config.paths.state}/impl-specs/${spec_id}.json
      - GENESIS context: @${genesis_dir}/SUBSYSTEMS_DRAFT.md
      - ADR constraints: @${genesis_dir}/ADR-*.md (relevant ones)
      - Step manifest: @${config.paths.state}/steps/${spec_id}/manifest.json
      - Implementation preferences: @batch.implementation_preferences
      - Enforcement ruleset: @batch.enforcement_ruleset

    AGENT PROMPT:
      "Implement subsystem ${subsystem_name} according to the spec.

       Spec: @{spec_file}
       GENESIS Subsystems: @{SUBSYSTEMS_DRAFT.md}
       Architecture: @{ARCHITECTURE_DRAFT.md}
       ADR Constraints: @{relevant ADR files}

       IMPLEMENTATION PREFERENCES (MANDATORY — violations will block your commits):
       - File naming: ${preferences.codingStyle.fileNaming}
       - Code organization: ${preferences.codingStyle.codeOrganization}
       - Import style: ${preferences.codingStyle.importStyle}
       - Export style: ${preferences.codingStyle.exportStyle}
       - Error handling: ${preferences.errorHandling.strategy}
       - Logging: ${preferences.logging.approach} (NO raw console.* in production code)
       - Debug tracing: ${preferences.debugging.traceLevel}
       - SOLID: ${preferences.designPrinciples.solidAdherence}
       - DRY: ${preferences.designPrinciples.dryStrategy}
       - Testing: ${preferences.testing.strategy}
       - Language: ${preferences.platform.language}

       These are NOT suggestions. Every preference above is verified after each
       step via a Three-Tier Enforcement Engine:
       - T1: Comment-stripped pattern matching (fast, catches naming/logging)
       - T2: AST structural analysis (TypeScript API, catches imports/exports/types/errors)
       - T3: Schema-constrained agent review (semantic, catches SOLID/DRY/design patterns)

       If your code violates ANY preference, the commit will be REJECTED and
       you must fix it before proceeding. Violations include file:line evidence.

       Follow the step manifest. For each step:
       1. Create/modify files following the preferences above
       2. Ensure code compiles (run build_command)
       3. Create tests for the functionality
       4. Commit atomically with message: [${step_id}] impl: {description}

       Constraints:
       - Respect ADR constraints listed in the spec
       - Follow the implementation preferences exactly
       - Create tests alongside implementation
       - Public API must match spec.boundary.exports

       Return: { result: success|partial|blocked, filesCreated, filesModified, testsCreated, notes }"

    For each step in manifest.steps:

      1. EXECUTE STEP
         Create directory structure, files, implementation
         Follow spec.boundary, GENESIS architecture, AND implementation preferences

      2. VERIFY STEP — FUNCTIONAL (unless --skip-tests)
         Run spec.verification.build_command
         Run spec.verification.test_command (if tests exist for this step)
         Run spec.verification.lint_command (if applicable)

      3. VERIFY STEP — THREE-TIER PREFERENCE ENFORCEMENT
         Load enforcement engine: configs/enforcement-engine.json
         Load script library: templates/ast-verification-scripts.md

         STEP 3a. TIER PREREQUISITE CHECK (once per worktree):
           T2_AVAILABLE = node -e "try{require('typescript');process.exit(0)}catch(e){process.exit(1)}"
           NPX_AVAILABLE = which npx >/dev/null 2>&1
           If T2 not available: WARN "TypeScript not found. T2 checks will fall back to T1."

         STEP 3b. TWO-STAGE DETECTION (if > 5 changed files):
           Stage 1 — T1 fast filter on ALL changed files:
             For each changed file (non-test, non-spec):
               Strip comments: node -e "...comment strip..." ${file}
               Check patterns for each T1-eligible check
               IF match → add to candidates list

           Stage 2 — T2/T3 verification on CANDIDATES ONLY:
             For each candidate file:
               Run the check at its recommendedTier (T2 or T3)

         STEP 3c. EXECUTE CHECKS PER TIER:

           For each check in enforcement_ruleset:
             tier = check.recommendedTier

             IF tier == "T1" (comment-stripped pattern matching):
               Strip comments from each file via node -e
               Run pattern match on stripped source
               IF output is non-empty → VIOLATION (with file:line evidence)

             ELIF tier == "T2" (AST structural analysis):
               IF T2_AVAILABLE:
                 Run AST script from ast-verification-scripts.md
                 Uses TypeScript API: node -e "const ts=require('typescript')..."
                 IF exit code 1 → VIOLATION (with AST-derived file:line evidence)
               ELSE:
                 WARN "Falling back to T1 for ${check.check_id}"
                 Run T1 command instead

             ELIF tier == "T3" (schema-constrained agent review):
               Agent reviews code with MANDATORY JSON output:
               {
                 "verdict": "PASS" | "FAIL",
                 "violations": [{ file, line, rule, description, severity, suggested_fix }],
                 "confidence": 0.0-1.0,
                 "evidence": ["specific code citations"]
               }

               VALIDATE agent output:
                 IF not valid JSON → WARN, fall back to T2
                 IF verdict not in [PASS, FAIL] → WARN, fall back to T2
                 IF confidence < 0.7 → Cross-verify with T2 before accepting

               IF verdict == "FAIL" → VIOLATION (with agent evidence)

         STEP 3d. VIOLATION HANDLING:

         IF violations found:
           a. Collect all violations into structured report:
              [{ check, preference, tier, violation, file, line, fixInstruction, evidence }]
           b. Agent receives violation report with tier-specific evidence
           c. Agent MUST fix all violations in the same worktree
           d. Return to step 3c (re-run ONLY failed checks, not all checks)
           e. Maximum 3 retry attempts per step

         IF max retries exceeded:
           Mark step as 'blocked' with violation details
           Record in batch.compliance.blocked_steps
           Record tier usage statistics
           Notify user: "Step ${step_id} blocked after 3 preference enforcement attempts"
           Continue to next step

      4. COMMIT STEP (atomic) — only after ALL checks pass
         git add ${created_and_modified_files}
         git commit -m "[${step_id}] impl: ${step.description}

         Subsystem: ${subsystem_name}
         Files: ${file_count} created/modified
         Preference compliance: PASS"

      5. UPDATE STATE
         Mark step complete in manifest
         Record commit hash
         Record compliance result (checks_run, checks_passed, retries_needed)
         Update batch state

    After all steps for spec:

      FINAL VERIFICATION:
        Run all verification commands from spec.verification
        Check acceptance criteria
        Verify API surface matches spec.boundary.exports

      UPDATE SPEC STATUS:
        If all pass: status = "complete"
        If partial: status = "blocked" with details
```

### Phase 3: INTEGRATION MERGE (Reused from remediate-parallel, adapted)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: INTEGRATION BRANCH ASSEMBLY                                         │
└─────────────────────────────────────────────────────────────────────────────┘

1. CREATE INTEGRATION BRANCH
   git checkout -b acis/integrate-impl-${project}-${NNN} main

2. MERGE SPEC BRANCHES (sequential, in dependency order)
   for spec_id in batch.dependency_graph.topological_order:

     ATTEMPT MERGE:
       git merge acis/impl/${spec_id} --no-ff -m "Merge ${spec_id}: ${subsystem_name}"

     IF CONFLICT → CLASSIFY AND HANDLE:
       (Same conflict resolution as remediate-parallel)

       TRIVIAL: Auto-resolve
       PARTIAL: Cherry-pick clean commits
       SEMANTIC: Rebase attempt → human review
       UNRESOLVABLE: Preserve work, notify user

     VERIFY AFTER EACH MERGE:
       Run spec.verification.build_command
       If regression: git revert HEAD → investigate

3. CROSS-SUBSYSTEM INTEGRATION TESTS
   After all specs merged:
   - Run full project build
   - Run full test suite
   - Verify cross-subsystem communication patterns work
   - Check that all acceptance criteria pass

   If any failure:
     git bisect to find causing merge
     Report which subsystem integration failed
```

### Phase 4: SQUASH TO MAIN + CLEANUP (Reused from remediate-parallel)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: SQUASH TO MAIN + CLEANUP                                            │
└─────────────────────────────────────────────────────────────────────────────┘

1. FINAL VERIFICATION
   Checkout integration branch
   Run full verification suite
   Run all acceptance criteria checks

2. PRESERVE HISTORY (before squashing)
   git tag acis/history/IMPL-${project}-${NNN} acis/integrate-impl-${project}-${NNN}

   for spec_id in batch.specs:
     git tag acis/archive/${spec_id} acis/impl/${spec_id}

3. SQUASH MERGE TO MAIN
   git checkout main
   git merge --squash acis/integrate-impl-${project}-${NNN}
   git commit -m "[ACIS] ${BATCH_ID}: ${spec_count} subsystems implemented

   Subsystems:
   - ${spec_1_id}: ${spec_1_subsystem_name}
   - ${spec_2_id}: ${spec_2_subsystem_name}
   ...

   Source: GENESIS output from ${genesis_dir}
   Total: ${files_created} files created, ${files_modified} files modified"

4. AUTOMATIC WORKTREE CLEANUP
   for spec_id in batch.specs:
     if spec.status == 'complete':
       git worktree remove .acis-work/impl/${spec_id}
       git branch -d acis/impl/${spec_id}
     elif spec.status == 'blocked':
       AskUserQuestion: "Spec ${spec_id} is blocked. Keep worktree?"
       Handle response
     else:
       Preserve worktree

   git worktree prune
   git branch -d acis/integrate-impl-${project}-${NNN}

5. GENERATE REPORT
   Write implementation report (see Output Report below)
   Update spec status files
```

## Handling `--resume` and `--status`

### `--resume <batch-id>`

```
1. Read batch state: ${config.paths.state}/parallel/${batch_id}.json
2. Identify incomplete specs
3. Re-enter pipeline at the appropriate phase:
   - If specs not all extracted → Phase 0
   - If worktrees not all set up → Phase 1
   - If execution incomplete → Phase 2
   - If integration not done → Phase 3
   - If squash not done → Phase 4
4. Continue from where interrupted
```

### `--status <batch-id>`

```
Display batch status:
╔══════════════════════════════════════════════════════════════════════════════╗
║  IMPLEMENTATION STATUS: IMPL-careai-001                                      ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  Phase: EXECUTING (Phase 2)                                                  ║
║  Created: 2026-02-07T10:30:00Z                                              ║
║                                                                              ║
║  Spec ID              Status        Steps     Branch                        ║
║  ────────────────────  ───────────   ─────     ──────                        ║
║  SPEC-auth-service     complete      5/5       acis/impl/SPEC-auth-service  ║
║  SPEC-offline-store    executing     3/4       acis/impl/SPEC-offline-store ║
║  SPEC-sync-engine      pending       0/6       (not started)                ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Handling `--cleanup`

```
1. Find all implementation worktrees:
   ls -d .acis-work/impl/SPEC-*/ 2>/dev/null

2. For each worktree:
   - Check if associated batch is complete
   - If complete → remove worktree and branch
   - If in-progress → skip (warn user)
   - If orphaned (no batch state) → prompt user

3. Prune stale references:
   git worktree prune

4. Report cleanup results
```

## Output Report

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  PARALLEL IMPLEMENTATION COMPLETE: IMPL-careai-001                           ║
║  {timestamp}                                                                  ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  BATCH SUMMARY                                                              ║
║  ──────────────────────────────────────────────────────────────────────────  ║
║                                                                              ║
║  Source: docs/genesis/                                                       ║
║  Subsystems Implemented: 5                                                   ║
║  ├── Complete:     5                                                         ║
║  ├── Blocked:      0                                                         ║
║  └── Deferred:     0                                                         ║
║                                                                              ║
║  PER-SUBSYSTEM RESULTS                                                      ║
║  ──────────────────────────────────────────────────────────────────────────  ║
║                                                                              ║
║  SPEC-auth-service (Auth Service) [Tier 2]                                   ║
║    Steps: 5/5 | Files Created: 6 | Tests: 3 | Build: PASS                  ║
║    Merge: regular                                                            ║
║                                                                              ║
║  SPEC-offline-store (Offline Store) [Tier 2]                                 ║
║    Steps: 4/4 | Files Created: 4 | Tests: 2 | Build: PASS                  ║
║    Merge: regular                                                            ║
║                                                                              ║
║  SPEC-sync-engine (Sync Engine) [Tier 3]                                     ║
║    Steps: 8/8 | Files Created: 10 | Tests: 5 | Build: PASS                 ║
║    Merge: regular                                                            ║
║                                                                              ║
║  MERGE RESULTS                                                              ║
║  ──────────────────────────────────────────────────────────────────────────  ║
║                                                                              ║
║  Integration: acis/integrate-impl-careai-001                                 ║
║  Merge Order: dependency-based (topological)                                 ║
║  Conflicts: 0                                                                ║
║  Cross-Subsystem Tests: PASS                                                ║
║  Final Merge: Squash to main                                                ║
║                                                                              ║
║  VERIFICATION                                                               ║
║  ──────────────────────────────────────────────────────────────────────────  ║
║                                                                              ║
║  Build:                PASS                                                  ║
║  Tests:                PASS (47 new tests)                                   ║
║  Lint:                 PASS                                                  ║
║  Acceptance Criteria:  12/12 PASS                                            ║
║                                                                              ║
║  TOTAL CHANGES                                                              ║
║  ──────────────────────────────────────────────────────────────────────────  ║
║                                                                              ║
║  Files Created:    28                                                        ║
║  Files Modified:   3                                                         ║
║  Tests Created:    12                                                        ║
║  Insertions:       +1,847                                                    ║
║  Deletions:        -23                                                       ║
║                                                                              ║
║  PREFERENCE COMPLIANCE                                                     ║
║  ──────────────────────────────────────────────────────────────────────────  ║
║                                                                              ║
║  Preference              Checks Run  Passed  Fixed  Blocked                 ║
║  ────────────────────    ──────────  ──────  ─────  ───────                 ║
║  File Naming (kebab)     23          23      0      0                       ║
║  Export Style (named)    18          16      2      0                       ║
║  Error Handling (typed)  15          15      0      0                       ║
║  Logging (structured)    12          10      2      0                       ║
║  Testing (alongside)     28          28      0      0                       ║
║  ...                                                                        ║
║                                                                              ║
║  Overall Compliance: 97.2% (126/130 first-pass, 4 fixed on retry)          ║
║                                                                              ║
║  HISTORY PRESERVED                                                          ║
║  ──────────────────────────────────────────────────────────────────────────  ║
║                                                                              ║
║  Tag: acis/history/IMPL-careai-001                                           ║
║  Spec Archives: 5 tags created                                               ║
║  Retention: 30 days                                                          ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Safety Guarantees

| Guarantee | How Achieved |
|-----------|--------------|
| **Main never corrupted** | All work in worktrees, main only receives verified squashes |
| **Dependency order respected** | Topological sort determines merge order |
| **Atomic rollback** | Each step is one commit |
| **Conflict visibility** | Full atomic history in integration branch |
| **GENESIS traceability** | Each spec links back to source documents |
| **ADR compliance** | Constraints from ADRs enforced in spec |
| **Three-tier enforcement** | T1 (comment-stripped grep) → T2 (AST/compiler) → T3 (schema-constrained agent review); violations block commits with file:line evidence |
| **Recovery from any point** | Batch state checkpointed every step |

## Examples

```bash
# Basic parallel implementation from GENESIS
/acis:implement-parallel --genesis docs/genesis/

# Generate specs only (review before implementing)
/acis:implement-parallel --genesis docs/genesis/ --specs-only

# Dry run - show full plan without executing
/acis:implement-parallel --dry-run

# Implement only specific subsystems
/acis:implement-parallel --subsystems auth-service,sync-engine

# Skip confirmation prompts
/acis:implement-parallel --genesis docs/genesis/ --yes

# Limit concurrent worktrees
/acis:implement-parallel --genesis docs/genesis/ --max-parallel 2

# Resume interrupted implementation
/acis:implement-parallel --resume IMPL-careai-001

# Check batch status
/acis:implement-parallel --status IMPL-careai-001

# Keep worktrees for inspection
/acis:implement-parallel --genesis docs/genesis/ --preserve-worktrees

# Manual cleanup of implementation worktrees
/acis:implement-parallel --cleanup

# Skip preference interview (use saved or defaults)
/acis:implement-parallel --genesis docs/genesis/ --skip-interview
```

## Related Commands

- `/acis:genesis` - Generate GENESIS architecture output (prerequisite)
- `/acis:remediate-parallel` - Parallel remediation of existing code (fix violations)
- `/acis:status` - View overall ACIS status
- `/acis:help` - See all available commands
