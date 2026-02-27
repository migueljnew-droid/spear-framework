# Upgrade: Memory Backends

By default, SPEAR stores memory (decisions, deviations, retrospectives) as JSON and Markdown files in `.spear/memory/`. For larger projects or teams that need search, SPEAR supports alternative memory backends.

---

## Default: File-Based Memory

```
.spear/memory/
  decisions/
    DEC-001.md
    DEC-002.md
  deviations/
    DEV-001.md
  retrospectives/
    retro-2026-02.md
  index.json          # Search index (auto-generated)
```

**Pros:** Zero setup, git-trackable, human-readable, works offline.

**Cons:** Search is linear (slow at 500+ entries), no semantic search, merge conflicts in index.json.

**Best for:** Solo developers, small projects, projects under 200 memory entries.

---

## SQLite-FTS Backend

Full-text search using SQLite's FTS5 extension. Fast keyword search across thousands of entries.

### Setup

```bash
spear memory upgrade sqlite-fts
```

This creates `.spear/memory/spear.db` with FTS5 tables. Existing file-based memories are migrated automatically.

### Configuration

```json
{
  "memory": {
    "backend": "sqlite-fts",
    "db_path": ".spear/memory/spear.db",
    "sync_to_files": true
  }
}
```

`sync_to_files: true` keeps Markdown files updated alongside the database, so you can still read memories as files and track them in git. The database is the source of truth for search; files are the source of truth for git history.

### Usage

```bash
# Search is now fast with full-text search
spear memory search "authentication decision"
# => DEC-012: Selected bcrypt for password hashing (score: 0.92)
# => DEC-018: JWT vs session-based auth (score: 0.85)
# => DEC-005: API authentication strategy (score: 0.78)

# Prefix search
spear memory search "auth*"

# Phrase search
spear memory search '"rate limiting strategy"'

# Boolean search
spear memory search "authentication AND NOT oauth"
```

### Performance

| Entries | File-based search | SQLite-FTS search |
|---------|-------------------|-------------------|
| 100     | 50ms              | 2ms               |
| 1,000   | 500ms             | 5ms               |
| 10,000  | 5s                | 8ms               |

**Pros:** Fast search, handles thousands of entries, standard SQLite tooling.

**Cons:** Binary file (.db) doesn't diff well in git, requires SQLite.

**Best for:** Teams, projects with 200+ memory entries, projects needing fast search.

---

## Qdrant Backend

Semantic vector search using Qdrant. Finds conceptually related memories even without keyword matches.

### Setup

```bash
# Start Qdrant (Docker)
docker run -d --name qdrant -p 6333:6333 qdrant/qdrant

# Configure SPEAR
spear memory upgrade qdrant --url http://localhost:6333
```

### Configuration

```json
{
  "memory": {
    "backend": "qdrant",
    "qdrant_url": "http://localhost:6333",
    "collection": "spear_memory",
    "embedding_model": "all-MiniLM-L6-v2",
    "sync_to_files": true
  }
}
```

### Usage

```bash
# Semantic search — finds related concepts, not just keywords
spear memory search "how did we handle user sessions?"
# => DEC-012: JWT token implementation (similarity: 0.89)
# => DEC-025: Redis session store decision (similarity: 0.85)
# => DEV-003: Switched from cookies to bearer tokens (similarity: 0.72)

# Even finds memories with different terminology
spear memory search "protecting API routes from unauthorized access"
# => DEC-005: Authentication middleware strategy (similarity: 0.91)
# => DEC-018: Rate limiting implementation (similarity: 0.67)
```

### Embedding Models

| Model | Size | Quality | Speed |
|-------|------|---------|-------|
| all-MiniLM-L6-v2 | 80MB | Good | Fast |
| all-mpnet-base-v2 | 420MB | Better | Medium |
| bge-large-en-v1.5 | 1.3GB | Best | Slow |

Default is `all-MiniLM-L6-v2` — good balance of quality and speed for code-related memories.

**Pros:** Semantic search, finds related concepts, scales to millions of entries.

**Cons:** Requires Qdrant service, embedding model download, not git-trackable.

**Best for:** Large teams, knowledge-heavy projects, cross-project memory sharing.

---

## Hybrid Backend

Combine SQLite-FTS (keyword) and Qdrant (semantic) for best-of-both-worlds search.

```json
{
  "memory": {
    "backend": "hybrid",
    "sqlite_path": ".spear/memory/spear.db",
    "qdrant_url": "http://localhost:6333",
    "search_strategy": "rrf",
    "sync_to_files": true
  }
}
```

`search_strategy: "rrf"` uses Reciprocal Rank Fusion to merge results from both backends:

```bash
spear memory search "how we handle auth"
# => Combines keyword matches (SQLite) with semantic matches (Qdrant)
# => Results ranked by fused score
```

---

## Migration Between Backends

```bash
# File -> SQLite
spear memory migrate --from file --to sqlite-fts

# SQLite -> Qdrant
spear memory migrate --from sqlite-fts --to qdrant

# Any -> File (export)
spear memory export --format markdown --output ./memory-export/
```

Migrations are non-destructive. The source backend data is preserved until you explicitly delete it.

---

## Backend Comparison

| Feature | File | SQLite-FTS | Qdrant | Hybrid |
|---------|------|------------|--------|--------|
| Setup complexity | None | Low | Medium | Medium |
| Git-trackable | Yes | Partial | No | Partial |
| Keyword search | Linear scan | Fast FTS5 | No | Yes |
| Semantic search | No | No | Yes | Yes |
| Offline capable | Yes | Yes | No | Partial |
| Scale (entries) | ~200 | ~100K | Millions | Millions |
| Dependencies | None | SQLite | Docker/Qdrant | Both |

### Recommendation

- Start with **file-based** (default). It works for most projects.
- Upgrade to **SQLite-FTS** when search gets slow (200+ entries).
- Upgrade to **Qdrant** when you need semantic search or cross-project memory.
- Use **hybrid** for large teams with diverse search patterns.

You can always upgrade later. The migration path is one command.
