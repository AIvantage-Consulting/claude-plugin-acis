# ACIS - Automated Code Improvement System

A Claude Plugin for decision-oriented discovery, behavioral TDD remediation, and continuous process improvement through dynamic skill generation.

## Features

- **Project Bootstrapping** (`/acis init`) - Interview-based or doc-extraction project setup
- **Decision-Oriented Discovery** (`/acis discovery`) - Surface decisions before implementation
- **Dual-CEO Validation** - AI-Native + Modern SWE perspectives on pending decisions
- **Multi-Perspective Discovery** - 10+ agents analyze in parallel
- **Behavioral TDD** - Persona-driven acceptance tests before code
- **Consensus Verification** - Independent metric verification with veto power
- **Process Auditor** (`/acis audit`) - Pattern analysis and dynamic skill generation
- **Three-Loop Architecture** - Process → Discovery → Remediation loops

## Installation

```bash
# Clone or copy to your plugins directory
cp -r acis ~/AI_Products/aivantage/claude-plugins/

# The plugin will be auto-discovered by Claude Code
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
├── .claude-plugin/plugin.json     # Plugin manifest
├── commands/
│   ├── acis.md                    # Main command
│   ├── acis-init.md               # Project bootstrapping
│   └── acis-audit.md              # Process Auditor
├── schemas/                       # JSON schemas
├── configs/                       # Perspectives, lenses
├── templates/                     # Codex delegation templates
├── interview/                     # Interview system
├── audit/                         # Process Auditor system
├── skill-templates/               # Templates for generated skills
├── ralph-profiles/                # Ralph-loop execution profiles
└── docs/                          # Architecture, user guide
```

## Requirements

- Claude Code CLI
- MCP server: `codex` (optional, for deep analysis)

## License

MIT

## Author

aivantage-consulting
