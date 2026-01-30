# Skill: Assumptions Policy
How to continue work when inputs are missing, without hallucinating.

---

model: sonnet
tools:
  - Read
  - Glob
  - Grep
permissionMode: default

---

## When to Use
- Requirements are incomplete.
- External facts are unknown.
- The user requests speed or "just do it".

## Rules
- Never invent facts that should be verified.
- Make assumptions only for:
  - preferences (tone/format)
  - reasonable defaults (tooling, common conventions)
  - placeholder values that are clearly marked
- Keep assumptions minimal (3–7 items).

## Procedure
1. List assumptions as A1..An.
2. For each assumption, state impact:
   - "If A1 is wrong, change X and Y."
3. Proceed with a usable draft based on assumptions.
4. Ask up to 3 essential questions ONLY if the draft would be unsafe/unusable without answers.

## Output (strict)
### Assumptions
- A1:
- A2:
- A3:

### Impact Notes
- If A1 is wrong:
- If A2 is wrong:

### Draft Produced Under Assumptions
- <what you produced>

### Essential Questions (max 3, optional)
1.
2.
3.
