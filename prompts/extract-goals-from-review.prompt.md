# LLM Prompt: Extract Remediation Goals from Code Review

## Purpose

This prompt is used by Claude to extract quantifiable remediation goals from code review comments. It transforms natural language feedback into structured, measurable improvement targets.

## Input

You will receive:

1. **PR Number**: The pull request being reviewed
2. **Review Comments**: Raw comments from reviewers (Codex, Claude, Gemini, human)
3. **Code Context**: Relevant code snippets referenced in comments

## Output

Generate a JSON array of remediation goals conforming to the schema.

---

## Prompt

````
You are an expert code reviewer assistant. Your task is to analyze code review comments and extract QUANTIFIABLE remediation goals.

## Review Comments to Analyze

{{REVIEW_COMMENTS}}

## Referenced Code (if available)

{{CODE_CONTEXT}}

## Instructions

For each substantive review comment, determine if it can be converted into a measurable goal:

### 1. IDENTIFY Quantifiable Issues
Look for comments that mention:
- Specific code patterns (e.g., "Math.random", "console.log", "any type")
- Code smells (e.g., "empty catch blocks", "magic numbers")
- Security concerns (e.g., "hardcoded secrets", "SQL injection")
- Performance issues (e.g., "N+1 queries", "memory leaks")
- Accessibility gaps (e.g., "missing alt text", "no keyboard navigation")

### 2. SKIP Non-Quantifiable Comments
Skip comments that are:
- Subjective opinions without specific patterns
- Questions or clarifications
- Praise or acknowledgments
- Already resolved in the PR

### 3. For Each Quantifiable Issue, Extract:

**a) Detection Pattern**
- What regex or grep pattern would find this issue?
- What files should be searched?
- What should be excluded (tests, mocks)?

**b) Current State**
- How many instances exist currently?
- Use grep/ripgrep to count

**c) Target State**
- Should this be zero? Below a threshold? Reduced by X%?

**d) Remediation Strategy**
- What should replace the problematic pattern?
- Are there context-dependent rules?
- What imports are needed?

**e) Assessment Lens**
Categorize as: security | privacy | performance | maintainability | accessibility | architecture | testing | operational-costs

**f) Severity**
Rate as: critical | high | medium | low

### 4. Output Format

Return a JSON array:

```json
[
  {
    "id": "M1-descriptive-name",
    "source": {
      "reviewer": "codex|claude|gemini|human",
      "lens": "security",
      "severity": "high",
      "original_comment": "The original review comment text"
    },
    "detection": {
      "pattern": "regex pattern",
      "pattern_description": "Human readable description",
      "command": "grep -rE 'pattern' --include='*.ts' packages/ | wc -l",
      "file_types": ["*.ts", "*.tsx"],
      "exclusions": ["*.spec.ts", "*.test.ts"]
    },
    "target": {
      "type": "zero|threshold|reduction",
      "count": 0,
      "allowed_exceptions": {
        "in_tests": true,
        "in_mocks": true
      }
    },
    "remediation": {
      "strategy": "replace|remove|refactor|add",
      "replacement": "What to use instead",
      "guidance": "Step-by-step guidance for fixing"
    }
  }
]
````

### 5. Quality Criteria

Only include goals that are:

- **Measurable**: Can be verified with a command
- **Actionable**: Clear path to remediation
- **Specific**: Precise pattern, not vague
- **Valuable**: Addresses real code quality issue

## Example

**Input Comment**:
"Using Math.random() for generating user IDs is not secure. Should use crypto.getRandomValues() or a UUID library instead."

**Output Goal**:

```json
{
  "id": "M1-math-random-ids",
  "source": {
    "reviewer": "claude",
    "lens": "security",
    "severity": "high",
    "original_comment": "Using Math.random() for generating user IDs is not secure..."
  },
  "detection": {
    "pattern": "Math\\.random",
    "pattern_description": "Insecure random number generation",
    "command": "grep -rE 'Math\\.random' --include='*.ts' --include='*.tsx' --exclude='*.spec.ts' packages/ | wc -l",
    "file_types": ["*.ts", "*.tsx"],
    "exclusions": ["*.spec.ts", "*.test.ts", "__mocks__"]
  },
  "target": {
    "type": "zero",
    "count": 0,
    "allowed_exceptions": {
      "in_tests": true,
      "in_mocks": true
    }
  },
  "remediation": {
    "strategy": "replace",
    "replacement": "crypto.getRandomValues() for random numbers, uuid library for IDs",
    "guidance": "1. Identify usage context (ID generation vs random selection)\n2. For IDs: import { v4 as uuidv4 } from 'uuid'\n3. For random numbers: use crypto.getRandomValues()\n4. Update tests to verify new implementation"
  }
}
```

Now analyze the provided review comments and extract all quantifiable goals.

````

---

## Usage in ACIS

This prompt is invoked by the extraction script:

```bash
# The script fetches PR comments, then calls Claude with this prompt
./scripts/extract-review-goals-llm.sh <PR_NUMBER>
````

The LLM response is validated against the schema and saved to `docs/reviews/goals/`.
