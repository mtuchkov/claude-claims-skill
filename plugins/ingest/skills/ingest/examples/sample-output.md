# Sample Ingest Output

This shows what the `/ingest` skill creates when processing a document.

## Example Session

**User input:**
```
/ingest ~/Downloads/attention-is-all-you-need.pdf
```

**Output:**
```
Reading config... vault at ~/Documents/notes

Extracting text from PDF...
Document: 15 pages, ~12,000 words

Analyzing and extracting concepts...

Extracted 6 concepts from "Attention Is All You Need":

1. self-attention (technique)
2. multi-head-attention (technique)
3. positional-encoding (technique)
4. transformer-architecture (finding)
5. scaled-dot-product-attention (technique)
6. training-efficiency (benchmark)

Checking for semantic duplicates...
  ✓ self-attention → no similar notes
  ✓ multi-head-attention → no similar notes
  ✓ positional-encoding → found: lit-position-embeddings.md (0.78)
    → New info: sinusoidal functions vs learned embeddings
    → Will merge
  ✓ transformer-architecture → no similar notes
  ✓ scaled-dot-product-attention → no similar notes
  ✓ training-efficiency → found: lit-training-speed.md (0.81)
    → No new info (already covers GPU training time)
    → Skipping

Creating notes...

Created source note:
  literature/lit-attention-is-all-you-need.md

Created 4 concept notes:
  ✓ literature/lit-self-attention.md
  ✓ literature/lit-multi-head-attention.md
  ✓ literature/lit-transformer-architecture.md
  ✓ literature/lit-scaled-dot-product-attention.md

Merged into existing:
  ✓ literature/lit-position-embeddings.md
    Added: sinusoidal encoding as alternative to learned embeddings

Skipped (already covered):
  - training-efficiency → lit-training-speed.md
```

---

## Created Files

### Source Index Note

**File:** `literature/lit-attention-is-all-you-need.md`

```markdown
---
tags:
  - source/literature
  - index
  - machine-learning
  - transformers
source: "attention-is-all-you-need.pdf"
author: "Vaswani et al."
year: 2017
ingested: 2024-01-15
---

# Attention Is All You Need

## Summary

Introduces the Transformer architecture, which relies entirely on attention mechanisms without recurrence or convolution. Achieves state-of-the-art results on machine translation while being significantly more parallelizable and faster to train than previous approaches.

## Interesting Takeaways

The most surprising finding is how much simpler the Transformer is compared to previous seq2seq models. By removing recurrence entirely, they achieved a 10x speedup in training time. The attention visualizations are particularly compelling—you can actually see the model learning grammatical structure without being explicitly taught.

The claim that "attention is all you need" is bold but backed up: they match or beat complex encoder-decoder models on translation while using a more elegant architecture. The positional encoding approach (using sinusoidal functions) is clever—it lets the model generalize to longer sequences than seen during training.

## Extracted Concepts

- [[lit-self-attention]] - Self-Attention Mechanism
- [[lit-multi-head-attention]] - Multi-Head Attention
- [[lit-transformer-architecture]] - Transformer Architecture
- [[lit-scaled-dot-product-attention]] - Scaled Dot-Product Attention

## Metadata

- **Type:** paper
- **Citation:** Vaswani et al. (2017)
- **Ingested:** 2024-01-15
```

---

### Concept Note: Self-Attention

**File:** `literature/lit-self-attention.md`

```markdown
---
tags:
  - source/literature
  - lit/technique
  - machine-learning
  - attention
source: "[[literature/lit-attention-is-all-you-need]]"
added: 2024-01-15
---

# Self-Attention Mechanism

Self-attention computes representations of a sequence by relating different positions within the same sequence. Each position attends to all positions in the previous layer, allowing the model to capture dependencies regardless of distance. This replaces recurrence, which processes sequences step-by-step.

## Details

The mechanism works by computing three vectors for each position:
- **Query (Q)**: What this position is looking for
- **Key (K)**: What this position offers
- **Value (V)**: The actual content to aggregate

Attention scores are computed as: `Attention(Q,K,V) = softmax(QK^T / √d_k) V`

The scaling factor `√d_k` prevents the dot products from growing too large, which would push softmax into regions with tiny gradients.

Key advantages over recurrence:
- Constant path length between any two positions (O(1) vs O(n))
- All positions computed in parallel
- More interpretable—can visualize what attends to what

## Relevance

For Fi's behavior classification: self-attention could help the model understand temporal patterns in accelerometer data. A sudden spike in movement might need to "attend" to what happened 5 seconds ago (was the dog already running, or did it just start?).

## Related

- [[lit-multi-head-attention]] - Extension with multiple attention heads
- [[lit-scaled-dot-product-attention]] - The core attention computation

---

*Source: Vaswani et al. (2017)*
```

---

### Concept Note: Multi-Head Attention

**File:** `literature/lit-multi-head-attention.md`

```markdown
---
tags:
  - source/literature
  - lit/technique
  - machine-learning
  - attention
source: "[[literature/lit-attention-is-all-you-need]]"
added: 2024-01-15
---

# Multi-Head Attention

Multi-head attention runs multiple attention operations in parallel, each with different learned projection matrices. This allows the model to attend to information from different representation subspaces at different positions—essentially learning multiple types of relationships simultaneously.

## Details

Instead of one attention function with d_model dimensions, they use h=8 parallel attention heads, each with d_k = d_v = d_model/h = 64 dimensions.

```
MultiHead(Q,K,V) = Concat(head_1, ..., head_h) W^O
where head_i = Attention(QW_i^Q, KW_i^K, VW_i^V)
```

Each head learns different attention patterns:
- Head 1 might focus on syntactic relationships
- Head 2 might focus on semantic similarity
- Head 3 might focus on positional proximity

The paper shows attention visualizations where different heads clearly learn different linguistic patterns (anaphora resolution, phrase structure, etc.).

Computational cost is similar to single-head attention with full dimensionality due to the reduced dimension per head.

## Related

- [[lit-self-attention]] - The base attention mechanism
- [[lit-transformer-architecture]] - How multi-head attention fits in the full model

---

*Source: Vaswani et al. (2017)*
```

---

### Merged Note Example

**File:** `literature/lit-position-embeddings.md` (existed before, now updated)

```markdown
---
tags:
  - source/literature
  - lit/technique
  - machine-learning
  - embeddings
sources:
  - "[[literature/lit-bert-paper]]"
  - "[[literature/lit-attention-is-all-you-need]]"
added: 2024-01-10
updated: 2024-01-15
---

# Positional Embeddings

Positional embeddings inject sequence order information into models that process all positions in parallel. Without them, a Transformer would treat "dog bites man" and "man bites dog" identically. Two main approaches exist: learned embeddings and fixed sinusoidal encodings.

## Details

**Learned embeddings** (BERT approach):
- Train a separate embedding for each position (0, 1, 2, ... 512)
- Simple and effective
- Limited to max sequence length seen during training

**Sinusoidal encoding** (original Transformer):
- Uses sin/cos functions at different frequencies
- No learned parameters
- Can theoretically generalize to longer sequences

## Additional Sources

**From Attention Is All You Need (Vaswani 2017):**
The paper introduces sinusoidal positional encodings as an alternative to learned embeddings. They use sin/cos functions with wavelengths forming a geometric progression from 2π to 10000·2π. This choice allows the model to learn relative positions because PE(pos+k) can be represented as a linear function of PE(pos). They found sinusoidal encodings performed nearly identically to learned embeddings on their translation tasks.

## Related

- [[lit-transformer-architecture]] - Full architecture using these encodings
- [[lit-self-attention]] - The attention mechanism these complement

---

*Sources: Devlin 2018, Vaswani 2017*
```

---

## Dry Run Example

**User input:**
```
/ingest paper.pdf --dry-run
```

**Output:**
```
=== DRY RUN ===

Would create source note:
  literature/lit-attention-is-all-you-need.md

Would create 4 concept notes:
  - literature/lit-self-attention.md
  - literature/lit-multi-head-attention.md
  - literature/lit-transformer-architecture.md
  - literature/lit-scaled-dot-product-attention.md

Would merge into existing:
  - literature/lit-position-embeddings.md
    New info: sinusoidal encoding functions, comparison with learned embeddings

Would skip (already covered):
  - "training efficiency" → literature/lit-training-speed.md (score: 0.81)
    Reason: Both discuss GPU training time for Transformers

No files written.
```

---

## Internal Mode Example

**User input:**
```
/ingest ~/work/deploy-process.md --internal
```

**Creates:**

1. `internal/int-deploy-process.md` (source index)
2. `internal/int-canary-deployment.md` (concept)
3. `internal/int-rollback-procedure.md` (concept)
4. `internal/int-deploy-approval-workflow.md` (concept)
