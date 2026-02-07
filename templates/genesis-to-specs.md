# GENESIS to Implementation Specs Conversion Template

You are converting GENESIS output documents into actionable implementation specification JSON files. Each subsystem identified in GENESIS becomes one implementation spec.

## Input Documents

Read and analyze these GENESIS output files:

1. **SUBSYSTEMS_DRAFT.md** - Primary source for subsystem definitions
2. **ARCHITECTURE_DRAFT.md** - Boundaries, communication patterns, layers
3. **ADR files (ADR-*.md)** - Architectural constraints and decisions
4. **JOURNEYS_DRAFT.md** - User journey acceptance criteria
5. **PERSONAS_DRAFT.md** - User personas for context (if available)

## Extraction Process

### Step 1: Extract Subsystems from SUBSYSTEMS_DRAFT.md

For each subsystem section:
- **subsystem_name**: The subsystem heading/title
- **description**: The subsystem description (must be 20+ characters)
- **spec_id**: Generate as `SPEC-{kebab-case-name}` (e.g., `SPEC-auth-service`)

### Step 2: Extract Boundaries from ARCHITECTURE_DRAFT.md

For each subsystem:
- **directories_to_create**: Infer directory structure from architecture layers
- **files_to_create**: List key files (index/entry point, types, tests)
- **exports**: Public API surface described in architecture
- **communication_patterns**: How this subsystem talks to others

### Step 3: Extract Constraints from ADRs

For each ADR that mentions a subsystem:
- **adr_constraints**: Record the ADR ID and the specific constraint
- **adr_refs**: Link ADR IDs to the spec's source

### Step 4: Extract Acceptance Criteria from JOURNEYS_DRAFT.md

For each user journey that touches a subsystem:
- **criterion**: The user story or acceptance criterion
- **verification**: How to verify (test command or description)
- **source**: Reference back to JOURNEYS_DRAFT.md section

### Step 5: Determine Complexity Tier

Classify each subsystem:
- **Tier 1**: Single-purpose utility, straightforward logic, few files
- **Tier 2**: Multi-file subsystem, some integration points, moderate logic
- **Tier 3**: Complex subsystem, many integration points, architecture-significant

### Step 6: Build Dependency Graph

From boundary.dependencies and communication_patterns:
- Identify which specs depend on others
- Perform topological sort to determine build order
- Group independent specs for parallel execution

## Output Format

For each subsystem, generate a JSON file conforming to `implementation-spec.schema.json`:

```json
{
  "spec_id": "SPEC-{kebab-case-name}",
  "subsystem_name": "{Subsystem Name}",
  "description": "{20+ character description from SUBSYSTEMS_DRAFT.md}",
  "source": {
    "genesis_dir": "{genesis_dir_path}",
    "subsystem_ref": "{Section reference in SUBSYSTEMS_DRAFT.md}",
    "adr_refs": ["ADR-001", "ADR-003"],
    "architecture_ref": "{Section reference in ARCHITECTURE_DRAFT.md}",
    "journey_refs": ["Journey: {name}"]
  },
  "boundary": {
    "directories_to_create": ["src/{subsystem-name}/"],
    "files_to_create": [
      "src/{subsystem-name}/index.ts",
      "src/{subsystem-name}/types.ts",
      "src/{subsystem-name}/__tests__/{subsystem-name}.test.ts"
    ],
    "exports": ["public API functions/classes/types"],
    "dependencies": ["SPEC-other-subsystem"],
    "communication_patterns": [
      {
        "target": "SPEC-other-subsystem",
        "pattern": "direct-import",
        "interface": "Interface description"
      }
    ]
  },
  "verification": {
    "build_command": "{project build command}",
    "test_command": "{subsystem test command}",
    "lint_command": "{subsystem lint command}",
    "api_surface_check": "grep -r 'export' src/{subsystem-name}/ | wc -l"
  },
  "acceptance_criteria": [
    {
      "criterion": "{From JOURNEYS_DRAFT.md}",
      "verification": "{test command or description}",
      "source": "JOURNEYS_DRAFT.md: {section}"
    }
  ],
  "complexity_tier": "1|2|3",
  "adr_constraints": [
    {
      "adr_id": "ADR-001",
      "constraint": "{Specific constraint text}"
    }
  ],
  "status": "pending"
}
```

## Guidelines

1. **Be specific**: File paths and commands must be concrete, not placeholders
2. **Respect architecture layers**: Directory structure should reflect the architecture
3. **Include tests**: Every subsystem must have at least one test file in files_to_create
4. **Minimal dependencies**: Only list actual dependencies, not aspirational ones
5. **Verification must be runnable**: All commands must be executable in the project context
6. **Acceptance criteria must be testable**: Each criterion needs a concrete verification method
