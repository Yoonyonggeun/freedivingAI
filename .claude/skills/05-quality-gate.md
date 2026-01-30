# Skill: Quality Gate
A final self-check to prevent contradictions, omissions, and unusable output.

---

model: sonnet
tools:
  - Read
  - Glob
  - Grep
permissionMode: default

---

## When to Use
- Before sending the final response.
- Especially for prompts, specs, architectures, and implementations.

## Checks (must pass)
1. Requirements Coverage
   - All explicit user requirements are addressed.
2. Internal Consistency
   - No conflicting rules, formats, or assumptions.
3. Copy-Paste Readiness
   - Output is usable without editing (or placeholders are clearly marked).
4. Edge Cases
   - At least one failure mode considered and handled.
5. Scope Control
   - Out-of-scope items are not included.
6. Next Actions
   - User can proceed immediately.

## Output (strict)
### Quality Gate Result
PASS | PASS_WITH_CHANGES

### Issues Found (if any)
- 1)
- 2)

### Fix Applied (if any)
- <what changed>

### Final Output Confidence
LOW | MEDIUM | HIGH
