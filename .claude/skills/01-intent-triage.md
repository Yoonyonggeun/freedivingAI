# Skill: Intent Triage
Fast classification of user intent + routing hints for the Orchestrator.

---

model: sonnet
tools:
  - Read
  - Glob
  - Grep
permissionMode: default

---

## When to Use
- Any time the request is ambiguous or could map to multiple categories.
- As the first step before delegating to Agents.

## Inputs
- User request text
- Optional: any project constraints from CLAUDE.md

## Procedure
1. Extract the user's primary goal in 1 sentence.
2. Identify deliverable type(s):
   - prompt / plan / architecture / code / review / debug / doc
3. Classify category:
   - Architecture / Prompt Engineering / Planning / Implementation / Review
4. Decide agent set:
   - single agent for small tasks
   - staged multi-agent pipeline for medium/large
5. Identify missing critical info:
   - ask up to 3 essential questions OR proceed with assumptions

## Output (strict)
### Goal
- <one sentence>

### Category
- <one of: Architecture | Prompt Engineering | Planning | Implementation | Review>

### Recommended Agent(s)
- Primary:
- Supporting (optional):

### Deliverable Type
- <what will be produced>

### Missing Info (max 3)
1.
2.
3.

### Proceed Now
- <what can be done immediately>
