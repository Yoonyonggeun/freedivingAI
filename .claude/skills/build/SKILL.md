---
disable-model-invocation: true
description: Build the project safely
---

# /build

Run the project's build.

## Rules

- Do not guess commands.
- Detect scripts/config first.
- Print the exact command before running.

## Steps

1. Detect build system
   - package.json → npm/pnpm/yarn
   - Cargo.toml → cargo
   - Makefile → make
2. Choose minimal command
   - npm run build / pnpm build / make build
3. Execute once
4. If failed
   - capture last 50 log lines
   - fix smallest change
   - retry once

## Output

- command used
- result (success/fail)
- files changed
