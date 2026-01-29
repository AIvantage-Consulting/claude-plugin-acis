# Migration Guide: Local ACIS to Standalone Plugin

This guide details how to migrate a project from embedded local ACIS files to the standalone ACIS plugin.

**Target Version**: ACIS v2.4.0
**Last Updated**: 2026-01-29

---

## Overview

Projects that previously embedded ACIS directly (via a local skill and governance files) should migrate to the standalone plugin for:

- **Automatic updates**: New features (v2.2 Quality Gate, v2.3 Parallel Remediation, v2.4 Traces) available immediately
- **Single source of truth**: No version drift between projects
- **Reduced maintenance**: Plugin handles all schemas, prompts, and configs

---

## Pre-Migration Checklist

Before starting, verify:

- [ ] Standalone ACIS plugin is installed and enabled
- [ ] Project has `.acis-config.json` (run `/acis init` if not)
- [ ] No active remediations in progress
- [ ] Git working tree is clean

**Verify plugin is enabled:**
```bash
# Check .claude/settings.json contains:
{
  "enabledPlugins": {
    "acis@aivantage-consulting": true
  }
}
```

**Verify plugin commands work:**
```bash
# These should be recognized as valid slash commands:
/acis status
/acis:remediate-parallel --help
```

---

## Migration Steps

### Phase 1: Remove Local Skill (Required)

**File to remove:**
```
.claude/commands/acis-local-backup.md
```

**Action:** Delete this file. It intercepts ACIS commands and uses outdated v2.1 logic.

**Verification:** After removal, `/acis audit` should invoke the plugin's `acis-audit.md`, not the local backup.

---

### Phase 2: Archive Local Documentation (Required)

The following files contain outdated documentation (v2.1) that conflicts with the current plugin (v2.4).

**Files to archive or remove:**

| File | Size | Action | Reason |
|------|------|--------|--------|
| `docs/governance/ACIS_USER_GUIDE.md` | ~70KB | **Archive** | Outdated v2.1, missing Quality Gate, Parallel Remediation, Traces |
| `docs/governance/ACIS_ARCHITECTURE.md` | ~27KB | **Archive** | May contain project-specific context worth preserving |

**Archive location:** `docs/governance/archive/acis-v2.1/`

**Commands:**
```bash
# Create archive directory
mkdir -p docs/governance/archive/acis-v2.1

# Move outdated docs
mv docs/governance/ACIS_USER_GUIDE.md docs/governance/archive/acis-v2.1/
mv docs/governance/ACIS_ARCHITECTURE.md docs/governance/archive/acis-v2.1/

# Add README explaining the archive
cat > docs/governance/archive/acis-v2.1/README.md << 'EOF'
# ACIS v2.1 Archive

These files were archived on migration to standalone ACIS plugin v2.4.

**Why archived:**
- ACIS_USER_GUIDE.md was v2.1, missing features from v2.2-v2.4
- ACIS_ARCHITECTURE.md may contain historical project context

**Current documentation:**
- User guide: Access via `/acis help` or see plugin's `docs/ACIS_USER_GUIDE.md`
- Architecture: See plugin's `docs/ACIS_ARCHITECTURE.md`

**Do not reference these files for current ACIS operations.**
EOF
```

---

### Phase 3: Migrate Local Configs (Evaluate)

**Directory:** `docs/governance/configs/`

**Contents found:**
- `acis-perspectives.json` (~11KB)
- `assessment-lenses.json` (~15KB)

**Evaluation:**

1. **Check if project-specific:**
   - If these contain CareAICompanion-specific personas or assessment criteria → **Keep**
   - If these are generic ACIS defaults → **Remove** (plugin provides these)

2. **If keeping:** Move to `.acis/configs/` (plugin's expected location)
   ```bash
   mkdir -p .acis/configs
   mv docs/governance/configs/*.json .acis/configs/
   ```

3. **If removing:**
   ```bash
   rm -rf docs/governance/configs/
   ```

**Note:** The standalone plugin has default perspectives and lenses. Project-specific overrides should go in `.acis/configs/`.

---

### Phase 4: Migrate Local Schemas (Remove)

**Directory:** `docs/governance/schemas/`

**Contents found:**
- `acis-decision-manifest.schema.json`
- `acis-decision.schema.json`
- `acis-v2-goal.schema.json`
- `remediation-goal.schema.json`

**Action:** **Remove**. The plugin provides all schemas.

```bash
rm -rf docs/governance/schemas/
```

**Reason:** Schema files should come from the plugin to ensure compatibility. Local copies cause version drift.

---

### Phase 5: Migrate Local Prompts (Remove)

**Directory:** `docs/governance/prompts/`

**Contents found:**
- `extract-goals-from-review.prompt.md`

**Action:** **Remove**. The plugin provides all prompts.

```bash
rm -rf docs/governance/prompts/
```

**Reason:** Prompts should come from the plugin to ensure they work with current schemas and features.

---

### Phase 6: Clean Up Empty Directory (Optional)

After removing files, `docs/governance/` may be mostly empty.

**Check remaining contents:**
```bash
ls -la docs/governance/
```

**If only archive remains:**
```bash
# Keep the archive for reference, or remove if not needed
# The directory structure is fine to leave as-is
```

---

### Phase 7: Verify Project Config

**File:** `.acis-config.json` (project root)

This file should remain - it's the project-specific ACIS configuration.

**Verify schema reference points to plugin:**
```json
{
  "$schema": "https://raw.githubusercontent.com/aivantage-consulting/claude-plugin-acis/main/schemas/project-config.schema.json",
  ...
}
```

**Verify required fields:**
- `projectName`
- `vision` (problem, solution)
- `personas` (at least one primary)
- `compliance`
- `architectureModel`

---

## Post-Migration Verification

Run these commands to verify the migration succeeded:

### 1. Check ACIS Status
```bash
/acis status
```
Expected: Shows project goals and progress (or "No goals found" if fresh)

### 2. Test Discovery
```bash
/acis discovery "test feature" --dry-run
```
Expected: Multi-perspective analysis runs using plugin agents

### 3. Test Parallel Remediation (v2.3+)
```bash
/acis remediate-parallel --help
```
Expected: Shows help for parallel remediation (not "command not found")

### 4. Check Traces (v2.4+)
After running any ACIS command, verify traces are emitted:
```bash
ls docs/acis/traces/
```
Expected: Trace files exist (or directory created on first run)

---

## Rollback Plan

If issues occur after migration:

### Restore Local Skill
```bash
# If archived:
mv .claude/commands/acis-local-backup.md.bak .claude/commands/acis-local-backup.md

# If deleted, restore from git:
git checkout HEAD~1 -- .claude/commands/acis-local-backup.md
```

### Restore Docs
```bash
mv docs/governance/archive/acis-v2.1/* docs/governance/
rmdir docs/governance/archive/acis-v2.1
```

### Disable Plugin (Temporary)
Edit `.claude/settings.json`:
```json
{
  "enabledPlugins": {
    "acis@aivantage-consulting": false
  }
}
```

---

## CareAICompanion Specific Migration

For the CareAICompanion project specifically:

### Files Summary

| Path | Action | Command |
|------|--------|---------|
| `.claude/commands/acis-local-backup.md` | **Delete** | `rm .claude/commands/acis-local-backup.md` |
| `docs/governance/ACIS_USER_GUIDE.md` | **Archive** | `mv` to `archive/acis-v2.1/` |
| `docs/governance/ACIS_ARCHITECTURE.md` | **Archive** | `mv` to `archive/acis-v2.1/` |
| `docs/governance/configs/` | **Evaluate** | Keep if project-specific, else remove |
| `docs/governance/schemas/` | **Remove** | `rm -rf docs/governance/schemas/` |
| `docs/governance/prompts/` | **Remove** | `rm -rf docs/governance/prompts/` |
| `.acis-config.json` | **Keep** | No action needed |
| `.claude/settings.json` | **Keep** | Plugin already enabled |

### One-Shot Migration Script

```bash
#!/bin/bash
# CareAICompanion ACIS Migration Script
# Run from project root: /Users/umesh/AI_Products/aivantage/CareAICompanion

set -e

echo "=== ACIS Migration: Local → Standalone Plugin ==="

# Phase 1: Remove local skill
echo "Phase 1: Removing local skill..."
rm -f .claude/commands/acis-local-backup.md
echo "  ✓ Removed .claude/commands/acis-local-backup.md"

# Phase 2: Archive docs
echo "Phase 2: Archiving outdated documentation..."
mkdir -p docs/governance/archive/acis-v2.1
mv docs/governance/ACIS_USER_GUIDE.md docs/governance/archive/acis-v2.1/ 2>/dev/null || true
mv docs/governance/ACIS_ARCHITECTURE.md docs/governance/archive/acis-v2.1/ 2>/dev/null || true

cat > docs/governance/archive/acis-v2.1/README.md << 'EOF'
# ACIS v2.1 Archive

Archived on migration to standalone ACIS plugin v2.4.

Current docs: Use `/acis help` or see plugin documentation.
EOF
echo "  ✓ Archived to docs/governance/archive/acis-v2.1/"

# Phase 3: Evaluate configs (manual decision)
echo "Phase 3: Configs evaluation needed..."
echo "  → Check docs/governance/configs/ for project-specific content"
echo "  → If generic: rm -rf docs/governance/configs/"
echo "  → If specific: mkdir -p .acis/configs && mv docs/governance/configs/*.json .acis/configs/"

# Phase 4: Remove schemas
echo "Phase 4: Removing local schemas..."
rm -rf docs/governance/schemas/
echo "  ✓ Removed docs/governance/schemas/"

# Phase 5: Remove prompts
echo "Phase 5: Removing local prompts..."
rm -rf docs/governance/prompts/
echo "  ✓ Removed docs/governance/prompts/"

echo ""
echo "=== Migration Complete ==="
echo "Run '/acis status' to verify plugin is working."
echo "Run '/acis:remediate-parallel --help' to verify v2.3+ features."
```

---

## FAQ

**Q: Why not just keep both local and plugin?**
A: The local skill intercepts commands, causing confusion about which version is running. Also causes version drift where local docs don't match plugin capabilities.

**Q: What about my existing goals in `docs/reviews/goals/`?**
A: Keep them. Goal files are project data, not ACIS system files. The plugin reads goals from the path configured in `.acis-config.json`.

**Q: Do I need to re-run `/acis init`?**
A: No, if `.acis-config.json` exists and is valid. The init command is only needed for new projects.

**Q: What if I customized the local prompts/schemas?**
A: Document your customizations, then request they be added to the plugin via GitHub issue. Project-specific overrides should go in `.acis/` directory.
