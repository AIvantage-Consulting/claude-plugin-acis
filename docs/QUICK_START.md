# ACIS Quick Start Guide

Get up and running with ACIS in 5 minutes.

## Step 1: Install the Plugin

Copy the ACIS plugin to your Claude plugins directory:

```bash
# Option A: Direct copy
cp -r ~/AI_Products/aivantage/claude-plugins/acis ~/.claude/plugins/

# Option B: Symlink (for development)
ln -s ~/AI_Products/aivantage/claude-plugins/acis ~/.claude/plugins/acis
```

## Step 2: Bootstrap Your Project

In your project directory, run:

```bash
/acis init
```

### If you have existing documentation:

ACIS will scan for:
- `vision.md`, `VISION.md`
- `prd.md`, `PRD.md`
- `persona*.md`
- `requirements*.md`
- `README.md` (Vision/Problem sections)

It will extract project context and show you a preview for validation.

### If no docs exist:

ACIS will interview you with questions like:
- "What problem are you trying to solve?"
- "Who are your primary users?"
- "Any compliance requirements?"

After the interview, ACIS generates:
- `.acis-config.json` - Project configuration
- `docs/vision.md` - Vision document (optional)
- `docs/user-journeys.md` - User journey diagrams (optional)

## Step 3: Extract Goals from a PR

When you have a PR with review comments:

```bash
/acis extract 55
```

This creates goal files in `docs/reviews/goals/`:
- `PR55-G1-math-random.json`
- `PR55-G2-layer-violation.json`
- etc.

## Step 4: Remediate a Goal

Run the full remediation pipeline:

```bash
/acis remediate docs/reviews/goals/PR55-G1-math-random.json
```

This executes:
1. **Multi-Perspective Discovery** - 10+ agents analyze in parallel
2. **Behavioral TDD** - Persona-driven tests written first
3. **Ralph-Loop** - Iterative fix cycle until metrics pass
4. **Consensus Verification** - Independent verification by agents

## Step 5: Check Status

See progress on all goals:

```bash
/acis status
```

Output:
```
## ACIS Status: CareAICompanion

### Goals Summary
| Status | Count |
|--------|-------|
| Achieved | 12 |
| Pending | 3 |
| In Progress | 1 |
| Failed | 0 |

### Active Goals
- [IN_PROGRESS] PR55-G3-orchestrator-consistency (iteration 4)

### Recent Achievements
- PR55-G1-math-random (5 iterations)
- PR55-G2-layer-violation (2 iterations)
```

## Step 6: Run Process Auditor

After completing several goals, run the Process Auditor:

```bash
/acis audit
```

This analyzes your remediation patterns and:
- Identifies **reinforcements** (what's working)
- Identifies **corrections** (what needs to change)
- Generates **skills** from repeated patterns (5+ occurrences)
- Creates audit report in `docs/audits/`

## Common Workflows

### Feature Discovery

Before implementing a new feature:

```bash
/acis discovery "offline voice commands" --type feature
```

Outputs:
- Discovery report
- Decision manifest (with pending decisions)
- Goal files (if issues found)

### Security Audit

Deep security analysis:

```bash
/acis discovery "PHI exposure risks" --type audit --depth deep
```

### Resolve Decisions

After discovery surfaces pending decisions:

```bash
/acis resolve docs/manifests/DISC-2026-01-19-voice.json
```

CEOs (Alpha and Beta) provide recommendations. Converged decisions auto-approve; diverged decisions require your input.

### Remediate with Manifest

Bind remediation to resolved decisions:

```bash
/acis remediate docs/reviews/goals/VOICE-001.json \
  --manifest docs/manifests/DISC-2026-01-19-voice.json
```

## Flags Quick Reference

### For `/acis remediate`

| Flag | Description |
|------|-------------|
| `--no-behavioral` | Skip behavioral TDD phase |
| `--no-consensus` | Skip multi-agent verification |
| `--skip-codex` | Use internal agents only |
| `--discovery-only` | Run discovery phase only |
| `--max-iterations N` | Max ralph-loop iterations (default: 20) |
| `--manifest <file>` | Bind to decision manifest |
| `--deep-5whys` | Force multi-perspective 5 Whys |

### For `/acis discovery`

| Flag | Description |
|------|-------------|
| `--type <type>` | feature, refactor, audit, what-if, bug-hunt |
| `--scope <paths>` | Limit to specific paths |
| `--depth <level>` | shallow, medium, deep |
| `--skip-codex` | Internal agents only |

## Troubleshooting

### "No .acis-config.json found"

Run `/acis init` to create your project configuration.

### Detection command not working

Ensure commands are Bash 3.2 compatible. Test on macOS:

```bash
/bin/bash -c 'your_detection_command'
```

### Goal stuck (same metric failing)

The system will auto-trigger Multi-Perspective 5 Whys after 2+ iterations on the same metric. If still stuck:

```bash
/acis remediate <goal> --deep-5whys
```

### Consensus verification failing

Check which agent is vetoing:

```bash
/acis verify <goal-file>
```

Security and Architecture agents have veto power.

## Next Steps

- Read the full [User Guide](ACIS_USER_GUIDE.md)
- Explore the [Architecture](ACIS_ARCHITECTURE.md)
- Check example configs in `examples/`
