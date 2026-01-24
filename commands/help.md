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
   ║  ACIS v2.1 - Automated Code Improvement System                               ║
   ║  https://github.com/aivantage-consulting/claude-plugin-acis                  ║
   ╠══════════════════════════════════════════════════════════════════════════════╣
   ║                                                                              ║
   ║  Available Commands:                                                         ║
   ║                                                                              ║
   ║  /acis:init          Bootstrap ACIS for a new project                       ║
   ║  /acis:status        Show progress across all goals                          ║
   ║  /acis:discovery     Multi-perspective investigation                         ║
   ║  /acis:extract       Extract goals from PR review comments                   ║
   ║  /acis:remediate     Full TDD remediation pipeline                           ║
   ║  /acis:resolve       Resolve pending decisions                               ║
   ║  /acis:verify        Run consensus verification                              ║
   ║  /acis:audit         Process Auditor - improve ACIS itself                   ║
   ║  /acis:help          This help (you are here)                                ║
   ║                                                                              ║
   ║  Quick Start:                                                                ║
   ║    1. /acis:init              (bootstrap project)                            ║
   ║    2. /acis:discovery "topic" (investigate)                                  ║
   ║    3. /acis:remediate <goal>  (fix issues)                                   ║
   ║    4. /acis:status            (track progress)                               ║
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
| `acis-init.md` or `init.md` | `/acis:init` | Bootstrap ACIS for a new project |
| `status.md` | `/acis:status` | Show progress across all goals |
| `discovery.md` | `/acis:discovery` | Multi-perspective investigation |
| `extract.md` | `/acis:extract` | Extract goals from PR review |
| `remediate.md` | `/acis:remediate` | Full TDD remediation pipeline |
| `resolve.md` | `/acis:resolve` | Resolve pending decisions |
| `verify.md` | `/acis:verify` | Run consensus verification |
| `acis-audit.md` or `audit.md` | `/acis:audit` | Process Auditor |

## Installation Status Check

Also check and report:

1. **Plugin Status**
   ```bash
   # Check if plugin is loaded via --plugin-dir or installed
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
