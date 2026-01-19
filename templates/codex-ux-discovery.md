# Codex UX Discovery Template

Use this template when delegating to Codex for UX and Design analysis.

## Delegation Format

```
TASK: Analyze {GOAL_ID} for user experience implications across all personas.

EXPECTED OUTCOME: UX assessment with persona-specific acceptance criteria.

MODE: Advisory

CONTEXT:
- Goal: {GOAL_DESCRIPTION}
- Personas:
  - **Brenda**: Elderly patient (65+), primary app user, limited tech familiarity
  - **David**: Adult caregiver, manages Brenda's care remotely
  - **Dr. Evans**: Healthcare provider, occasional check-ins
- Current UX principles: Offline-first, large touch targets, high contrast
- Accessibility: WCAG 2.1 AA compliance required

CONSTRAINTS:
- Must support elderly users with potential vision/motor limitations
- Must work fully offline
- Voice input support for Brenda
- No cognitive overload - simple, clear flows

MUST DO:
- Analyze impact on each persona's journey
- Identify accessibility concerns
- Propose behavioral acceptance scenarios (Given/When/Then)
- Recommend error state handling from user's perspective
- Consider offline UX feedback

MUST NOT DO:
- Design for power users at expense of primary persona (Brenda)
- Introduce complex multi-step flows
- Ignore accessibility requirements

OUTPUT FORMAT:
## UX Impact Summary
[1-2 sentence summary]

## Persona Analysis

### Brenda (Elderly Patient)
- **Journey Impact**: [how this affects Brenda's typical flows]
- **Accessibility Concerns**: [vision, motor, cognitive]
- **Offline Experience**: [what happens when offline]

### David (Caregiver)
- **Journey Impact**: [how this affects David's monitoring]
- **Notification Needs**: [what should David be alerted to]

### Dr. Evans (Provider)
- **Journey Impact**: [how this affects provider review]

## Behavioral Acceptance Scenarios

### Scenario 1: {SCENARIO_NAME}
- **Persona**: {PERSONA}
- **Given**: [context/precondition]
- **When**: [action taken]
- **Then**: [expected outcome]
- **And**: [additional verification]

### Scenario 2: {SCENARIO_NAME}
[...]

## Accessibility Verification
- [ ] Touch target size >= 44x44 points
- [ ] Color contrast ratio >= 4.5:1
- [ ] Screen reader compatible
- [ ] Keyboard navigable
- [ ] Error messages are descriptive

## Offline UX Requirements
- [What should show when offline]
- [How to indicate data freshness]
- [Sync conflict resolution UX]
```

## Integration with ACIS

The UX response feeds into:
1. `behavioral.acceptance_scenarios`
2. `behavioral.personas`
3. `multi_perspective.discovery_results[codex-ux]`
