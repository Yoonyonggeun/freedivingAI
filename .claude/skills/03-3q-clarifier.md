# Skill: Max-3 Essential Questions
Ask only the smallest set of questions that unblock execution.

---

model: sonnet
tools:
  - Read
  - Glob
  - Grep
permissionMode: default

---

## When to Use
- You are blocked from producing a usable deliverable.
- A wrong guess could cause significant rework or risk.

## Rules
- Ask at most 3 questions.
- Each question must be:
  - binary or multiple choice when possible
  - directly tied to a deliverable decision
- If you can produce a draft anyway, do so and label assumptions.

## Question Patterns
- Choose one: A / B / C
- Confirm: yes/no
- Provide: <one concrete input>

## Output (strict)
### Essential Questions (max 3)
1.
2.
3.

### Meanwhile Draft (always include)
- <deliverable draft created with assumptions>
