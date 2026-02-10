# ACIS Help - Dynamic Command Discovery

You are executing the ACIS help system. This command dynamically discovers and documents all available ACIS commands.

## Arguments

- `$ARGUMENTS` - Optional: specific command name to get detailed help (e.g., `remediate`, `discovery`)

## Behavior

### When invoked with no arguments: `/acis:help`

1. **Discover Available Commands**

   Scan the plugin's commands directory to find all command files:
   ```bash
   ls -1 "${CLAUDE_PLUGIN_ROOT}/commands/"*.md 2>/dev/null | while read -r file; do
     basename "$file" .md
   done
   ```

2. **Extract Command Metadata**

   For each command file, extract:
   - **Name**: Filename without `.md` extension
   - **Description**: First non-empty line after `# ` heading, or first paragraph
   - **Arguments**: Look for `## Arguments` section
   - **Key Flags**: Look for `## Flags` section (first 5 flags)

3. **Present Formatted Help**

   Output in this format:
   ```
   ╔══════════════════════════════════════════════════════════════════════════════╗
   ║  ACIS v2.10.0 - Automated Code Improvement System                           ║
   ║  https://github.com/aivantage-consulting/claude-plugin-acis                 ║
   ╠══════════════════════════════════════════════════════════════════════════════╣
   ║                                                                              ║
   ║  COMMANDS:                                                                   ║
   ║                                                                              ║
   ║  /acis:init                Bootstrap ACIS for a project                      ║
   ║                            Creates .acis-config.json via interview or        ║
   ║                            doc extraction                                    ║
   ║                            Example: /acis:init                               ║
   ║                                                                              ║
   ║  /acis:genesis             Transform vision into system architecture         ║
   ║                            4-layer agent swarm: Analysis -> Synthesis ->     ║
   ║                            Challenge -> Arbitrate                            ║
   ║                            Example: /acis:genesis --output docs/genesis/     ║
   ║                                                                              ║
   ║  /acis:implement-parallel  Build subsystems from GENESIS specs in parallel   ║
   ║                            Uses git worktrees for isolation, merges via      ║
   ║                            integration branch                                ║
   ║                            Example: /acis:implement-parallel                 ║
   ║                                     --genesis docs/genesis/                  ║
   ║                                                                              ║
   ║  /acis:discovery           Multi-perspective investigation of a topic        ║
   ║                            10+ agents analyze in parallel, surfaces          ║
   ║                            decisions                                         ║
   ║                            Example: /acis:discovery "offline sync strategy"  ║
   ║                                     --type feature                           ║
   ║                                                                              ║
   ║  /acis:resolve             Resolve pending decisions from discovery          ║
   ║                            Auto-approves CEO-aligned decisions, prompts      ║
   ║                            for conflicts                                     ║
   ║                            Example: /acis:resolve                            ║
   ║                                     docs/acis/decisions/DISC-*.json          ║
   ║                                                                              ║
   ║  /acis:extract             Extract remediation goals from PR review          ║
   ║                            Generates goal JSON files with detection          ║
   ║                            commands                                          ║
   ║                            Example: /acis:extract PR-55                      ║
   ║                                                                              ║
   ║  /acis:remediate           Full TDD remediation pipeline for a single goal   ║
   ║                            Discovery -> Behavioral TDD -> Fix Loop ->       ║
   ║                            Verification                                      ║
   ║                            Example: /acis:remediate                          ║
   ║                                     docs/acis/goals/G1.json                  ║
   ║                                                                              ║
   ║  /acis:remediate-parallel  Remediate multiple goals in parallel via          ║
   ║                            worktrees                                         ║
   ║                            Isolated execution, integration merge, squash     ║
   ║                            to main                                           ║
   ║                            Example: /acis:remediate-parallel G1 G2 G3        ║
   ║                                                                              ║
   ║  /acis:verify              Re-run consensus verification for a goal          ║
   ║                            Independent multi-agent metric verification       ║
   ║                            Example: /acis:verify                             ║
   ║                                     docs/acis/goals/G1.json                  ║
   ║                                                                              ║
   ║  /acis:pre-commit-review   Quick design review of staged changes             ║
   ║                            PASS/WARN/BLOCK verdicts, strict mode by          ║
   ║                            default                                           ║
   ║                            Example: /acis:pre-commit-review --advisory       ║
   ║                                                                              ║
   ║  /acis:audit               Process Auditor - analyze and improve ACIS        ║
   ║                            Extracts patterns into skills, routes             ║
   ║                            improvements                                      ║
   ║                            Example: /acis:audit                              ║
   ║                                                                              ║
   ║  /acis:feedback            Report bugs, request features, or give feedback   ║
   ║                            Submits to GitHub or saves locally                ║
   ║                            Example: /acis:feedback --type bug_report         ║
   ║                                                                              ║
   ║  /acis:status              Show progress across all goals and manifests      ║
   ║                            Example: /acis:status                             ║
   ║                                                                              ║
   ║  /acis:upgrade             Check for and install missing ACIS components     ║
   ║                            Example: /acis:upgrade                            ║
   ║                                                                              ║
   ║  /acis:version             Display installed plugin version                  ║
   ║                            Example: /acis:version --short                    ║
   ║                                                                              ║
   ║  /acis:help                This help system                                  ║
   ║                            Example: /acis:help remediate                     ║
   ║                                                                              ║
   ║  ────────────────────────────────────────────────────────────────────────── ║
   ║                                                                              ║
   ║  QUICK START:                                                                ║
   ║    1. /acis:init              (bootstrap project)                            ║
   ║    2. /acis:discovery "topic" (investigate)                                  ║
   ║    3. /acis:remediate <goal>  (fix issues)                                   ║
   ║    4. /acis:status            (track progress)                               ║
   ║                                                                              ║
   ║  ────────────────────────────────────────────────────────────────────────── ║
   ║                                                                              ║
   ║  WORKFLOW SCENARIOS:                                                         ║
   ║                                                                              ║
   ║  Greenfield Project (starting from scratch):                                 ║
   ║    1. /acis:genesis                    <- Vision -> Architecture             ║
   ║    2. /acis:init --from-genesis        <- Create project config              ║
   ║    3. /acis:implement-parallel         <- Build subsystems in parallel       ║
   ║    4. /acis:pre-commit-review          <- Review before each commit          ║
   ║    5. /acis:audit                      <- Improve process                    ║
   ║                                                                              ║
   ║  Brownfield Project (existing codebase):                                     ║
   ║    1. /acis:init                       <- Bootstrap with interview/docs      ║
   ║    2. /acis:extract PR-{N}             <- Extract goals from PR review       ║
   ║    3. /acis:remediate-parallel G1 G2   <- Fix issues in parallel             ║
   ║    4. /acis:audit                      <- Learn from remediations            ║
   ║                                                                              ║
   ║  Feature Development:                                                        ║
   ║    1. /acis:discovery "topic"          <- Surface decisions                  ║
   ║    2. /acis:resolve manifest.json      <- Resolve decisions                  ║
   ║    3. /acis:remediate goal.json        <- Implement with TDD                 ║
   ║    4. /acis:verify goal.json           <- Verify independently               ║
   ║                                                                              ║
   ║  Ongoing Maintenance:                                                        ║
   ║    1. /acis:pre-commit-review          <- Every commit                       ║
   ║    2. /acis:extract PR-{N}             <- After PR review                    ║
   ║    3. /acis:remediate goal.json        <- Fix findings                       ║
   ║    4. /acis:audit                      <- Periodic improvement               ║
   ║                                                                              ║
   ║  Quick Bug Fix:                                                              ║
   ║    1. /acis:extract PR-{N}             <- Extract the issue                  ║
   ║    2. /acis:remediate goal.json        <- Fast fix                           ║
   ║       --no-behavioral                                                        ║
   ║                                                                              ║
   ║  ────────────────────────────────────────────────────────────────────────── ║
   ║                                                                              ║
   ║  For detailed help on a command: /acis:help <command>                        ║
   ║  Example: /acis:help remediate                                               ║
   ║                                                                              ║
   ╚══════════════════════════════════════════════════════════════════════════════╝
   ```

### When invoked with a command name: `/acis:help <command>`

1. **Locate Command File**

   Check for the command file:
   ```bash
   command_file="${CLAUDE_PLUGIN_ROOT}/commands/${ARGUMENTS}.md"
   if [ ! -f "$command_file" ]; then
     # Try with acis- prefix
     command_file="${CLAUDE_PLUGIN_ROOT}/commands/acis-${ARGUMENTS}.md"
   fi
   ```

2. **Extract Detailed Documentation**

   Read the command file and extract:
   - Full description (first section)
   - Arguments
   - All flags with descriptions
   - Examples (if present)
   - Workflow overview (if present)

3. **Present Detailed Help**

   Output in this format:
   ```
   ╔══════════════════════════════════════════════════════════════════════════════╗
   ║  /acis:remediate - Full TDD Remediation Pipeline                             ║
   ╠══════════════════════════════════════════════════════════════════════════════╣
   ║                                                                              ║
   ║  DESCRIPTION:                                                                ║
   ║    Execute the full ACIS remediation pipeline for a goal file:               ║
   ║    Discovery → Behavioral TDD → Ralph-Loop → Consensus Verification          ║
   ║                                                                              ║
   ║  USAGE:                                                                      ║
   ║    /acis:remediate <goal-file> [flags]                                       ║
   ║                                                                              ║
   ║  ARGUMENTS:                                                                  ║
   ║    <goal-file>    Path to goal JSON file (e.g., docs/acis/goals/G1.json)    ║
   ║                                                                              ║
   ║  FLAGS:                                                                      ║
   ║    --no-behavioral      Skip behavioral TDD phase                            ║
   ║    --no-consensus       Skip consensus verification                          ║
   ║    --skip-codex         Skip Codex delegations                               ║
   ║    --force-codex        Require Codex (error if unavailable)                 ║
   ║    --discovery-only     Run discovery phase only                             ║
   ║    --max-iterations N   Maximum loop iterations (default: 20)                ║
   ║    --deep-5whys         Multi-perspective 5 Whys analysis                    ║
   ║                                                                              ║
   ║  EXAMPLES:                                                                   ║
   ║    /acis:remediate docs/acis/goals/PR55-G1.json                             ║
   ║    /acis:remediate docs/acis/goals/G1.json --skip-codex                     ║
   ║    /acis:remediate docs/acis/goals/G1.json --force-full                     ║
   ║                                                                              ║
   ╚══════════════════════════════════════════════════════════════════════════════╝
   ```

## Dynamic Discovery Algorithm

```python
def discover_commands():
    """Dynamically discover all ACIS commands from the plugin directory."""
    commands = {}
    commands_dir = f"{CLAUDE_PLUGIN_ROOT}/commands"

    for file in glob(f"{commands_dir}/*.md"):
        name = basename(file, ".md")

        # Skip the main acis.md (subcommands are now separate files)
        # But include it if no separate files exist

        content = read_file(file)

        # Extract description from first heading or paragraph
        description = extract_description(content)

        # Extract arguments section
        arguments = extract_section(content, "## Arguments")

        # Extract flags section
        flags = extract_section(content, "## Flags")

        # Extract examples section
        examples = extract_section(content, "## Examples")

        commands[name] = {
            "name": name,
            "file": file,
            "description": description,
            "arguments": arguments,
            "flags": flags,
            "examples": examples
        }

    return commands
```

## Command Mapping

When presenting commands, use these display names:

| File Name | Display Name | Short Description |
|-----------|--------------|-------------------|
| `help.md` | `/acis:help` | Dynamic help system |
| `acis-init.md` or `init.md` | `/acis:init` | Bootstrap ACIS for a project |
| `genesis.md` | `/acis:genesis` | Transform vision into system architecture |
| `implement-parallel.md` | `/acis:implement-parallel` | Build subsystems from GENESIS specs in parallel |
| `status.md` | `/acis:status` | Show progress across all goals and manifests |
| `discovery.md` | `/acis:discovery` | Multi-perspective investigation |
| `extract.md` | `/acis:extract` | Extract goals from PR review |
| `remediate.md` | `/acis:remediate` | Full TDD remediation pipeline |
| `remediate-parallel.md` | `/acis:remediate-parallel` | Parallel remediation via worktrees |
| `resolve.md` | `/acis:resolve` | Resolve pending decisions |
| `verify.md` | `/acis:verify` | Run consensus verification |
| `pre-commit-review.md` | `/acis:pre-commit-review` | Quick design review of staged changes |
| `acis-audit.md` or `audit.md` | `/acis:audit` | Process Auditor |
| `feedback.md` | `/acis:feedback` | Report bugs, request features, give feedback |
| `upgrade.md` | `/acis:upgrade` | Check for and install missing components |
| `version.md` | `/acis:version` | Display installed plugin version |

## Installation Status Check

Also check and report:

1. **Plugin Status**
   ```bash
   # Check if plugin is loaded via --plugin-dir or installed
   plugin_version=$(jq -r '.version' "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" 2>/dev/null || echo "unknown")
   echo "ACIS v${plugin_version}"
   echo "Plugin loaded from: ${CLAUDE_PLUGIN_ROOT}"
   ```

2. **Project Configuration**
   ```bash
   # Check for .acis-config.json
   if [ -f ".acis-config.json" ]; then
     echo "Project configured: YES"
     jq -r '.projectName // "unnamed"' .acis-config.json
   else
     echo "Project configured: NO (run /acis:init)"
   fi
   ```

3. **Optional Dependencies**
   ```bash
   # Check for Codex MCP
   # Check for ralph-wiggum plugin
   # Report availability
   ```

## Output Format Guidelines

- Use box-drawing characters for visual structure
- Keep lines under 80 characters when possible
- Use consistent indentation (2 spaces)
- Highlight important commands with emphasis
- Include "Quick Start" section for new users
- Include "Workflow Scenarios" section with chained command examples
- Always end with pointer to detailed help

## Error Handling

If command not found:
```
╔══════════════════════════════════════════════════════════════════════════════╗
║  Command not found: {ARGUMENTS}                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  Did you mean one of these?                                                  ║
║    /acis:remediate                                                           ║
║    /acis:resolve                                                             ║
║                                                                              ║
║  Run /acis:help for a list of all commands.                                  ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```
