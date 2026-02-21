# Claims Note Formats

This skill creates TWO types of files for design claims:

1. **Claims Index** - Registry of all claims extracted from a spec, with dependency graph
2. **Claim Notes** - Standalone atomic files, one per falsifiable statement

---

## Claims Index

Created at: `claims/{system}-claims-index.md`

```markdown
---
tags:
  - claims/index
  - system/{system}
created: {YYYY-MM-DD}
spec_file: "{original-filename-or-url}"
---

# Design Claims: {system}

{2-3 sentence summary of what this spec defines and its scope.}

## Claim Registry

| ID      | Title                        | Category      | File                              |
|---------|------------------------------|---------------|-----------------------------------|
| CLM-001 | {Title}                      | {category}    | [[claims/claim-{slug}]]           |
| CLM-002 | {Title}                      | {category}    | [[claims/claim-{slug}]]           |

## Dependency Graph

```
CLM-002 → CLM-001
CLM-005 → CLM-002 → CLM-001
```

## Source

- **Spec:** `{original-filename-or-url}`
- **Extracted:** {YYYY-MM-DD}
```

### Field Guidelines

- **tags**: Always include `claims/index` and `system/{system}`
- **spec_file**: Original filename or URL the claims were extracted from
- **Claim Registry**: Every claim extracted from this spec, including MERGEd ones
- **Dependency Graph**: Only include edges that exist; omit section if no dependencies
- **Summary**: Scope of the spec — what system, what lifecycle phase, what risks it addresses

**Real example — index for `Multitenancy.md`:**

```markdown
---
tags:
  - claims/index
  - system/blitz-multitenancy
created: 2026-02-20
spec_file: "Multitenancy.md"
---

# Design Claims: blitz-multitenancy

A Blitz.js multitenancy implementation guide defining tenant isolation via a
shared database. Establishes the Organization → Membership → User data model,
session-scoped org tracking, and mandatory query/mutation filtering patterns
that collectively enforce tenant data boundaries.

## Claim Registry

| ID      | Title                                    | Category      | File                                                    |
|---------|------------------------------------------|---------------|---------------------------------------------------------|
| CLM-001 | organizationId on Every Domain Model     | invariant     | [[claims/claim-organizationid-on-every-model]]          |
| CLM-002 | Queries Must Filter by organizationId    | invariant     | [[claims/claim-query-must-filter-by-orgid]]             |
| CLM-003 | Creates Must Attach organizationId       | postcondition | [[claims/claim-create-must-attach-orgid]]               |
| CLM-004 | Updates/Deletes Must Include orgId Where | invariant     | [[claims/claim-update-delete-where-includes-orgid]]     |
| CLM-005 | Session Scoped to One Org at a Time      | constraint    | [[claims/claim-session-single-context]]                 |
| CLM-006 | Entity Assignments Target Membership     | constraint    | [[claims/claim-entity-assigned-to-membership]]          |
| CLM-007 | Signup Atomically Creates Org + Member   | postcondition | [[claims/claim-signup-creates-org-and-membership]]      |

## Dependency Graph

```
CLM-002 → CLM-001
CLM-003 → CLM-001
CLM-004 → CLM-001
CLM-004 → CLM-005
CLM-006 → CLM-001
```

## Source

- **Spec:** `Multitenancy.md`
- **Extracted:** 2026-02-20
```

---

## Claim Note

Created at: `claims/claim-{slug}.md`

Each claim is a **standalone falsifiable statement** with enough context to generate assertions and reason about system correctness without reading the original spec.

```markdown
---
id: {CLM-NNN}
tags:
  - claims/{category}
  - system/{system}
  - {domain-tags...}
category: {category}
system: {system}
source: "[[claims/{system}-claims-index]]"
added: {YYYY-MM-DD}
---

# {Title}

> **{Single falsifiable statement. Active voice. Present tense. RFC 2119 modal verb.}**

## Rationale

{1-3 sentences: why this claim exists, which failure mode or risk it mitigates.}

## Violation Scenario

{Concrete description of what breaks when this claim is false. Name the data state,
the sequence of events, and the observable consequence.}

## Assertion Hint

```pseudo
{Pseudo-code or structured natural language showing how to assert this claim
in a unit test, integration test, or runtime invariant check.}
```

## Dependencies

{Wikilinks to claims this one depends on, or "None"}

---
*Extracted from: {spec title} — {YYYY-MM-DD}*
```

### Claim Categories

Use these category tags (`claims/{category}`):

| Category | Meaning | Modal | Example (from Multitenancy) |
|---|---|---|---|
| `premise` | Assumed true about the environment; not enforced by this system | WILL | "The database WILL enforce foreign key constraints on organizationId" |
| `invariant` | Always true regardless of operation sequence | SHALL / SHALL NOT | "Every domain model SHALL carry an organizationId foreign key" |
| `guarantee` | What this system promises to callers and consumers | MUST | "The org-switch operation MUST reflect the new orgId on all subsequent requests" |
| `constraint` | Hard limit on valid inputs or state transitions | MUST NOT | "A session MUST NOT be active in more than one organization simultaneously" |
| `precondition` | Must hold before an operation executes | MUST | "A user MUST have an active Membership in an org before querying its data" |
| `postcondition` | Must hold after an operation completes | MUST | "After signup, an OWNER Membership MUST exist linking the User to their Organization" |

### Field Guidelines

- **id**: Sequential within the source spec (`CLM-001`, `CLM-002`, …)
- **category**: Exactly one from the table above; determines test strategy
- **system**: Logical service or component name, kebab-case
- **statement**: The core of the file — one sentence, no hedging, disprovable by counterexample
- **Rationale**: The *why*, not a restatement of the claim
- **Violation Scenario**: Must name a concrete data state or call sequence, not just "it breaks"
- **Assertion Hint**: At minimum one test case; layered (unit → integration → concurrency) when relevant

**Real example — invariant claim from `Multitenancy.md`:**

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

A query for GET /projects?id=42 runs `db.project.findFirst({ where: { id: 42 } })`.
User in Org A submits id=42, which belongs to Org B. The query succeeds and returns
Org B's data. No authorization error fires because the record exists and the user
is authenticated.

## Assertion Hint

```pseudo
// Static analysis rule (AST lint)
for each db.*.findFirst / findMany / findUnique call:
  assert: where clause contains "organizationId"

// Integration test — cross-tenant read attempt
login as user_a (orgId = 1)
seed: project { id: 99, organizationId: 2 }
GET /projects/99 as user_a
assert: response status is 404 or 403 — NOT 200
```

## Dependencies

[[claims/claim-organizationid-on-every-model]] (CLM-001)

---
*Extracted from: Multitenancy.md — 2026-02-20*
```

---

## Multi-Source Accumulation

When the same claim appears in multiple specs, new context is appended without overwriting the original.

```markdown
---
id: CLM-005
tags:
  - claims/constraint
  - system/blitz-multitenancy
  - system/auth-service
  - sessions
  - multitenancy
category: constraint
system:
  - auth-service        ← original
  - blitz-multitenancy  ← added on merge
sources:
  - "[[claims/auth-service-claims-index]]"
  - "[[claims/blitz-multitenancy-claims-index]]"
added: 2025-11-03
updated: 2026-02-20
---

# Session Scoped to One Org at a Time

> **A user session MUST be active in exactly one organization at a time;
> switching organizations MUST replace the previous org context.**

{Original rationale, violation scenario, and assertion hint from auth-service spec}

## Additional Context (blitz-multitenancy, 2026-02-20)

In Blitz.js, `orgId` lives in `Session.PublicData` declared in `types.ts`.
Both `GlobalRole` and `MembershipRole` values coexist in the session `roles`
array simultaneously. Org switching is performed via `session.$setPublicData({ orgId })`.
The session is initialized at login with `memberships[0].organizationId`.

```pseudo
POST /login
assert: session.orgId == user.memberships[0].organizationId
assert: session.roles includes user.role          // GlobalRole
assert: session.roles includes memberships[0].role // MembershipRole
```

*Source: Multitenancy.md*

## Dependencies

None

---
*Sources: auth-service spec (2025-11-03), Multitenancy.md (2026-02-20)*
```

### Accumulation Rules

- Convert `system: "single-value"` to `system: [array]` when a second system is added
- Convert `source:` to `sources:` array; keep all backlinks
- Add `updated:` to frontmatter
- Append an `## Additional Context ({system}, {YYYY-MM-DD})` section — never overwrite the original
- If the new source **contradicts** the existing statement, do NOT merge; flag as `CONFLICT` and stop

---

## Conflict Record

When two specs contradict each other on the same claim, the file is NOT written.
Instead, a conflict entry is appended to the index of the *newer* spec:

```markdown
## Unresolved Conflicts

### ⚡ CLM-NEW-008 vs [[claims/claim-superadmin-access]]

| | Statement |
|---|---|
| **Existing** (`claim-superadmin-access.md`) | "A SUPERADMIN MAY read data across all organizations" |
| **New** (`Multitenancy.md`) | "A SUPERADMIN MUST bypass organizationId filtering on all operations" |

**Action required:** MAY (read-only) vs MUST (all ops) is a security boundary decision.
Confirm with the platform team; update the winning file's modal verb. Re-run after resolution.
```

---

## Example: Complete Extraction

**Input:** `Multitenancy.md --system blitz-multitenancy`

**Creates:**

1. `claims/blitz-multitenancy-claims-index.md` (index)
2. `claims/claim-organizationid-on-every-model.md` (invariant)
3. `claims/claim-query-must-filter-by-orgid.md` (invariant)
4. `claims/claim-create-must-attach-orgid.md` (postcondition)
5. `claims/claim-update-delete-where-includes-orgid.md` (invariant)
6. `claims/claim-entity-assigned-to-membership.md` (constraint)
7. `claims/claim-signup-creates-org-and-membership.md` (postcondition)

**Merges into:**

8. `claims/claim-session-single-context.md` (constraint — adds Blitz-specific PublicData details)

**Flags (not written):**

9. `claim-superadmin-access.md` — CONFLICT: MAY read vs MUST bypass all ops
