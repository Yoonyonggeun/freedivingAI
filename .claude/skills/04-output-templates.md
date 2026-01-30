# Skill: Output Templates
Reusable response skeletons for consistent, high-quality deliverables.

---

model: sonnet
tools:
  - Read
  - Glob
  - Grep
permissionMode: default

---

## When to Use
- Any time you produce a deliverable.
- To enforce consistent structure across Agents.

## Templates

### Template A: Standard Deliverable
1) Summary (1–3 lines)
2) Assumptions (if needed)
3) Plan (short steps)
4) Deliverable (copy-paste ready)
5) Next Actions (1–3 steps)

### Template B: Architecture Deliverable
1) Summary
2) Assumptions
3) Components & Responsibilities
4) Data Flow (happy + failure)
5) Interfaces / Contracts
6) Folder / File Structure
7) Risks & Mitigations
8) Next Actions

### Template C: Prompt Deliverable
1) Summary
2) Assumptions
3) Final Prompt (copy-paste)
4) Optional Variants
5) Model Self-Check Checklist
6) Usage Notes (minimal)

### Template D: Review Deliverable
1) Verdict (PASS | PASS_WITH_CHANGES | NEEDS_REWORK)
2) Findings (prioritized)
3) Suggestions (concrete)
4) Risk Level (LOW | MEDIUM | HIGH)
5) Quick Re-test Checklist

## Output (strict)
### Selected Template
- A | B | C | D

### Filled Output
- <use the chosen template>
