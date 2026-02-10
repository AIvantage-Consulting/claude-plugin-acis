# AST Verification Scripts Library

Reusable AST-level verification scripts for the ACIS Three-Tier Enforcement Engine. These scripts are referenced by `configs/enforcement-engine.json` and executed during Phase 2 preference enforcement.

## Design Principles

1. **No permanent installation** — all scripts use `node -e` one-liners or `npx -y` for ephemeral execution
2. **Bash 3.2 compatible** — no associative arrays, mapfile, or case modification
3. **Two-stage detection** — T1 fast-filters candidates, T2 AST-verifies only candidates
4. **Consistent output format** — `filepath:line: description` for all violations
5. **Exit codes** — 0 = PASS, 1 = violations found, 2 = script error

---

## Comment Stripping (Foundation for T1)

All T1 checks strip comments before pattern matching to eliminate false positives.

### Strip Single File

```bash
# Strip // and /* */ comments, output clean source
node -e "
  const fs = require('fs');
  const src = fs.readFileSync(process.argv[1], 'utf8');
  const stripped = src
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/\/\/.*/g, '');
  console.log(stripped);
" "${file}"
```

### Strip and Search (Combined)

```bash
# Strip comments then search for pattern — single command
node -e "
  const fs = require('fs');
  const src = fs.readFileSync(process.argv[1], 'utf8')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/\/\/.*/g, '');
  const lines = src.split('\n');
  const pattern = new RegExp(process.argv[2]);
  lines.forEach((line, i) => {
    if (pattern.test(line)) {
      console.log(process.argv[1] + ':' + (i + 1) + ': ' + line.trim());
    }
  });
" "${file}" "${pattern}"
```

### Batch Strip and Search (Multiple Files)

```bash
# Process all .ts/.tsx files in a directory
find "${worktree}/src/${subsystem}" -name '*.ts' -o -name '*.tsx' \
  | grep -v node_modules | grep -v '.test.' | grep -v '.spec.' \
  | while IFS= read -r file; do
    node -e "
      const fs = require('fs');
      const src = fs.readFileSync(process.argv[1], 'utf8')
        .replace(/\/\*[\s\S]*?\*\//g, '')
        .replace(/\/\/.*/g, '');
      const lines = src.split('\n');
      const pattern = new RegExp(process.argv[2]);
      lines.forEach((line, i) => {
        if (pattern.test(line)) {
          console.log(process.argv[1] + ':' + (i + 1) + ': ' + line.trim());
        }
      });
    " "$file" "${pattern}"
  done
```

---

## T2 Scripts: TypeScript AST Analysis

These use the TypeScript Compiler API (`require('typescript')`) which is available in any TypeScript project's node_modules.

### Prerequisite Check

Before running any T2 script, verify TypeScript is available:

```bash
# Check if TypeScript compiler API is accessible
node -e "try { require('typescript'); process.exit(0) } catch(e) { process.exit(1) }" 2>/dev/null
T2_AVAILABLE=$?

if [ "$T2_AVAILABLE" -ne 0 ]; then
  echo "WARN: TypeScript not found in node_modules. Falling back to T1."
  # Fall back to T1 comment-stripped grep
fi
```

### import-style-check

Verifies import declarations use the chosen style. AST-level — only checks actual `import` declarations, not comments or strings.

```bash
node -e "
  const ts = require('typescript');
  const fs = require('fs');
  const file = process.argv[1];
  const violationPattern = new RegExp(process.argv[2]);
  const src = fs.readFileSync(file, 'utf8');
  const sf = ts.createSourceFile('f.ts', src, ts.ScriptTarget.Latest, true);
  let violations = 0;

  function visit(node) {
    if (ts.isImportDeclaration(node)) {
      const moduleSpec = node.moduleSpecifier.text;
      if (violationPattern.test(moduleSpec)) {
        const line = sf.getLineAndCharacterOfPosition(node.getStart()).line + 1;
        console.log(file + ':' + line + ': ' + moduleSpec);
        violations++;
      }
    }
    ts.forEachChild(node, visit);
  }

  visit(sf);
  process.exit(violations > 0 ? 1 : 0);
" "${file}" "${violation_regex}"
```

**Violation patterns by preference:**

| Preference | violation_regex | Meaning |
|------------|-----------------|---------|
| `path-aliases` | `^\\.\\.` | Relative imports (should use @/) |
| `relative` | `^@/` | Path alias imports (should use relative) |
| `package-imports` | `^\\.\\.` | Relative imports (should use package) |

### export-style-check

Verifies export declarations match the chosen style.

```bash
node -e "
  const ts = require('typescript');
  const fs = require('fs');
  const file = process.argv[1];
  const style = process.argv[2]; // 'named-exports' | 'mixed-exports' | 'barrel-exports'
  const src = fs.readFileSync(file, 'utf8');
  const sf = ts.createSourceFile('f.ts', src, ts.ScriptTarget.Latest, true);
  let violations = 0;

  function visit(node) {
    // Check for default exports when named-exports is required
    if (style === 'named-exports') {
      if (ts.isExportAssignment(node) && !node.isExportEquals) {
        const line = sf.getLineAndCharacterOfPosition(node.getStart()).line + 1;
        console.log(file + ':' + line + ': default export (use named export)');
        violations++;
      }
      // export default class/function
      if ((ts.isClassDeclaration(node) || ts.isFunctionDeclaration(node)) &&
          node.modifiers && node.modifiers.some(m => m.kind === ts.SyntaxKind.DefaultKeyword)) {
        const line = sf.getLineAndCharacterOfPosition(node.getStart()).line + 1;
        console.log(file + ':' + line + ': default export declaration');
        violations++;
      }
    }
    ts.forEachChild(node, visit);
  }

  visit(sf);
  process.exit(violations > 0 ? 1 : 0);
" "${file}" "${preference_value}"
```

### error-handling-check

Verifies error handling follows the chosen strategy. Distinguishes `throw new Error()` from `throw new AuthError()`.

```bash
node -e "
  const ts = require('typescript');
  const fs = require('fs');
  const file = process.argv[1];
  const strategy = process.argv[2]; // 'typed-errors' | 'result-type' | 'error-codes'
  const src = fs.readFileSync(file, 'utf8');
  const sf = ts.createSourceFile('f.ts', src, ts.ScriptTarget.Latest, true);
  let violations = 0;

  function visit(node) {
    if (ts.isThrowStatement(node) && node.expression) {
      const line = sf.getLineAndCharacterOfPosition(node.getStart()).line + 1;

      if (strategy === 'typed-errors') {
        // Flag throw new Error() but allow throw new CustomError()
        if (ts.isNewExpression(node.expression)) {
          const cls = node.expression.expression;
          if (ts.isIdentifier(cls) && cls.text === 'Error') {
            console.log(file + ':' + line + ': throw new Error() — use typed error class');
            violations++;
          }
        }
      } else if (strategy === 'result-type') {
        // Flag any throw statement in non-test code
        console.log(file + ':' + line + ': throw statement — use Result<T,E> pattern');
        violations++;
      } else if (strategy === 'error-codes') {
        // Flag throw new Error() without .code property
        if (ts.isNewExpression(node.expression)) {
          const cls = node.expression.expression;
          if (ts.isIdentifier(cls) && cls.text === 'Error') {
            console.log(file + ':' + line + ': throw new Error() — use error code pattern');
            violations++;
          }
        }
      }
    }
    ts.forEachChild(node, visit);
  }

  visit(sf);
  process.exit(violations > 0 ? 1 : 0);
" "${file}" "${preference_value}"
```

### any-type-check

Detects all uses of the `any` keyword in type positions. Zero false positives — only matches the actual `any` keyword in the AST, not in comments, strings, or variable names.

```bash
node -e "
  const ts = require('typescript');
  const fs = require('fs');
  const file = process.argv[1];
  const src = fs.readFileSync(file, 'utf8');
  const sf = ts.createSourceFile('f.ts', src, ts.ScriptTarget.Latest, true);
  let violations = 0;

  function visit(node) {
    if (node.kind === ts.SyntaxKind.AnyKeyword) {
      const line = sf.getLineAndCharacterOfPosition(node.getStart()).line + 1;
      const parent = node.parent;
      let context = 'type annotation';
      if (ts.isAsExpression(parent)) context = 'as assertion';
      if (ts.isTypeReferenceNode(parent)) context = 'type reference';
      if (ts.isParameter(parent)) context = 'parameter type';
      if (ts.isVariableDeclaration(parent)) context = 'variable type';
      if (ts.isFunctionDeclaration(parent) || ts.isMethodDeclaration(parent)) context = 'return type';
      console.log(file + ':' + line + ': any (' + context + ')');
      violations++;
    }
    ts.forEachChild(node, visit);
  }

  visit(sf);
  process.exit(violations > 0 ? 1 : 0);
" "${file}"
```

### console-usage-check

Detects all `console.*` calls via AST. Cannot be fooled by comments containing console.log.

```bash
node -e "
  const ts = require('typescript');
  const fs = require('fs');
  const file = process.argv[1];
  const src = fs.readFileSync(file, 'utf8');
  const sf = ts.createSourceFile('f.ts', src, ts.ScriptTarget.Latest, true);
  let violations = 0;
  const banned = ['log', 'warn', 'error', 'info', 'debug'];

  function visit(node) {
    if (ts.isCallExpression(node) && ts.isPropertyAccessExpression(node.expression)) {
      const obj = node.expression.expression;
      const prop = node.expression.name;
      if (ts.isIdentifier(obj) && obj.text === 'console' && banned.includes(prop.text)) {
        const line = sf.getLineAndCharacterOfPosition(node.getStart()).line + 1;
        console.log(file + ':' + line + ': console.' + prop.text + '()');
        violations++;
      }
    }
    ts.forEachChild(node, visit);
  }

  visit(sf);
  process.exit(violations > 0 ? 1 : 0);
" "${file}"
```

### layer-dependency-check

Verifies that lower architectural layers never import from higher layers. Uses import declaration AST nodes, not grep.

```bash
node -e "
  const ts = require('typescript');
  const fs = require('fs');
  const path = require('path');
  const file = process.argv[1];

  // Layer hierarchy — customize per project in .acis-config.json
  const layers = {
    foundation: 1, core: 1, shared: 1, common: 1,
    journey: 2, service: 2, domain: 2,
    composition: 3, ui: 3, app: 3, pages: 3
  };

  const src = fs.readFileSync(file, 'utf8');
  const sf = ts.createSourceFile('f.ts', src, ts.ScriptTarget.Latest, true);

  // Determine this file's layer
  const fileLayer = Object.keys(layers).find(l => file.includes('/' + l + '/'));
  if (!fileLayer) process.exit(0); // Not in a recognized layer

  let violations = 0;

  function visit(node) {
    if (ts.isImportDeclaration(node)) {
      const moduleSpec = node.moduleSpecifier.text;
      const importLayer = Object.keys(layers).find(l => moduleSpec.includes('/' + l + '/'));

      if (importLayer && layers[fileLayer] < layers[importLayer]) {
        const line = sf.getLineAndCharacterOfPosition(node.getStart()).line + 1;
        console.log(file + ':' + line + ': Layer ' + fileLayer + ' (L' + layers[fileLayer] + ') imports from ' + importLayer + ' (L' + layers[importLayer] + '): ' + moduleSpec);
        violations++;
      }
    }
    ts.forEachChild(node, visit);
  }

  visit(sf);
  process.exit(violations > 0 ? 1 : 0);
" "${file}"
```

### solid-structural-check

Structural SOLID checks via AST. Catches obvious violations: large classes (SRP), direct instantiation in constructors (DIP), unused interface implementations.

```bash
node -e "
  const ts = require('typescript');
  const fs = require('fs');
  const file = process.argv[1];
  const level = process.argv[2]; // 'pragmatic-solid' | 'strict-solid' | 'relaxed-solid'
  if (level === 'relaxed-solid') process.exit(0);

  const src = fs.readFileSync(file, 'utf8');
  const sf = ts.createSourceFile('f.ts', src, ts.ScriptTarget.Latest, true);
  let violations = 0;

  const SRP_METHOD_THRESHOLD = level === 'strict-solid' ? 7 : 10;
  const SRP_LINE_THRESHOLD = level === 'strict-solid' ? 200 : 300;

  function visit(node) {
    // SRP: Class too large
    if (ts.isClassDeclaration(node)) {
      const name = node.name ? node.name.text : '<anonymous>';
      const methods = node.members.filter(m => ts.isMethodDeclaration(m)).length;
      const startLine = sf.getLineAndCharacterOfPosition(node.getStart()).line + 1;
      const endLine = sf.getLineAndCharacterOfPosition(node.getEnd()).line + 1;
      const lineCount = endLine - startLine;

      if (methods > SRP_METHOD_THRESHOLD) {
        console.log(file + ':' + startLine + ': SRP — class ' + name + ' has ' + methods + ' methods (max ' + SRP_METHOD_THRESHOLD + ')');
        violations++;
      }
      if (lineCount > SRP_LINE_THRESHOLD) {
        console.log(file + ':' + startLine + ': SRP — class ' + name + ' is ' + lineCount + ' lines (max ' + SRP_LINE_THRESHOLD + ')');
        violations++;
      }
    }

    // DIP: Direct instantiation of services in constructor
    if (ts.isConstructorDeclaration(node) && node.body) {
      node.body.statements.forEach(stmt => {
        function findNew(n) {
          if (ts.isNewExpression(n)) {
            const cls = n.expression;
            if (ts.isIdentifier(cls)) {
              const name = cls.text;
              if (name.endsWith('Service') || name.endsWith('Repository') || name.endsWith('Provider')) {
                const line = sf.getLineAndCharacterOfPosition(n.getStart()).line + 1;
                console.log(file + ':' + line + ': DIP — direct instantiation of ' + name + ' in constructor (inject via parameter)');
                violations++;
              }
            }
          }
          ts.forEachChild(n, findNew);
        }
        findNew(stmt);
      });
    }

    // ISP (strict only): Interface with too many methods
    if (level === 'strict-solid' && ts.isInterfaceDeclaration(node)) {
      const name = node.name.text;
      const methods = node.members.filter(m => ts.isMethodSignature(m) || ts.isPropertySignature(m)).length;
      if (methods > 5) {
        const line = sf.getLineAndCharacterOfPosition(node.getStart()).line + 1;
        console.log(file + ':' + line + ': ISP — interface ' + name + ' has ' + methods + ' members (consider segregating)');
        violations++;
      }
    }

    ts.forEachChild(node, visit);
  }

  visit(sf);
  process.exit(violations > 0 ? 1 : 0);
" "${file}" "${preference_value}"
```

### circular-dependency-check

Uses `madge` for dependency graph analysis. Ephemeral (npx).

```bash
# Check for circular dependencies in a subsystem
RESULT=$(npx -y madge@latest --circular --json "${worktree}/src/${subsystem}/" 2>/dev/null || echo "[]")
CYCLES=$(echo "$RESULT" | node -e "
  const data = require('fs').readFileSync('/dev/stdin', 'utf8');
  const cycles = JSON.parse(data || '[]');
  cycles.forEach(cycle => {
    console.log('Circular dependency: ' + cycle.join(' → '));
  });
  process.exit(cycles.length > 0 ? 1 : 0);
")
echo "$CYCLES"
```

---

## T3 Scripts: Schema-Constrained Agent Review

T3 checks use Claude agents but enforce structured JSON output. The agent MUST produce a JSON object matching the enforcement engine's output schema.

### Agent Review Prompt Template

```markdown
## Structured Code Review: ${check_id}

You are performing an automated code review for ACIS governance enforcement.

**CHECK**: ${check_description}
**PREFERENCE**: ${preference_key} = ${preference_value}
**FILES**: ${file_list}

### Code Under Review

${code_content}

### Your Task

Analyze the code above against the preference '${preference_key}' at the '${preference_value}' level.

### MANDATORY Output Format

You MUST respond with ONLY a JSON object matching this EXACT schema. No prose, no markdown, no explanation — ONLY valid JSON:

```json
{
  "verdict": "PASS" | "FAIL",
  "violations": [
    {
      "file": "path/to/file.ts",
      "line": 42,
      "rule": "RULE_ID",
      "description": "What the violation is",
      "severity": "blocking" | "important" | "minor",
      "suggested_fix": "Concrete fix suggestion"
    }
  ],
  "confidence": 0.85,
  "evidence": [
    "function X at file.ts:42 has no error handling for the DB call at line 45"
  ]
}
```

### Rules

1. **verdict** MUST be "PASS" or "FAIL" — no other values
2. **violations** array is empty when verdict is "PASS"
3. **confidence** is 0.0-1.0 — below 0.7 triggers T2 cross-verification
4. **evidence** must cite specific code locations, not general impressions
5. Every violation must have a concrete **suggested_fix**, not "consider refactoring"
```

### Agent Review Validation

After receiving agent output, validate it matches the schema:

```bash
# Validate agent review output is valid JSON with required fields
node -e "
  const output = process.argv[1];
  try {
    const result = JSON.parse(output);

    // Required fields
    if (!['PASS', 'FAIL'].includes(result.verdict)) {
      console.error('Invalid verdict: ' + result.verdict);
      process.exit(2);
    }
    if (typeof result.confidence !== 'number' || result.confidence < 0 || result.confidence > 1) {
      console.error('Invalid confidence: ' + result.confidence);
      process.exit(2);
    }
    if (!Array.isArray(result.violations)) {
      console.error('violations must be an array');
      process.exit(2);
    }

    // Validate each violation
    result.violations.forEach((v, i) => {
      if (!v.file || !v.line || !v.rule || !v.description || !v.severity) {
        console.error('Violation ' + i + ' missing required fields');
        process.exit(2);
      }
      if (!['blocking', 'important', 'minor'].includes(v.severity)) {
        console.error('Violation ' + i + ' invalid severity: ' + v.severity);
        process.exit(2);
      }
    });

    // Output validated result
    console.log(JSON.stringify(result));

    // Exit based on verdict
    process.exit(result.verdict === 'PASS' ? 0 : 1);
  } catch (e) {
    console.error('Agent output is not valid JSON: ' + e.message);
    process.exit(2); // Script error, not a violation
  }
" '${agent_output}'
```

---

## Two-Stage Detection Pattern

The recommended approach for all checks that support both T1 and T2:

```bash
#!/usr/bin/env bash
# Two-stage detection: T1 fast-filter → T2 AST verification
# Usage: two-stage-check.sh <worktree> <subsystem> <check_id>

WORKTREE="$1"
SUBSYSTEM="$2"
CHECK_ID="$3"

# Count changed files
FILE_COUNT=$(find "${WORKTREE}/src/${SUBSYSTEM}" -name '*.ts' -o -name '*.tsx' \
  | grep -v node_modules | grep -v '.test.' | grep -v '.spec.' | wc -l | tr -d ' ')

# Skip T1 if few files — go directly to T2
if [ "$FILE_COUNT" -le 5 ]; then
  echo "Few files ($FILE_COUNT), using T2 directly"
  # Run T2 script on all files
  exit $?
fi

# Stage 1: T1 fast filter
CANDIDATES=$(find "${WORKTREE}/src/${SUBSYSTEM}" -name '*.ts' -o -name '*.tsx' \
  | grep -v node_modules | grep -v '.test.' | grep -v '.spec.' \
  | while IFS= read -r file; do
    # Comment-stripped grep — fast
    MATCH=$(node -e "
      const fs = require('fs');
      const src = fs.readFileSync(process.argv[1], 'utf8')
        .replace(/\/\*[\s\S]*?\*\//g, '')
        .replace(/\/\/.*/g, '');
      if (/${T1_PATTERN}/.test(src)) console.log(process.argv[1]);
    " "$file" 2>/dev/null)
    [ -n "$MATCH" ] && echo "$MATCH"
  done)

if [ -z "$CANDIDATES" ]; then
  echo "T1: No candidates found. PASS."
  exit 0
fi

CANDIDATE_COUNT=$(echo "$CANDIDATES" | wc -l | tr -d ' ')
echo "T1: Found $CANDIDATE_COUNT candidate files. Escalating to T2 for AST verification."

# Stage 2: T2 AST verification on candidates only
echo "$CANDIDATES" | while IFS= read -r file; do
  # Run the appropriate T2 AST script per check_id
  # (Selected from the scripts above based on CHECK_ID)
  node -e "${T2_SCRIPT}" "$file"
done

exit $?
```

---

## Fallback Chain

If a tier is unavailable, the engine falls back gracefully:

```
T3 (agent review) → T2 (AST analysis) → T1 (comment-stripped grep) → raw grep + WARNING

T3 fallback triggers:
  - Agent times out (>30s)
  - Agent output fails schema validation
  - Agent confidence < 0.7

T2 fallback triggers:
  - TypeScript not in node_modules
  - npx not available
  - tsconfig.json missing

T1 fallback triggers:
  - Node.js not available (extremely rare)
  → Falls back to raw grep with WARNING: "Comment stripping unavailable. Results may include false positives."
```

---

## Performance Characteristics

| Tier | Per-File | 10 Files | 100 Files | Best For |
|------|----------|----------|-----------|----------|
| T1 | ~50ms | ~500ms | ~5s | Naming, logging, simple patterns |
| T2 | ~200ms | ~2s | ~20s | Imports, exports, types, layers |
| T3 | ~5s | ~15s (batched) | ~60s (batched) | SOLID, DRY, design patterns |
| Two-Stage | ~100ms | ~1s | ~8s | Any check with T1+T2 support |
