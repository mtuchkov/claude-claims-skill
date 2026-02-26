---
name: claims
description: "Build a constraint graph from a spec or codebase: extract, normalize, derive, scope, deduplicate, type, conflict-check, and compose constraints into top-level invariants. No implied constraints; only explicit semantics from the source."
argument-hint: "[file-or-url] [--system <n>] [--dry-run]"
allowed-tools:
  - Read
  - Write
  - Bash
  - WebFetch
  - mcp__qmd__vsearch
  - mcp__qmd__get
---

# Constraint Graph Skill

When invoked with `/claims`, follow these phases EXACTLY and in order.
Do not skip phases.
Every node and edge must be traceable to a literal token in the spec or code.

---

## Step 1: Parse Arguments

```
/claims <file-or-url> [--system <n>] [--dry-run]
```

- `file-or-url`: Required. Path to spec file, code file, or URL.
- `--system <n>`: Logical system name (e.g., "payment-service"). Defaults to filename stem.
- `--dry-run`: Preview extracted nodes; do not write files.

Set variables:
- `SYSTEM` = value of `--system`, or filename stem
- `FOLDER`  = "claims"

---

## Step 2: Get Vault Path

```bash
cat ~/.config/claude-note/config.toml 2>/dev/null
```

Extract `vault_root`. Set `OUTPUT_DIR` = `{vault_root}/claims/`.

If no config, ask: "Where should I create constraint graph files? (e.g., ~/Documents/notes)"

---

## Step 3: Read Source Content

Set `TITLE` from `--system` or filename.

**For local files:**
- `.md` or `.txt`: Use Read tool directly
- `.pdf`: Run `pdftotext "{file}" - 2>/dev/null || pandoc "{file}" -t plain`
- `.docx`: Run `pandoc "{file}" -t plain --wrap=none`
- `.java`, `.ts`, `.py`, or any code file: Read directly; treat structure as normative

**For URLs:** Use WebFetch to get the content.

Store in `CONTENT`. If longer than 100,000 characters, truncate and append `\n\n[... content truncated ...]`

---

## Step 4: Apply Controlled Vocabulary

Before extraction, internalize the full controlled vocabulary.
Every word in a normalized statement MUST map to one of the tiers below,
or be a domain term preserved verbatim from the source.

### Tier 1 — Modal Operators (RFC 2119)

| Token | Meaning |
|---|---|
| MUST | Absolute requirement, no exceptions |
| MUST NOT | Absolute prohibition |
| SHOULD | Strong recommendation, exceptions acknowledged |
| SHOULD NOT | Strong discouragement |
| MAY | Permitted but not required |

### Tier 2 — Relationship Verbs

| Token | Meaning |
|---|---|
| requires | A cannot exist or execute without B |
| produces | A creates or emits B |
| consumes | A takes B as input and transforms it |
| contains | A holds B as a member |
| references | A points to B without ownership |
| extends | A inherits all constraints of B and adds more |
| excludes | A and B cannot coexist in the same scope |
| precedes | A must complete before B begins |
| triggers | A causes B to initiate |
| satisfies | A fulfills the condition stated by B |
| violates | A breaks the condition stated by B |

### Tier 3 — Verification Verbs

| Token | Meaning |
|---|---|
| holds | A condition is true at a given point in time |
| preserves | An operation leaves a condition unchanged |
| establishes | An operation makes a condition true for the first time |
| invalidates | An operation makes a previously true condition false |
| guarantees | A component commits to a condition unconditionally |
| assumes | A component requires a condition without verifying it |
| asserts | A component checks a condition and halts if false |
| implies | If A holds, B must also hold |
| is invariant under | A condition holds regardless of which operation is applied |

### Tier 4 — Distributed Systems Verbs

| Token | Meaning |
|---|---|
| propagates | A change flows from one node to others |
| converges | A system reaches a consistent state over time |
| replicates | A copy of B is maintained at another location |
| partitions | A group splits into subgroups that cannot communicate |
| coordinates | Multiple parties synchronize to reach a shared decision |
| acknowledges | A receiver confirms receipt to the sender |
| retries | An operation is repeated after a failure |
| times out | An operation is abandoned after a bounded wait |
| linearizes | Operations appear to execute in a single global order |
| serializes | Operations are forced into a strict sequential order |

### Tier 5 — Collection and Structure Nouns

| Token | Meaning |
|---|---|
| set | Unordered collection, no duplicates |
| multiset | Unordered collection, duplicates allowed |
| sequence | Ordered collection, duplicates allowed |
| queue | Ordered collection, FIFO access |
| map | Key-value pairs, unique keys |
| graph | Nodes connected by edges |
| tree | Acyclic graph with a single root |
| stream | Unbounded sequence arriving over time |
| partition | Non-overlapping subsets covering the full set |
| quorum | A subset sufficient to make a decision |
| epoch | A bounded period with a consistent configuration |
| snapshot | A consistent point-in-time capture of state |
| replica | A copy maintained for availability or locality |
| shard | A horizontal subset of a dataset |
| boundary | The limit defining where a constraint applies |

### Tier 6 — Adjectives

| Token | Meaning |
|---|---|
| bounded | Has a finite, defined upper limit |
| unbounded | Has no defined upper limit |
| atomic | Executes as a single indivisible unit |
| idempotent | Applying N times produces the same result as applying once |
| deterministic | Same input always produces same output |
| monotonic | Value only moves in one direction over time |
| consistent | All observers see the same state at the same logical time |
| eventual | A property holds after an unspecified but finite time |
| strict | No exceptions permitted |
| partial | Applies to a subset, not the whole |
| total | Applies to every member of the set |
| exclusive | Only one member may hold this at a time |
| shared | Multiple members may hold this simultaneously |
| durable | Survives failures and restarts |
| volatile | Lost on failure or restart |
| ordered | Elements have a defined sequence |
| unordered | Elements have no defined sequence |

### Tier 7 — Adverbs

**Temporal:**
| Token | Meaning |
|---|---|
| immediately | Before any other operation in the same scope |
| eventually | After an unspecified but finite number of steps |
| never | Under no circumstances, at no point in time |
| always | At every point in time, without exception |
| once | Exactly one time across the lifetime of the system |
| initially | At system or component startup only |
| finally | At the last step of a sequence or lifecycle |
| concurrently | Simultaneously with another operation |
| sequentially | Strictly one after another, no overlap |

**Frequency:**
| Token | Meaning |
|---|---|
| exactly N times | Neither more nor less than N occurrences |
| at most N times | Upper bound, zero is permitted |
| at least N times | Lower bound, no upper bound unless stated |
| periodically | At regular bounded intervals |
| on demand | Only when explicitly triggered |

**Degree:**
| Token | Meaning |
|---|---|
| strictly | No relaxation permitted under any condition |
| partially | Applies to a defined subset |
| globally | Across all nodes, partitions, or scopes |
| locally | Within a single node, partition, or scope only |
| transitively | Applies through the full chain of references |
| directly | Applies only to the immediate relationship |

**Certainty:**
| Token | Meaning |
|---|---|
| necessarily | Cannot be otherwise given the premises |
| possibly | Permitted but not guaranteed |
| conditionally | True only when a stated predicate holds |
| unconditionally | True regardless of any other state |

**Banned adverbs — reject at normalization gate:**

| Banned | Replace With |
|---|---|
| quickly | within N milliseconds |
| soon | eventually / within N seconds |
| usually | at least N% of the time |
| often | at least N times per period |
| rarely | at most N times per period |
| typically | SHOULD / conditionally |

### Tier 8 — Generalization and Domain Nouns

**Entities:**
| Token | Meaning |
|---|---|
| entity | A distinct object with a unique, persistent identity |
| aggregate | A cluster of entities treated as a single unit with one root |
| value object | An immutable descriptor with no independent identity |
| reference | A pointer to an entity without ownership |
| identifier | A value that uniquely distinguishes one entity from all others |
| version | A labeled snapshot of an entity at a point in time |
| lifecycle | The bounded set of states an entity may pass through |
| owner | The entity that holds exclusive write authority over another |

**Messages:**
| Token | Meaning |
|---|---|
| message | A discrete unit of communication between two parties |
| command | A message that requests a state change |
| event | A message that records a state change that already occurred |
| query | A message that requests information without side effects |
| request | A message expecting a response |
| response | A message sent in reply to a request |
| notification | A one-way message expecting no reply |
| acknowledgment | A message confirming receipt or processing |
| signal | A lightweight message carrying intent but no payload |
| payload | The data carried inside a message |
| envelope | The metadata wrapping a payload |
| correlation identifier | A value linking a request to its response across time |

**Data Contracts:**
| Token | Meaning |
|---|---|
| schema | A formal definition of the structure of a data artifact |
| contract | A mutual agreement on shape, behavior, and obligations |
| invariant | A condition that MUST hold at all times within a defined scope |
| precondition | A condition that MUST hold before an operation executes |
| postcondition | A condition that MUST hold after an operation completes |
| constraint | A restriction on valid states or transitions |
| assertion | A condition checked at runtime that halts if violated |
| guarantee | A condition a producer commits to unconditionally |
| assumption | A condition a consumer depends on without verifying |
| obligation | A condition one party MUST fulfill toward another |
| violation | A state in which a constraint no longer holds |
| compatibility | The degree to which one version of a contract satisfies another |

**Interfaces:**
| Token | Meaning |
|---|---|
| interface | A named boundary defining what operations a component exposes |
| operation | A named action exposed through an interface |
| endpoint | A network-addressable location where an interface is reachable |
| protocol | A defined sequence of message exchanges between two parties |
| handshake | A bounded protocol establishing shared parameters |
| channel | A medium through which messages flow |
| port | A typed interaction point on a component |
| adapter | A component that translates between two incompatible interfaces |
| facade | An interface that simplifies access to a complex subsystem |
| gateway | A boundary component mediating access between two scopes |
| proxy | A component that forwards operations on behalf of a caller |
| stub | A test double satisfying an interface without real behavior |

**Domain:**
| Token | Meaning |
|---|---|
| domain | A named set of entity classes and the invariants that govern them, independent of time, space, or flow |
| subdomain | A cohesive subset of a domain, fully contained within the parent |
| core domain | The domain representing the primary competitive differentiator |
| supporting domain | A domain that enables the core domain without competitive value |
| generic domain | A domain whose behavior is commodity and MAY be replaced off-the-shelf |
| entity class | The definition of a type of entity: its identity, attributes, and lifecycle |
| domain invariant | A condition that MUST hold for all instances of an entity class, always |
| domain owner | The single authority responsible for a domain's entity classes and invariants |
| seam constraint | A constraint governing the relationship between entity classes from two different domains, owned by neither |
| anti-corruption layer | A boundary component translating between two domain models |
| shared kernel | A subset of a domain model explicitly co-owned by two domains |
| conformist | A domain that adopts another domain's model without translation |
| domain event | An event recording a state change of an entity class |

**Scope and Boundary:**
| Token | Meaning |
|---|---|
| context | A scope within which a term has a single unambiguous meaning |
| seam | A point where two components meet and may be independently replaced |
| layer | A horizontal grouping of components at equivalent abstraction level |
| module | A named, self-contained unit of behavior and state |
| component | A deployable unit with a defined interface and lifecycle |
| service | A component that exposes behavior over a network boundary |
| consumer | A party that depends on an interface or contract |
| provider | A party that fulfills an interface or contract |

### Tier 9 — Boolean and Logical Operators

Used to compose compound constraint statements. Every compound statement using these operators
MUST be split into atomic sentences during normalization unless the operator itself
is the constraint (e.g., an exclusive-or cardinality rule that cannot be expressed atomically).

**Connectives:**
| Token | Logical Symbol | Meaning |
|---|---|---|
| and | ∧ | Both conditions must hold simultaneously |
| or | ∨ | At least one condition must hold; both may hold |
| exclusive or | ⊕ | Exactly one condition must hold; not both |
| not | ¬ | The condition must not hold |
| if … then | → | The first condition holding requires the second to hold |
| if and only if | ↔ | Both conditions hold or neither holds |
| implies | → | Synonym for if … then; use in derivation traces |
| unless | ¬A → B | If the first condition does not hold, the second must |

**Quantifiers:**
| Token | Logical Symbol | Meaning |
|---|---|---|
| for all | ∀ | The constraint applies to every member of the set |
| there exists | ∃ | At least one member of the set satisfies the condition |
| there exists exactly one | ∃! | Exactly one member satisfies the condition; no more, no fewer |
| there exists at most one | ∃≤1 | Zero or one member satisfies the condition |
| there exists at least one | ∃≥1 | One or more members satisfy the condition |

**Cardinality Constraints:**
| Token | Meaning |
|---|---|
| exactly N | Neither more nor fewer than N |
| at most N | Upper bound; zero is permitted |
| at least N | Lower bound; no upper bound unless stated |
| between N and M | Lower and upper bounds, both inclusive |
| zero or one | Optional but not repeatable |
| one or more | Required and repeatable |

**Truthiness and Completeness:**
| Token | Meaning |
|---|---|
| holds | The condition evaluates to true in the current state |
| does not hold | The condition evaluates to false in the current state |
| is satisfiable | There exists at least one state in which the condition holds |
| is unsatisfiable | No state exists in which the condition holds |
| is vacuously true | The condition holds because its antecedent never applies |
| is contradictory | The condition and its negation both hold — a conflict |
| is tautological | The condition holds in every possible state |

**Normalization rule for compound statements:**
When a source sentence contains AND, OR, or UNLESS connecting two distinct predicates,
split into two atomic nodes before proceeding.
Preserve the connective as an edge type between the resulting nodes:

```
Source: "A user MUST be authenticated and have an active membership."

N001: "A user MUST be authenticated."           [AuthN]
N002: "A user MUST have an active membership."  [AuthZ]
Edge:  N001 AND N002  → D001 (conjunct precondition for downstream operation)
```

Exclusive-or cardinality constraints are the primary exception — they cannot be
split without losing the mutual exclusion semantic, so they are preserved as a
single node typed `exclusive or`.

---

## Step 5: Extract

Read `CONTENT` **start to end, statement by statement, no skipping**.
Selection bias here poisons everything downstream.

**Source pointer — required for every extracted statement.**
Capture the most precise locator available for the source type:

| Source Type | Required Pointer |
|---|---|
| Spec document | Section number + paragraph number + sentence position. Example: `§3.2 ¶4 s2` |
| Markdown / plain text | Heading path + line number. Example: `## Payment Rules > ### Validation / line 47` |
| Code — behavior statement | Class name + method name + line number. Example: `PaymentService.validate() / line 83` |
| Code — type or field declaration | Class name + field name + line number. Example: `Order.paymentMethod / line 12` |
| Code — annotation or decorator | Class name + annotation + line number. Example: `OrderController @Transactional / line 34` |
| URL / fetched content | URL + section anchor or paragraph index. Example: `https://… #validation ¶2` |

Prefer the nearest structural anchor (method name, heading, clause label) otherwise use line number.
A statement with no traceable source pointer MUST be flagged.
The pointer is permanent and survives every downstream phase unchanged.

For every sentence, classify:

| Source Type | Action |
|---|---|
| Formal assertion | Normalize → include |
| Code statement | Translate using code translation rules → normalize → include |
| Rationale prose | Mine for scope signals → annotate only, do not normalize |
| Example | Flag as `[CANDIDATE]` if it implies an undocumented constraint |
| Preamble / decorative | Discard |

**Code translation rules:**

Treat code as a normative spec written in a different language.
Translate its structure and behavior into normalized narrative statements.
The goal is to preserve the semantics that matter architecturally — not to describe
the implementation mechanically.

Apply the following translation patterns:

**Null and presence checks**
```java
if (user == null) throw new IllegalArgumentException();
```
→ "A user MUST be present before this operation executes."
⚠️ Scope this to the enclosing method or class — not globally.
A null-check at one call site is NOT a global non-null invariant.

**Ordering and precondition sequences**
```java
validate(order);
authorize(user);
persist(order);
```
→ "Validation MUST precede authorization."
→ "Authorization MUST precede persistence."
Each ordering relationship that is load-bearing becomes a separate node.
Ask: would swapping these two lines break correctness or security?
If yes → the ordering is a constraint. If no → it is an implementation detail, discard.

**Idempotency**
```java
if (order.getStatus() == SUBMITTED) return;
order.setStatus(SUBMITTED);
```
→ "The submit operation MUST be idempotent — applying it more than once
   MUST produce the same result as applying it once."
Flag the entity class and operation explicitly in the node.

**Immutability**
```java
private final PaymentMethod paymentMethod;
// no setter exposed
```
→ "A PaymentMethod MUST NOT be modified after assignment."
Immutability at field level → value object constraint.
Immutability at reference level → ownership constraint.
Distinguish the two.

**Atomicity and transactions**
```java
@Transactional
public void createOrder(Order order, Payment payment) { ... }
```
→ "Order creation and payment recording MUST be atomic —
   either both succeed or neither is persisted."

**State machine transitions**
```java
if (order.getStatus() != PENDING) throw new IllegalStateException();
order.setStatus(CONFIRMED);
```
→ "An order MUST be in PENDING state before it can transition to CONFIRMED."
Translate every guarded transition. Together they define the lifecycle — compose
them into a lifecycle node after individual nodes are established.

**Cardinality from collection types and constraints**
```java
Set<Role> roles;  // roles.size() enforced by addRole() to max 3
```
→ "A user MUST have at most 3 roles."
Collection type alone is not a constraint — enforce it only when the code
explicitly guards cardinality.

**Conditional branching as domain logic**
```java
if (user.isSuperAdmin()) {
    return repository.findAll();
} else {
    return repository.findByOrgId(user.getOrgId());
}
```
→ "A superadmin MAY query across all organizations."
→ "A non-superadmin user MUST query within their own organization only."
Each branch is a separate node. Do not collapse them.

**Error type selection**
```java
throw new NotFoundException();  // on unauthorized access
```
→ "The system MUST return a not-found response on unauthorized access
   to conceal entity existence from unauthorized callers."
The choice of error type encodes a deliberate behavioral or security decision.
Always extract it as an explicit constraint.

**Retry and timeout semantics**
```java
retryTemplate.execute(ctx -> paymentGateway.charge(request), MAX_RETRIES);
```
→ "Payment gateway calls MUST be retried at most N times on failure."
→ "Retry operations MUST be idempotent."
Extract both the bound and the idempotency requirement as separate nodes.

**What to discard:**
- Variable names, formatting, comments that do not alter behavior
- Internal helper method decomposition with no architectural significance
- Logging, metrics, and instrumentation calls
- Test setup and teardown code unless it reveals a contract

---

## Step 6: Normalize

Rewrite every extracted statement using the controlled vocabulary.

Rules:
1. Active voice only
2. Present tense only
3. One claim per sentence — split on AND, OR, UNLESS
4. Domain terms preserved verbatim
5. No abbreviations, symbols, or code syntax
6. Every banned adverb replaced or statement flagged

Capture the full context block at this step — it is ephemeral and unrecoverable later:

```
N{n}  SOURCE: {precise source pointer}
      STATEMENT:     "{normalized statement}"
      ENTITY DOMAIN: {domain name}
      RATIONALE:     "{rationale prose, verbatim, for human reference only}"
      SEMANTIC FLAGS: [idempotent] [atomic] [immutable] [ordered] [bounded] — 
                      only if the code translation step surfaced one of these properties
```

The `SEMANTIC FLAGS` field is populated exclusively from the code translation phase.
It carries properties that the normalized narrative statement alone cannot fully express,
ensuring they survive into typing and composition without being lost in plain language.

**Entity domain assignment rule:**
Assign to the domain of the entity class the statement *governs*.
Not the flow it appears in. Not the section. Not the actor. Not the phase.

If the statement governs a relationship between two entity classes from different domains,
mark it `SEAM CONSTRAINT` and assign to neither domain.

If the domain is ambiguous, flag `[DOMAIN UNRESOLVED]` — do not guess.

---

## Step 7: Negative to Positive

Convert every prohibitive or exclusive statement to affirmative precondition form:

```
"No order without payment"           → "An order MUST require payment."
"Unless authenticated, deny access"  → "Access MUST require authentication."
"Orders lacking auth are rejected"   → "An order MUST require an authenticated user."
```

**Exception:** A statement that would lose its exclusion semantics when flipped stays as `MUST NOT`.
Test: if flipping changes what the system *does*, preserve as `MUST NOT`.

---

## Step 8: Derive

Apply only the logical connectives the spec itself uses — AND, OR, IF-THEN, UNLESS.
No creative inference. No implied constraints.

**First-order derivation:**
Combine premises directly stated together. Each derivative carries a justification trace.

```
D{n} ← {N1, N3}
      STATEMENT: "{derived statement}"
      DOMAIN:    {domain}
      TRACE:     "N1 AND N3 stated together in §2.1"
```

**Recurse downward:**
For each node, ask: does this statement reference a term defined or constrained elsewhere in the spec?
- YES → decompose into sub-nodes
- NO  → leaf node. Stop. Tag `[UNDEFINED TERM]` if the term is undefined anywhere in the spec.

**Recurse upward:**
Once bottom is capped, walk up and ask: what higher-level claim does this cluster assert?
That claim becomes a candidate top-level invariant (TLI).

Circular references are real and meaningful — flag as `[CIRCULAR DEPENDENCY]`, do not break them.

---

## Step 8a: Extract Implicit Claims

After deriving explicit first-order nodes, make a dedicated pass over `CONTENT` to surface
**implicit claims** — conditions the spec or code assumes but never states.

Look for:
- Guard clauses whose precondition is never documented in the spec
- Error types selected for behavioral reasons that are never spelled out (security, UX, conceal)
- Data shapes accessed or mutated without a declared schema or ownership rule
- Annotations/decorators whose behavioral contract is applied but not defined
- Examples that presuppose a rule for which no explicit node exists
- Retry or timeout sites where the required idempotency/bound is implied but unwritten
- Cross-service calls where the caller assumes a contract the provider never published

For each implicit claim found:

```
I{n}  ORIGIN:    {precise source pointer where the assumption surfaces}
      STATEMENT: "{what must be true for the code or spec to be valid}"
      DOMAIN:    {domain of the entity class being assumed about}
      FLAGS:     [IMPLICIT] [REQUIRES_ATTENTION]
      CONFIRMED: false
```

Add each to `EXTRACTION.implicit_claims`.

**Inviolable:** An implicit claim MUST NOT be merged into, treated as, or used to derive
explicit nodes until a spec owner confirms it. Confirmed: false means no downstream effect.

---

## Step 8b: Capture TIL

Identify architectural observations that emerge from reading the source — non-obvious patterns,
surprising design decisions, or relationships that are not constraints themselves but are worth
preserving for the team.

Capture only what was genuinely discovered by reading this source. Do not restate explicit nodes.

For each TIL:

```
TIL-{n}  DOMAIN:      {domain most relevant to the observation}
         STATEMENT:   "{one-sentence crisp claim — the distilled insight}"
         OBSERVATION: "{1-3 sentences expanding on the statement — context, consequence, or evidence}"
         ORIGIN:      {source location where it was noticed}
         NODES:       {node IDs this relates to, if any}
```

Add each to `EXTRACTION.til`.

---

## Step 9: Scope

Confirm or reject domain assignments. All nodes must carry a domain before dedup.

```
1. List all entity classes and domains identified in the spec.
2. For each node: confirm domain assignment or resolve [DOMAIN UNRESOLVED] flags.
3. Identify all SEAM CONSTRAINTs — track in separate artifact.
4. Flag any statement spanning more than two domains as [MULTI-DOMAIN CONSTRAINT].
```

Seam constraints are tracked separately. They are the first thing that breaks
under independent domain evolution.

---

## Step 10: Deduplicate

Two nodes are candidates for merging **only if predicate AND entity domain are identical**.

Three passes in order:

**Pass 1 — Syntactic:** identical normalized form → merge, union all source citations.

**Pass 2 — Semantic:** same predicate, aliased terms per spec glossary → merge.
  - Aliasing MUST be supported by a definition in the spec itself.
  - Suspected aliases without spec evidence → flag `[SUSPECTED DUPLICATE]`, do not merge.

**Pass 3 — Domain guard:** identical predicate, different domain → NOT duplicates. Preserve both.

Merged nodes carry ALL source citations. Original statements are never deleted.

---

## Step 11: Type

Assign exactly one modal to every node:

| Type | Modal | Meaning |
|---|---|---|
| `invariant` | MUST | Holds at all times, no exceptions |
| `exclusion` | MUST NOT | Hard prohibition |
| `soft` | SHOULD | Strong preference, exceptions acknowledged |
| `conditional` | MUST (when X) | Holds only when a stated predicate is true |
| `permission` | MAY | Permitted but not required |

**3-letter type codes** — used in file names:

| Code | Type |
|------|------|
| `inv` | invariant |
| `exc` | exclusion |
| `sft` | soft |
| `cnd` | conditional |
| `prm` | permission |
| `sea` | seam |
| `der` | derived |
| `tli` | top-level invariant |
| `imp` | implicit |
| `til` | TIL |

If the source is ambiguous between MUST and SHOULD, flag `[MODAL UNRESOLVED]` for spec owner.
Do not resolve by assumption.

---

## Step 12: Conflict Check

**Intra-domain conflicts:**
Same entity class, mutually exclusive predicates → `ERROR`.
Must be resolved before the graph is trusted.

**Seam constraint conflicts:**
A seam constraint that contradicts a domain invariant on either side → `INTEGRATION RISK`.
Flag separately. Never auto-resolve.

**Phantom conflicts:**
Apparent contradictions between nodes that are actually undetected duplicates.
Resolve by re-running dedup pass before escalating to spec owner.

All conflicts are visible artifacts with full citation trails. None are auto-resolved.

---

## Step 13: Compose

Walk bottom-up. Cluster nodes whose combined meaning asserts a higher-level claim.
That claim becomes a **top-level invariant (TLI)**.

```
TLI-{n}
  STATEMENT: "{system-level contract}"
  DOMAIN:    {domain}
  NODES:     {N3, N7, D2}
  TYPE:      invariant | guarantee | constraint
```

TLIs are your system contracts — acceptance criteria, SLA commitments, architecture decisions.
Every TLI must be traceable down to its constituent normalized statements and source locations.

---

## Step 14: Build JSON Output

Produce this structure:

```json
{
  "system": "<system name>",
  "spec_summary": "2-3 sentences: what this spec defines and its scope.",
  "vocabulary_violations": [
    {
      "location": "§2.1, line 4",
      "original": "the system should respond quickly",
      "violation": "banned adverb: quickly",
      "action": "FLAGGED — replace with bounded time expression"
    }
  ],
  "nodes": [
    {
      "id": "N001",
      "slug": "kebab-case-max-50-chars",
      "title": "Human-readable label",
      "statement": "Single normalized declarative sentence.",
      "type": "invariant|exclusion|soft|conditional|permission",
      "modal": "MUST|MUST NOT|SHOULD|MAY",
      "entity_domain": "DomainName",
      "seam_constraint": false,
      "sources": [
        {
          "pointer": "§2.1 ¶3 s1",
          "type": "spec"
        },
        {
          "pointer": "PaymentService.validate() / line 83",
          "type": "code"
        }
      ],
      "semantic_flags": ["idempotent", "atomic"],
      "rationale": "Verbatim rationale prose from spec, for reference only.",
      "derived": false,
      "trace": null,
      "depends_on": ["N003"],
      "flags": []
    }
  ],
  "seam_constraints": [
    {
      "id": "SC001",
      "statement": "...",
      "domain_a": "Order",
      "domain_b": "Payment",
      "sources": ["§4.2 line 7"]
    }
  ],
  "top_level_invariants": [
    {
      "id": "TLI-001",
      "statement": "...",
      "domain": "Payment",
      "composed_from": ["N003", "N007", "D002"],
      "type": "invariant"
    }
  ],
  "flags": [
    {
      "id": "FLAG-001",
      "type": "UNDEFINED_TERM|DOMAIN_UNRESOLVED|MODAL_UNRESOLVED|SUSPECTED_DUPLICATE|CIRCULAR_DEPENDENCY|CONFLICT|CANDIDATE",
      "node": "N007",
      "description": "Term 'trial period' is undefined in spec.",
      "action_required": "Spec owner must define or clarify."
    }
  ],
  "conflicts": [
    {
      "id": "CONFLICT-001",
      "type": "intra-domain|seam",
      "nodes": ["N003", "N011"],
      "description": "N003 and N011 assert mutually exclusive predicates for PaymentMethod.",
      "status": "UNRESOLVED"
    }
  ],
  "implicit_claims": [
    {
      "id": "I001",
      "statement": "Single normalized declarative sentence of the assumed condition.",
      "entity_domain": "DomainName",
      "origin": "PaymentService.retryTemplate / line 62",
      "confirmed": false,
      "flags": ["IMPLICIT", "REQUIRES_ATTENTION"]
    }
  ],
  "til": [
    {
      "id": "TIL-001",
      "domain": "Payment",
      "statement": "One-sentence crisp distilled insight.",
      "observation": "1-3 sentences expanding on the statement.",
      "origin": "PaymentService.createOrderWithPayment() / line 47",
      "nodes": ["N004", "N006"]
    }
  ]
}
```

**After building the structure, append every derived node from Step 8 into `EXTRACTION.nodes`**
with `"derived": true` and `"trace": "{N1} AND {N3} stated together in {source pointer}"`.
Derived nodes (D-prefix) flow through Steps 15–18 exactly like extracted nodes.
Without this step they will not be deduplicated or written as files.

---

## Step 15: Semantic Deduplication Against Vault

For each node in `EXTRACTION.nodes`:

### 15a. Build query
```
QUERY = "{node.title} {node.statement} {node.entity_domain}"
```

### 15b. Search existing nodes
```
mcp__qmd__vsearch(query: QUERY, limit: 3, minScore: 0.80)
```

### 15c. Classify

- **No match ≥ 0.80** → `CREATE_NEW`
- **Match ≥ 0.80, same domain** → read existing; compare:
  - Semantically equivalent → `SKIP`
  - New node strengthens or contradicts → `CONFLICT` (flag for human review)
  - New node adds scope, system, or assertion hint → `MERGE`
- **Match ≥ 0.80, different domain** → `CREATE_NEW` (domain distinction is load-bearing)

> ⚠️ Contradictions are first-class findings. If N-NEW contradicts an existing node,
> do NOT silently merge. Surface it in the report. Do NOT write the file.

---

## Step 16: Report Plan

```
Extracted {N} constraint nodes from "{TITLE}" ({SYSTEM}):

Domains identified:     {list}
Seam constraints:       {X}
Top-level invariants:   {Y}
Implicit claims:        {Z} ⚠️ REQUIRES_ATTENTION
TIL:                    {W} observations captured

CREATE    {A} new node files
MERGE     {B} existing node files
CONFLICT  {C} contradictions — HUMAN REVIEW REQUIRED
SKIP      {D} duplicates

Flags requiring spec owner action:
  [UNDEFINED_TERM]     {n} terms
  [DOMAIN_UNRESOLVED]  {n} nodes
  [MODAL_UNRESOLVED]   {n} nodes
  [CIRCULAR_DEP]       {n} cycles
  [IMPLICIT]           {n} unconfirmed implicit claims

Contradiction details:
  ⚡ N-NEW-008 vs {domain}-inv-payment-method-validity.md
     New:      "A PaymentMethod MUST be validated on every order."
     Existing: "A PaymentMethod MUST be validated on create only."
     → Resolve before ingesting.
```

**If `--dry-run`:** stop here. Do not write any files.

---

## Step 17: Create Source Index File

Create `{OUTPUT_DIR}/{SYSTEM}-idx.md`:

```markdown
---
tags:
  - claims/index
  - system/{SYSTEM}
created: {YYYY-MM-DD}
spec_file: "{original_filename}"
---

# Constraint Graph: {SYSTEM}

{spec_summary}

## Domain Map

| Domain | Entity Classes | Node Count |
|--------|---------------|------------|
| {domain} | {entity classes} | {n} |

## Node Registry

| ID    | Title   | Type      | Domain   | File                                          |
|-------|---------|-----------|----------|-----------------------------------------------|
| N001  | {title} | {type}    | {domain} | [[claims/{domain_lower}-{type3}-{name}]]      |

## Seam Constraints

| ID    | Statement | Domain A | Domain B | File                                            |
|-------|-----------|----------|----------|-------------------------------------------------|
| SC001 | {stmt}    | {a}      | {b}      | [[claims/{domain_a_lower}-sea-{name}]]          |

## Top-Level Invariants

| ID      | Statement | Domain | File                                          |
|---------|-----------|--------|-----------------------------------------------|
| TLI-001 | {stmt}    | {dom}  | [[claims/{domain_lower}-tli-{name}]]          |

## Implicit Claims

| ID   | Statement | Domain | Origin |
|------|-----------|--------|--------|
| I001 | {stmt}    | {dom}  | {where it was implied} |

> ⚠️ All implicit claims require spec owner confirmation before use.

## TIL

| ID      | Domain | Statement | File                                          |
|---------|--------|-----------|-----------------------------------------------|
| TIL-001 | {dom}  | {stmt}    | [[claims/{domain_lower}-til-{name}]]          |

## Dependency Graph

\```
N002 → N001
N004 → N001
N004 → SC001
\```

## Open Flags

| Flag ID  | Type              | Node | Description |
|----------|-------------------|------|-------------|
| FLAG-001 | UNDEFINED_TERM    | N007 | "trial period" undefined |

## Unresolved Conflicts

### ⚡ N-NEW-{n} vs [[claims/{domain_lower}-{type3}-{existing-name}]]

| | Statement |
|---|---|
| **Existing** | "{existing statement}" |
| **New** | "{new statement}" |

**Action required:** {what differs and what to decide}.

## Source

- **Spec:** `{original_filename}`
- **Extracted:** {YYYY-MM-DD}
```

---

## Step 18: Create New Node Files

For each `CREATE_NEW` node, create `{OUTPUT_DIR}/{entity_domain_lower}-{type3}-{name}.md`.

Use the 3-letter type code from the type code table.
For seam constraints use `{domain_a_lower}-sea-{name}.md`.
For derived nodes use `{entity_domain_lower}-der-{name}.md`.
For implicit claims use `{entity_domain_lower}-imp-{name}.md`.
For TIL files use `{domain_lower}-til-{name}.md`.

**Node / Derived node template:**

```markdown
---
id: {id}
tags:
  - claims/{type}
  - system/{SYSTEM}
  - domain/{entity_domain}
type: {type}
modal: {MUST|MUST NOT|SHOULD|MAY}
entity_domain: {domain}
system: {SYSTEM}
source: "[[claims/{SYSTEM}-idx]]"
seam_constraint: {true|false}
derived: {true|false}
trace: "{N1} AND {N3} stated together in {source pointer} | null if not derived"
added: {YYYY-MM-DD}
---

# {title}

> **{statement}**

## Domain

{entity_domain}
{if seam_constraint: "⚠️ Seam constraint between {domain_a} and {domain_b}."}

## Sources

{sources as list with section and line references}
{if derived: "Derived from: {trace}"}

## Rationale

{rationale verbatim from spec — for human reference, not part of the constraint}

## Dependencies

{depends_on as wikilinks, or "None"}

## Flags

{flags, or "None"}

---
*{if derived: "Derived from: {trace} — " else "Extracted from: "}{TITLE} — {YYYY-MM-DD}*
```

**Implicit claim template** (`{domain_lower}-imp-{name}.md`):

```markdown
---
id: {I###}
tags:
  - claims/implicit
  - system/{SYSTEM}
  - domain/{entity_domain}
type: implicit
entity_domain: {domain}
system: {SYSTEM}
source: "[[claims/{SYSTEM}-idx]]"
implicit: true
confirmed: false
attention_required: true
added: {YYYY-MM-DD}
---

# {title}

> **{statement}**

## Domain

{entity_domain}

## Origin

{precise source pointer where the assumption surfaces}

## Attention Required

{What must be confirmed. What breaks if this assumption is wrong.
Who needs to sign off — spec owner, domain team, or architect.}

## Related Nodes

{wikilinks to explicit nodes that depend on or relate to this assumption, or "None"}

---
*Implicit claim — unconfirmed. Extracted from: {TITLE} — {YYYY-MM-DD}*
```

**TIL template** (`{domain_lower}-til-{name}.md`):

```markdown
---
id: {TIL-###}
tags:
  - claims/til
  - system/{SYSTEM}
  - domain/{domain}
type: til
domain: {domain}
system: {SYSTEM}
source: "[[claims/{SYSTEM}-idx]]"
added: {YYYY-MM-DD}
---

# {title}

> **{statement}**

## Observation

{1-3 sentences expanding on the statement — context, consequence, or evidence from the source.}

## Origin

{precise source pointer where this was noticed}

## Related Nodes

{wikilinks to nodes this relates to, or "None"}

---
*TIL — Extracted from: {TITLE} — {YYYY-MM-DD}*
```

---

## Step 19: Merge Into Existing Node Files

For each `MERGE` node:

1. Read existing file.
2. Update frontmatter:
   - Add `updated: {YYYY-MM-DD}`
   - If `system:` is scalar, convert to array and append new system
   - If `source:` is scalar, rename to `sources:` array and append new index link
3. Append section before the final `---` footer:

```markdown
## Additional Context ({SYSTEM}, {YYYY-MM-DD})

{new rationale, scope extension, or additional source evidence}

*Source: {TITLE}*
```

4. Write file.

---

## Step 20: Final Report

```
=== Constraint Graph Complete ({SYSTEM}) ===

Index:                {SYSTEM}-idx.md
Domains:              {list}
Seam Constraints:     {X} (see index)
Top-Level Invariants: {Y}

Created:          {A} node files
Merged:           {B} node files
Conflicts:        {C} (see index — unresolved, files NOT written)
Skipped:          {D} duplicates
Implicit claims:  {E} files (⚠️ REQUIRES_ATTENTION — unconfirmed)
TIL:              {F} files

⚡ UNRESOLVED CONFLICTS — action required:
  {list each conflict with both statements}

🚩 OPEN FLAGS — spec owner action required:
  {list each flag with description}

⚠️ IMPLICIT CLAIMS — confirmation required:
  {I-ID} [{domain}] {statement}
    Origin: {source pointer}
    → {what needs to be confirmed}

💡 TIL:
  {TIL-ID} [{domain}] {statement}

📋 Full Node Registry:
────────────────────────────────────────
{ID} [{type}] [{domain}] {statement}
...
────────────────────────────────────────

📋 Top-Level Invariants:
────────────────────────────────────────
{TLI-ID} [{domain}] {statement}
  ← {node ids}
...
────────────────────────────────────────
```

---

## Inviolable Rules

These rules apply at every phase. Any output that violates them is incorrect.

```
1.  No node without a source citation.
2.  No edge without an explicit logical basis in the source.
3.  No inference beyond what the spec or code states.
4.  No assumption silently promoted to constraint.
5.  No gap auto-resolved — every unknown is a visible flag.
6.  No banned adverb survives normalization.
7.  No domain assignment by flow, section, or actor — only by entity class.
8.  No dedup across different entity domains.
9.  No conflict auto-resolved — conflicts are artifacts, not obstacles.
10. No implied constraint — only explicit semantics from the source.
11. No implicit claim promoted to a node or used in derivation until confirmed: true
    is set by a spec owner. confirmed: false means zero downstream effect.
```

---

## Fallback: No qmd Available

If `mcp__qmd__vsearch` is not available:

1. Fall back to filename matching:
   ```bash
   ls {OUTPUT_DIR}/ 2>/dev/null | grep -i "{keywords from node title or domain}"
   ```
2. If similar filename found, read it and do manual comparison.
3. Otherwise, create new file.

---

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

Extracting and normalizing statements...

Identified domains: Payment, Order, Identity

Extracted 11 constraint nodes:

 1. payment-method-requires-non-expired      (inv)   [Payment]
 2. order-requires-valid-payment-method      (inv)   [Order]
 3. order-requires-authenticated-user        (inv)   [Order]
 4. transaction-must-be-atomic               (inv)   [Payment]
 5. refund-references-existing-transaction   (inv)   [Payment]
 6. session-scoped-to-one-identity           (inv)   [Identity]
 7. payment-method-validated-on-create       (cnd)   [Payment]
 8. order-payment-method-seam                (sea)   [Order ↔ Payment]
 9. admin-may-override-validation-limit      (prm)   [Payment]
10. acknowledgment-must-precede-fulfillment  (inv)   [Order]
11. retry-must-be-idempotent                 (inv)   [Payment]

Extracting implicit claims...
  I001 [IMPLICIT] [Payment] — PaymentGateway.charge() has no documented timeout bound;
       the retry site assumes one exists but the spec never states it.
       Origin: PaymentService.retryTemplate / line 62
  I002 [IMPLICIT] [Order]   — OrderService.fulfill() assumes ACKNOWLEDGED status is always
       set by a prior caller; no contract documents which component is responsible.
       Origin: OrderService.fulfill() / line 91
  2 implicit claims flagged — REQUIRES_ATTENTION

Capturing TIL...
  TIL-001 [Payment] — Atomicity and idempotency form a complementary write-lifecycle pair.
          N004 prevents partial writes on first attempt; N011 prevents double-writes on retry.
          Neither alone is sufficient. Origin: §3.1 + §3.2

Flags:
  [UNDEFINED_TERM]     N009 — "validation limit" undefined in spec
  [MODAL_UNRESOLVED]   N009 — MAY vs SHOULD ambiguous in source

Checking for semantic duplicates...
  ✓ payment-method-requires-non-expired   → no similar nodes
  ✓ order-requires-valid-payment-method   → found: order-inv-order-payment-check.md (0.84)
    → Same predicate, same domain
    → New source adds §4.2 reference
    → Will merge
  ✗ payment-method-validated-on-create    → found: payment-inv-payment-method-validity.md (0.91)
    → CONFLICT: existing says "validated on every order"
                new spec says "validated on create only"
    → Flagged — file NOT written

Top-Level Invariants composed:
  TLI-001 [Payment]  "The Payment domain guarantees all transactions reference
                      valid, non-expired payment methods established at create time."
           ← N001, N004, N007

Creating files...

=== Constraint Graph Complete (payment-service) ===

Index:                payment-service-idx.md
Domains:              Payment, Order, Identity
Seam Constraints:     1
Top-Level Invariants: 1

Created:          9 node files
Merged:           1 node file
Conflicts:        1 (see index — unresolved, file NOT written)
Skipped:          0
Implicit claims:  2 files (⚠️ REQUIRES_ATTENTION)
TIL:              1 file

⚡ UNRESOLVED CONFLICTS — action required:
  payment-inv-payment-method-validity.md vs N007
    Existing: "A PaymentMethod MUST be validated on every order."
    New spec:  "A PaymentMethod MUST be validated on create only."
    → Validation timing is a security and performance boundary decision.
      Confirm with the payments team before proceeding.

🚩 OPEN FLAGS — spec owner action required:
  FLAG-001 [UNDEFINED_TERM]    N009 — "validation limit" has no definition in spec
  FLAG-002 [MODAL_UNRESOLVED]  N009 — source says "can override"; MUST or MAY?

⚠️ IMPLICIT CLAIMS — confirmation required:
  I001 [Payment] A payment gateway timeout bound MUST exist for retry logic to be valid.
    Origin: PaymentService.retryTemplate / line 62
    → Spec owner must state the bound or confirm it is delegated to the gateway contract.
  I002 [Order] A caller MUST set order status to ACKNOWLEDGED before invoking fulfill().
    Origin: OrderService.fulfill() / line 91
    → Confirm which component owns the ACKNOWLEDGED transition and document it.

💡 TIL:
  TIL-001 [Payment] Atomicity (N004) and idempotency (N011) form a complementary
                    write-lifecycle pair — neither alone is sufficient.

📋 Full Node Registry:
────────────────────────────────────────
N001 [inv]    [Payment]  A payment method MUST NOT be expired.
N002 [inv]    [Order]    An order MUST require a valid payment method.
N003 [inv]    [Order]    An order MUST require an authenticated user.
N004 [inv]    [Payment]  A transaction MUST be atomic.
N005 [inv]    [Payment]  A refund MUST reference an existing transaction.
N006 [inv]    [Identity] A session MUST be scoped to exactly one identity at a time.
N008 [sea]    [Order↔Payment] An order MUST reference a payment method that satisfies Payment domain invariants.
N010 [inv]    [Order]    An acknowledgment MUST precede order fulfillment.
N011 [inv]    [Payment]  A retry operation MUST be idempotent.
────────────────────────────────────────

📋 Top-Level Invariants:
────────────────────────────────────────
TLI-001 [Payment] "The Payment domain guarantees all transactions reference
                   valid, non-expired payment methods established at create time."
  ← N001, N004, N007
────────────────────────────────────────
```
