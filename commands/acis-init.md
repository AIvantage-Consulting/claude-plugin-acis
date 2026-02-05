# /acis init - Project Bootstrapping Command

Bootstrap ACIS for a new project by creating the `.acis-config.json` file.

## Trigger

User invokes `/acis init` command with optional flags:
- `--from-docs`: Attempt to extract from existing project docs first
- `--interactive`: Force interactive interview mode
- `--output <path>`: Custom output path (default: `.acis-config.json`)
- `--skip-plugins`: Skip plugin dependency check
- `--skip-pre-commit-hook`: Don't install the pre-commit review reminder hook

## Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                       /acis init                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────┐
            │  STEP 0: Dependency Check       │
            │  - Check ralph-wiggum plugin    │
            │  - Check Codex MCP server       │
            │  - Offer installation options   │
            │  - Record plugin availability   │
            └─────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────┐
            │  Check for existing docs:       │
            │  - vision.md / VISION.md        │
            │  - prd.md / PRD.md              │
            │  - persona*.md                  │
            │  - requirements*.md             │
            │  - README.md (Vision section)   │
            └─────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
        Found docs?                     No docs found
              │                               │
              ▼                               ▼
    ┌─────────────────┐           ┌─────────────────────┐
    │ Extract & Parse │           │ Dynamic Interview   │
    │ Show summary    │           │ BA/PM Discovery     │
    │ Ask to validate │           └─────────────────────┘
    └─────────────────┘                     │
              │                             ▼
              │               ┌─────────────────────────┐
              │               │ Generate Vision &       │
              │               │ User Journey Flows      │
              │               │ (Mermaid diagrams)      │
              │               └─────────────────────────┘
              │                             │
              ▼                             ▼
    ┌─────────────────────────────────────────────────┐
    │  Show visual summary to human                    │
    │  Ask: "Is this accurate? Want to modify?"        │
    └─────────────────────────────────────────────────┘
                              │
                              ▼
    ┌─────────────────────────────────────────────────┐
    │  Generate .acis-config.json                      │
    │  + Optional: docs/vision.md (if created)         │
    │  + Optional: docs/user-journeys.md               │
    └─────────────────────────────────────────────────┘
                              │
                              ▼
    ┌─────────────────────────────────────────────────┐
    │  STEP 7: Install ACIS Hooks                       │
    │  - Path validator (blocks bad paths)              │
    │  - Pre-commit review reminder (default ON)        │
    │  - Configure PreToolUse hooks in settings.json    │
    │  - Use --skip-pre-commit-hook to opt out          │
    └─────────────────────────────────────────────────┘
```

## Step 0: Dependency Check (Pre-flight)

**Skip this step if `--skip-plugins` flag is set.**

ACIS depends on optional plugins that enhance its capabilities. This step checks for their availability and offers installation options.

### 0.1 Check ralph-wiggum Plugin

**Detection method:**
```bash
# Check if ralph-wiggum is available in plugins
ls ~/.claude/plugins/repos/ralph-wiggum 2>/dev/null || \
ls ~/.claude/plugins/marketplaces/*/plugins/ralph-wiggum 2>/dev/null || \
ls ~/.claude/plugins/cache/*/ralph-wiggum 2>/dev/null
```

**Also check if `/ralph-loop` command is available** by checking the Skill tool's available skills list.

### 0.2 Check Codex MCP Server

**Detection method:**
```bash
# Check if codex MCP is configured
grep -l "codex" ~/.claude/mcp*.json 2>/dev/null || \
grep -l "codex" ~/.claude/settings*.json 2>/dev/null
```

**Also check if `mcp__codex__codex` tool is available** in the current session's tool list.

### 0.3 Present Dependency Status

Show the user what's installed and what's missing:

```
╔══════════════════════════════════════════════════════════════════╗
║  ACIS Dependency Check                                            ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  ralph-wiggum plugin:  [✓ Installed] or [✗ Not found]            ║
║  Codex MCP server:     [✓ Configured] or [✗ Not configured]      ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

### 0.4 Handle Missing Dependencies

For EACH missing dependency, use AskUserQuestion to prompt:

#### If ralph-wiggum is missing:

```
╔══════════════════════════════════════════════════════════════════╗
║  ralph-wiggum Plugin Not Found                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  This plugin provides:                                            ║
║    • Persistent remediation loops (/ralph-loop)                   ║
║    • Autonomous execution until goals are achieved                ║
║    • Process Auditor continuous mode                              ║
║                                                                   ║
║  WITHOUT IT, you will lose:                                       ║
║    ✗ /acis remediate will not persist across context limits       ║
║    ✗ /acis audit --continuous mode unavailable                    ║
║    ✗ Goals may need manual re-triggering if interrupted           ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

**Options (via AskUserQuestion):**
1. **Install ralph-wiggum (Recommended)** - "I'll install from the Claude marketplace"
2. **Continue without it** - "Proceed with limited functionality"
3. **I'll install it myself later** - "Skip and remind me in config"

**If user chooses to install:**
- Show installation instructions:
  ```
  To install ralph-wiggum:
  1. Open Claude Code settings
  2. Go to Plugins → Marketplace
  3. Search for "ralph-wiggum"
  4. Click Install

  Or run: /plugins install ralph-wiggum

  After installation, re-run /acis init
  ```
- Exit init (so they can install first)

**If user chooses to continue without:**
- Set `pluginDefaults.skipRalphLoop = true` in config
- Warn: "Remediation will require manual re-triggering if interrupted"

#### If Codex MCP is missing:

```
╔══════════════════════════════════════════════════════════════════╗
║  Codex MCP Server Not Configured                                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  This provides:                                                   ║
║    • External expert perspectives (Architect, Security, UX)       ║
║    • CEO-Alpha AI-native decision validation                      ║
║    • Deep architecture and algorithm analysis                     ║
║                                                                   ║
║  WITHOUT IT, you will lose:                                       ║
║    ✗ Codex expert delegations in /acis discovery                  ║
║    ✗ CEO-Alpha perspective in /acis resolve                       ║
║    ✗ External architecture reviews                                ║
║                                                                   ║
║  NOTE: ACIS still works with internal Claude agents only.         ║
║  Most features remain functional, just without external experts.  ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

**Options (via AskUserQuestion):**
1. **I'll configure Codex MCP** - "Show me how to set it up"
2. **Continue without Codex (Recommended for most users)** - "Use internal agents only"
3. **I'll configure it later** - "Skip and remind me in config"

**If user chooses to configure:**
- Show configuration instructions:
  ```
  To configure Codex MCP:
  1. Ensure you have claude-delegator or similar MCP server
  2. Add to your Claude MCP configuration:
     {
       "codex": {
         "command": "...",
         "args": [...]
       }
     }
  3. Restart Claude Code

  After configuration, re-run /acis init
  ```
- Exit init (so they can configure first)

**If user chooses to continue without:**
- Set `pluginDefaults.skipCodex = true` in config
- Note: "--skip-codex will be applied by default to all commands"

### 0.5 Record Plugin State

Store the dependency check results for later reference:

```json
"installedPlugins": {
  "ralphWiggum": {
    "installed": true|false,
    "checkedAt": "{ISO timestamp}",
    "userChoice": "installed|skipped|deferred"
  },
  "codexMcp": {
    "installed": true|false,
    "checkedAt": "{ISO timestamp}",
    "userChoice": "configured|skipped|deferred"
  }
}
```

### 0.6 Summary Before Proceeding

Always show summary of plugin configuration:

```
╔══════════════════════════════════════════════════════════════════╗
║  ACIS Plugin Configuration                                        ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Plugin Status:                                                   ║
║    • ralph-wiggum: [Installed ✓] or [Skipped ✗]                  ║
║    • Codex MCP:    [Configured ✓] or [Skipped ✗]                 ║
║                                                                   ║
║  Default Behavior:                                                ║
║    {If ralph-wiggum installed: "Ralph-loop enabled (--skip-ralph-loop to disable)"}
║    {If ralph-wiggum skipped:   "Ralph-loop disabled (--use-ralph-loop to enable)"}
║    {If Codex configured:       "Codex enabled (--skip-codex to disable)"}
║    {If Codex skipped:          "Codex disabled (--use-codex to enable)"}
║                                                                   ║
║  Config defaults set:                                             ║
║    pluginDefaults.skipCodex: {false if installed, true if skipped}
║    pluginDefaults.skipRalphLoop: {false if installed, true if skipped}
║                                                                   ║
║  You can change these later in .acis-config.json                  ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝

Continuing to project setup...
```

**Key principle**: Defaults match plugin availability. Override flags go the opposite direction.

---

## Step 1: Doc Detection

Search for existing project documentation using Glob:

```
Glob patterns to search:
- **/vision.md
- **/VISION.md
- **/prd.md
- **/PRD.md
- **/persona*.md
- **/PERSONA*.md
- **/requirements*.md
- **/REQUIREMENTS*.md
- README.md (check for Vision/Problem section)
```

If `--from-docs` flag is set or docs are found, proceed to Step 2.
If `--interactive` flag is set or no docs found, proceed to Step 3.

## Step 2: Extract from Docs

Read each found document and extract:

| Field | Source Documents |
|-------|------------------|
| `projectName` | README.md title, directory name |
| `vision.problem` | PRD problem statement, Vision doc |
| `vision.solution` | PRD solution, Vision doc |
| `vision.scope` | PRD scope section |
| `personas` | persona*.md files, PRD personas |
| `compliance` | PRD compliance section, security docs |
| `platform` | PRD technical requirements |

After extraction, show a validation preview and ask user to confirm or modify.

## Step 3: Dynamic Interview

Load the interview system:
1. Read `${CLAUDE_PLUGIN_ROOT}/interview/interview-flow.md` for behavior rules
2. Load `${CLAUDE_PLUGIN_ROOT}/interview/question-bank.json` for questions
3. Use AskUserQuestion tool for each question
4. Apply adaptive questioning rules (skip if already answered)

### Interview Phases

**Phase 1: Problem Space (3-5 questions)**
- What problem are you solving?
- Who experiences this problem?
- What's the core value proposition?
- What's explicitly out of scope?

**Phase 2: Solution Vision (3-5 questions)**
- Walk through the user journey
- What data does the system need?
- Offline/mobile requirements?

**Phase 3: Users & Personas (2-4 questions)**
- Who are primary users?
- Who are secondary users?
- Any anti-personas?

**Phase 4: Constraints & Compliance (2-3 questions)**
- Regulatory requirements?
- Technical constraints?
- Success metrics?

## Step 4: Generate Artifacts

After interview or extraction:

1. **Create Vision Summary** using `${CLAUDE_PLUGIN_ROOT}/interview/artifact-templates/vision-summary.md`
2. **Create User Journey Diagrams** using `${CLAUDE_PLUGIN_ROOT}/interview/artifact-templates/user-journey.md`
3. **Show validation preview** to user

## Step 5: Validation Preview

```
╔══════════════════════════════════════════════════════════════════╗
║  ACIS Project Configuration Preview                               ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Project: {ProjectName}                                          ║
║                                                                   ║
║  Problem: {one-line summary}                                     ║
║  Solution: {one-line summary}                                    ║
║                                                                   ║
║  Personas:                                                        ║
║    - {Name} (primary) - {role}                                   ║
║    - {Name} (secondary) - {role}                                 ║
║                                                                   ║
║  Compliance: {badges}                                            ║
║  Platform: {platforms}                                           ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝

Is this accurate?
  [Looks good, generate config]
  [I want to modify something]
  [Start over]
```

Use AskUserQuestion with these options.

## Step 6: Write Configuration

Generate `.acis-config.json` in project root:

```json
{
  "$schema": "${CLAUDE_PLUGIN_ROOT}/schemas/project-config.schema.json",
  "projectName": "{extracted}",
  "vision": {
    "problem": "{extracted}",
    "solution": "{extracted}",
    "scope": "{extracted}",
    "successMetrics": ["{extracted}"]
  },
  "personas": [
    {
      "name": "{extracted}",
      "role": "{extracted}",
      "type": "primary",
      "description": "{extracted}",
      "keyNeed": "{extracted}",
      "frustration": "{extracted}"
    }
  ],
  "compliance": ["{extracted}"],
  "architectureModel": "{extracted or 'custom'}",
  "platform": {
    "web": true,
    "mobile": false,
    "offline": false
  },
  "integrations": [],
  "goalsDirectory": "docs/reviews/goals",
  "skillsDirectory": "skills",
  "auditThreshold": 5,
  "pluginDefaults": {
    "skipCodex": false,
    "skipRalphLoop": false,
    "useInternalAgentsOnly": false
  },
  "installedPlugins": {
    "ralphWiggum": {
      "installed": true,
      "checkedAt": "{ISO timestamp}",
      "userChoice": "installed"
    },
    "codexMcp": {
      "installed": true,
      "checkedAt": "{ISO timestamp}",
      "userChoice": "configured"
    }
  },
  "generatedFrom": "interview | docs",
  "generatedAt": "{ISO timestamp}"
}
```

**Note on pluginDefaults:**

The values above show the "all plugins installed" case. Adjust based on Step 0 results:

| Plugin State | skipCodex | skipRalphLoop | Available Override |
|--------------|-----------|---------------|-------------------|
| Codex installed | `false` | - | `--skip-codex` to disable |
| Codex skipped | `true` | - | `--use-codex` to enable |
| ralph-wiggum installed | - | `false` | `--skip-ralph-loop` to disable |
| ralph-wiggum skipped | - | `true` | `--use-ralph-loop` to enable |

**Principle**: Defaults match availability. Override flags go the opposite direction.

**Example configs:**

All plugins installed:
```json
"pluginDefaults": { "skipCodex": false, "skipRalphLoop": false }
```

No plugins installed:
```json
"pluginDefaults": { "skipCodex": true, "skipRalphLoop": true, "useInternalAgentsOnly": true }
```

## Step 7: Install ACIS Hooks

**CRITICAL**: Install runtime hooks that ENFORCE path validation and provide pre-commit review reminders.

This step is NOT optional. Without hooks, path validation rules are just documentation.

### 7.1 Run Installation Script

Execute the hook installation script:

```bash
# Default: install both path validator AND pre-commit review hooks
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-hooks.sh" "${PROJECT_ROOT}"

# If --skip-pre-commit-hook flag was passed:
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-hooks.sh" "${PROJECT_ROOT}" --skip-pre-commit-hook
```

This will:
1. Create `${PROJECT_ROOT}/.claude/hooks/` directory
2. Copy `acis-path-validator.sh` to project
3. Copy `acis-pre-commit-hook.sh` to project (unless --skip-pre-commit-hook)
4. Create/update `${PROJECT_ROOT}/.claude/settings.json` with hook configuration

### 7.2 Hook Behaviors

**Path Validator** (intercepts Edit/Write operations):

| Detection | Action | Exit Code |
|-----------|--------|-----------|
| Nested ACIS path (`docs/acis/goals/docs/acis/goals`) | **BLOCK** | 2 |
| Absolute path in .acis-config.json | **BLOCK** | 2 |
| Path traversal (`..`) in config | **BLOCK** | 2 |
| ACIS artifact in non-standard location | **WARN** (allow) | 0 |

**Pre-Commit Review** (intercepts git commit via Bash):

| Condition | Action |
|-----------|--------|
| `git commit` with staged changes | Show reminder to run `/acis pre-commit-review` |
| `git commit --no-verify` | Skip reminder |
| `ACIS_SKIP_PRE_COMMIT=1` | Skip reminder |

The pre-commit hook is **non-blocking** - it shows a reminder but always allows the commit to proceed.

### 7.3 Show Installation Summary

```
╔══════════════════════════════════════════════════════════════════╗
║  ACIS Hooks Installed                                             ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Installed files:                                                 ║
║    • .claude/hooks/acis-path-validator.sh                        ║
║    • .claude/hooks/acis-pre-commit-hook.sh                       ║
║    • .claude/settings.json (updated)                             ║
║                                                                   ║
║  Path Validator will:                                             ║
║    ✗ BLOCK nested paths (docs/acis/goals/docs/acis/goals)        ║
║    ✗ BLOCK absolute paths in .acis-config.json                   ║
║    ✗ BLOCK path traversal (..) in config                         ║
║    ⚠ WARN about artifacts in non-standard locations              ║
║                                                                   ║
║  Pre-Commit Review will:                                          ║
║    • Remind you to run /acis pre-commit-review before commit     ║
║    • Non-blocking (you can proceed with commit)                  ║
║                                                                   ║
║  To skip pre-commit reminder:                                     ║
║    git commit --no-verify                                         ║
║    ACIS_SKIP_PRE_COMMIT=1 git commit                              ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

### 7.4 Hooks Already Exist

If hooks are already installed, the script detects this and skips:

```
ACIS hooks already installed.
```

## Optional Outputs

If user approves, also generate:
- `docs/vision.md` - Project vision document
- `docs/user-journeys.md` - Mermaid journey diagrams

## Completion Message

```
ACIS initialized successfully!

Configuration: .acis-config.json
Goals directory: docs/reviews/goals/
Skills directory: skills/ (populated by Process Auditor)
Hooks installed:
  - Path validator: .claude/hooks/acis-path-validator.sh (ACTIVE)
  - Pre-commit review: .claude/hooks/acis-pre-commit-hook.sh (ACTIVE)

Next steps:
  /acis status           - View current status
  /acis discovery        - Start feature discovery
  /acis extract          - Extract goals from PR review
  /acis pre-commit-review - Quick design review before committing

Notes:
  - Path validation hooks are now ACTIVE. Invalid paths will be BLOCKED.
  - Pre-commit hook will remind you to run /acis pre-commit-review.
    Skip with: git commit --no-verify
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Config already exists | Ask to overwrite or merge |
| Interview abandoned | Save partial state, offer resume |
| Doc extraction fails | Fall back to interactive mode |
| Invalid input | Re-ask question with clarification |

## Integration with Other Commands

Once `.acis-config.json` exists:
- `/acis discovery` uses personas for perspective framing
- `/acis remediate` references compliance requirements
- `/acis status` shows project context in header
- `/acis audit` uses auditThreshold for skill generation trigger
- All templates use `${config.projectName}`, `${config.personas}`, etc.
