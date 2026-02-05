# ACIS - Automated Code Improvement System

A Claude Plugin for decision-oriented discovery, behavioral TDD remediation, and continuous process improvement through dynamic skill generation.

## Features

- **GENESIS Framework** (`/acis genesis`) - Transform vague ideas into structured system architectures
- **Project Bootstrapping** (`/acis init`) - Interview-based or doc-extraction project setup
- **Decision-Oriented Discovery** (`/acis discovery`) - Surface decisions before implementation
- **Dual-CEO Validation** - AI-Native + Modern SWE perspectives on pending decisions
- **Multi-Perspective Discovery** - 10+ agents analyze in parallel
- **Behavioral TDD** - Persona-driven acceptance tests before code
- **Consensus Verification** - Independent metric verification with veto power
- **Parallel Remediation** (`/acis remediate-parallel`) - Worktree-isolated parallel goal execution
- **Trust but Re-verify** - Smart duplicate detection with TTL and change detection
- **Quality Gate** - Codex code review before marking goals achieved
- **Pre-Commit Review** (`/acis pre-commit-review`) - Quick design review of staged changes before commit
- **ACIS Traces** - User-visible and structured observability for Process Auditor learning
- **Process Auditor** (`/acis audit`) - Pattern analysis and dynamic skill generation
- **Recommendation Routing** - Automatic classification and routing of process improvements to project or plugin scope
- **Three-Loop Architecture** - Process → Discovery → Remediation loops

## Installation

### Option 1: Via Marketplace (Recommended)

**Add the marketplace:**
```bash
# From GitHub (when published)
/plugin marketplace add aivantage-consulting/claude-plugin-acis

# Or from local path (development)
/plugin marketplace add /path/to/acis
```

**Install the plugin:**
```bash
/plugin install acis@aivantage-acis
```

### Option 2: Direct Plugin Installation

**For development/testing:**
```bash
claude --plugin-dir /path/to/acis
```

**For permanent local installation:**
```bash
# Create symlink in Claude's plugin cache
ln -s /path/to/acis ~/.claude/plugins/repos/acis
```

### Option 3: Project-Wide Configuration

Add to your project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "aivantage-acis": {
      "source": {
        "source": "github",
        "repo": "aivantage-consulting/claude-plugin-acis"
      }
    }
  },
  "enabledPlugins": {
    "acis@aivantage-acis": true
  }
}
```

### Option 4: System-Wide Configuration

Add to `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "aivantage-acis": {
      "source": "./repos/acis"
    }
  },
  "enabledPlugins": {
    "acis@aivantage-acis": true
  }
}
```

## Quick Start

### 1. Bootstrap a New Project

```bash
/acis init
```

This will either:
- **Extract** project context from existing docs (vision.md, prd.md, persona*.md)
- **Interview** you with BA/PM-style questions if no docs exist

Output: `.acis-config.json` with personas, compliance, architecture model.

### 2. Run Discovery

```bash
/acis discovery "offline voice commands" --type feature
```

Surfaces decisions, generates specs, finds issues before implementation.

### 3. Remediate Goals

```bash
/acis remediate docs/reviews/goals/WO63-CRIT-001.json
```

Full pipeline: Discovery → Behavioral TDD → Ralph-Loop → Consensus Verification.

### 4. Run Process Auditor

```bash
/acis audit
```

Analyzes completed remediations, extracts patterns into skills, improves ACIS itself.

## Commands

| Command | Description |
|---------|-------------|
| `/acis genesis` | Transform an idea into structured architecture via 4-layer agent swarm |
| `/acis init` | Bootstrap ACIS for a new project |
| `/acis status` | Show progress on all goals |
| `/acis discovery "<topic>"` | Proactive investigation |
| `/acis extract <PR>` | Extract goals from PR review comments |
| `/acis resolve <manifest>` | Resolve pending decisions |
| `/acis remediate <goal-file>` | Full TDD remediation pipeline |
| `/acis remediate-parallel <goals>` | Parallel remediation with worktree isolation |
| `/acis verify <goal-file>` | Run consensus verification only |
| `/acis pre-commit-review` | Quick design review of staged changes |
| `/acis audit` | Process Auditor (pattern analysis, skill generation) |
| `/acis upgrade` | Check for and install missing ACIS components |
| `/acis version` | Display installed plugin version |

## Three-Loop Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│  LOOP 1: PROCESS AUDITOR (Outermost)                                    │
│  Cadence: After N goals achieved                                        │
│  Phases: PAUSE → REFLECT → LEARN → APPLY → DOCUMENT                     │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  LOOP 2: DISCOVERY ORCHESTRATOR (Middle)                          │  │
│  │  Cadence: Per feature/PR/audit scope                              │  │
│  │  Phases: DISCOVER → DECIDE → EXTRACT-GOALS → SCAFFOLD → VERIFY    │  │
│  │                                                                   │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │  LOOP 3: BEHAVIORAL TDD (Innermost)                         │  │  │
│  │  │  Cadence: Per individual goal                               │  │  │
│  │  │  Phases: MEASURE → 5-WHYS → FIX → VERIFY                    │  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Dynamic Skill Generation

Skills are NOT static documentation. They **emerge** from the Process Auditor when patterns meet ALL criteria:

| Criterion | Threshold | Rationale |
|-----------|-----------|-----------|
| **Repetition** | 5+ occurrences | Proven recurring need |
| **ROI** | >20% time savings | Clear return on investment |
| **Project-Specific** | Requires local context | Generic patterns belong in defaults |
| **Measurable** | Detection command exists | Must be verifiable |
| **Step Sequence** | 3+ sequential steps | Enough complexity to warrant abstraction |

Skills are generated to `skills/{skill-name}/SKILL.md` after `/acis audit`.

## Project Configuration

ACIS uses `.acis-config.json` in your project root:

```json
{
  "projectName": "MyProject",
  "vision": {
    "problem": "...",
    "solution": "..."
  },
  "personas": [
    { "name": "User", "role": "primary user", "type": "primary" }
  ],
  "compliance": ["HIPAA"],
  "architectureModel": "three-layer",
  "platform": { "web": true, "mobile": true, "offline": true },
  "goalsDirectory": "docs/reviews/goals",
  "auditThreshold": 3
}
```

Run `/acis init` to generate this interactively.

## Bash 3.2 Compatibility

All detection commands MUST work on macOS Bash 3.2. Avoid:
- `declare -A` (associative arrays)
- `mapfile` / `readarray`
- `${var,,}` / `${var^^}` (case modification)
- `shopt -s globstar`

Use POSIX constructs: `grep`, `find`, `sed`, `awk`, `[ ]` tests.

## File Structure

```
acis/
├── .claude-plugin/
│   ├── plugin.json               # Plugin manifest
│   └── marketplace.json          # Marketplace definition (for distribution)
├── .claude/
│   └── hooks/
│       ├── acis-path-validator.sh    # Path validation hook
│       └── acis-pre-commit-hook.sh   # Pre-commit review reminder hook
├── commands/
│   ├── acis.md                   # Main ACIS command reference
│   ├── acis-init.md              # Project bootstrapping
│   ├── acis-audit.md             # Process Auditor
│   ├── genesis.md                # GENESIS vision-to-architecture orchestrator
│   ├── help.md                   # Dynamic help system
│   ├── status.md                 # Progress dashboard
│   ├── extract.md                # PR goal extraction
│   ├── discovery.md              # Multi-perspective investigation
│   ├── resolve.md                # Decision resolution
│   ├── remediate.md              # Full TDD pipeline
│   ├── pre-commit-review.md      # Quick design review before commit
│   ├── upgrade.md                # Upgrade existing installations
│   ├── verify.md                 # Consensus verification
│   └── version.md                # Display plugin version
├── agents/                       # Specialized agents
│   ├── genesis-*.md              # GENESIS framework agents (10 total)
│   └── ...                       # Other agents
├── schemas/                      # JSON schemas
├── configs/                      # Perspectives, lenses
├── templates/
│   ├── genesis/                  # GENESIS output templates
│   │   └── VISION_BOUNDED.md     # Vision bounding interview output
│   └── ...                       # Other templates
├── prompts/                      # LLM prompt templates
├── interview/
│   ├── genesis-vision-interview.json  # GENESIS vision bounding questions
│   └── ...                       # Other interview systems
├── audit/                        # Process Auditor system
├── skill-templates/              # Templates for generated skills
├── skills/                       # Dynamically generated skills
├── ralph-profiles/               # Ralph-loop execution profiles
├── examples/                     # Example configurations
└── docs/                         # Architecture, user guide
```

## Requirements

- Claude Code CLI (v2.1.19+ for swarm orchestration)
- MCP server: `codex` (optional, for deep analysis)

## Version History

### v2.8.0 (2026-02-05)
- **Recommendation Routing**: Automatic classification and routing of Process Auditor recommendations
  - Recommendations classified by scope: `project` vs `plugin`
  - Plugin-scope recommendations auto-submitted as GitHub issues (primary)
  - Fallback to `.acis/plugin-feedback/` files when GitHub unavailable
  - New schema: `schemas/acis-recommendation.schema.json`
- **Process Auditor Enhancements**:
  - New Phase 3.5: CLASSIFY - Categorize recommendations by applicability
  - New Phase 4.5: ROUTE - Submit plugin feedback to GitHub or fallback
  - Structured recommendation storage in `audits/recommendations/`
- New templates:
  - `templates/plugin-feedback-issue.md` - GitHub issue format
  - `templates/plugin-feedback-file.md` - Fallback file format
- Classification criteria for project vs plugin scope documented
- Dual-track improvement path: local skills + plugin-wide fixes

### v2.7.0 (2026-02-01)
- **Pre-Commit Code Review**: Quick design review of staged changes before committing
  - New command: `/acis pre-commit-review` for design/architecture review
  - Focuses on SOLID violations, layer breaches, coupling red flags
  - Delegates to Codex for thorough review (or heuristic mode with `--skip-codex`)
  - Verdicts: PASS (clean), WARN (advisory), BLOCK (with `--strict`)
  - Non-blocking by default (WARN doesn't prevent commit)
- **Pre-Commit Hook** (installed by default via `/acis init`)
  - Reminds users to run `/acis pre-commit-review` before `git commit`
  - Shows staged file count and line count
  - Non-blocking: always allows commit to proceed
  - Skip with: `git commit --no-verify` or `ACIS_SKIP_PRE_COMMIT=1`
  - Opt out during install: `/acis init --skip-pre-commit-hook`
- New template: `templates/codex-pre-commit-review.md`
- New hook: `.claude/hooks/acis-pre-commit-hook.sh`
- New command: `/acis version` to display installed plugin version
- New command: `/acis upgrade` for upgrading existing installations
  - Detects missing hooks and outdated config
  - Auto-detect on first use of any ACIS command per session
  - Shows non-intrusive one-liner when upgrade available
- Updated: `scripts/install-hooks.sh` with pre-commit hook support

### v2.6.0 (2026-01-30)
- **GENESIS Framework**: Transform vague product ideas into structured system architectures
  - Vision Bounding Interview (Gate 0) with red flag detection prevents "garbage-in"
  - 4-Layer Agent Swarm Architecture:
    - **Layer 1**: Parallel Analysis (Persona, Journey, Event Stormer, Similar Systems)
    - **Layer 2**: Synthesis Agent with Elite Architect questions
    - **Layer 3**: Challenge Reviewers (Security, Scalability, Accessibility, Cost)
    - **Layer 4**: Arbitrator Agent with ADR generation
  - 5 Strategic Human Gates for oversight without micro-management
  - Dual-CEO model at Gate 3 (AI-Native vs Modern SWE perspectives)
  - GTM positioning extraction from Similar Systems analysis
- New command: `/acis genesis` to start vision-to-architecture transformation
- New interview: `interview/genesis-vision-interview.json` (18 questions across 4 phases)
- New template: `templates/genesis/VISION_BOUNDED.md`
- New agents (10 total):
  - `genesis-persona-analyst.md` - Extract personas and needs hierarchy
  - `genesis-journey-mapper.md` - Map user flows with experience layers
  - `genesis-event-stormer.md` - DDD event storming for domain events
  - `genesis-similar-systems-analyst.md` - Competitive analysis with ADOPT/ADAPT/AVOID/INNOVATE
  - `genesis-synthesis-agent.md` - Subsystem proposals with build vs buy
  - `genesis-security-reviewer.md` - STRIDE analysis and compliance gaps
  - `genesis-scalability-reviewer.md` - Bottleneck and SPOF analysis
  - `genesis-accessibility-reviewer.md` - WCAG alignment for target users
  - `genesis-cost-reviewer.md` - Budget mapping and cost projection
  - `genesis-arbitrator-agent.md` - Conflict resolution and ADR generation
- Output: `docs/genesis/` directory ready for `/acis init --from-genesis`
- Pattern: ALIGNED decisions get rubber-stamp, CONFLICTED decisions require human choice

### v2.5.0 (2026-01-30)
- **Swarm Orchestration**: Multi-agent coordination using Claude Code's TeammateTool
  - Persistent agent teams with inbox-based communication
  - Self-organizing task queues with auto-dependency management
  - Graceful shutdown protocols with heartbeat monitoring
  - Fallback to Task tool when TeammateTool unavailable
- New skill: `skills/swarm-orchestration/SKILL.md`
- New ralph profile: `swarm-remediation.json`
- New flag: `--swarm` for `/acis remediate-parallel`
- Migration guide: `docs/MIGRATION_FROM_LOCAL.md`
- Requires Claude Code v2.1.19+ for full swarm features

### v2.4.0 (2026-01-28)
- **ACIS Traces / Observability**: Dual-purpose tracing for user visibility and Process Auditor learning
  - User-visible traces with `[ACIS:{loop}:{phase}]` prefix
  - Structured observability traces capturing micro-decisions, knowledge gaps, skill applications
  - Trace types: lifecycle, decision, knowledge, skill, effectiveness, blocker
  - Separate storage: project traces in `docs/acis/traces/`, process traces in `.acis/traces/`
- New schema: `acis-trace.schema.json`
- New prompt: `trace-emission.md` defining trace emission patterns
- Process Auditor updated to consume traces as additional context

### v2.3.0 (2026-01-28)
- **Parallel Remediation**: Worktree-isolated parallel goal execution with integration branch merge
  - File-disjointness verification before parallelization
  - Atomic step commits for fine-grained rollback
  - Hybrid conflict resolution (trivial/partial/semantic/unresolvable)
  - History preservation via tags before squash to main
- New schemas: `parallel-batch`, `step-manifest`, `merge-report`
- New command: `/acis remediate-parallel`
- New ralph profile: `parallel-remediation.json`

### v2.2.0 (2026-01-27)
- **Trust but Re-verify**: Smart duplicate detection for `/acis extract`
  - TTL-based re-verification (14-60 days based on confidence)
  - Git change detection triggers mandatory re-check
  - 10% random spot-check sampling
- **Quality Gate**: Codex code review before marking goals achieved
- **Stuck Consultation**: Codex problem-solving after 4+ iterations
- **Complexity-only Estimation**: Tier 1/2/3 (no time estimates)
- Known resolutions registry for intentional exceptions

### v2.1.0 (2026-01-22)
- **Path Validation**: Enforce relative paths, prevent `..` traversal
- **Hook Installation**: Runtime path validation hooks
- **Artifact Taxonomy**: Structured directory organization

### v2.0.0 (2026-01-19)
- Initial plugin release
- Three-loop architecture (Process → Discovery → Remediation)
- Multi-perspective discovery with 10+ agents
- Behavioral TDD with persona-driven tests
- Consensus verification with veto power
- Process Auditor with dynamic skill generation

## License

MIT

## Author

aivantage-consulting
