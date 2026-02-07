# ACIS Feedback - Bug Reports, Feature Requests, and General Feedback

You are executing the ACIS feedback command. This provides a simple, user-friendly way to report bugs, request features, or give general feedback about ACIS.

## Arguments

- `$ARGUMENTS` - Optional flags: `--type <type>`, `--submit-pending`, `--list-pending`

## Behavior

### Flag Parsing

```bash
FEEDBACK_TYPE=""
SUBMIT_PENDING=false
LIST_PENDING=false

# Parse arguments
for arg in $ARGUMENTS; do
  case "$arg" in
    --type)       shift_next=type ;;
    --submit-pending) SUBMIT_PENDING=true ;;
    --list-pending)   LIST_PENDING=true ;;
    bug_report|feedback|feature_request)
      if [ "$shift_next" = "type" ]; then
        FEEDBACK_TYPE="$arg"
        shift_next=""
      fi
      ;;
  esac
done
```

### Handle `--list-pending`

If `LIST_PENDING=true`:

```bash
pending_dir=".acis/feedback"
if [ -d "$pending_dir" ]; then
  count=$(ls -1 "$pending_dir"/FEEDBACK-*.md 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    echo "Pending feedback ($count items):"
    for f in "$pending_dir"/FEEDBACK-*.md; do
      title=$(grep '^## ' "$f" | head -1 | sed 's/^## //')
      echo "  - $(basename "$f"): $title"
    done
  else
    echo "No pending feedback."
  fi
else
  echo "No pending feedback directory found."
fi
```

Present the results and exit.

### Handle `--submit-pending`

If `SUBMIT_PENDING=true`:

1. Check `gh` CLI is available and authenticated:
   ```bash
   gh auth status 2>/dev/null
   ```

2. If not available, inform user:
   ```
   GitHub CLI not available or not authenticated.
   Install: https://cli.github.com/
   Authenticate: gh auth login
   ```

3. If available, for each file in `.acis/feedback/FEEDBACK-*.md`:
   - Parse the file to extract type, title, and body
   - Submit via `gh issue create`
   - On success, delete the local file
   - On failure, keep the file and report the error

Exit after processing.

### Interactive Feedback Flow

#### Step 1: ASK TYPE (if not provided via `--type`)

If `FEEDBACK_TYPE` is empty, use AskUserQuestion:

```
AskUserQuestion:
  question: "What type of feedback would you like to submit?"
  header: "Type"
  options:
    - label: "Bug Report"
      description: "Something isn't working as expected"
    - label: "Feature Request"
      description: "Suggest a new feature or improvement"
    - label: "General Feedback"
      description: "Share thoughts, praise, or concerns"
```

Map the response:
- "Bug Report" → `bug_report`
- "Feature Request" → `feature_request`
- "General Feedback" → `feedback`

#### Step 2: ASK TITLE

```
AskUserQuestion:
  question: "Brief title for your {type} (1 line):"
  header: "Title"
  options:
    - label: "Type your title"
      description: "A short, descriptive summary"
```

Since AskUserQuestion requires options, present a prompt and accept the user's "Other" free-text input as the title.

#### Step 3: ASK DESCRIPTION

The prompt varies by type:

**Bug Report:**
```
AskUserQuestion:
  question: "Describe the bug. Include: steps to reproduce, expected behavior, and actual behavior."
  header: "Details"
  options:
    - label: "Describe the bug"
      description: "Steps to reproduce, expected vs actual behavior"
```

**Feature Request:**
```
AskUserQuestion:
  question: "Describe the feature. What problem does it solve? What's your proposed solution?"
  header: "Details"
  options:
    - label: "Describe the feature"
      description: "Problem statement and proposed solution"
```

**General Feedback:**
```
AskUserQuestion:
  question: "What's on your mind?"
  header: "Details"
  options:
    - label: "Share your feedback"
      description: "Any thoughts, praise, or concerns about ACIS"
```

Accept the user's free-text input as the description.

#### Step 4: AUTO-COLLECT CONTEXT

Automatically gather environment information:

```bash
# ACIS version
acis_version=$(jq -r '.version' "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" 2>/dev/null || echo "unknown")

# OS
os_name=$(uname -s 2>/dev/null || echo "unknown")

# Project configured
if [ -f ".acis-config.json" ]; then
  project_configured="yes"
else
  project_configured="no"
fi
```

#### Step 5: FORMAT & CONFIRM

Present a formatted preview to the user:

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  ACIS FEEDBACK PREVIEW                                                      ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  Type:  {Bug Report | Feature Request | General Feedback}                    ║
║  Title: {user_title}                                                         ║
║                                                                              ║
║  Description:                                                                ║
║    {user_description}                                                        ║
║                                                                              ║
║  Environment:                                                                ║
║    ACIS Version:      {version}                                              ║
║    OS:                {os}                                                    ║
║    Project Config:    {yes/no}                                               ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

Then ask for confirmation:

```
AskUserQuestion:
  question: "How would you like to submit this feedback?"
  header: "Submit"
  options:
    - label: "Submit to GitHub (Recommended)"
      description: "Creates an issue on the ACIS repository"
    - label: "Save locally"
      description: "Saves to .acis/feedback/ for later submission"
    - label: "Cancel"
      description: "Discard this feedback"
```

#### Step 6a: GITHUB SUBMISSION (primary)

If user chose "Submit to GitHub":

1. Check `gh` CLI availability:
   ```bash
   gh auth status 2>/dev/null
   ```

2. If available, create the issue:
   ```bash
   # Determine labels
   case "$FEEDBACK_TYPE" in
     bug_report)      type_label="bug" ; type_display="Bug Report" ;;
     feature_request) type_label="enhancement" ; type_display="Feature Request" ;;
     feedback)        type_label="feedback" ; type_display="General Feedback" ;;
   esac

   gh issue create \
     --repo "aivantage-consulting/claude-plugin-acis" \
     --title "[${type_display}] ${user_title}" \
     --body "$(cat <<'ISSUE_EOF'
   ## {type_display}: {user_title}

   ### Description
   {user_description}

   ### Environment
   | Field | Value |
   |-------|-------|
   | ACIS Version | {acis_version} |
   | OS | {os_name} |
   | Project Configured | {project_configured} |

   ---
   *Submitted via `/acis:feedback` v{acis_version}*
   ISSUE_EOF
   )" \
     --label "user-feedback,${type_label}"
   ```

3. On success, display the issue URL:
   ```
   Feedback submitted successfully!
   Issue URL: {url}
   ```

4. If `gh` is not available or not authenticated, fall through to local save (Step 6b) with a message:
   ```
   GitHub CLI not available or not authenticated. Saving locally instead.
   ```

#### Step 6b: LOCAL SAVE (fallback)

If user chose "Save locally" or GitHub submission failed:

1. Create the feedback directory:
   ```bash
   mkdir -p .acis/feedback
   ```

2. Generate a sequential filename:
   ```bash
   date_stamp=$(date +%Y%m%d)
   seq=1
   while [ -f ".acis/feedback/FEEDBACK-${date_stamp}-$(printf '%03d' $seq).md" ]; do
     seq=$((seq + 1))
   done
   filename="FEEDBACK-${date_stamp}-$(printf '%03d' $seq).md"
   ```

3. Write the feedback file:

   ```markdown
   ## {type_display}: {user_title}

   **Type:** {type_display}
   **Date:** {YYYY-MM-DD}

   ### Description
   {user_description}

   ### Environment
   | Field | Value |
   |-------|-------|
   | ACIS Version | {acis_version} |
   | OS | {os_name} |
   | Project Configured | {project_configured} |

   ---
   *Saved via `/acis:feedback` v{acis_version}*
   *Submit later with: `/acis:feedback --submit-pending`*
   ```

4. Inform the user:
   ```
   Feedback saved to .acis/feedback/{filename}
   Submit later with: /acis:feedback --submit-pending
   ```

#### Step 6c: CANCEL

If user chose "Cancel":
```
Feedback cancelled. No data was saved or submitted.
```

## Labels Reference

| Type | GitHub Labels |
|------|-------------|
| `bug_report` | `user-feedback`, `bug` |
| `feature_request` | `user-feedback`, `enhancement` |
| `feedback` | `user-feedback`, `feedback` |

## Flags

| Flag | Description |
|------|-------------|
| `--type <type>` | Pre-select feedback type: `bug_report`, `feature_request`, or `feedback` |
| `--submit-pending` | Submit all locally saved feedback to GitHub |
| `--list-pending` | Show locally saved feedback not yet submitted |

## Examples

```bash
# Interactive feedback (guided flow)
/acis:feedback

# Pre-select bug report type
/acis:feedback --type bug_report

# Pre-select feature request type
/acis:feedback --type feature_request

# List pending local feedback
/acis:feedback --list-pending

# Submit all pending feedback to GitHub
/acis:feedback --submit-pending
```

## Related Commands

- `/acis:help` - See all available commands
- `/acis:version` - Check installed ACIS version
- `/acis:audit` - Process Auditor (auto-generates plugin improvement recommendations)
