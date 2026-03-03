---
name: sql
description: Write and optimize SQL queries for PostgreSQL, SQL Server, and Supabase. Use when writing queries, designing schemas, or debugging slow queries.
---

You are a SQL expert covering PostgreSQL and SQL Server. Apply these patterns.

## Query Patterns

### Pagination
```sql
-- Offset pagination (simple, good to ~100k rows)
SELECT * FROM items
WHERE org_id = $1
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- Keyset / cursor pagination (fast, any size)
SELECT * FROM items
WHERE org_id = $1
  AND (created_at, id) < ($last_created_at, $last_id)
ORDER BY created_at DESC, id DESC
LIMIT $2;
```

### CTEs and Window Functions
```sql
-- CTE for readability
WITH active_users AS (
  SELECT user_id, COUNT(*) as session_count
  FROM sessions
  WHERE created_at > NOW() - INTERVAL '30 days'
  GROUP BY user_id
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY org_id ORDER BY session_count DESC) as rank
  FROM active_users
  JOIN users USING (user_id)
)
SELECT * FROM ranked WHERE rank <= 10;
```

### Upsert (PostgreSQL)
```sql
INSERT INTO items (id, name, org_id, updated_at)
VALUES ($1, $2, $3, NOW())
ON CONFLICT (id)
DO UPDATE SET name = EXCLUDED.name, updated_at = NOW();
```

### Upsert (SQL Server)
```sql
MERGE items AS target
USING (SELECT @id AS id, @name AS name) AS source ON target.id = source.id
WHEN MATCHED THEN UPDATE SET name = source.name, updated_at = GETUTCDATE()
WHEN NOT MATCHED THEN INSERT (id, name) VALUES (source.id, source.name);
```

## Schema Design
```sql
-- Standard table structure (PostgreSQL)
CREATE TABLE items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name        TEXT NOT NULL CHECK (char_length(name) > 0),
  status      TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived')),
  metadata    JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by  UUID REFERENCES users(id)
);

CREATE INDEX idx_items_org_id ON items(org_id);
CREATE INDEX idx_items_status ON items(org_id, status) WHERE status = 'active';
```

## Performance
- Always index foreign keys and columns used in WHERE/ORDER BY
- Use `EXPLAIN ANALYZE` to diagnose slow queries
- Partial indexes for common filtered queries: `WHERE deleted_at IS NULL`
- JSONB: use `@>` for containment, index with `gin(metadata)`
- Avoid `SELECT *` in production — project only needed columns
- N+1 queries: use JOINs or `array_agg` / `json_agg` to batch

## PostgreSQL-Specific
```sql
-- Array operations
SELECT * FROM posts WHERE tags @> ARRAY['typescript'];

-- Full-text search
SELECT *, ts_rank(search_vector, query) AS rank
FROM articles, plainto_tsquery('english', $1) query
WHERE search_vector @@ query
ORDER BY rank DESC;

-- JSONB aggregation
SELECT org_id, json_agg(json_build_object('id', id, 'name', name)) AS items
FROM items GROUP BY org_id;
```

## SQL Server-Specific
```sql
-- Row count without full scan
SELECT SUM(p.rows) FROM sys.partitions p
JOIN sys.objects o ON p.object_id = o.object_id
WHERE o.name = 'items' AND p.index_id IN (0, 1);

-- String aggregation (SQL Server 2017+)
SELECT org_id, STRING_AGG(name, ', ') WITHIN GROUP (ORDER BY name) AS names
FROM items GROUP BY org_id;
```
