# claude-ingest-skill

A Claude Code skill that transforms documents into **atomic, interconnected concept notes** with semantic deduplication.

## What Makes This Different

Unlike simple summarizers that create one page per document, this skill:

| Traditional Summarizer | This Skill |
|----------------------|------------|
| 1 summary file per document | 5-15 separate concept files |
| Concepts as bullet points | Each concept is standalone note |
| No deduplication | Semantic search finds similar notes |
| Content isolated per source | Concepts accumulate across sources |

**Result:** A growing knowledge graph where each concept links to others and gets richer as you add sources.

## Installation

### Claude Code (recommended)

```
/plugin marketplace add crimeacs/claude-ingest-skill
/plugin install ingest@crimeacs-claude-ingest-skill
```

### Manual Installation

```bash
git clone https://github.com/crimeacs/claude-ingest-skill.git ~/.claude/skills/ingest
```

## Usage

```
/ingest ~/Downloads/attention-paper.pdf
/ingest https://example.com/api-docs --internal
/ingest spec.docx --title "API Specification v2"
/ingest paper.pdf --dry-run
```

### Arguments

| Argument | Description |
|----------|-------------|
| `[file-or-url]` | Path to document (.pdf, .docx, .md, .txt) or URL |
| `--internal` | Create internal notes instead of literature notes |
| `--title "..."` | Override the document title |
| `--dry-run` | Preview extraction without writing files |

## How It Works

### 1. Extract Atomic Concepts

The skill analyzes your document and extracts 3-15 standalone concepts:

```
Input: attention-is-all-you-need.pdf

Extracted concepts:
- self-attention (technique)
- multi-head-attention (technique)
- positional-encoding (technique)
- transformer-architecture (finding)
- scaled-dot-product-attention (technique)
```

### 2. Semantic Deduplication

Before creating each note, the skill searches your vault for similar existing concepts:

```
Checking for duplicates...
✓ self-attention → no similar notes
✓ positional-encoding → found: lit-position-embeddings.md (similarity: 0.78)
  → New info detected: sinusoidal vs learned embeddings
  → Will merge into existing note
```

### 3. Create or Merge

**New concepts** get their own files:
```
Created: literature/lit-self-attention.md
Created: literature/lit-multi-head-attention.md
```

**Overlapping concepts** merge into existing notes:
```
Merged into: literature/lit-position-embeddings.md
  Added: sinusoidal encoding approach from Vaswani et al.
```

### 4. Source Index

A source note links to all extracted concepts:

```markdown
# Attention Is All You Need

## Extracted Concepts

- [[lit-self-attention]] - Self-Attention Mechanism
- [[lit-multi-head-attention]] - Multi-Head Attention
- [[lit-transformer-architecture]] - Transformer Architecture
```

## Output Structure

```
vault/
├── literature/
│   ├── lit-attention-is-all-you-need.md  ← Source index
│   ├── lit-self-attention.md              ← Concept note
│   ├── lit-multi-head-attention.md        ← Concept note
│   └── lit-position-embeddings.md         ← Merged with new source
└── internal/
    ├── int-deploy-process.md              ← Source index
    ├── int-canary-deployment.md           ← Concept note
    └── int-rollback-procedure.md          ← Concept note
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
brew install qmd  # or your package manager

# Index your vault
cd ~/Documents/my-vault
qmd index
qmd embed  # For vector search
```

Without qmd, the skill falls back to filename matching for deduplication.

### For PDF extraction

```bash
# macOS
brew install poppler pandoc

# Linux
apt install poppler-utils pandoc
```

## Concept Note Format

Each concept is a standalone note:

```markdown
---
tags:
  - source/literature
  - lit/technique
  - machine-learning
source: "[[literature/lit-attention-paper]]"
added: 2024-01-15
---

# Self-Attention Mechanism

Self-attention computes representations by relating different positions
within the same sequence. Each position attends to all positions,
capturing dependencies regardless of distance.

## Details

The mechanism uses Query, Key, Value vectors...

## Related

- [[lit-multi-head-attention]]
- [[lit-transformer-architecture]]

---

*Source: Vaswani et al. (2017)*
```

## Multi-Source Accumulation

When you ingest another paper covering the same concept, it merges:

```markdown
---
sources:
  - "[[literature/lit-attention-paper]]"
  - "[[literature/lit-bert-paper]]"     ← Added
updated: 2024-01-20                      ← Updated
---

# Self-Attention Mechanism

{Original content}

## Additional Sources

**From BERT Paper (Devlin 2018):**
Adds bidirectional context—attends to both left and right tokens.
Pre-training with masked language modeling improves downstream tasks.
```

## Modes

### Literature Mode (default)

For external research: papers, articles, documentation.

- Creates `lit-*` files in `literature/`
- Extracts: findings, techniques, definitions, benchmarks
- Includes citation metadata

### Internal Mode (`--internal`)

For team documentation: processes, architecture, decisions.

- Creates `int-*` files in `internal/`
- Extracts: processes, architecture, decisions, conventions
- Includes owner/team metadata

## Tips

- Use `--dry-run` first to preview extraction
- Review merged notes for quality
- Add manual annotations after ingestion
- For batch processing, use [claude-note CLI](https://github.com/crimeacs/claude-note)

## Related Projects

- [claude-note](https://github.com/crimeacs/claude-note) - Full knowledge synthesis daemon
- [qmd](https://github.com/tobi/qmd) - Quick Markdown Search for semantic deduplication
- [Obsidian](https://obsidian.md) - Knowledge base for local Markdown files

## License

MIT
