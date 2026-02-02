# Literature Note Formats

This skill creates TWO types of notes for literature ingestion:

1. **Source Index Note** - Links to all concepts extracted from a document
2. **Concept Notes** - Standalone atomic notes for each concept

## Source Index Note

Created at: `literature/lit-{source-slug}.md`

```markdown
---
tags:
  - source/literature
  - index
  - {topic-tags}
source: "{original-filename-or-url}"
author: "{Author et al.}"
year: {YYYY}
ingested: {YYYY-MM-DD}
---

# {Document Title}

## Summary

{2-3 sentence overview of what this document covers and its main contribution}

## Interesting Takeaways

{1-2 paragraph narrative of the most surprising or useful findings. What would you tell a colleague about this paper?}

## Extracted Concepts

- [[lit-{concept-1-slug}]] - {Concept 1 Title}
- [[lit-{concept-2-slug}]] - {Concept 2 Title}
- [[lit-{concept-3-slug}]] - {Concept 3 Title}

## Metadata

- **Type:** {paper|review|report|documentation|article}
- **Citation:** {Author et al. (Year)}
- **Ingested:** {YYYY-MM-DD}
```

### Field Guidelines

- **tags**: Always include `source/literature` and `index`
- **source**: Original filename or full URL
- **author/year**: Include if available, omit if unknown
- **Summary**: Focus on contribution, not just coverage
- **Interesting Takeaways**: Write conversationally, highlight surprising findings
- **Extracted Concepts**: Wiki-links to all concept notes created

---

## Concept Note

Created at: `literature/lit-{concept-slug}.md`

Each concept is a **standalone note** that can be understood without reading the source.

```markdown
---
tags:
  - source/literature
  - lit/{type}
  - {topic-tags}
source: "[[literature/lit-{source-slug}]]"
added: {YYYY-MM-DD}
---

# {Concept Title}

{2-4 sentence summary that fully explains this concept. Must be standalone - reader should understand without seeing the source document.}

## Details

{Longer explanation with specifics:
- Include exact numbers, percentages, benchmarks
- Quote key phrases when impactful
- Provide examples or use cases
- Explain mechanisms or processes}

## Relevance

{How this concept relates to user's domain/project. Omit section if concept is general-purpose.}

## Related

- [[{related-concept-1}]] - {brief context}
- [[{related-concept-2}]] - {brief context}

---

*Source: {Citation}*
```

### Concept Types

Use these type tags (`lit/{type}`):

| Type | Description | Example |
|------|-------------|---------|
| `finding` | Research result or discovery | "Transformers train 10x faster than RNNs" |
| `technique` | Method or approach | "Multi-head attention mechanism" |
| `definition` | Term or concept explanation | "Self-attention defined" |
| `benchmark` | Performance metric or comparison | "28.4 BLEU on EN-DE translation" |
| `open-question` | Unresolved issue or future work | "Memory scaling for long sequences" |

### Field Guidelines

- **tags**: Include `source/literature`, type tag, and 1-2 topic tags
- **source**: Wiki-link to the source index note
- **Summary**: 2-4 sentences, MUST be standalone
- **Details**: Optional but recommended; include specifics
- **Relevance**: Connect to user's work; omit if general
- **Related**: Link to existing concept notes in vault

---

## Multi-Source Accumulation

When a concept appears in multiple sources, the note grows:

```markdown
---
tags:
  - source/literature
  - lit/technique
  - machine-learning
sources:
  - "[[literature/lit-attention-paper]]"
  - "[[literature/lit-bert-paper]]"
added: 2024-01-15
updated: 2024-01-20
---

# Self-Attention Mechanism

{Original summary}

## Details

{Original details}

## Additional Sources

**From BERT Paper (Devlin 2018):**
Adds bidirectional context - attends to both left and right tokens simultaneously. Shows that pre-training with masked language modeling dramatically improves downstream task performance.

**From GPT-2 Paper (Radford 2019):**
Demonstrates that self-attention scales to very large models (1.5B parameters) and can generate coherent long-form text without task-specific training.

## Related

- [[lit-transformer-architecture]]
- [[lit-positional-encoding]]

---

*Sources: Vaswani 2017, Devlin 2018, Radford 2019*
```

### Merge Rules

1. Convert `source:` to `sources:` array
2. Add `updated:` date
3. Append to `## Additional Sources` with attribution
4. Only merge if new source adds genuinely new information
5. Maximum 5 sources per concept (configurable)

---

## Example: Complete Extraction

**Input:** `attention-is-all-you-need.pdf`

**Creates:**

1. `literature/lit-attention-is-all-you-need.md` (source index)
2. `literature/lit-self-attention.md` (concept)
3. `literature/lit-multi-head-attention.md` (concept)
4. `literature/lit-positional-encoding.md` (concept)
5. `literature/lit-transformer-architecture.md` (concept)
6. `literature/lit-scaled-dot-product-attention.md` (concept)
