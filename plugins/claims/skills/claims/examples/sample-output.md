# Sample Constraint Graph Output

This shows what the `/claims` skill creates when processing a spec file.

## Example Session

**User input:**
```
/claims ~/docs/PaymentService.md --system payment-service
```

**Output:**
```
Reading config... vault at ~/Documents/notes

Reading spec...
Document: PaymentService.md, ~2,400 words

Applying controlled vocabulary...

Extracting statements start to end...
  §1.1  preamble — discarded
  §2.1  formal assertion — normalized → N001
  §2.1  formal assertion — normalized → N002
  §2.2  rationale prose — scope signal captured → annotated N002
  §2.3  code block — translated → N003 (ordered), N004 (atomic)
  §3.1  formal assertion — normalized → N005
  §3.2  code block — translated → N006 (idempotent)
  §3.3  formal assertion — normalized → N007
  §4.1  formal assertion — normalized → N008
  §4.2  cross-domain relationship — normalized → SC001
  §4.3  rationale prose — scope signal captured → annotated SC001
  §5.1  example — implied constraint flagged → [CANDIDATE FLAG-001]
  §5.2  formal assertion — modal ambiguous → N009 + FLAG-002
  §5.2  undefined term → FLAG-003

Normalized 9 nodes, 1 seam constraint.

Running negative-to-positive pass...
  N001: "A payment method MUST NOT be expired."              — exclusion, preserved as MUST NOT
  N007: "No order may proceed without acknowledgment."       → "An order MUST require acknowledgment before fulfillment."

Deriving first-order nodes...
  D001 ← {N002, N003}: "An order MUST require both a valid payment method and an authenticated user."
  D002 ← {N004, N006}: "A transaction MUST be atomic and its retry MUST be idempotent."

Composing top-level invariants...
  TLI-001 ← {N001, N004, N006}: Payment domain guarantee composed.

Assigning entity domains...
  N001 → Payment    N002 → Order     N003 → Order
  N004 → Payment    N005 → Payment   N006 → Payment
  N007 → Order      N008 → Order     N009 → Payment [MODAL_UNRESOLVED]
  D001 → Order      D002 → Payment
  SC001 → Order ↔ Payment

Checking for semantic duplicates...
  ✓ payment-method-not-expired          → no similar nodes
  ✓ order-requires-valid-payment        → no similar nodes
  ✓ order-requires-auth-user            → no similar nodes
  ✓ transaction-atomic                  → no similar nodes
  ✓ refund-references-transaction       → no similar nodes
  ✓ retry-idempotent                    → no similar nodes
  ✓ acknowledgment-precedes-fulfillment → no similar nodes
  ✓ seam-order-payment-method-ref       → no similar nodes
  ✓ session-single-identity             → found: node-session-single-context.md (0.84)
    → Same predicate, same domain (Identity)
    → New source adds Blitz PublicData session shape
    → Will merge
  ✗ payment-method-validated-on-create  → found: node-payment-method-validity.md (0.91)
    → CONFLICT: existing says "validated on every order";
                new spec says "validated on create only"
    → Flagged — file NOT written

Creating files...

Created index:
  claims/payment-service-claims-index.md

Created 8 node files:
  ✓ claims/node-payment-method-not-expired.md
  ✓ claims/node-order-requires-valid-payment.md
  ✓ claims/node-order-requires-auth-user.md
  ✓ claims/node-transaction-atomic.md
  ✓ claims/node-refund-references-transaction.md
  ✓ claims/node-retry-idempotent.md
  ✓ claims/node-acknowledgment-precedes-fulfillment.md
  ✓ claims/node-order-requires-auth-and-payment.md  (derived: D001)

Created 1 seam constraint file:
  ✓ claims/seam-order-payment-method-ref.md

Created 1 top-level invariant file:
  ✓ claims/tli-payment-valid-instruments.md

Merged into existing:
  ✓ claims/node-session-single-context.md
    Added: Blitz PublicData orgId shape; $setPublicData switch; dual-role array

Skipped (conflict — not written):
  ✗ payment-method-validated-on-create → node-payment-method-validity.md
    Reason: "validated on every order" vs "validated on create only" contradicts existing node

=== Constraint Graph Complete (payment-service) ===

Index:                payment-service-claims-index.md
Domains:              Payment, Order, Identity
Seam Constraints:     1
Top-Level Invariants: 1

Created:    10 node/seam/tli files
Merged:     1 node file
Conflicts:  1 (NOT written — resolve first)
Skipped:    0

⚡ UNRESOLVED CONFLICTS — action required:

  node-payment-method-validity.md vs N009
    Existing: "A payment method MUST be validated on every order."
    New spec:  "A payment method MUST be validated on create only."
    → Validation timing is a security and performance boundary decision.
      Validated on every order = defense in depth, higher latency.
      Validated on create only = trusts method state does not change post-assignment.
      Confirm with the payments team; update the winning node and re-run.

🚩 OPEN FLAGS — spec owner action required:

  FLAG-001 [CANDIDATE]        §5.1 example implies a constraint on refund eligibility window.
                              Confirm: is there a time limit on refunds? Not stated elsewhere.
  FLAG-002 [MODAL_UNRESOLVED] N009 — source says "admin can override validation limit."
                              MUST or MAY? Confirm intended modal with payments team.
  FLAG-003 [UNDEFINED_TERM]   N009 — "validation limit" has no definition in spec.
                              Spec owner must define or remove.

📋 Full Node Registry:
────────────────────────────────────────────────────────────────────
N001 [invariant]   [Payment]  A payment method MUST NOT be expired.
N002 [invariant]   [Order]    An order MUST require a valid payment method.
N003 [invariant]   [Order]    An order MUST require an authenticated user.
N004 [invariant]   [Payment]  A transaction MUST be atomic.
N005 [invariant]   [Payment]  A refund MUST reference an existing transaction.
N006 [invariant]   [Payment]  A retry operation MUST be idempotent.
N007 [invariant]   [Order]    An order MUST require acknowledgment before fulfillment.
N008 [constraint]  [Identity] A session MUST be scoped to exactly one identity at a time.
D001 [invariant]   [Order]    An order MUST require both a valid payment method and an authenticated user.
D002 [invariant]   [Payment]  A transaction MUST be atomic and its retry MUST be idempotent.
SC001 [seam]       [Order↔Payment] An order MUST reference a payment method satisfying Payment domain invariants.
────────────────────────────────────────────────────────────────────

📋 Top-Level Invariants:
────────────────────────────────────────────────────────────────────
TLI-001 [Payment] "The Payment domain guarantees all transactions reference valid,
                   non-expired payment methods, committed atomically, safe to retry."
  ← N001, N004, N006
────────────────────────────────────────────────────────────────────
```

---

## Created Files

### Graph Index

**File:** `claims/payment-service-claims-index.md`

```markdown
---
tags:
  - claims/index
  - system/payment-service
created: 2026-02-22
spec_file: "PaymentService.md"
---

# Constraint Graph: payment-service

A payment processing service spec covering transaction lifecycle, payment method
validation, and session scoping. Defines constraints across three domains —
Payment, Order, and Identity — with one explicit cross-domain seam between
Order and Payment entity classes.

## Domain Map

| Domain   | Entity Classes                     | Node Count |
|----------|------------------------------------|------------|
| Payment  | PaymentMethod, Transaction, Refund | 5          |
| Order    | Order, OrderLine                   | 4          |
| Identity | User, Session, Membership          | 1          |

## Node Registry

| ID   | Title                                      | Type       | Modal    | Domain   | File                                                    |
|------|--------------------------------------------|------------|----------|----------|---------------------------------------------------------|
| N001 | Payment Method Must Not Be Expired         | invariant  | MUST NOT | Payment  | [[claims/node-payment-method-not-expired]]              |
| N002 | Order Requires Valid Payment Method        | invariant  | MUST     | Order    | [[claims/node-order-requires-valid-payment]]            |
| N003 | Order Requires Authenticated User          | invariant  | MUST     | Order    | [[claims/node-order-requires-auth-user]]                |
| N004 | Transaction Must Be Atomic                 | invariant  | MUST     | Payment  | [[claims/node-transaction-atomic]]                      |
| N005 | Refund References Existing Transaction     | invariant  | MUST     | Payment  | [[claims/node-refund-references-transaction]]           |
| N006 | Retry Operation Must Be Idempotent         | invariant  | MUST     | Payment  | [[claims/node-retry-idempotent]]                        |
| N007 | Acknowledgment Precedes Fulfillment        | invariant  | MUST     | Order    | [[claims/node-acknowledgment-precedes-fulfillment]]     |
| N008 | Session Scoped to One Identity             | constraint | MUST NOT | Identity | [[claims/node-session-single-identity]]                 |
| D001 | Order Requires Auth User and Valid Payment | invariant  | MUST     | Order    | [[claims/node-order-requires-auth-and-payment]]         |
| D002 | Transaction Atomic and Retry Idempotent    | invariant  | MUST     | Payment  | [[claims/node-transaction-atomic-retry-idempotent]]     |

## Seam Constraints

| ID   | Statement                                                                               | Domain A | Domain B | File                                       |
|------|-----------------------------------------------------------------------------------------|----------|----------|--------------------------------------------|
| SC001| An order MUST reference a payment method satisfying all Payment domain invariants.      | Order    | Payment  | [[claims/seam-order-payment-method-ref]]   |

## Top-Level Invariants

| ID      | Statement                                                                                                     | Domain  | Composed From    |
|---------|---------------------------------------------------------------------------------------------------------------|---------|------------------|
| TLI-001 | The Payment domain guarantees all transactions reference valid non-expired payment methods, atomically committed and safe to retry. | Payment | N001, N004, N006 |

## Dependency Graph

```
N002 → SC001 → N001
D001 → N002
D001 → N003
D002 → N004
D002 → N006
N005 → N004
N007 → N003
TLI-001 ← N001, N004, N006
```

## Open Flags

| Flag ID  | Type               | Node  | Description                                       | Action Required                        |
|----------|--------------------|-------|---------------------------------------------------|----------------------------------------|
| FLAG-001 | CANDIDATE          | —     | §5.1 example implies a refund eligibility window  | Confirm: is there a time limit?        |
| FLAG-002 | MODAL_UNRESOLVED   | N009  | Source says "can override" — MUST or MAY?         | Confirm modal with payments team       |
| FLAG-003 | UNDEFINED_TERM     | N009  | "validation limit" undefined in spec              | Spec owner must define or remove       |

## Unresolved Conflicts

### ⚡ N009 vs [[claims/node-payment-method-validity]]

| | Statement |
|---|---|
| **Existing** (`node-payment-method-validity.md`) | "A payment method MUST be validated on every order." |
| **New spec** (`PaymentService.md`) | "A payment method MUST be validated on create only." |

**Action required:** Validation timing is a security and performance boundary decision.
Validated on every order = defense in depth but higher latency per request.
Validated on create only = trusts that method state does not change post-assignment.
Confirm with the payments team; update the winning node's statement and re-run.

## Source

- **Spec:** `PaymentService.md`
- **Extracted:** 2026-02-22
```

---

### Node Note: Invariant with Semantic Flag

**File:** `claims/node-transaction-atomic.md`

```markdown
---
id: N004
tags:
  - claims/invariant
  - system/payment-service
  - domain/Payment
  - atomic
type: invariant
modal: MUST
entity_domain: Payment
semantic_flags: [atomic]
system: payment-service
source: "[[claims/payment-service-claims-index]]"
seam_constraint: false
added: 2026-02-22
---

# Transaction Must Be Atomic

> **A transaction MUST be atomic — order creation and payment recording
> either both succeed or neither is persisted.**

## Domain

**Payment** — governs the Transaction entity class and its persistence guarantees
across the Order and Payment write path.

## Sources

- `§3.1 ¶2 s1` (spec)
- `PaymentService.createOrderWithPayment() / line 47` (code — `@Transactional` annotation)

## Rationale

"Partial writes — where the order is created but the payment record is not —
leave the system in a state that cannot be automatically recovered and requires
manual intervention to reconcile."

## Semantic Properties

| Property | Meaning in this context |
|---|---|
| atomic | `@Transactional` on `createOrderWithPayment()` — both the Order insert and the Transaction insert commit together or both roll back. Removing the annotation silently allows partial writes with no runtime error. |

## Dependencies

None

## Flags

None

---
*Extracted from: PaymentService.md — 2026-02-22*
```

---

### Node Note: Invariant with Ordering Flag

**File:** `claims/node-acknowledgment-precedes-fulfillment.md`

```markdown
---
id: N007
tags:
  - claims/invariant
  - system/payment-service
  - domain/Order
  - ordered
type: invariant
modal: MUST
entity_domain: Order
semantic_flags: [ordered]
system: payment-service
source: "[[claims/payment-service-claims-index]]"
seam_constraint: false
added: 2026-02-22
---

# Acknowledgment Precedes Fulfillment

> **An order MUST require acknowledgment before fulfillment.**

## Domain

**Order** — governs the Order entity class lifecycle transition
from CONFIRMED to FULFILLING state.

## Sources

- `§4.1 ¶1 s3` (spec — originally stated as "No order may proceed without acknowledgment")
- `OrderService.fulfill() / line 91` (code — guard: `if (order.status != ACKNOWLEDGED) throw`)

## Rationale

"Fulfillment without acknowledgment means physical goods or service delivery
may begin before the customer or downstream system has confirmed the order
details, creating irrecoverable dispatch errors."

## Semantic Properties

| Property | Meaning in this context |
|---|---|
| ordered | The `fulfill()` method explicitly guards on `ACKNOWLEDGED` status. Swapping acknowledgment and fulfillment in the call sequence breaks the state machine — `fulfill()` throws `IllegalStateException`, not a business logic error. The ordering is load-bearing. |

## Dependencies

[[claims/node-order-requires-auth-user]] (N003)

## Flags

None

---
*Extracted from: PaymentService.md — 2026-02-22*
```

---

### Node Note: Derived Node

**File:** `claims/node-order-requires-auth-and-payment.md`

```markdown
---
id: D001
tags:
  - claims/invariant
  - system/payment-service
  - domain/Order
type: invariant
modal: MUST
entity_domain: Order
semantic_flags: []
system: payment-service
source: "[[claims/payment-service-claims-index]]"
seam_constraint: false
added: 2026-02-22
---

# Order Requires Authenticated User and Valid Payment Method

> **An order MUST require both an authenticated user and a valid payment
> method before it may be created.**

## Domain

**Order** — governs the Order entity class creation preconditions as a
compound constraint derived from N002 and N003.

## Sources

- Derived from `§2.1 ¶1` and `§2.1 ¶3` (spec — stated together as joint preconditions)

## Rationale

N002 and N003 are stated as a conjunct pair in §2.1 — the spec treats them
as a single gate on order creation, not independent optional checks.
The derivation preserves that intent as an explicit compound node.

## Semantic Properties

None

## Dependencies

[[claims/node-order-requires-valid-payment]] (N002)
[[claims/node-order-requires-auth-user]] (N003)

## Flags

None

---
*Derived from: N002 ∧ N003 — PaymentService.md — 2026-02-22*
```

---

### Seam Constraint Note

**File:** `claims/seam-order-payment-method-ref.md`

```markdown
---
id: SC001
tags:
  - claims/seam
  - system/payment-service
  - domain/Order
  - domain/Payment
type: seam
modal: MUST
domain_a: Order
domain_b: Payment
system: payment-service
source: "[[claims/payment-service-claims-index]]"
added: 2026-02-22
---

# Order Must Reference Valid Payment Method Across Domain Boundary

> **An Order MUST reference a PaymentMethod that satisfies all Payment
> domain invariants at the time of order creation.**

## Domains

**Order** → **Payment**

An Order entity class holds a foreign reference to a PaymentMethod entity class
owned by the Payment domain. The dependency is unidirectional — Order depends
on Payment to enforce its own invariants; Payment has no knowledge of Order.

## Sources

- `§4.2 ¶1 s2` (spec)
- `§4.3` (rationale — scope signal: "at the time of order creation" scopes the validity check)

## Rationale

"Orders created against an invalid or expired payment method will not fail
immediately — they enter a PENDING state that cannot automatically transition
to CONFIRMED. The resulting stuck orders require manual ops intervention."

## Domain Invariants At Risk

- **Order**: An order MUST require a valid payment method (N002)
- **Payment**: A payment method MUST NOT be expired (N001)

## Dependencies

[[claims/node-order-requires-valid-payment]] (N002)
[[claims/node-payment-method-not-expired]] (N001)

---
*Extracted from: PaymentService.md — 2026-02-22*
```

---

### Top-Level Invariant Note

**File:** `claims/tli-payment-valid-instruments.md`

```markdown
---
id: TLI-001
tags:
  - claims/tli
  - system/payment-service
  - domain/Payment
type: tli
domain: Payment
system: payment-service
composed_from: [N001, N004, N006]
source: "[[claims/payment-service-claims-index]]"
added: 2026-02-22
---

# Payment Domain Guarantees Valid Non-Expired Transaction Instruments

> **The Payment domain guarantees that all transactions reference valid,
> non-expired payment methods, are committed atomically, and are safe
> to retry without side effects.**

## Domain

**Payment** — covers the full transaction lifecycle from method validation
through atomic persistence and retry safety.

## Composed From

| Node | Statement |
|------|-----------|
| [[claims/node-payment-method-not-expired]] (N001) | A payment method MUST NOT be expired. |
| [[claims/node-transaction-atomic]] (N004)         | A transaction MUST be atomic. |
| [[claims/node-retry-idempotent]] (N006)           | A retry operation MUST be idempotent. |

## What This Guarantees

Any caller of the Payment domain can assume that a successfully created
transaction involved a non-expired, validated payment method, was committed
atomically with no risk of partial write, and can be safely retried on network
failure without risk of double-charge or duplicate state.

## What Would Break It

Violating any one of N001, N004, or N006 collapses this contract:
- N001 violated: an expired method reaches the charge gateway, producing a
  hard decline after order state has already been written.
- N004 violated: a partial write leaves an Order record with no corresponding
  Transaction — balance and order state are permanently inconsistent.
- N006 violated: a network retry on a non-idempotent operation double-charges
  the customer with no observable error.

---
*Composed from: PaymentService.md — 2026-02-22*
```

---

### Merged Node Note

**File:** `claims/node-session-single-identity.md` (existed before, now updated)

```markdown
---
id: N008
tags:
  - claims/constraint
  - system/payment-service
  - system/auth-service
  - domain/Identity
  - sessions
type: constraint
modal: MUST NOT
entity_domain: Identity
semantic_flags: []
system:
  - auth-service
  - payment-service
sources:
  - "[[claims/auth-service-claims-index]]"
  - "[[claims/payment-service-claims-index]]"
seam_constraint: false
added: 2025-11-03
updated: 2026-02-22
---

# Session Scoped to One Identity at a Time

> **A session MUST NOT be active in more than one organization simultaneously;
> switching organizations MUST replace the previous org context entirely.**

## Domain

**Identity** — governs the Session entity class and its org-scoping invariant.

## Sources

- `§6.1 ¶2 s1` (spec — auth-service)
- `§3.3 ¶1 s2` (spec — payment-service)

## Rationale

"Simultaneous multi-org access in a single session makes ctx.session.orgId
ambiguous. Every query and mutation must know exactly which tenant it is
operating on — ambiguity here is a data isolation failure, not a UX issue."

## Semantic Properties

None

## Dependencies

None

## Flags

None

## Additional Context (payment-service, 2026-02-22)

In Blitz.js, `orgId` lives in `Session.PublicData` declared in `types.ts`.
Both `GlobalRole` and `MembershipRole` values coexist in the session `roles`
array simultaneously. Org switching is performed via
`session.$setPublicData({ orgId })`. The session initializes at login with
`memberships[0].organizationId` as the default active org.

```pseudo
// Blitz-specific initialization assertion
POST /login
assert: session.orgId == user.memberships[0].organizationId
assert: session.roles includes user.role           // GlobalRole
assert: session.roles includes memberships[0].role // MembershipRole

// Org switch
session.$setPublicData({ orgId: newOrgId })
assert: session.orgId == newOrgId
assert: session.orgId != previousOrgId
```

*Source: PaymentService.md*

---
*Sources: auth-service spec (2025-11-03), PaymentService.md (2026-02-22)*
```

---

## Dry Run Example

**User input:**
```
/claims ~/docs/PaymentService.md --system payment-service --dry-run
```

**Output:**
```
=== DRY RUN — no files written ===

Would create index:
  claims/payment-service-claims-index.md

Would create 8 node files:
  - claims/node-payment-method-not-expired.md          [invariant, Payment]
  - claims/node-order-requires-valid-payment.md        [invariant, Order]
  - claims/node-order-requires-auth-user.md            [invariant, Order]
  - claims/node-transaction-atomic.md                  [invariant, Payment — atomic]
  - claims/node-refund-references-transaction.md       [invariant, Payment]
  - claims/node-retry-idempotent.md                    [invariant, Payment — idempotent]
  - claims/node-acknowledgment-precedes-fulfillment.md [invariant, Order — ordered]
  - claims/node-order-requires-auth-and-payment.md     [invariant, Order — derived: D001]

Would create 1 seam constraint file:
  - claims/seam-order-payment-method-ref.md            [Order ↔ Payment]

Would create 1 top-level invariant file:
  - claims/tli-payment-valid-instruments.md            [Payment ← N001, N004, N006]

Would merge into 1 existing file:
  - claims/node-session-single-identity.md
    New context: Blitz PublicData orgId shape; $setPublicData switch; dual-role array

Would flag 1 conflict — NOT written:
  ⚡ node-payment-method-validity.md vs N009
     Existing: "A payment method MUST be validated on every order."
     New spec:  "A payment method MUST be validated on create only."
     → Resolve before running without --dry-run.

Would raise 3 flags for spec owner:
  FLAG-001 [CANDIDATE]        §5.1 implies refund eligibility window — confirm or discard
  FLAG-002 [MODAL_UNRESOLVED] N009 — "can override": MUST or MAY?
  FLAG-003 [UNDEFINED_TERM]   N009 — "validation limit" undefined in spec

No files written.
```

---

## Conflict-Only Example

**User input:**
```
/claims ~/docs/PaymentService-v2.md --system payment-service
```

**Output (excerpt):**
```
...
  ✗ payment-method-validated-on-create → found: node-payment-method-validity.md (0.91)
    → CONFLICT: existing says "validated on every order";
                new spec says "validated on create only"
    → Flagged — NOT written

  ✗ session-orgid-nullable → found: node-session-single-identity.md (0.88)
    → CONFLICT: existing says session.orgId MUST NOT be null after login;
                new spec says session.orgId MAY be null for pending-invite users
    → Flagged — NOT written
...

=== Constraint Graph Complete (payment-service) ===

Created:    6 node files
Merged:     0 node files
Conflicts:  2 (NOT written — resolve first)
Skipped:    0

⚡ UNRESOLVED CONFLICTS — action required:

  1. node-payment-method-validity.md vs N-NEW-003
     Existing: "A payment method MUST be validated on every order."
     New spec:  "A payment method MUST be validated on create only."
     → Defense in depth vs trust-on-assignment is a performance and security trade-off.
       Confirm with the payments team; update the winning node's statement and re-run.

  2. node-session-single-identity.md vs N-NEW-008
     Existing: "A session MUST NOT have a null orgId after login."
     New spec:  "A session MAY have a null orgId for users with pending-invite Memberships."
     → Pending-invite is a new Identity lifecycle state not modeled in v1.
       Scope the original node to fully-joined users, or replace it with a
       conditional node that covers both states explicitly.
```
