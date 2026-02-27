# SPEAR Memory System

Memory is a local, persistent knowledge base for the project. It survives across SPEAR
audit cycles and allows agents to learn from past decisions, findings, and patterns.

## Structure

```
memory/
  index.json          # Searchable catalog of all entries
  decisions/          # Architectural and design decisions (ADRs)
  findings/           # Audit findings, bug discoveries, insights
  patterns/           # Proven patterns worth reusing
  antipatterns/       # Known pitfalls to avoid
```

## How It Works

- Each entry is stored as an individual Markdown file in its category folder.
- `index.json` is the searchable catalog with id, type, title, summary, tags, and
  a reference to the full Markdown file.
- Entries are append-mostly. Updates modify the existing file and bump `updated` in the index.

## Backends

| Backend | Description | Default |
|---------|-------------|---------|
| **json** | Plain JSON index, committed to git | Yes |
| **sqlite-fts** | SQLite with FTS5 for fast local full-text search | Optional |
| **qdrant** | Vector search for semantic similarity queries | Optional |

The default `json` backend requires no setup and is version-controlled with the project.
Switch backends by setting `memory.backend` in `.spear/config.json`.

## Usage

Agents should **check memory before making decisions**. Before proposing an architecture
change, search for prior decisions. Before flagging an issue, check if it was already found.

### Writing an Entry

1. Create a Markdown file in the appropriate category folder.
2. Add a corresponding entry to `index.json` with a unique UUID, title, summary, and tags.
3. Cross-reference related entries using the `references` field.

### Reading / Searching

- Scan `index.json` for entries matching tags, category, or keywords in the summary.
- Read the full Markdown file for detailed context.
- With `sqlite-fts` or `qdrant` backends, use their respective query interfaces.

## Persistence

Memory persists across SPEAR cycles. It is the institutional knowledge of the project.
Treat it as a living document -- prune stale entries, update outdated decisions, and
always add context when recording new findings.
