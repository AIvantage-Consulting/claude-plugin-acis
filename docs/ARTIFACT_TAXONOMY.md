# ACIS Artifact Taxonomy

**Purpose**: Define where every ACIS artifact lives to prevent scattered files and nested path bugs.

---

## Core Principle: Plugin vs Project Separation

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PLUGIN ARTIFACTS (shipped with ACIS, version-controlled in plugin repo)   │
│                                                                             │
│  ~/claude-plugins/acis/                                                     │
│  ├── schemas/          ← JSON schemas (immutable)                           │
│  ├── templates/        ← Codex delegation templates (immutable)             │
│  ├── configs/          ← Default perspectives, lenses (immutable)           │
│  ├── prompts/          ← Prompt templates (immutable)                       │
│  ├── interview/        ← Interview system (immutable)                       │
│  ├── audit/            ← Audit system (immutable)                           │
│  ├── ralph-profiles/   ← Ralph-loop profiles (immutable)                    │
│  ├── skill-templates/  ← Templates for skill generation (immutable)        │
│  └── docs/             ← Plugin documentation (immutable)                   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  PROJECT ARTIFACTS (created per-project, version-controlled in project)    │
│                                                                             │
│  {project-root}/                                                            │
│  ├── .acis-config.json          ← Project configuration (ALWAYS at root)   │
│  └── docs/acis/                 ← ALL ACIS artifacts under ONE directory   │
│      ├── goals/                 ← Goal files (PR55-G1.json, WO59-P1-001.json)│
│      ├── discovery/             ← Discovery reports (DISC-2026-01-21.md)    │
│      ├── decisions/             ← Decision manifests (DEC-offline-arch.json)│
│      ├── audits/                ← Audit reports (AUDIT-2026-01-21.md)       │
│      ├── skills/                ← Project-specific skills (extracted)       │
│      └── state/                 ← Runtime state (state.json, progress.json) │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Artifact Types Reference

### Plugin Artifacts (READ-ONLY by ACIS runtime)

| Directory | Contents | Modified By |
|-----------|----------|-------------|
| `schemas/` | `acis-goal.schema.json`, `acis-decision.schema.json`, `project-config.schema.json` | Plugin maintainers only |
| `templates/` | `codex-architect-discovery.md`, `codex-ceo-alpha.md`, etc. | Plugin maintainers only |
| `configs/` | `acis-perspectives.json`, `assessment-lenses.json` | Plugin maintainers only |
| `prompts/` | `extract-goals-from-review.prompt.md` | Plugin maintainers only |
| `interview/` | `interview-flow.md`, `question-bank.json` | Plugin maintainers only |
| `audit/` | `audit-flow.md`, `reflection-prompts.md` | Plugin maintainers only |
| `ralph-profiles/` | `behavioral-tdd.json`, `process-auditor.json` | Plugin maintainers only |
| `skill-templates/` | `skill-template.md` | Plugin maintainers only |

### Project Artifacts (READ-WRITE by ACIS runtime)

| Directory | Contents | Created By | Naming Convention |
|-----------|----------|------------|-------------------|
| `docs/acis/goals/` | Remediation goals | `/acis extract`, `/acis discovery` | `{SOURCE}-{SEVERITY}-{SEQ}-{slug}.json` |
| `docs/acis/discovery/` | Discovery reports | `/acis discovery` | `DISC-{YYYY-MM-DD}-{topic}.md` |
| `docs/acis/decisions/` | Decision manifests | `/acis discovery`, `/acis resolve` | `DEC-{topic}.json` |
| `docs/acis/audits/` | Process audit reports | `/acis audit` | `AUDIT-{YYYY-MM-DD}.md` |
| `docs/acis/skills/` | Project-specific skills | `/acis audit` (auto-generated) | `{skill-name}/SKILL.md` |
| `docs/acis/state/` | Runtime state | ACIS runtime | `state.json`, `progress.json` |

---

## Goal File Naming Convention

```
{SOURCE}-{SEVERITY}-{SEQ}-{slug}.json

SOURCE:    PR55, WO59, DISC (discovery), AUDIT (audit-generated)
SEVERITY:  CRITICAL, HIGH, MEDIUM, LOW, DOC
SEQ:       001, 002, 003... (zero-padded)
slug:      kebab-case description

Examples:
  PR55-HIGH-001-math-random-usage.json
  WO59-CRITICAL-002-unencrypted-sync-queue.json
  DISC-MEDIUM-001-missing-error-boundary.json
  AUDIT-LOW-001-inconsistent-logging.json
```

---

## Path Configuration in `.acis-config.json`

```json
{
  "projectName": "CareAICompanion",
  "paths": {
    "acisRoot": "docs/acis",
    "goals": "docs/acis/goals",
    "discovery": "docs/acis/discovery",
    "decisions": "docs/acis/decisions",
    "audits": "docs/acis/audits",
    "skills": "docs/acis/skills",
    "state": "docs/acis/state"
  },
  "personas": [...],
  "compliance": ["HIPAA"],
  "architectureModel": "three-layer"
}
```

### Default Paths (if `paths` not specified)

| Key | Default Value |
|-----|---------------|
| `acisRoot` | `docs/acis` |
| `goals` | `${acisRoot}/goals` |
| `discovery` | `${acisRoot}/discovery` |
| `decisions` | `${acisRoot}/decisions` |
| `audits` | `${acisRoot}/audits` |
| `skills` | `${acisRoot}/skills` |
| `state` | `${acisRoot}/state` |

---

## Path Validation Rules

### Rule 1: No Nested Paths

ACIS MUST validate that output paths don't create nested structures:

```typescript
// BAD - creates docs/acis/goals/docs/acis/goals/
const goalPath = path.join(config.paths.goals, config.paths.goals, filename);

// GOOD - single level
const goalPath = path.join(projectRoot, config.paths.goals, filename);
```

**Validation**:
```bash
# Detection command for nested paths
find docs/acis -type d -path "*docs/acis*docs/acis*" 2>/dev/null | wc -l
# Expected: 0
```

### Rule 2: All Paths Relative to Project Root

All paths in `paths` config MUST be relative to project root, never absolute:

```json
// GOOD
"paths": { "goals": "docs/acis/goals" }

// BAD
"paths": { "goals": "/Users/umesh/project/docs/acis/goals" }
```

### Rule 3: No Path Traversal

Paths MUST NOT contain `..` or start with `/`:

```typescript
function validatePath(p: string): boolean {
  return !p.includes('..') && !p.startsWith('/');
}
```

### Rule 4: Single ACIS Root

All ACIS artifacts MUST be under `acisRoot`. This prevents scattering:

```json
// GOOD - all under acisRoot
"paths": {
  "acisRoot": "docs/acis",
  "goals": "docs/acis/goals",
  "audits": "docs/acis/audits"
}

// BAD - scattered across repo
"paths": {
  "goals": "docs/reviews/goals",      // Different parent
  "audits": "docs/governance/audits"  // Different parent
}
```

---

## Migration Guide: CareAICompanion

### Current (Chaotic) Structure

```
docs/
├── governance/
│   ├── schemas/           ← ACIS schemas (should be in plugin)
│   ├── templates/         ← ACIS templates (should be in plugin)
│   ├── configs/           ← ACIS configs (should be in plugin)
│   ├── prompts/           ← ACIS prompts (should be in plugin)
│   ├── ACIS_*.md          ← ACIS docs (should be in plugin)
│   └── COO_*.md           ← Project governance (keep here)
├── reviews/
│   ├── goals/             ← Goal files (move to docs/acis/goals/)
│   ├── PR-55-*.md         ← PR reports (move to docs/acis/discovery/)
│   └── PR-55-*.json       ← Resolution files (move to docs/acis/decisions/)
└── work-orders/           ← Keep here (not ACIS artifacts)
```

### Target (Clean) Structure

```
docs/
├── acis/                  ← ALL ACIS artifacts here
│   ├── goals/
│   ├── discovery/
│   ├── decisions/
│   ├── audits/
│   ├── skills/
│   └── state/
├── governance/            ← Only COO/AIOM docs (non-ACIS)
│   ├── COO_*.md
│   └── checkpoint-reports/
└── work-orders/           ← Unchanged
```

### Migration Commands

```bash
# 1. Create new structure
mkdir -p docs/acis/{goals,discovery,decisions,audits,skills,state}

# 2. Move goal files
mv docs/reviews/goals/*.json docs/acis/goals/

# 3. Move discovery/resolution artifacts
mv docs/reviews/PR-*-process-auditor-report.md docs/acis/audits/
mv docs/reviews/PR-*-resolution.json docs/acis/decisions/

# 4. Remove empty directories
rmdir docs/reviews/goals docs/reviews 2>/dev/null || true

# 5. Update .acis-config.json
# (Set paths.goals to "docs/acis/goals")
```

---

## Nested Path Bug Prevention

### How the Bug Occurs

```typescript
// BUG: Using config path as both base AND relative
const outputDir = config.paths.goals;  // "docs/acis/goals"
const fullPath = path.join(outputDir, config.paths.goals, filename);
// Result: "docs/acis/goals/docs/acis/goals/filename.json" ← NESTED!
```

### Correct Implementation

```typescript
// CORRECT: Join project root with config path
const projectRoot = process.cwd();
const outputDir = config.paths.goals;  // "docs/acis/goals"
const fullPath = path.join(projectRoot, outputDir, filename);
// Result: "/path/to/project/docs/acis/goals/filename.json" ← CORRECT
```

### Validation in ACIS Runtime

Add this validation at startup:

```typescript
function validatePaths(config: AcisConfig): void {
  const paths = config.paths || {};

  for (const [key, value] of Object.entries(paths)) {
    // Rule 2: No absolute paths
    if (value.startsWith('/')) {
      throw new Error(`ACIS: Path "${key}" must be relative, got absolute: ${value}`);
    }

    // Rule 3: No traversal
    if (value.includes('..')) {
      throw new Error(`ACIS: Path "${key}" contains traversal: ${value}`);
    }

    // Rule 4: Under acisRoot
    const acisRoot = paths.acisRoot || 'docs/acis';
    if (key !== 'acisRoot' && !value.startsWith(acisRoot)) {
      console.warn(`ACIS: Path "${key}" (${value}) is outside acisRoot (${acisRoot})`);
    }
  }
}
```

---

## Summary

| Question | Answer |
|----------|--------|
| Where do schemas go? | Plugin: `schemas/` |
| Where do goal files go? | Project: `docs/acis/goals/` |
| Where do audit reports go? | Project: `docs/acis/audits/` |
| Where do discovery reports go? | Project: `docs/acis/discovery/` |
| Where is config stored? | Project root: `.acis-config.json` |
| How to prevent nested paths? | Validate paths at ACIS startup |
| How to migrate existing projects? | Use migration commands above |
