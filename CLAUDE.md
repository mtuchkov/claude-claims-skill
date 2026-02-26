# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A Claude Code skill that transforms specs, ADRs, and post-mortems into atomic, falsifiable design claims. There is no compiled code — the skill is entirely declarative markdown that Claude interprets and executes step-by-step. There is no build system, no package manager, and no test runner.

## Repository Structure

```
skill.json                                         ← Skill manifest; entry point is plugins/claims/skills/claims/SKILL.md
plugins/claims/.claude-plugin/plugin.json          ← Plugin marketplace metadata
plugins/claims/skills/claims/
    SKILL.md                                       ← Normative implementation (1,383 lines; 20 phases + 11 rules)
    references/format.md                           ← Output file format templates (6 file types)
    examples/sample-output.md                      ← Full example session output
skills/claims/                                    ← Codex-installable skill bundle (mirrors plugins/claims/skills/claims)
README.md                                          ← User-facing documentation
```

## Key Files and Their Roles

**`SKILL.md`** is the single source of truth for the algorithm. It defines 20 sequential phases that Claude executes exactly and in order. Any change to skill behavior must happen here.

**`references/format.md`** defines every output file type the skill can write. Modify this when changing templates, frontmatter fields, naming conventions, or file structure.

**`skill.json`** is the manifest Claude Code reads to register the skill. It must point to `SKILL.md` and stay in sync with `plugin.json` on version bumps.

## Architecture

The skill operates on a `SYSTEM` name and an input file or URL, writing output to `{vault_root}/claims/` (configured via `~/.config/claude-note/config.toml`).

**20-phase pipeline** (all phases in SKILL.md must execute in order):
1. Parse arguments → set `SYSTEM`, `FOLDER`
2. Read vault config → set `OUTPUT_DIR`
3. Read source content (md, pdf via pdftotext, docx via pandoc, URL via WebFetch)
4–7. Apply controlled vocabulary → extract statements → normalize → convert negatives to positives
8. Derive new claims from explicit combinations
8a. Extract implicit claims (unconfirmed assumptions)
8b. Capture TIL (architectural observations)
9–13. Assign domains → deduplicate → type claims → check conflicts → compose Top-Level Invariants
14. Build JSON graph
15. Semantic dedup against vault (via `mcp__qmd__vsearch`; falls back to filename matching)
16. Report plan (show all CREATE / MERGE / CONFLICT / SKIP decisions before writing)
17. Write index file
18. Write new node files
19. Merge into existing node files
20. Final report

**Six output file types** (naming conventions from `format.md`):
| Type | Filename pattern | Purpose |
|---|---|---|
| Graph Index | `{SYSTEM}-idx.md` | Registry + dependency graph |
| Node Note | `{domain_lower}-{type}-{name}.md` | Atomic constraint statement |
| Seam Constraint | `{domain1_lower}-{domain2_lower}-sea-{name}.md` | Cross-domain relationship |
| Top-Level Invariant | `{domain_lower}-tli-{name}.md` | Composed system contract |
| Implicit Claim | `{domain_lower}-imp-{name}.md` | Unconfirmed assumption |
| TIL Note | `{domain_lower}-til-{name}.md` | Architectural observation |

**Allowed tools** (declared in SKILL.md frontmatter): `Read`, `Write`, `Bash`, `WebFetch`, `mcp__qmd__vsearch`, `mcp__qmd__get`

## Inviolable Rules

These 11 rules in SKILL.md apply at every phase. Any modification to the skill must preserve them:

1. No node without a source citation.
2. No edge without an explicit logical basis in the source.
3. No inference beyond what the spec or code states.
4. No assumption silently promoted to constraint.
5. No gap auto-resolved — every unknown is a visible flag.
6. No banned adverb survives normalization.
7. No domain assignment by flow, section, or actor — only by entity class.
8. No dedup across different entity domains.
9. No conflict auto-resolved — conflicts are artifacts, not obstacles.
10. No implied constraint — only explicit semantics from the source.
11. No implicit claim promoted to a node or used in derivation until `confirmed: true` is set by a spec owner.

## Previewing Changes

Use `--dry-run` to run extraction without writing files:

```
/claims design-doc.md --system my-system --dry-run
```

This executes all phases up through the plan report (Step 16) and shows every CREATE / MERGE / CONFLICT decision without touching the vault.

## Versioning

When releasing a new version, bump `version` in both `skill.json` and `plugins/claims/.claude-plugin/plugin.json` to keep them in sync.
