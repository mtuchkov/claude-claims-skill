# claude-claims-skill

A Claude Code skill that transforms specs, ADRs, and post-mortems into **atomic, falsifiable design claims** with semantic deduplication and conflict detection.

## What Makes This Different

Unlike doc summarizers or comment generators, this skill extracts the *contractual skeleton* of your design documents — the premises, invariants, guarantees, and constraints that must hold for the system to be correct.

| Generic Summarizer | This Skill |
|---|---|
| 1 summary file per document | 5–25 separate claim files |
| Claims buried in prose | Each claim is standalone and falsifiable |
| No deduplication | Semantic search finds overlapping claims |
| Silent on contradictions | Flags conflicting claims across specs |
| Content isolated per source | Claims accumulate and strengthen across specs |

**Result:** A growing oracle set where every claim is directly traceable to a spec, linked to dependent claims, and equipped with assertion hints ready for test generation or AI reasoning.

## Installation

### Claude Code (recommended)

```
/plugin marketplace add crimeacs/claude-claims-skill
/plugin install claims@crimeacs-claude-claims-skill
```

### Manual Installation

```bash
git clone https://github.com/crimeacs/claude-claims-skill.git ~/.claude/skills/claims
```

## Usage

```
/claims ~/docs/Multitenancy.md --system blitz-multitenancy
/claims ~/docs/auth-adr-007.md --system auth
/claims https://wiki.internal/post-mortem-42 --system payments
/claims design-doc.md --system order-api --dry-run
```

### Arguments

| Argument | Description |
|---|---|
| `[file-or-url]` | Path to spec, ADR, post-mortem (.md, .pdf, .docx, .txt) or URL |
| `--system <n>` | Logical system name (e.g., `blitz-multitenancy`, `auth`). Defaults to filename stem. |
| `--dry-run` | Preview extraction without writing files |

## How It Works

### 1. Extract Falsifiable Claims

The skill analyzes your document and extracts 5–25 standalone claims, each assigned a category:

```
Input: Multitenancy.md

Extracted claims:
- organizationid-on-every-model        (invariant)
- query-must-filter-by-orgid           (invariant)
- create-must-attach-orgid             (postcondition)
- update-delete-where-includes-orgid   (invariant)
- session-scoped-to-one-org            (constraint)
- entity-assigned-to-membership        (constraint)
- signup-creates-org-and-membership    (postcondition)
```

Every statement uses RFC 2119 modal verbs (MUST / SHALL / WILL) and must be disprovable by a concrete counterexample. Vague prose like "queries should be tenant-scoped" is rewritten into something precise and testable — or discarded.

### 2. Semantic Deduplication

Before creating each file, the skill searches your vault for similar existing claims:

```
Checking for duplicates...
✓ organizationid-on-every-model  → no similar claims
✓ session-scoped-to-one-org      → found: claim-session-single-context.md (0.82)
  → New info: orgId in Blitz PublicData; $setPublicData switch mechanism
  → Will merge
✗ superadmin-bypasses-org-filter → found: claim-superadmin-access.md (0.93)
  → CONFLICT: existing says MAY read across orgs;
              new spec says MUST bypass filter on ALL operations
  → Flagged — NOT written
```

### 3. Create, Merge, or Flag

**New claims** get their own files:
```
Created: claims/claim-organizationid-on-every-model.md
Created: claims/claim-query-must-filter-by-orgid.md
```

**Overlapping claims** with new information merge into existing files:
```
Merged into: claims/claim-session-single-context.md
  Added: orgId in Blitz PublicData; $setPublicData switch; dual-role array shape
```

**Contradicting claims** are flagged and blocked — never silently merged:
```
⚡ CONFLICT: claim-superadmin-access.md vs CLM-NEW-008
   Existing: "A SUPERADMIN MAY read data across all organizations"
   New spec:  "A SUPERADMIN MUST bypass organizationId filtering on all operations"
   → File NOT written. Resolve before re-running.
```

### 4. Claims Index

An index file links every extracted claim and renders the dependency graph:

```markdown
# Design Claims: blitz-multitenancy

| ID      | Title                                  | Category      | File                          |
|---------|----------------------------------------|---------------|-------------------------------|
| CLM-001 | organizationId on Every Domain Model   | invariant     | [[claim-organizationid-...]]  |
| CLM-002 | Queries Must Filter by organizationId  | invariant     | [[claim-query-...]]           |
| CLM-007 | Signup Atomically Creates Org + Member | postcondition | [[claim-signup-...]]          |

## Dependency Graph

CLM-002 → CLM-001
CLM-003 → CLM-001
CLM-006 → CLM-001
```

## Output Structure

```
vault/
└── claims/
    ├── blitz-multitenancy-claims-index.md          ← Registry + dependency graph
    ├── claim-organizationid-on-every-model.md
    ├── claim-query-must-filter-by-orgid.md
    ├── claim-create-must-attach-orgid.md
    ├── claim-update-delete-where-includes-orgid.md
    ├── claim-entity-assigned-to-membership.md
    ├── claim-signup-creates-org-and-membership.md
    └── claim-session-single-context.md              ← Merged: auth-service + blitz-multitenancy
```

## Prerequisites

### Required

Configure your vault location in `~/.config/claude-note/config.toml`:

```toml
vault_root = "~/Documents/my-vault"
```

### Optional (for semantic deduplication)

Install [qmd](https://github.com/tobi/qmd) and index your vault:

```bash
# Install qmd
brew install qmd

# Index your vault
cd ~/Documents/my-vault
qmd index
qmd embed  # enables vector search
```

Without qmd, the skill falls back to filename matching for deduplication.

### For PDF extraction

```bash
# macOS
brew install poppler pandoc

# Linux
apt install poppler-utils pandoc
```

## Claim File Format

Each claim is a standalone falsifiable statement with rationale, a violation scenario, and assertion hints:

```markdown
---
id: CLM-002
tags:
  - claims/invariant
  - system/blitz-multitenancy
  - security
  - prisma
category: invariant
system: blitz-multitenancy
source: "[[claims/blitz-multitenancy-claims-index]]"
added: 2026-02-20
---

# Queries Must Filter by organizationId

> **Every Prisma read query on a tenant-scoped model MUST include
> `organizationId: ctx.session.orgId` in the `where` clause.**

## Rationale

A shared-database multitenant system has no network or schema barrier between
tenants. The `organizationId` filter is the sole runtime enforcement mechanism —
omitting it on a single query is a data-leak vulnerability.

## Violation Scenario

GET /projects?id=42 runs `db.project.findFirst({ where: { id: 42 } })`.
User in Org A submits id=42, which belongs to Org B. The query returns Org B's
data. No error fires because the record exists and the user is authenticated.

## Assertion Hint

```pseudo
// AST lint — every db read must have organizationId in where
for each db.*.findFirst / findMany / findUnique call:
  assert: where clause contains "organizationId"

// Integration test
login as user_a (orgId = 1)
seed: project { id: 99, organizationId: 2 }
GET /projects/99 as user_a → expect 404 or 403, NOT 200
```

## Dependencies

[[claims/claim-organizationid-on-every-model]] (CLM-001)
```

## Claim Categories

| Category | Meaning | Example |
|---|---|---|
| `premise` | Assumed true about the environment; not enforced by this system | "The database WILL enforce foreign key constraints on organizationId" |
| `invariant` | Always true regardless of operation sequence | "Every domain model SHALL carry an organizationId foreign key" |
| `guarantee` | What this system promises to callers | "The org-switch MUST reflect the new orgId on all subsequent requests" |
| `constraint` | Hard limit on valid inputs or state transitions | "A session MUST NOT be active in more than one organization simultaneously" |
| `precondition` | Must hold before an operation executes | "A user MUST have an active Membership before querying org data" |
| `postcondition` | Must hold after an operation completes | "After signup, an OWNER Membership MUST exist linking User to Organization" |

## Multi-Source Accumulation

When the same claim appears in multiple specs, new context is appended without overwriting the original:

```markdown
---
id: CLM-005
system:
  - auth-service        ← original
  - blitz-multitenancy  ← added on merge
sources:
  - "[[claims/auth-service-claims-index]]"
  - "[[claims/blitz-multitenancy-claims-index]]"
updated: 2026-02-20
---

# Session Scoped to One Org at a Time

> **A user session MUST be active in exactly one organization at a time.**

{Original content from auth-service spec}

## Additional Context (blitz-multitenancy, 2026-02-20)

In Blitz.js, orgId lives in Session.PublicData. Switching is performed via
session.$setPublicData({ orgId }). Both GlobalRole and MembershipRole values
coexist in the roles array simultaneously.

*Source: Multitenancy.md*
```

## What to Feed It

The skill works on any document that makes design decisions:

- **Specs** — functional requirements, API contracts, data model definitions
- **ADRs** — Architecture Decision Records; the *consequences* section is especially claim-rich
- **Post-mortems** — contributing factors become premises; corrective actions become invariants or guarantees
- **RFCs** — interface contracts, SLA definitions, error-handling policies
- **Runbooks** — operational constraints and preconditions for procedures

## Tips

- Run `--dry-run` first to preview extraction and spot conflicts before writing
- Feed ADRs in chronological order — a later ADR superseding an earlier one surfaces as a conflict to resolve deliberately, not silently
- After ingestion, sort the dependency graph topologically; foundational claims (no `depends_on`) are where your test suite should fail fast
- Treat every `premise` claim as a monitoring gap: if it's never checked in production, you're flying blind on an assumption your entire system depends on

## Related Projects

- [claude-ingest](https://github.com/crimeacs/claude-ingest-skill) - Sister skill for ingesting literature and internal docs into concept notes
- [claude-note](https://github.com/crimeacs/claude-note) - Full knowledge synthesis daemon
- [qmd](https://github.com/tobi/qmd) - Quick Markdown Search for semantic deduplication
- [Obsidian](https://obsidian.md) - Knowledge base for local Markdown files

## License

MIT
