# StarkHealthiOS — Claude Code context

## Shared language and decisions

The source of truth for this project's domain language and architectural decisions
lives in the Jarvis vault (external to this repo):

- **context.md** (ubiquitous language): `/Users/mariooliver/Documents/Obsidian Vault/Jarvis/Projects/Stark Health_A/` — created during the first grill-with-docs session.
- **ADRs**: `/Users/mariooliver/Documents/Obsidian Vault/Jarvis/Decisions_A/Engineering/`
- **Workflow philosophy**: `/Users/mariooliver/Documents/Obsidian Vault/Jarvis/Reference/Philosophy/AI_Coding_Workflow_Philosophy.md`

**Before planning or coding any feature:**
1. Read `context.md`. Use its language verbatim in Swift types, view names, model fields, and UI copy. The same word must mean the same thing everywhere.
2. When new domain terms appear, clarify them with the human and update `context.md`.
3. For hard-to-reverse decisions, write an ADR.

## Workflow

Structured feature work uses the two-loop AI coding workflow:
- **Outer loop** (human-in-the-loop): `grill-with-docs` → `write-prd` → `prd-to-issues` → `review-diff`
- **Inner loop** (implement-afk): `/inner-loop` in Claude Code, one AFK issue at a time, supervised

Issues live in `.issues/` at the repo root. Each AFK issue has a Feedback Loops block.

Small, incidental changes may use Cursor without the full loop.

iOS is heavily taste-sensitive (sprite companion, visual design). Use `trust-prior-verify` liberally for subjective criteria — do not claim visual output green based on a passing test alone. Human eyeball is required.

## Feedback Loops (native gate commands)

Stack: SwiftUI / XCTest | Scheme: `StarkHealthiOS`

```bash
xcodebuild test -project StarkHealthiOS.xcodeproj -scheme StarkHealthiOS \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -only-testing:StarkHealthiOSTests
# HARNESS_READY — smoke-verified 2026-06-09
# swiftlint — not configured as of 2026-06-09; add .swiftlint.yml if warnings-as-signal is desired
```

iOS gates are slower and simulator-dependent. Set a lower turn cap for `/goal` runs on this repo. Much of the UI is trust-prior-verify.

See full gate reference: `/Users/mariooliver/Documents/Obsidian Vault/Jarvis/Skills_A/workflow/inner-loop/references/test-gates.md`

## Graduation status

Supervised until the per-repo streak in the graduation tracker warrants human judgment to flip. See: `/Users/mariooliver/Documents/Obsidian Vault/Jarvis/Projects/Stark Health_A/Engineering/inner-loop-graduation-tracker.md`
