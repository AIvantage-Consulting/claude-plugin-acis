# Remediation Loop Prompt Template

## Purpose

This template is used by ralph-loop to iteratively remediate code issues until all goals are achieved.
The loop will repeat until the completion promise is output.

---

## Template Variables

Replace these placeholders before invoking ralph-loop:

| Variable             | Description            | Example                                  |
| -------------------- | ---------------------- | ---------------------------------------- |
| `{{GOAL_FILE}}`      | Path to goal JSON file | `docs/reviews/goals/M1-math-random.json` |
| `{{GOAL_ID}}`        | Goal identifier        | `M1-math-random`                         |
| `{{PATTERN}}`        | Pattern to find        | `Math\.random`                           |
| `{{TARGET_COUNT}}`   | Target count           | `0`                                      |
| `{{REPLACEMENT}}`    | What to replace with   | `crypto.getRandomValues`                 |
| `{{LENS}}`           | Assessment lens        | `security`                               |
| `{{MAX_ITERATIONS}}` | Safety limit           | `20`                                     |

---

## Prompt Template

````markdown
# Remediation Loop: {{GOAL_ID}}

## Objective

Reduce occurrences of `{{PATTERN}}` from current count to {{TARGET_COUNT}}.

## Context

- Goal File: {{GOAL_FILE}}
- Lens: {{LENS}}
- Replacement: {{REPLACEMENT}}

## Instructions

### Phase 1: MEASURE

Run the detection command and record current count:

```bash
grep -rE "{{PATTERN}}" --include="*.ts" --include="*.tsx" \
  --exclude="*.spec.ts" --exclude="*.test.ts" \
  packages/mobile/src packages/web/src 2>/dev/null | wc -l
```
````

Record: CURRENT_COUNT = [result]

### Phase 2: CHECK COMPLETION

If CURRENT_COUNT <= {{TARGET_COUNT}}:

- Output: `<promise>GOAL_{{GOAL_ID}}_ACHIEVED</promise>`
- Stop iteration

### Phase 3: ANALYZE (if not complete)

1. List all files containing the pattern
2. Categorize by context (which are safe to change, which need investigation)
3. Identify 1-3 files to fix in this iteration

### Phase 4: FIX (TDD)

For each file identified:

#### 4a. RED - Write/update test

```typescript
// Test that the replacement works correctly
it('should use secure random generation', () => {
  // Test the new implementation
});
```

#### 4b. GREEN - Make minimal fix

- Replace `{{PATTERN}}` with `{{REPLACEMENT}}`
- Add required imports
- Ensure tests pass

#### 4c. VERIFY

- Run tests for affected files
- Run detection command again
- Record new count

### Phase 5: REPORT

Output a structured checkpoint:

```
## Iteration Report

### Measurements
- Previous count: [X]
- Files fixed this iteration: [list]
- New count: [Y]
- Progress: [X - Y] instances fixed

### Changes Made
- [file1]: [what was changed]
- [file2]: [what was changed]

### Remaining Work
- [N] instances remaining in [M] files

### Next Iteration Focus
- [file or area to target next]
```

### Phase 6: LOOP DECISION

- If new*count <= {{TARGET_COUNT}}: Output `<promise>GOAL*{{GOAL_ID}}\_ACHIEVED</promise>`
- If new_count > {{TARGET_COUNT}}: Continue to next iteration
- If stuck (no progress for 3 iterations): Output `<promise>GOAL_{{GOAL_ID}}_BLOCKED</promise>` with explanation

## Safety Rules

1. Never delete tests to make goals pass
2. Never use `@ts-ignore` or `any` to bypass issues
3. Each fix must include appropriate tests
4. Maximum {{MAX_ITERATIONS}} iterations (safety limit)
5. If a fix would break other functionality, document and defer

## Completion Promises

- Success: `<promise>GOAL_{{GOAL_ID}}_ACHIEVED</promise>`
- Blocked: `<promise>GOAL_{{GOAL_ID}}_BLOCKED</promise>`
- Max iterations reached: `<promise>GOAL_{{GOAL_ID}}_MAX_ITERATIONS</promise>`

````

---

## Example: Math.random() Remediation

```bash
# Generate the prompt
./scripts/generate-ralph-prompt.sh \
  --goal-file docs/reviews/goals/M1-math-random.json \
  --max-iterations 20

# Start ralph-loop
/ralph-loop "$(cat /tmp/remediation-prompt.md)" \
  --completion-promise "GOAL_M1-math-random_ACHIEVED" \
  --max-iterations 20
````

---

## Multi-Goal Orchestration

For multiple goals, use the orchestrator:

```bash
# Process all goals in a directory
./scripts/orchestrate-remediation.sh docs/reviews/goals/ --sequential

# Or in parallel (for independent goals)
./scripts/orchestrate-remediation.sh docs/reviews/goals/ --parallel --max-concurrent 3
```
