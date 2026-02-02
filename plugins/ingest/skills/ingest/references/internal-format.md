# Internal Note Formats

This skill creates TWO types of notes for internal documentation:

1. **Source Index Note** - Links to all concepts extracted from a document
2. **Concept Notes** - Standalone atomic notes for each concept

## Source Index Note

Created at: `internal/int-{source-slug}.md`

```markdown
---
tags:
  - source/internal
  - index
  - {category-tags}
source: "{original-filename-or-url}"
owner: "{Team or Person}"
ingested: {YYYY-MM-DD}
---

# {Document Title}

## Summary

{2-3 sentence overview of what this document covers and WHY it matters}

## Extracted Concepts

- [[int-{concept-1-slug}]] - {Concept 1 Title}
- [[int-{concept-2-slug}]] - {Concept 2 Title}
- [[int-{concept-3-slug}]] - {Concept 3 Title}

## Metadata

- **Type:** {process|architecture|decision|convention|reference|how-to}
- **Owner:** {Team or Person}
- **Ingested:** {YYYY-MM-DD}
```

### Field Guidelines

- **tags**: Always include `source/internal` and `index`
- **source**: Original filename or internal URL (Confluence, Notion, etc.)
- **owner**: Team or person responsible; omit if unknown
- **Summary**: Focus on WHY this matters for a new team member

---

## Concept Note

Created at: `internal/int-{concept-slug}.md`

Each concept is a **standalone note** that captures institutional knowledge.

```markdown
---
tags:
  - source/internal
  - int/{type}
  - {category-tags}
source: "[[internal/int-{source-slug}]]"
owner: "{Team or Person}"
added: {YYYY-MM-DD}
---

# {Concept Title}

{2-4 sentence summary that fully explains this concept. A new team member should understand without additional context.}

## Details

{Specific information:
- Step-by-step procedures
- Commands or code snippets
- Configuration examples
- Decision rationale}

## Related

- [[{related-concept-1}]] - {brief context}
- [[{related-concept-2}]] - {brief context}

---

*Source: {Document Name}*
```

### Concept Types

Use these type tags (`int/{type}`):

| Type | Description | Example |
|------|-------------|---------|
| `process` | Workflow or procedure | "Deployment approval workflow" |
| `architecture` | System design or structure | "Auth service architecture" |
| `decision` | Why something was done a certain way | "Why we chose Postgres over MongoDB" |
| `convention` | Team standards or patterns | "API naming conventions" |
| `how-to` | Step-by-step guide | "How to set up local dev environment" |
| `reference` | Lookup information | "Environment variable reference" |

### Field Guidelines

- **tags**: Include `source/internal`, type tag, and category tags
- **source**: Wiki-link to the source index note
- **owner**: Team or person responsible
- **Summary**: 2-4 sentences, standalone, written for new team members
- **Details**: Specific steps, commands, code, configuration

---

## Multi-Source Accumulation

When the same concept appears in multiple internal docs:

```markdown
---
tags:
  - source/internal
  - int/process
  - deployment
sources:
  - "[[internal/int-deploy-guide-2023]]"
  - "[[internal/int-deploy-guide-2024]]"
owner: "Platform Team"
added: 2023-06-01
updated: 2024-01-15
---

# Production Deployment Process

{Current summary reflecting latest state}

## Details

{Current details}

## Additional Sources

**From Deploy Guide 2024 Update:**
Canary percentage changed from 5% to 10%. New requirement: must have SRE approval for deploys after 4pm. Added automatic rollback trigger at 5% error rate increase.

## Related

- [[int-rollback-procedures]]
- [[int-oncall-rotation]]

---

*Sources: Deploy Guide 2023, Deploy Guide 2024*
```

---

## Example: Complete Extraction

**Input:** `auth-service-architecture.md --internal`

**Creates:**

1. `internal/int-auth-service-architecture.md` (source index)
2. `internal/int-jwt-token-flow.md` (concept)
3. `internal/int-session-management.md` (concept)
4. `internal/int-oauth-integration.md` (concept)
5. `internal/int-auth-database-schema.md` (concept)
