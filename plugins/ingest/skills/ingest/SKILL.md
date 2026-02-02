---
name: ingest
description: Ingest documents into atomic concept notes with semantic deduplication. Creates separate files per concept, not summaries.
argument-hint: [file-or-url] [--internal] [--dry-run]
allowed-tools: Read, Write, Bash, WebFetch, mcp__qmd__vsearch, mcp__qmd__get
---

# Document Ingestion Skill

When invoked with `/ingest`, follow these steps EXACTLY.

## Step 1: Parse Arguments

```
/ingest <file-or-url> [--internal] [--title "..."] [--dry-run]
```

- `file-or-url`: Required. Path to file or URL
- `--internal`: Use internal mode (team docs) instead of literature mode (research)
- `--title "..."`: Override document title
- `--dry-run`: Preview only, don't write files

Set variables:
- `MODE` = "internal" if `--internal`, else "literature"
- `PREFIX` = "int" if internal, else "lit"
- `FOLDER` = "internal" if internal, else "literature"

## Step 2: Get Vault Path

Run:
```bash
cat ~/.config/claude-note/config.toml 2>/dev/null
```

Look for `vault_root = "..."`. Extract the path.

If no config found, ask user: "Where should I create notes? (e.g., ~/Documents/notes)"

Set `OUTPUT_DIR` = `{vault_root}/{FOLDER}/`

## Step 3: Read Document Content

**For local files:**

- `.md` or `.txt`: Use Read tool directly
- `.pdf`: Run `pdftotext "{file}" - 2>/dev/null || pandoc "{file}" -t plain`
- `.docx`: Run `pandoc "{file}" -t plain --wrap=none`

**For URLs:**

Use WebFetch to get the content.

Store in `CONTENT`. If longer than 100,000 characters, truncate and append `\n\n[... content truncated ...]`

Set `TITLE` from `--title` argument, or derive from filename/URL.

## Step 4: Extract Atomic Concepts

Analyze the document content and extract structured knowledge.

**For LITERATURE mode**, extract this JSON structure:

```json
{
  "source_summary": "2-3 sentence summary of what this document covers",
  "source_type": "paper|review|report|documentation|article|other",
  "key_citation": "Author et al. (Year) or Document Title",
  "interesting_takeaways": "1-2 paragraph narrative of surprising/useful findings. Write conversationally. Focus on insights that could change how we approach work, specific numbers that stand out, counterintuitive findings.",
  "notes": [
    {
      "slug": "kebab-case-max-50-chars",
      "title": "Human Readable Title",
      "type": "finding|technique|definition|benchmark|open-question",
      "summary": "2-4 sentence STANDALONE explanation. Reader must understand without seeing source.",
      "details": "Longer explanation with specific numbers, quotes, examples. Optional but recommended.",
      "relevance": "How this connects to user's work domain. Null if general-purpose.",
      "tags": ["topic-tag-1", "topic-tag-2"]
    }
  ]
}
```

**For INTERNAL mode**, extract this JSON structure:

```json
{
  "source_summary": "2-3 sentence summary",
  "source_type": "process|architecture|decision|convention|reference|how-to",
  "key_citation": "Document Title",
  "interesting_takeaways": "1-2 paragraph narrative of important institutional knowledge. Focus on non-obvious processes, key decisions and rationale, gotchas, things that save time.",
  "notes": [
    {
      "slug": "kebab-case-max-50-chars",
      "title": "Human Readable Title",
      "type": "process|architecture|decision|convention|how-to|reference",
      "summary": "2-4 sentence STANDALONE explanation for a new team member.",
      "details": "Specific steps, commands, config examples, rationale.",
      "owner": "Team or person responsible. Null if unknown.",
      "tags": ["category-tag"]
    }
  ]
}
```

**Extraction rules:**
1. Create 3-15 concepts depending on document richness
2. Each concept MUST be standalone - understandable without the source
3. Include specific numbers, percentages, commands when available
4. Skip generic/obvious information
5. Slugs become filenames: `{PREFIX}-{slug}.md`

Store extraction result in `EXTRACTION`.

## Step 5: Semantic Deduplication

For EACH concept in `EXTRACTION.notes`, do the following:

### 5a. Build search query

```
QUERY = "{concept.title} {concept.summary first 200 chars}"
```

### 5b. Search for similar existing notes

Call MCP tool:
```
mcp__qmd__vsearch(
  query: QUERY,
  limit: 3,
  minScore: 0.75
)
```

### 5c. Process results

**If no results with score >= 0.75:**
- Mark concept as `CREATE_NEW`

**If result found with score >= 0.75:**
- Check if result path contains `{FOLDER}/` (same directory)
- If yes: Mark concept as `MAYBE_MERGE` with `existing_path`
- If no: Mark concept as `CREATE_NEW`

### 5d. Assess merge (for MAYBE_MERGE concepts)

Read the existing note content using Read tool or `mcp__qmd__get`.

Compare existing content with new concept. Ask yourself:
- Does new concept provide NEW techniques, numbers, or findings?
- Does it offer a DIFFERENT perspective or application?
- Or is it just restating the same thing with different words?

**If genuinely new information exists:**
- Mark as `MERGE` with `new_info_summary` (2-4 sentences of what's new)

**If no new information:**
- Mark as `SKIP` with reason

## Step 6: Report Plan (Dry Run stops here)

Print:
```
Extracted {N} concepts from "{TITLE}":

Will CREATE {X} new notes:
  - {PREFIX}-{slug}.md: {title}
  ...

Will MERGE into {Y} existing notes:
  - {existing_filename}: adds {new_info_summary snippet}
  ...

Will SKIP {Z} concepts (already covered):
  - "{concept title}" → {existing_filename} (score: {score})
  ...
```

**If `--dry-run`:** Stop here. Do not write any files.

## Step 7: Create Source Index Note

Create file at `{OUTPUT_DIR}/{PREFIX}-{source_slug}.md`:

```markdown
---
tags:
  - source/{MODE}
  - {source_type}
source_file: "{original_filename}"
ingested: {YYYY-MM-DD}
---

# {key_citation}

{source_summary}

## Interesting Takeaways

{interesting_takeaways}

## Extracted Concepts

- [[{FOLDER}/{PREFIX}-{concept1_slug}|{concept1_title}]]
- [[{FOLDER}/{PREFIX}-{concept2_slug}|{concept2_title}]]
...

## Source

- **File:** `{original_filename}`
- **Type:** {source_type}
- **Ingested:** {YYYY-MM-DD}
```

## Step 8: Create New Concept Notes

For each concept marked `CREATE_NEW`:

Create file at `{OUTPUT_DIR}/{PREFIX}-{slug}.md`:

```markdown
---
tags:
  - source/{MODE}
  - {PREFIX}/{type}
  - {tags...}
source: "[[{FOLDER}/{PREFIX}-{source_slug}]]"
added: {YYYY-MM-DD}
---

# {title}

{summary}

## Details

{details}

## Relevance

{relevance if not null, otherwise omit this section}

## Related

- [[fi-moc]]

---

*Source: {key_citation}*
```

For internal mode, add `## Owner` section with `{owner}` if not null.

## Step 9: Merge Into Existing Notes

For each concept marked `MERGE`:

### 9a. Read existing note

Use Read tool to get current content.

### 9b. Update YAML frontmatter

If note has `source: "..."`:
- Convert to `sources:` array
- Add new source link

If note has `sources:` array:
- Append new source link

Add or update `updated: {YYYY-MM-DD}`

### 9c. Append new information

Find or create `## Additional Sources` section.

Add:
```markdown
**From {key_citation}:**
{new_info_summary}
```

### 9d. Write updated note

Use Write tool to save changes.

## Step 10: Report Results

Print:
```
=== Ingestion Complete ({MODE} mode) ===

Source note: {PREFIX}-{source_slug}.md

Created {X} concept notes:
  ✓ {PREFIX}-{slug1}.md
  ✓ {PREFIX}-{slug2}.md
  ...

Merged into {Y} existing notes:
  ✓ {existing1}.md (added: {snippet})
  ...

Skipped {Z} concepts (already covered)

📌 Key Takeaways:
────────────────────────────────────────
{interesting_takeaways}
────────────────────────────────────────
```

---

## Fallback: No qmd Available

If `mcp__qmd__vsearch` is not available or returns an error:

1. Fall back to filename matching:
   ```bash
   ls {OUTPUT_DIR}/ 2>/dev/null | grep -i "{keywords from concept title}"
   ```

2. If similar filename found, read it and do manual comparison
3. Otherwise, create new note

This provides basic deduplication even without semantic search.

---

## Example Session

```
User: /ingest ~/Downloads/attention-paper.pdf

Claude:
Reading config... vault at ~/Documents/notes
Extracting text from PDF... 45,231 characters

Analyzing document...

Extracted 5 concepts from "Attention Is All You Need":

Checking for duplicates...
  "self-attention" → searching... no similar notes (create new)
  "multi-head-attention" → searching... no similar notes (create new)
  "positional-encoding" → searching... found lit-position-embeddings.md (0.81)
    → Reading existing note...
    → New info: sinusoidal functions vs learned embeddings
    → Will merge
  "transformer-architecture" → searching... no similar notes (create new)
  "training-efficiency" → searching... found lit-gpu-training.md (0.79)
    → Reading existing note...
    → No new information (already covers training speedups)
    → Skipping

Creating notes...

=== Ingestion Complete (literature mode) ===

Source note: lit-attention-is-all-you-need.md

Created 4 concept notes:
  ✓ lit-self-attention.md
  ✓ lit-multi-head-attention.md
  ✓ lit-transformer-architecture.md
  ✓ lit-scaled-dot-product.md

Merged into 1 existing note:
  ✓ lit-position-embeddings.md (added: sinusoidal encoding approach)

Skipped 1 concept (already covered):
  - "training-efficiency" → lit-gpu-training.md

📌 Key Takeaways:
────────────────────────────────────────
The most surprising finding is how much simpler the Transformer is
compared to previous seq2seq models. By removing recurrence entirely,
they achieved 10x speedup in training. The attention visualizations
show the model learning grammatical structure without explicit teaching.
────────────────────────────────────────
```
