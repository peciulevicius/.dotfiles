# Database Rules (Supabase / PostgreSQL)

## Schema Conventions
```sql
-- All tables get these columns
id          uuid primary key default gen_random_uuid()
created_at  timestamptz not null default now()
updated_at  timestamptz not null default now()

-- Tables that belong to a user or org
user_id         uuid references auth.users(id) on delete cascade
organization_id uuid references organizations(id) on delete cascade

-- Naming: snake_case, plural table names
-- users, organizations, projects, subscription_plans (not subscriptionPlan)
```

## RLS — Every Table Must Have It
```sql
-- Enable RLS on creation — never leave a table unprotected
alter table items enable row level security;

-- Standard user-owned resource
create policy "Users access own items" on items
  for all using (user_id = auth.uid());

-- Org-scoped resource
create policy "Org members access" on projects
  for all using (
    organization_id in (
      select organization_id from members
      where user_id = auth.uid()
    )
  );

-- Public read
create policy "Anyone can read" on posts
  for select using (published = true);
```

## Migrations (Supabase CLI)
```bash
# Generate migration from local schema changes
supabase db diff --schema public -f migration_name

# Apply to production
supabase db push

# Pull remote schema to local
supabase db pull

# Generate TypeScript types after schema changes
supabase gen types typescript --local > packages/types/db.types.ts
# or for single-app:
supabase gen types typescript --local > src/lib/db.types.ts
```

## Queries (Supabase JS)
```typescript
// Always handle errors
const { data, error } = await supabase.from('items').select('*')
if (error) throw error

// Select only what you need
const { data } = await supabase
  .from('items')
  .select('id, name, created_at')
  .eq('user_id', userId)
  .order('created_at', { ascending: false })
  .limit(20)

// Use server client in server components / actions (not browser client)
import { createServerClient } from '@/lib/supabase/server'
const supabase = createServerClient()
const { data: { user } } = await supabase.auth.getUser()  // not getSession()
```

## Performance
```sql
-- Index foreign keys and frequently filtered columns
create index on items(user_id);
create index on items(organization_id);
create index on items(created_at desc);  -- for ordering

-- Composite index for common query patterns
create index on items(organization_id, status, created_at desc);

-- Partial index for filtered queries
create index on items(user_id) where deleted_at is null;
```

## Soft Deletes (when history matters)
```sql
-- Add to table
deleted_at timestamptz  -- null = active, timestamp = deleted

-- Update RLS to exclude deleted
create policy "..." on items
  for select using (user_id = auth.uid() and deleted_at is null);
```

## Edge Functions
```typescript
// supabase/functions/my-function/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // Use service role for admin operations
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Verify user for user-facing operations
  const authHeader = req.headers.get('Authorization')
  const { data: { user } } = await supabase.auth.getUser(
    authHeader?.replace('Bearer ', '')
  )
  if (!user) return new Response('Unauthorized', { status: 401 })

  return new Response(JSON.stringify({ ok: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```
