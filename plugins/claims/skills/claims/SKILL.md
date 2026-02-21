---
name: claims
description: Extract falsifiable design claims from a project spec — premises, invariants, guarantees, and constraints — structured for AI reasoning, assertion generation, and test scaffolding.
argument-hint: [file-or-url] [--system <n>] [--dry-run]
allowed-tools: Read, Write, Bash, WebFetch, mcp__qmd__vsearch, mcp__qmd__get
---

# Design Claims Extraction Skill

When invoked with `/claims`, follow these steps EXACTLY.

## Step 1: Parse Arguments

```
/claims <file-or-url> [--system <n>] [--dry-run]
```

- `file-or-url`: Required. Path to spec file or URL.
- `--system <n>`: Logical system name (e.g., "blitz-multitenancy"). Defaults to filename stem.
- `--dry-run`: Preview extracted claims; do not write files.

Set variables:
- `SYSTEM` = value of `--system`, or filename stem
- `PREFIX`  = "claim"
- `FOLDER`  = "claims"

---

## Step 2: Get Vault Path

```bash
cat ~/.config/claude-note/config.toml 2>/dev/null
```

Extract `vault_root`. Set `OUTPUT_DIR` = `{vault_root}/claims/`.

If no config, ask: "Where should I create claim files? (e.g., ~/Documents/notes)"

---

## Step 3: Read Spec Content

Set `TITLE` from `--system` or filename.

**For local files:**
- `.md` or `.txt`: Use Read tool directly
- `.pdf`: Run `pdftotext "{file}" - 2>/dev/null || pandoc "{file}" -t plain`
- `.docx`: Run `pandoc "{file}" -t plain --wrap=none`

**For URLs:** Use WebFetch to get the content.

Store in `CONTENT`. If longer than 100,000 characters, truncate and append `\n\n[... content truncated ...]`

---

## Step 4: Extract Design Claims

Analyze `CONTENT` and extract this JSON structure:

```json
{
  "system": "<system name>",
  "spec_summary": "2-3 sentences: what this spec defines and its scope.",
  "claims": [
    {
      "id": "CLM-001",
      "slug": "kebab-case-max-50-chars",
      "title": "Human-readable label",
      "category": "premise|invariant|guarantee|constraint|postcondition|precondition",
      "statement": "Single falsifiable declarative sentence. Active voice, present tense, RFC 2119 modal. Example: 'Every domain model MUST carry an organizationId foreign key.'",
      "rationale": "1-3 sentences: why this claim exists, which risk it mitigates.",
      "violation_scenario": "Concrete example of what breaks if this claim is false. Name the data state and observable consequence.",
      "assertion_hint": "Pseudo-code or natural language describing how to assert this in a unit/integration test or runtime check.",
      "depends_on": ["CLM-00X"],
      "tags": ["domain-tag"]
    }
  ]
}
```

### Claim Categories — Definitions

| Category | Meaning | Modal | Example |
|---|---|---|---|
| `premise` | Assumed true about the environment; not enforced by this system | WILL | "The database WILL enforce foreign key constraints on organizationId" |
| `invariant` | Always true regardless of operation sequence | SHALL / SHALL NOT | "Every domain model SHALL carry an organizationId foreign key" |
| `guarantee` | What this system promises to callers and consumers | MUST | "The org-switch MUST reflect the new orgId on all subsequent requests" |
| `constraint` | Hard limit on valid inputs or state transitions | MUST NOT | "A session MUST NOT be active in more than one organization simultaneously" |
| `precondition` | Must hold before an operation executes | MUST | "A user MUST have an active Membership before querying org data" |
| `postcondition` | Must hold after an operation completes | MUST | "After signup, an OWNER Membership MUST exist linking User to Organization" |

### Extraction Rules

1. **Falsifiability gate**: every `statement` must be disprovable by a concrete counterexample. Reject vague prose ("the system should be secure") — rewrite as a specific, measurable claim or discard.
2. **Active voice, present tense, modal verb**: use MUST / MUST NOT / SHALL / SHALL NOT / WILL per RFC 2119 semantics.
3. **One claim per statement**: do not bundle compound conditions into one claim.
4. **Quantity and boundary claims are gold**: "exactly one", "at most N", "within T ms", "never null". Extract these aggressively. Example: "Every domain model MUST carry an `organizationId` foreign key" is stronger than "models should have org context".
5. **Derive implicit claims**: if the spec says "queries are org-scoped", extract the explicit invariant "Every Prisma read query on a tenant-scoped model MUST include `organizationId: ctx.session.orgId` in the `where` clause."
6. **Code examples are specs too**: for every code snippet, treat its structure as normative — not just its logic. Ask: "if a competent developer rewrote this from scratch and got a structural detail slightly wrong, would it silently violate correctness or security?" Extract a claim for each yes. The `violation_scenario` MUST show the plausible wrong version alongside the observable failure.
7. **Conspicuous absence**: what a spec omits is as normative as what it states. For each operation, data flow, or data type, ask: "what mechanism is conspicuously not shown — revocation, validation, expiry, rollback, authorization?" Each deliberate omission is a candidate invariant (e.g. "tokens MUST NOT have a server-side revocation path" or "input X is never validated because it comes from a trusted source").
8. **Cross-example consistency**: when multiple code examples share a structural pattern, that repetition defines an implicit convention. Compare examples to each other — patterns present in all examples are invariants; inconsistencies between examples are potential conflicts requiring a claim.
9. **Type signatures and schema shape**: treat field optionality, nullability, and enum member sets as claim sources. A required field encodes an invariant; an optional field encodes a constraint on when it may be absent; a closed enum encodes a finite set of valid states. Extract these as claims, not just as schema observations.
10. **Pipeline and call-site ordering**: when a spec shows a middleware chain, pipe, decorator stack, or multi-step sequence, extract a claim for each stage whose position is load-bearing. Ask: "what does this stage assume has already run, and what would break if it ran earlier or later?"
11. **Error type selection**: when a spec names a specific error type (e.g. `NotFoundError` vs `AuthorizationError`), extract the implied constraint. The choice of error encodes a deliberate behavioral or security decision — returning `NotFoundError` on an unauthorized access intentionally hides existence; that is a claim, not an implementation detail.
12. **Map dependencies**: if CLM-002 only holds because CLM-001 holds (e.g., query filtering depends on every model having `organizationId`), record it in `depends_on`.                                                       13. Extract 5–25 claims depending on spec richness. Thin specs = fewer, tighter. Dense specs = more, still tight.

Store result in `EXTRACTION`.

---

## Step 5: Semantic Deduplication

For each claim in `EXTRACTION.claims`:

### 5a. Build query
```
QUERY = "{claim.title} {claim.statement}"
```

### 5b. Search existing claims
```
mcp__qmd__vsearch(query: QUERY, limit: 3, minScore: 0.80)
```

### 5c. Classify

- **No match ≥ 0.80** → `CREATE_NEW`
- **Match ≥ 0.80 in `claims/` folder** → read existing; compare:
  - Statements are *semantically equivalent* → `SKIP`
  - New claim *strengthens or contradicts* existing → `CONFLICT` (flag for human review)
  - New claim *adds scope, system, or assertion hint* → `MERGE`

> ⚠️ **Contradictions are first-class findings.** If CLM-NEW contradicts an existing claim, do NOT silently merge. Surface it explicitly in the report. Do NOT write the file.
>
> Example: existing says "A SUPERADMIN MAY read across orgs"; new spec says "A SUPERADMIN MUST bypass all org filters including writes" — that's a CONFLICT, not a MERGE.

---

## Step 6: Report Plan

```
Extracted {N} design claims from "{TITLE}" ({SYSTEM}):

CREATE   {X} new claim files
MERGE    {Y} existing claim files
CONFLICT {C} contradictions — HUMAN REVIEW REQUIRED
SKIP     {Z} duplicates

Contradiction details:
  ⚡ CLM-NEW-008 vs claims/claim-superadmin-access.md
     New:      "A SUPERADMIN MUST bypass organizationId filtering on all operations"
     Existing: "A SUPERADMIN MAY read data across all organizations"
     → Resolve before ingesting.
```

**If `--dry-run`:** stop here. Do not write any files.

---

## Step 7: Create Source Index File

Create `{OUTPUT_DIR}/{SYSTEM}-claims-index.md`:

```markdown
---
tags:
  - claims/index
  - system/{SYSTEM}
created: {YYYY-MM-DD}
spec_file: "{original_filename}"
---

# Design Claims: {SYSTEM}

{spec_summary}

## Claim Registry

| ID      | Title     | Category   | File                      |
|---------|-----------|------------|---------------------------|
| CLM-001 | {title}   | {category} | [[claims/claim-{slug}]]   |

## Dependency Graph

\```
CLM-002 → CLM-001
CLM-004 → CLM-001
CLM-004 → CLM-005
\```

## Source

- **Spec:** `{original_filename}`
- **Extracted:** {YYYY-MM-DD}
```

Omit `## Dependency Graph` if no `depends_on` relationships exist.

If any `CONFLICT` claims were found, append to the index:

```markdown
## Unresolved Conflicts

### ⚡ CLM-NEW-{N} vs [[claims/claim-{existing-slug}]]

| | Statement |
|---|---|
| **Existing** (`claim-{existing-slug}.md`) | "{existing statement}" |
| **New** (`{spec_file}`) | "{new statement}" |

**Action required:** {brief description of what differs and what to decide}.
Re-run `/claims` after resolution.
```

---

## Step 8: Create New Claim Files

For each `CREATE_NEW` claim, create `{OUTPUT_DIR}/claim-{slug}.md`:

```markdown
---
id: {id}
tags:
  - claims/{category}
  - system/{SYSTEM}
  - {tags...}
category: {category}
system: {SYSTEM}
source: "[[claims/{SYSTEM}-claims-index]]"
added: {YYYY-MM-DD}
---

# {title}

> **{statement}**

## Rationale

{rationale}

## Violation Scenario

{violation_scenario}

## Assertion Hint

\```pseudo
{assertion_hint}
\```

## Dependencies

{depends_on as wikilinks, or "None"}

---
*Extracted from: {TITLE} — {YYYY-MM-DD}*
```

---

## Step 9: Merge Into Existing Claim Files

For each `MERGE` claim:

1. Read existing file.
2. Update frontmatter:
   - Add `updated: {YYYY-MM-DD}`
   - If `system:` is a scalar, convert to array and append new system
   - If `source:` is a scalar, rename to `sources:` array and append new index link
3. Append section before the final `---` footer:

```markdown
## Additional Context ({SYSTEM}, {YYYY-MM-DD})

{new assertion hint, scope extension, or implementation detail}

*Source: {TITLE}*
```

4. Write file.

---

## Step 10: Final Report

```
=== Claims Extraction Complete ({SYSTEM}) ===

Index:     {SYSTEM}-claims-index.md
Created:   {X} claim files
Merged:    {Y} claim files
Conflicts: {C} (see index — unresolved, files NOT written)
Skipped:   {Z} duplicates

⚡ UNRESOLVED CONFLICTS — action required:
  {list each conflict with both statements}

📋 Full Claim Registry:
────────────────────────────────────────
{ID} [{category}] {statement}
...
────────────────────────────────────────
```

---

## Fallback: No qmd Available

If `mcp__qmd__vsearch` is not available or returns an error:

1. Fall back to filename matching:
   ```bash
   ls {OUTPUT_DIR}/ 2>/dev/null | grep -i "{keywords from claim title}"
   ```
2. If similar filename found, read it and do manual comparison.
3. Otherwise, create new file.

---

## Example Session

**User input:**
```
/claims ~/docs/Multitenancy.md --system blitz-multitenancy
```

**Output:**
```
Reading config... vault at ~/Documents/notes

Reading spec...
Document: Multitenancy.md, ~1,800 words

Analyzing and extracting design claims...

Extracted 8 claims from "Multitenancy.md" (blitz-multitenancy):

1. organizationid-on-every-model        (invariant)
2. query-must-filter-by-orgid           (invariant)
3. create-must-attach-orgid             (postcondition)
4. update-delete-where-includes-orgid   (invariant)
5. session-scoped-to-one-org            (constraint)
6. entity-assigned-to-membership        (constraint)
7. signup-creates-org-and-membership    (postcondition)
8. superadmin-bypasses-org-filter       (guarantee)

Checking for semantic duplicates...
  ✓ organizationid-on-every-model       → no similar claims
  ✓ query-must-filter-by-orgid          → no similar claims
  ✓ create-must-attach-orgid            → no similar claims
  ✓ update-delete-where-includes-orgid  → no similar claims
  ✓ session-scoped-to-one-org           → found: claim-session-single-context.md (0.82)
    → New info: orgId in Blitz PublicData; $setPublicData switch mechanism
    → Will merge
  ✓ entity-assigned-to-membership       → no similar claims
  ✓ signup-creates-org-and-membership   → no similar claims
  ✗ superadmin-bypasses-org-filter      → found: claim-superadmin-access.md (0.93)
    → CONFLICT: existing says MAY read across orgs;
                new spec says MUST bypass filter on ALL operations
    → Flagged — file NOT written

Creating files...

Created index:
  claims/blitz-multitenancy-claims-index.md

Created 6 claim files:
  ✓ claims/claim-organizationid-on-every-model.md
  ✓ claims/claim-query-must-filter-by-orgid.md
  ✓ claims/claim-create-must-attach-orgid.md
  ✓ claims/claim-update-delete-where-includes-orgid.md
  ✓ claims/claim-entity-assigned-to-membership.md
  ✓ claims/claim-signup-creates-org-and-membership.md

Merged into existing:
  ✓ claims/claim-session-single-context.md
    Added: orgId in Blitz PublicData; $setPublicData switch; dual-role array shape

Skipped (conflict — not written):
  ✗ superadmin-bypasses-org-filter → claim-superadmin-access.md
    Reason: MAY (read-only) vs MUST (all operations) contradicts existing claim

=== Claims Extraction Complete (blitz-multitenancy) ===

Index:     blitz-multitenancy-claims-index.md
Created:   6 claim files
Merged:    1 claim file
Conflicts: 1 (see index — unresolved, file NOT written)
Skipped:   0

⚡ UNRESOLVED CONFLICTS — action required:
  claim-superadmin-access.md vs CLM-NEW-008
    Existing: "A SUPERADMIN MAY read data across all organizations"
    New spec:  "A SUPERADMIN MUST bypass organizationId filtering on all operations"
    → Read-only vs all-operations is a security boundary decision.
      Confirm with the platform team; update the winning file's modal verb.

📋 Full Claim Registry:
────────────────────────────────────────
CLM-001 [invariant]     Every domain model except User and Organization MUST carry an organizationId foreign key.
CLM-002 [invariant]     Every Prisma read query on a tenant-scoped model MUST include organizationId: ctx.session.orgId in the where clause.
CLM-003 [postcondition] On create, every tenant-scoped record MUST have organizationId set to ctx.session.orgId.
CLM-004 [invariant]     Update and delete mutations MUST include organizationId: ctx.session.orgId in the Prisma where clause.
CLM-005 [constraint]    A session MUST NOT be active in more than one organization simultaneously.
CLM-006 [constraint]    Entities with per-person assignment semantics MUST use membershipId, NOT userId, as the owner foreign key.
CLM-007 [postcondition] A successful signup MUST atomically produce a User, an Organization, and an OWNER Membership.
────────────────────────────────────────
```
