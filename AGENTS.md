# AGENTS.md

Guidance for coding agents working in this repository.

## Repository Purpose

This repo ships a declarative skill (`claims`) that Claude executes from markdown instructions.
There is no runtime application code, build system, or test suite here.

## Source of Truth

- Behavior lives in `plugins/claims/skills/claims/SKILL.md`.
- Output file templates live in `plugins/claims/skills/claims/references/format.md`.
- Codex install bundle lives in `skills/claims/` and must mirror the files above.
- Marketplace/manifest metadata lives in:
  - `skill.json`
  - `plugins/claims/.claude-plugin/plugin.json`

If behavior changes, update `SKILL.md` first, then update docs/examples as needed.
Then run `scripts/sync-codex-skill.sh` to refresh `skills/claims/`.

## High-Impact Edit Rules

- Do not reorder or drop phases in `SKILL.md` unless explicitly requested.
- Keep the "inviolable rules" semantics intact unless the user asks to change policy.
- Preserve filename conventions and frontmatter contracts in `references/format.md`.
- When releasing, keep `version` in `skill.json` and `plugins/claims/.claude-plugin/plugin.json` in sync.

## Safe Contribution Workflow

1. Read `README.md` and `CLAUDE.md` for current behavior and constraints.
2. Make minimal edits in the canonical file(s).
3. If examples are affected, update `plugins/claims/skills/claims/examples/sample-output.md`.
4. Verify paths and references are consistent.

## What Not To Add

- Do not add package managers, build scripts, or CI scaffolding unless explicitly requested.
- Do not introduce inferred behavior not stated in the source docs.
