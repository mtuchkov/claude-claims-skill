# Constraint Graph Note Formats

This skill creates FOUR types of files:

1. **Graph Index** — Registry of all nodes, seam constraints, and top-level invariants extracted from a source
2. **Node Notes** — Standalone atomic files, one per normalized constraint statement
3. **Seam Constraint Notes** — Standalone files for constraints that govern relationships across domain boundaries
4. **Top-Level Invariant Notes** — Composed system contracts derived from clusters of nodes

---

## Graph Index

Created at: `claims/{system}-claims-index.md`

```markdown
---
tags:
  - claims/index
  - system/{system}
created: {YYYY-MM-DD}
spec_file: "{original-filename-or-url}"
---

# Constraint Graph: {system}

{2-3 sentence summary of what this source defines, which domains it covers, and its scope.}

## Domain Map

| Domain | Entity Classes | Node Count |
|--------|---------------|------------|
| {domain} | {entity classes, comma-separated} | {n} |

## Node Registry

| ID    | Title   | Type      | Modal     | Domain   | File                     |
|-------|---------|-----------|-----------|----------|--------------------------|
| N001  | {title} | {type}    | {modal}   | {domain} | [[claims/node-{slug}]]   |

## Seam Constraints

| ID    | Statement | Domain A | Domain B | File |
|-------|-----------|----------|----------|------|
| SC001 | {stmt}    | {a}      | {b}      | [[claims/seam-{slug}]] |

## Top-Level Invariants

| ID      | Statement | Domain | Composed From |
|---------|-----------|--------|---------------|
| TLI-001 | {stmt}    | {dom}  | N001, N003, D002 |

## Dependency Graph

```
N002 → N001
N004 → N001
SC001 → N003
SC001 → N007
TLI-001 ← N001, N003, SC001
```

## Open Flags

| Flag ID  | Type               | Node  | Description                        | Action Required          |
|----------|--------------------|-------|------------------------------------|--------------------------|
| FLAG-001 | UNDEFINED_TERM     | N007  | "trial period" not defined in spec | Spec owner must define   |
| FLAG-002 | MODAL_UNRESOLVED   | N009  | Source says "can" — MUST or MAY?   | Spec owner must clarify  |
| FLAG-003 | DOMAIN_UNRESOLVED  | N011  | Entity class unclear               | Assign to domain         |

## Unresolved Conflicts

{Appended here when a new node contradicts an existing one — see Conflict Record section}

## Source

- **Spec:** `{original-filename-or-url}`
- **Extracted:** {YYYY-MM-DD}
```

### Field Guidelines

- **tags**: Always include `claims/index` and `system/{system}`
- **Domain Map**: Every domain identified in the source — not flows, not sections, entity classes
- **Node Registry**: Every node extracted, including merged ones
- **Seam Constraints**: Cross-domain relationship constraints — tracked separately, owned by neither domain
- **Top-Level Invariants**: Composed system contracts, each traceable to constituent node IDs
- **Dependency Graph**: Only include edges that exist; omit section if no dependencies
- **Open Flags**: Every unresolved ambiguity — spec owner must action before graph is trusted

**Real example — index for `PaymentService.md`:**

```markdown
---
tags:
  - claims/index
  - system/payment-service
created: 2026-02-22
spec_file: "PaymentService.md"
---

# Constraint Graph: payment-service

A payment processing service spec defining the Payment, Order, and Identity domains.
Covers transaction lifecycle, payment method validation, session scoping,
and cross-domain contracts between Order and Payment entity classes.

## Domain Map

| Domain   | Entity Classes                              | Node Count |
|----------|---------------------------------------------|------------|
| Payment  | PaymentMethod, Transaction, Refund          | 5          |
| Order    | Order, OrderLine                            | 3          |
| Identity | User, Session, Membership                   | 1          |

## Node Registry

| ID   | Title                                  | Type        | Modal    | Domain   | File                                             |
|------|----------------------------------------|-------------|----------|----------|--------------------------------------------------|
| N001 | Payment Method Must Not Be Expired     | invariant   | MUST NOT | Payment  | [[claims/node-payment-method-not-expired]]       |
| N002 | Order Requires Valid Payment Method    | invariant   | MUST     | Order    | [[claims/node-order-requires-valid-payment]]     |
| N003 | Order Requires Authenticated User      | invariant   | MUST     | Order    | [[claims/node-order-requires-auth-user]]         |
| N004 | Transaction Must Be Atomic             | invariant   | MUST     | Payment  | [[claims/node-transaction-atomic]]               |
| N005 | Refund References Existing Transaction | invariant   | MUST     | Payment  | [[claims/node-refund-references-transaction]]    |
| N006 | Session Scoped to One Identity         | constraint  | MUST NOT | Identity | [[claims/node-session-single-identity]]          |
| N007 | Retry Operation Must Be Idempotent     | invariant   | MUST     | Payment  | [[claims/node-retry-idempotent]]                 |
| N008 | Acknowledgment Precedes Fulfillment    | invariant   | MUST     | Order    | [[claims/node-acknowledgment-precedes-fulfill]]  |

## Seam Constraints

| ID   | Statement                                                                 | Domain A | Domain B | File                                         |
|------|---------------------------------------------------------------------------|----------|----------|----------------------------------------------|
| SC001| An order MUST reference a payment method satisfying Payment invariants.   | Order    | Payment  | [[claims/seam-order-payment-method-ref]]     |

## Top-Level Invariants

| ID      | Statement                                                                                              | Domain  | Composed From       |
|---------|--------------------------------------------------------------------------------------------------------|---------|---------------------|
| TLI-001 | The Payment domain guarantees all transactions reference valid non-expired payment methods.            | Payment | N001, N004, N007    |

## Dependency Graph

```
N002 → SC001 → N001
N003 → N002
N005 → N004
N007 → N004
N008 → N003
TLI-001 ← N001, N004, N007
```

## Open Flags

| Flag ID  | Type             | Node  | Description                                       | Action Required                    |
|----------|------------------|-------|---------------------------------------------------|------------------------------------|
| FLAG-001 | MODAL_UNRESOLVED | N009  | Source says "can override" — MUST or MAY?         | Confirm modal with payments team   |
| FLAG-002 | UNDEFINED_TERM   | N009  | "validation limit" has no definition in spec      | Spec owner must define the term    |

## Source

- **Spec:** `PaymentService.md`
- **Extracted:** 2026-02-22
```

---

## Node Note

Created at: `claims/node-{slug}.md`

Each node is a **standalone normalized constraint statement** — one atomic claim,
traceable to its source, typed, domain-scoped, and carrying enough context to
generate assertions without reading the original spec.

```markdown
---
id: {N###}
tags:
  - claims/{type}
  - system/{system}
  - domain/{entity-domain}
  - {semantic-flags: idempotent|atomic|immutable|ordered|bounded}
type: {invariant|exclusion|soft|conditional|permission}
modal: {MUST|MUST NOT|SHOULD|MAY}
entity_domain: {DomainName}
semantic_flags: [{idempotent|atomic|immutable|ordered|bounded}]
system: {system}
source: "[[claims/{system}-claims-index]]"
seam_constraint: false
added: {YYYY-MM-DD}
---

# {Title}

> **{Single normalized statement. Active voice. Present tense. Controlled vocabulary. One claim.}**

## Domain

**{EntityDomain}** — {brief statement of which entity class this governs}

## Sources

- `{precise source pointer}` ({spec|code})
- `{precise source pointer}` ({spec|code})

## Rationale

{Verbatim rationale prose from the source — for human reference only.
This is not part of the constraint. It informs scope decisions and
explains the risk the constraint mitigates.}

## Semantic Properties

{Only present if semantic_flags is non-empty. Describe the property and
why it was surfaced from the code translation phase.}

| Property | Meaning in this context |
|---|---|
| {idempotent\|atomic\|immutable\|ordered\|bounded} | {concrete description} |

## Dependencies

{Wikilinks to nodes this one depends on, or "None"}

## Flags

{Typed flags with descriptions, or "None"}

---
*Extracted from: {source title} — {YYYY-MM-DD}*
```

### Node Types

| Type | Modal | Meaning |
|---|---|---|
| `invariant` | MUST | Holds at all times, no exceptions |
| `exclusion` | MUST NOT | Hard prohibition |
| `soft` | SHOULD | Strong preference, exceptions acknowledged |
| `conditional` | MUST (when X) | Holds only when a stated predicate is true |
| `permission` | MAY | Permitted but not required |

### Semantic Flags

Populated exclusively from the code translation phase.
Carry architectural properties that the normalized narrative alone cannot fully express.

| Flag | Surfaces When |
|---|---|
| `idempotent` | Code guards against double-application; retry logic present |
| `atomic` | `@Transactional`, lock, or explicit rollback present |
| `immutable` | `final` field, no setter exposed, value object pattern |
| `ordered` | Operation sequence is load-bearing; swapping steps breaks correctness |
| `bounded` | Explicit cardinality guard or size limit enforced in code |

### Field Guidelines

- **id**: Sequential within the source (`N001`, `N002`, …)
- **type**: Exactly one from the node types table
- **entity_domain**: The domain of the entity class the statement *governs* — not the flow, section, or actor
- **statement**: One sentence, no hedging, disprovable by counterexample, controlled vocabulary only
- **Sources**: Every source pointer that contributed to this node — section + line for spec, class + method + line for code
- **Rationale**: The *why* from the source — never a restatement of the statement itself
- **Semantic Properties**: Only present when a code translation surfaced a property that matters architecturally

**Real example — invariant node from `PaymentService.md`:**

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

> **A Transaction MUST be atomic — Order creation and payment recording
> either both succeed or neither is persisted.**

## Domain

**Payment** — governs the Transaction entity class and its persistence guarantees.

## Sources

- `§3.1 ¶2 s1` (spec)
- `PaymentService.createOrderWithPayment() / line 47` (code — `@Transactional` annotation)

## Rationale

"Partial writes — where the order is created but the payment record is not —
leave the system in an inconsistent state that cannot be automatically recovered."

## Semantic Properties

| Property | Meaning in this context |
|---|---|
| atomic | `@Transactional` on `createOrderWithPayment()` — both inserts commit together or both roll back. Removing the annotation silently allows partial writes. |

## Dependencies

None

## Flags

None

---
*Extracted from: PaymentService.md — 2026-02-22*
```

---

## Seam Constraint Note

Created at: `claims/seam-{slug}.md`

A seam constraint governs the **relationship between entity classes from two different domains**.
It is owned by neither domain. It is the first thing that breaks under independent domain evolution.

```markdown
---
id: {SC###}
tags:
  - claims/seam
  - system/{system}
  - domain/{domain-a}
  - domain/{domain-b}
type: seam
modal: {MUST|MUST NOT}
domain_a: {DomainName}
domain_b: {DomainName}
system: {system}
source: "[[claims/{system}-claims-index]]"
added: {YYYY-MM-DD}
---

# {Title}

> **{Single normalized statement governing the relationship between two entity classes
> from different domains.}**

## Domains

**{DomainA}** → **{DomainB}**

{Brief statement of which entity class from each domain is involved
and the direction of the dependency.}

## Sources

- `{precise source pointer}` ({spec|code})

## Rationale

{Why this cross-domain relationship exists and what breaks if the contract is violated.}

## Domain Invariants At Risk

- **{DomainA}**: {which domain invariant this seam constraint must not violate}
- **{DomainB}**: {which domain invariant this seam constraint must not violate}

## Dependencies

{Wikilinks to the domain nodes on each side, or "None"}

---
*Extracted from: {source title} — {YYYY-MM-DD}*
```

**Real example:**

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

# Order Must Reference Valid Payment Method

> **An Order MUST reference a PaymentMethod that satisfies all Payment domain invariants
> at the time of order creation.**

## Domains

**Order** → **Payment**

An Order entity class holds a reference to a PaymentMethod entity class.
The dependency is unidirectional — Order depends on Payment, not the reverse.

## Sources

- `§4.2 ¶1 s2` (spec)

## Rationale

"Orders created against an invalid or expired payment method will fail at
charge time, leaving the order in an unrecoverable PENDING state."

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

## Top-Level Invariant Note

Created at: `claims/tli-{slug}.md`

A top-level invariant is a **system contract composed bottom-up from a cluster of nodes**.
It is the claim you would put in an SLA, an acceptance criterion, or an architecture decision record.

```markdown
---
id: {TLI-###}
tags:
  - claims/tli
  - system/{system}
  - domain/{domain}
type: tli
domain: {DomainName}
system: {system}
composed_from: [{N###}, {N###}, {SC###}]
source: "[[claims/{system}-claims-index]]"
added: {YYYY-MM-DD}
---

# {Title}

> **{Single system-level contract statement. This is what the system commits to,
> not what a single node asserts.}**

## Domain

**{Domain}** — {which part of the system this contract covers}

## Composed From

| Node | Statement |
|------|-----------|
| [[claims/node-{slug}]] (N###) | {statement} |
| [[claims/node-{slug}]] (N###) | {statement} |
| [[claims/seam-{slug}]] (SC###) | {statement} |

## What This Guarantees

{1-3 sentences: the observable system behavior this invariant commits to.
Written for a PM, manager, or architect — not just an engineer.}

## What Would Break It

{The minimum combination of node violations that would cause this
top-level invariant to fail. Name the entities and the sequence.}

---
*Composed from: {source title} — {YYYY-MM-DD}*
```

**Real example:**

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
composed_from: [N001, N004, N007]
source: "[[claims/payment-service-claims-index]]"
added: 2026-02-22
---

# Payment Domain Guarantees Valid Non-Expired Transaction Instruments

> **The Payment domain guarantees that all transactions reference
> valid, non-expired payment methods, established atomically at create time,
> and are safe to retry without side effects.**

## Domain

**Payment** — covers the full transaction lifecycle from method validation through persistence.

## Composed From

| Node | Statement |
|------|-----------|
| [[claims/node-payment-method-not-expired]] (N001) | A payment method MUST NOT be expired. |
| [[claims/node-transaction-atomic]] (N004) | A transaction MUST be atomic. |
| [[claims/node-retry-idempotent]] (N007) | A retry operation MUST be idempotent. |

## What This Guarantees

Any caller of the Payment domain can assume that a successfully created transaction
involved a validated, non-expired payment method, was committed atomically,
and can be safely retried on network failure without risk of double-charge.

## What Would Break It

Violating any one of N001, N004, or N007 breaks this contract:
an expired method slipping through validation, a partial write leaving
order and payment out of sync, or a non-idempotent retry causing duplicate charges.

---
*Composed from: PaymentService.md — 2026-02-22*
```

---

## Multi-Source Accumulation

When the same node appears in multiple specs, new context is appended without overwriting the original.

```markdown
---
id: N001
tags:
  - claims/invariant
  - system/payment-service
  - system/checkout-api
  - domain/Payment
type: invariant
modal: MUST NOT
entity_domain: Payment
semantic_flags: []
system:
  - payment-service      ← original
  - checkout-api         ← added on merge
sources:
  - "[[claims/payment-service-claims-index]]"
  - "[[claims/checkout-api-claims-index]]"
added: 2026-01-10
updated: 2026-02-22
---

# Payment Method Must Not Be Expired

> **A payment method MUST NOT be expired.**

{Original rationale, sources, semantic properties, and dependencies from payment-service}

## Additional Context (checkout-api, 2026-02-22)

In the checkout API, expiry is validated at two points: on payment method
selection (UX gate) and again at charge time (enforcement gate). The spec
explicitly states the charge-time check is the authoritative one — the UX
gate may be bypassed by direct API callers.

- `§2.4 ¶3 s1` (spec — checkout-api)
- `CheckoutController.charge() / line 112` (code — explicit expiry guard before gateway call)

*Source: checkout-api spec*

## Dependencies

None

---
*Sources: PaymentService.md (2026-01-10), checkout-api spec (2026-02-22)*
```

### Accumulation Rules

- Convert `system: "single-value"` to `system: [array]` when a second system is added
- Convert `source:` to `sources:` array — keep all backlinks
- Add `updated:` to frontmatter
- Append `## Additional Context ({system}, {YYYY-MM-DD})` before the final footer — never overwrite
- If the new source **contradicts** the existing statement → do NOT merge → flag as `CONFLICT` → stop

---

## Conflict Record

When a new node contradicts an existing one, the file is NOT written.
A conflict entry is appended to the index of the newer source:

```markdown
## Unresolved Conflicts

### ⚡ N-NEW-007 vs [[claims/node-payment-method-validity]]

| | Statement |
|---|---|
| **Existing** (`node-payment-method-validity.md`) | "A payment method MUST be validated on every order." |
| **New** (`checkout-api spec`) | "A payment method MUST be validated on create only." |

**Action required:** Validation timing is a security and performance boundary decision.
Validated on every order = defense in depth but higher latency.
Validated on create only = trusts that method state does not change.
Confirm with the payments team; update the winning node's statement and re-run.
```

---

## Example: Complete Extraction

**Input:** `PaymentService.md --system payment-service`

**Creates:**

1. `claims/payment-service-claims-index.md` (index)
2. `claims/node-payment-method-not-expired.md` (invariant, Payment)
3. `claims/node-order-requires-valid-payment.md` (invariant, Order)
4. `claims/node-order-requires-auth-user.md` (invariant, Order)
5. `claims/node-transaction-atomic.md` (invariant, Payment — semantic flag: atomic)
6. `claims/node-refund-references-transaction.md` (invariant, Payment)
7. `claims/node-session-single-identity.md` (constraint, Identity)
8. `claims/node-retry-idempotent.md` (invariant, Payment — semantic flag: idempotent)
9. `claims/node-acknowledgment-precedes-fulfill.md` (invariant, Order — semantic flag: ordered)
10. `claims/seam-order-payment-method-ref.md` (seam, Order ↔ Payment)
11. `claims/tli-payment-valid-instruments.md` (top-level invariant, Payment)

**Merges into:**

12. `claims/node-session-single-identity.md` — adds Blitz PublicData session context from prior run

**Flags (not written):**

13. `node-validation-limit-override.md` — MODAL_UNRESOLVED: "can override" is MUST or MAY?
14. `node-validation-limit-override.md` — UNDEFINED_TERM: "validation limit" undefined in spec

**Conflicts (not written):**

15. `node-payment-method-validity.md` — CONFLICT: validated on every order vs validated on create only
