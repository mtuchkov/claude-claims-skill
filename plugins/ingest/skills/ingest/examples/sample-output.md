# Sample Claims Output

This shows what the `/claims` skill creates when processing a spec file.

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
    → New info: orgId stored in PublicData; Blitz $setPublicData switch mechanism
    → Will merge
  ✓ entity-assigned-to-membership       → no similar claims
  ✓ signup-creates-org-and-membership   → no similar claims
  ✗ superadmin-bypasses-org-filter      → found: claim-superadmin-access.md (0.93)
    → CONFLICT: existing says SUPERADMIN MAY read across orgs;
                new spec says SUPERADMIN MUST bypass filter on ALL operations
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
    Added: orgId in Blitz PublicData; $setPublicData switch; roles array shape

Skipped (conflict — not written):
  ✗ superadmin-bypasses-org-filter → claim-superadmin-access.md
    Reason: MAY (read-only) vs MUST (all operations) contradicts existing claim
```

---

## Created Files

### Claims Index

**File:** `claims/blitz-multitenancy-claims-index.md`

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

## Unresolved Conflicts

### ⚡ CLM-NEW-008 vs [[claims/claim-superadmin-access]]

| | Statement |
|---|---|
| **Existing** (`claim-superadmin-access.md`) | "A SUPERADMIN MAY read data across all organizations" |
| **New spec** (`Multitenancy.md`) | "A SUPERADMIN MUST bypass organizationId filtering on all operations, including writes" |

**Action required:** MAY (read-only) vs MUST (all ops) is a meaningful security boundary.
Confirm intended scope with the platform team before re-running.

## Source

- **Spec:** `Multitenancy.md`
- **Extracted:** 2026-02-20
```

---

### Claim Note: Invariant

**File:** `claims/claim-organizationid-on-every-model.md`

```markdown
---
id: CLM-001
tags:
  - claims/invariant
  - system/blitz-multitenancy
  - data-modeling
  - multitenancy
category: invariant
system: blitz-multitenancy
source: "[[claims/blitz-multitenancy-claims-index]]"
added: 2026-02-20
---

# organizationId on Every Domain Model

> **Every domain model except User and Organization MUST carry an
> `organizationId` foreign key referencing the owning Organization.**

## Rationale

Without an explicit `organizationId` on every entity, tenant isolation
depends on join traversals — error-prone and easy to forget. A direct
foreign key makes ownership visible, enforceable at the DB level, and
indexable for query performance.

## Violation Scenario

A developer adds a `Comment` model linked only to `userId`. A query for
comments filters by `where: { userId }` with no org clause. User A, who
is also a member of Org B, reads Org B's comments by guessing a comment
ID. No error is raised; the data leak is silent.

## Assertion Hint

```pseudo
// Schema lint
for each model in schema:
  if model.name not in ["User", "Organization", "Membership"]:
    assert: model has field "organizationId Int"
    assert: model has @relation to Organization via organizationId

// Migration guard
assert: every Prisma migration that adds a new model
        also adds an organizationId column and foreign key
```

## Dependencies

None

---
*Extracted from: Multitenancy.md — 2026-02-20*
```

---

### Claim Note: Invariant (query layer)

**File:** `claims/claim-query-must-filter-by-orgid.md`

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

A shared-database multitenant system has no network or schema barrier
between tenants. The `organizationId` filter is the sole runtime
enforcement mechanism — omitting it on a single query is a data-leak
vulnerability.

## Violation Scenario

A query for `GET /projects?id=42` runs:
```ts
db.project.findFirst({ where: { id: 42 } })
```
User in Org A submits `id=42`, which belongs to Org B. The query succeeds
and returns Org B's data. No authorization error fires because the record
exists and the user is authenticated.

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

### Claim Note: Constraint

**File:** `claims/claim-entity-assigned-to-membership.md`

```markdown
---
id: CLM-006
tags:
  - claims/constraint
  - system/blitz-multitenancy
  - data-modeling
  - multitenancy
category: constraint
system: blitz-multitenancy
source: "[[claims/blitz-multitenancy-claims-index]]"
added: 2026-02-20
---

# Entity Assignments Target Membership, Not User

> **Any entity assigned to a specific person within an organization (e.g.,
> a Task) MUST store a `membershipId` foreign key, NOT a `userId` foreign key.**

## Rationale

A User can belong to multiple Organizations via separate Membership records.
Assigning to `userId` leaves org context ambiguous — which of the user's
memberships owns this record? A `membershipId` encodes both person and org
in a single field, making ownership unambiguous.

## Violation Scenario

`Task.userId = 7`. User 7 belongs to Org A and Org B. A task query filters
by `userId: 7` without an org clause — Org A's tasks leak to Org B context.
Worse, when the user leaves Org A, tasks remain linked to a User with no
active Membership there; business ownership is broken even though FK
integrity holds.

## Assertion Hint

```pseudo
// Schema lint
for each model with assignment semantics (Task, Ticket, etc.):
  assert: model has "membershipId Int" NOT "assigneeUserId Int"
  assert: model has @relation to Membership via membershipId

// Integration test — org-scoped assignment isolation
user_a has membership_1 (org=1) and membership_2 (org=2)
create task with membershipId = membership_1.id
login as user_a, orgId = 2
GET /tasks → assert: task NOT in response
login as user_a, orgId = 1
GET /tasks → assert: task IS in response
```

## Dependencies

[[claims/claim-organizationid-on-every-model]] (CLM-001)

---
*Extracted from: Multitenancy.md — 2026-02-20*
```

---

### Claim Note: Postcondition

**File:** `claims/claim-signup-creates-org-and-membership.md`

```markdown
---
id: CLM-007
tags:
  - claims/postcondition
  - system/blitz-multitenancy
  - data-modeling
  - onboarding
category: postcondition
system: blitz-multitenancy
source: "[[claims/blitz-multitenancy-claims-index]]"
added: 2026-02-20
---

# Signup Atomically Creates Org and Membership

> **A successful user signup MUST atomically create the User, an
> Organization, and an OWNER Membership in a single database transaction.**

## Rationale

If any of the three records is absent after signup, the user lands in a
broken state: no org means `ctx.session.orgId` is null, all queries fail,
and there is no self-service recovery path. Atomicity guarantees all three
exist or none do.

## Violation Scenario

The signup mutation creates the User first, then the Organization in a
separate call. The second call throws a DB constraint error (duplicate org
name). The User record now exists without an Organization or Membership.
On next login, `session.$create()` reads `memberships[0]` as `undefined`.
`orgId` becomes `undefined`. Every subsequent query throws
`"Missing session.orgId"`.

## Assertion Hint

```pseudo
// Integration test — happy path
POST /signup { name, email, password, orgName }
assert: db.user.count({ where: { email } }) == 1
assert: db.organization.count({ where: { name: orgName } }) == 1
assert: db.membership.count({ where: { userId, role: "OWNER" } }) == 1
assert: all three records share the same organizationId

// Integration test — atomicity on failure
mock db.organization.create to throw
POST /signup
assert: db.user.count({ where: { email } }) == 0  // rolled back
```

## Dependencies

None

---
*Extracted from: Multitenancy.md — 2026-02-20*
```

---

### Merged Claim Note

**File:** `claims/claim-session-single-context.md` (existed before, now updated)

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
  - auth-service
  - blitz-multitenancy
source: "[[claims/auth-service-claims-index]]"
added: 2025-11-03
updated: 2026-02-20
---

# Session Scoped to One Org at a Time

> **A user session MUST be active in exactly one organization at a time;
> switching organizations MUST replace the previous org context.**

## Rationale

Simultaneous multi-org access in a single session makes `ctx.session.orgId`
ambiguous. A single active org enforces a clear authorization boundary:
every query and mutation in the session knows exactly which tenant it is
operating on.

## Violation Scenario

Two browser tabs share a session. Tab A is in Org 1; Tab B switches to Org 2
via a concurrent `$setPublicData` call. Due to a session-update race, Tab A's
next mutation reads `orgId = 2` from the shared session and writes into Org 2
on behalf of an Org 1 user.

## Assertion Hint

```pseudo
// From auth-service spec
login → assert: session.orgId is exactly one integer, not null, not array

// Org switch
$setPublicData({ orgId: newOrgId })
assert: session.orgId == newOrgId
assert: session.orgId != previousOrgId
assert: subsequent queries use newOrgId, not previousOrgId
```

## Additional Context (blitz-multitenancy, 2026-02-20)

In Blitz.js, `orgId` lives in `Session.PublicData` declared in `types.ts`.
Both `GlobalRole` and `MembershipRole` values coexist in the session `roles`
array simultaneously. Org switching is performed via
`session.$setPublicData({ orgId })`. The session is initialized at login with
`memberships[0].organizationId` as the default active org.

```pseudo
// Blitz-specific initialization assertion
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

---

## Dry Run Example

**User input:**
```
/claims ~/docs/Multitenancy.md --system blitz-multitenancy --dry-run
```

**Output:**
```
=== DRY RUN — no files written ===

Would create index:
  claims/blitz-multitenancy-claims-index.md

Would create 6 claim files:
  - claims/claim-organizationid-on-every-model.md       [invariant]
  - claims/claim-query-must-filter-by-orgid.md          [invariant]
  - claims/claim-create-must-attach-orgid.md            [postcondition]
  - claims/claim-update-delete-where-includes-orgid.md  [invariant]
  - claims/claim-entity-assigned-to-membership.md       [constraint]
  - claims/claim-signup-creates-org-and-membership.md   [postcondition]

Would merge into 1 existing file:
  - claims/claim-session-single-context.md
    New info: orgId in Blitz PublicData; $setPublicData switch; dual-role array

Would flag 1 conflict — NOT written:
  ⚡ claim-superadmin-access.md vs CLM-NEW-008
     Existing: "A SUPERADMIN MAY read data across all organizations"
     New spec:  "A SUPERADMIN MUST bypass organizationId filtering on all operations"
     → Resolve before running without --dry-run

No files written.
```

---

## Conflict-Only Example

**User input:**
```
/claims ~/docs/Multitenancy-v2.md --system blitz-multitenancy
```

**Output (excerpt):**
```
...
  ✗ superadmin-bypasses-org-filter  → found: claim-superadmin-access.md (0.93)
    → CONFLICT: existing scopes SUPERADMIN to reads only;
                new spec mandates bypass on all operations including writes
    → Flagged — NOT written
  ✗ session-orgid-nullable          → found: claim-session-single-context.md (0.87)
    → CONFLICT: existing says orgId MUST be set after login;
                new spec says orgId MAY be null for pending-invite users
    → Flagged — NOT written
...

=== Claims Extraction Complete (blitz-multitenancy) ===

Created:   5 claim files
Merged:    1 claim file
Conflicts: 2 (NOT written — resolve first)
Skipped:   0

⚡ UNRESOLVED CONFLICTS — action required:

  1. claim-superadmin-access.md vs CLM-NEW-008
     Existing: "A SUPERADMIN MAY read data across all organizations"
     New spec:  "A SUPERADMIN MUST bypass organizationId filtering on all operations"
     → Read-only vs all-operations is a security boundary decision.
       Confirm with the platform team; update the winning file's modal verb.

  2. claim-session-single-context.md vs CLM-NEW-005
     Existing: "session.orgId MUST be set to an integer after login"
     New spec:  "session.orgId MAY be null for users with pending-invite Memberships"
     → Invited-but-not-yet-joined is a new session state not modeled in v1.
       Scope the original claim to fully-joined users or replace it.
```
