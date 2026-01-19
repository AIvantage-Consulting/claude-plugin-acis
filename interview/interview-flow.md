# ACIS Interview Flow

Orchestration and behavior rules for the `/acis init` dynamic interview system.

## Purpose

When no existing documentation is found (or `--interactive` is set), ACIS conducts a BA/PM-style discovery interview to capture project context for configuration.

## Interview Principles

### 1. Adaptive Questioning
- **Skip questions already answered** in previous responses
- If user mentions "HIPAA" in problem description, skip compliance question
- If user describes personas, skip persona questions
- Track answered topics in interview state

### 2. Clarifying Follow-ups
- Ask follow-ups when answers are vague or incomplete
- Use the optional follow-up questions from question-bank.json
- Maximum 2 follow-ups per question before moving on

### 3. Summarize & Confirm
- After each phase, summarize understanding
- Ask user to confirm before proceeding to next phase
- "Let me make sure I understand: {summary}. Is this correct?"

### 4. Non-Judgmental Discovery
- Accept all answers without critique
- This is discovery, not design review
- Don't suggest improvements during interview
- Save recommendations for post-interview

### 5. Time-Boxed Interaction
- Target: 10-15 minutes total interview time
- Phase 1 (Problem): 3-5 minutes
- Phase 2 (Solution): 3-5 minutes
- Phase 3 (Personas): 2-3 minutes
- Phase 4 (Constraints): 2-3 minutes

## Interview State

Track state during interview:

```json
{
  "currentPhase": 1,
  "answeredTopics": ["problem", "scope"],
  "extractedData": {
    "projectName": null,
    "problem": "...",
    "solution": null,
    "personas": [],
    "compliance": [],
    "platform": {}
  },
  "followUpCount": {
    "Q1": 0,
    "Q2": 1
  },
  "phaseConfirmed": {
    "1": false,
    "2": false,
    "3": false,
    "4": false
  }
}
```

## Phase Transitions

```
Phase 1 (Problem Space)
        │
        ▼
[Summarize & Confirm]
        │
        ▼
Phase 2 (Solution Vision)
        │
        ▼
[Summarize & Confirm]
        │
        ▼
Phase 3 (Users & Personas)
        │
        ▼
[Summarize & Confirm]
        │
        ▼
Phase 4 (Constraints & Compliance)
        │
        ▼
[Final Summary & Validation]
        │
        ▼
Generate Artifacts
```

## Question Delivery

Use AskUserQuestion tool for each question:

```typescript
AskUserQuestion({
  questions: [{
    question: questionText,
    header: shortLabel,
    options: [
      { label: "Option 1", description: "..." },
      { label: "Option 2", description: "..." },
      // "Other" is automatically added
    ],
    multiSelect: false
  }]
})
```

For open-ended questions, provide example options:
- Previous answers as templates
- Common patterns in similar projects
- "Other" for custom input

## Follow-up Logic

```
IF answer is vague:
  IF followUpCount < 2:
    Ask follow-up question
    Increment followUpCount
  ELSE:
    Accept answer as-is
    Move to next question
```

## Topic Detection

Scan answers for automatic topic completion:

| Keywords | Mark as Answered |
|----------|------------------|
| "HIPAA", "GDPR", "SOC2", "PCI" | compliance |
| "offline", "no internet" | platform.offline |
| "mobile", "iOS", "Android" | platform.mobile |
| "elderly", "patient", "caregiver" | personas (healthcare) |
| "React", "Vue", "web app" | platform.web |

## Phase Summaries

### Phase 1 Summary Template
```
Based on our conversation:

Problem: {extracted_problem}
Who's affected: {affected_parties}
Current state: {without_solution}
Core value: {value_proposition}

Does this capture the problem accurately?
```

### Phase 2 Summary Template
```
For the solution:

Main workflow: {user_journey}
Critical action: {critical_action}
Data needs: {data_requirements}
Platform: {platform_requirements}

Is this how you envision the solution?
```

### Phase 3 Summary Template
```
Users identified:

Primary:
  - {persona_name}: {role}, needs {key_need}

Secondary:
  - {persona_name}: {role}, interacts via {interaction}

Anyone I'm missing?
```

### Phase 4 Summary Template
```
Constraints & success:

Compliance: {compliance_list}
Tech constraints: {tech_constraints}
Success looks like: {success_metrics}

Ready to generate configuration?
```

## Error Recovery

| Scenario | Recovery |
|----------|----------|
| User says "I don't know" | Provide example, mark as optional |
| User wants to go back | Return to previous phase |
| User wants to skip | Mark topic as skipped, continue |
| User abandons interview | Save state, offer resume later |

## Completion Criteria

Interview is complete when:
- [ ] All 4 phases confirmed OR user explicitly skips
- [ ] At least projectName, problem, and one persona captured
- [ ] User approves final summary

## Output

Interview produces:
1. Populated interview state with extractedData
2. Ready for artifact generation (vision-summary.md, user-journey.md)
3. Ready for .acis-config.json generation
