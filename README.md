# ACIS - Automated Code Improvement System

A Claude Plugin for decision-oriented discovery, behavioral TDD remediation, and continuous process improvement through dynamic skill generation.

## Features

- **Project Bootstrapping** (`/acis init`) - Interview-based or doc-extraction project setup
- **Decision-Oriented Discovery** (`/acis discovery`) - Surface decisions before implementation
- **Dual-CEO Validation** - AI-Native + Modern SWE perspectives on pending decisions
- **Multi-Perspective Discovery** - 10+ agents analyze in parallel
- **Behavioral TDD** - Persona-driven acceptance tests before code
- **Consensus Verification** - Independent metric verification with veto power
- **Parallel Remediation** (`/acis remediate-parallel`) - Worktree-isolated parallel goal execution
- **Trust but Re-verify** - Smart duplicate detection with TTL and change detection
- **Quality Gate** - Codex code review before marking goals achieved
- **Process Auditor** (`/acis audit`) - Pattern analysis and dynamic skill generation
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
| `/acis init` | Bootstrap ACIS for a new project |
| `/acis status` | Show progress on all goals |
| `/acis discovery "<topic>"` | Proactive investigation |
| `/acis extract <PR>` | Extract goals from PR review comments |
| `/acis resolve <manifest>` | Resolve pending decisions |
| `/acis remediate <goal-file>` | Full TDD remediation pipeline |
| `/acis remediate-parallel <goals>` | Parallel remediation with worktree isolation |
| `/acis verify <goal-file>` | Run consensus verification only |
| `/acis audit` | Process Auditor (pattern analysis, skill generation) |

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
├── commands/
│   ├── acis.md                   # Main ACIS command reference
│   ├── acis-init.md              # Project bootstrapping
│   ├── acis-audit.md             # Process Auditor
│   ├── help.md                   # Dynamic help system
│   ├── status.md                 # Progress dashboard
│   ├── extract.md                # PR goal extraction
│   ├── discovery.md              # Multi-perspective investigation
│   ├── resolve.md                # Decision resolution
│   ├── remediate.md              # Full TDD pipeline
│   └── verify.md                 # Consensus verification
├── agents/                       # Specialized agents
├── schemas/                      # JSON schemas
├── configs/                      # Perspectives, lenses
├── templates/                    # Codex delegation templates
├── prompts/                      # LLM prompt templates
├── interview/                    # Interview system
├── audit/                        # Process Auditor system
├── skill-templates/              # Templates for generated skills
├── skills/                       # Dynamically generated skills
├── ralph-profiles/               # Ralph-loop execution profiles
├── examples/                     # Example configurations
└── docs/                         # Architecture, user guide
```

## Requirements

- Claude Code CLI
- MCP server: `codex` (optional, for deep analysis)

## Version History

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
