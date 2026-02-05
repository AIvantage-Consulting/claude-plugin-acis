# Codex Pre-Commit Review Template

Quick design/architecture review for staged changes before commit. Focus on catching design issues early, not style or formatting.

## Delegation Format

```markdown
TASK: Quick design review of staged changes before commit

EXPECTED OUTCOME: PASS, WARN, or BLOCK verdict with specific file:line findings (max 3)

MODE: Advisory (read-only)

## Staged Changes

- **Files**: {FILE_COUNT}
- **Lines changed**: {LINE_COUNT}
- **Architecture model**: {ARCHITECTURE_MODEL}
- **Compliance requirements**: {COMPLIANCE}

### Files Changed

{STAGED_FILES}

### Diff

```diff
{STAGED_DIFF}
```

---

## Review Focus Areas (Design/Architecture ONLY)

Check ONLY these high-signal design issues:

### 1. SOLID Violations (Priority)

| Principle | What to Look For |
|-----------|------------------|
| **Single Responsibility** | Class/function doing multiple unrelated things |
| **Dependency Inversion** | High-level modules importing concrete implementations |

Skip: Open/Closed, Liskov, Interface Segregation (too nuanced for quick review)

### 2. Layer Violations

| Pattern | Problem |
|---------|---------|
| Foundation → Journey | Lower layer importing from higher |
| Service → UI | Business logic importing UI components |
| Core → Infrastructure | Domain importing external services directly |

### 3. Coupling Red Flags

| Signal | Issue |
|--------|-------|
| God object | Single class with 10+ dependencies |
| Feature envy | Excessive use of another class's internals |
| Shotgun surgery | Single change requires modifying many files |

### 4. Naming That Obscures Intent

| Signal | Issue |
|--------|-------|
| `Manager`, `Handler`, `Processor` | Often indicates SRP violation |
| Generic names (`data`, `item`, `result`) | Hides what's actually happening |
| Mismatched name/behavior | Function name doesn't match what it does |

---

## DO NOT CHECK (Linters Handle These)

- Formatting, whitespace, indentation
- Import ordering
- Variable naming conventions (camelCase, etc.)
- Missing semicolons/commas
- Line length
- Comment style

---

## Constraints

- **Time budget**: Complete review in <30 seconds
- **Finding limit**: Maximum 3 findings (prioritize by severity)
- **Specificity**: Every finding MUST have file:line reference
- **Actionable**: Every finding MUST have concrete suggestion

---

## Output Format

### Verdict: {PASS | WARN | BLOCK}

**PASS**: No significant design concerns
**WARN**: Issues worth noting but not blocking
**BLOCK**: Significant design problems that should be fixed

### Findings

{If PASS, just say "No design concerns detected."}

{If WARN or BLOCK, format each finding as:}

[W1] {Issue Title}
     File: {file_path}:{line_number}
     Issue: {One sentence describing the problem}
     Suggestion: {Concrete fix, not vague advice}

### Summary

{One sentence summary: what's good, what's concerning}
```

## Example Output: PASS

```
### Verdict: PASS

No design concerns detected.

### Summary

Clean separation of concerns. Auth logic properly encapsulated in AuthService.
```

## Example Output: WARN

```
### Verdict: WARN

[W1] Dependency Direction
     File: src/services/UserService.ts:23
     Issue: Service imports UserCard component from UI layer
     Suggestion: Move UserDTO type to shared/types, import from there

[W2] Naming Concern
     File: src/core/DataManager.ts:1
     Issue: "Manager" class handling validation, persistence, and notifications
     Suggestion: Consider splitting into Validator, Repository, Notifier

### Summary

Good overall structure. Two naming/layering issues that may cause maintenance pain later.
```

## Example Output: BLOCK

```
### Verdict: BLOCK

[B1] Critical Layer Breach
     File: src/foundation/database.ts:45
     Issue: Foundation layer imports JourneyContext from journey layer
     Suggestion: Foundation must never depend on Journey. Extract shared interface to foundation/contracts.ts

[B2] Single Responsibility Violation
     File: src/core/AuthController.ts
     Issue: Single class handles HTTP parsing, auth logic, database writes, and email sending
     Suggestion: Split into AuthController (HTTP), AuthService (logic), AuthRepository (DB), NotificationService (email)

### Summary

Significant architecture violations that will compound if committed. Recommend addressing before merge.
```

## Integration Notes

### Calling from ACIS

```typescript
// Load template
const template = read("${CLAUDE_PLUGIN_ROOT}/templates/codex-pre-commit-review.md");

// Fill variables
const prompt = template
  .replace("{FILE_COUNT}", stagedFiles.length)
  .replace("{LINE_COUNT}", lineCount)
  .replace("{STAGED_FILES}", stagedFiles.join("\n"))
  .replace("{STAGED_DIFF}", diff.slice(0, MAX_DIFF_LINES))
  .replace("{ARCHITECTURE_MODEL}", config?.architectureModel || "unknown")
  .replace("{COMPLIANCE}", config?.compliance?.join(", ") || "none specified");

// Delegate
mcp__codex__codex({
  prompt: prompt,
  "developer-instructions": "You are a senior software architect doing a quick pre-commit review. Be concise, specific, and actionable. No generic advice.",
  sandbox: "read-only",
  cwd: projectRoot
});
```

### Response Handling

```typescript
const handleResponse = (response) => {
  const verdictMatch = response.match(/### Verdict: (PASS|WARN|BLOCK)/);
  const verdict = verdictMatch?.[1] || "WARN"; // Default to WARN if parsing fails

  return {
    verdict,
    findings: parseFindings(response),
    summary: parseSummary(response)
  };
};
```

## Flags

| Flag | Effect on Template |
|------|-------------------|
| `--skip-codex` | Don't use this template, use heuristics instead |
| `--strict` | No template change, affects exit code handling |
| `--quiet` | No template change, affects output display |
