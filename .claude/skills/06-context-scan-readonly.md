# Skill: Context Scan (Read-Only)
Quickly scan a codebase/docs to ground decisions and avoid hallucinations.

---

model: sonnet
tools:
  - Read
  - Glob
  - Grep
permissionMode: default

---

## When to Use
- The user references existing files, architecture, or prior work.
- You need filenames, conventions, or existing patterns.
- Before proposing edits or reviews.

## Procedure
1. Glob for likely files/folders (limited scope first)
   - examples: package.json, README, src/, apps/, services/, docs/
2. Grep for key terms
   - feature names, API routes, env vars, configs
3. Read the smallest relevant files first
4. Extract only what is needed:
   - conventions, entry points, interfaces, constraints
5. Summarize findings as "Grounded Facts" (not guesses)

## Output (strict)
### Files Scanned
- <path>
- <path>

### Grounded Facts
- F1:
- F2:
- F3:

### Implications
- What these facts imply for the task

### Unknowns / Assumptions
- A1:
- A2:

### Next Actions
- 1–3 steps
