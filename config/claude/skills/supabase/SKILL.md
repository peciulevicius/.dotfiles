---
name: supabase
description: Supabase patterns for schema design, RLS policies, auth, queries, and edge functions. Use when working with Supabase or PostgreSQL on any project.
---

You are a Supabase expert. Apply these patterns when working with Supabase.

## Schema Design
- Use `uuid` primary keys with `gen_random_uuid()` default
- Always add `created_at timestamptz default now()` and `updated_at timestamptz default now()`
- Add trigger for auto-updating `updated_at`:
  ```sql
  create or replace function update_updated_at()
  returns trigger as $$
  begin new.updated_at = now(); return new; end;
  $$ language plpgsql;
  create trigger update_updated_at before update on <table>
    for each row execute function update_updated_at();
  ```
- Use snake_case for table and column names
- Prefix junction tables: `user_organizations`, `post_tags`

## Row Level Security (RLS)
- Always enable RLS on every table: `alter table <t> enable row level security;`
- Standard user-owned rows policy:
  ```sql
  create policy "Users own their rows" on <table>
    for all using (auth.uid() = user_id);
  ```
- Service role bypasses RLS — use for server-side admin operations
- Never trust client-supplied user IDs — always use `auth.uid()`

## Auth Patterns
- Use `supabase.auth.getUser()` server-side (not `getSession()` — it's insecure)
- Client: `supabase.auth.onAuthStateChange()` for reactive auth state
- Store user profile in public `profiles` table, not in auth.users metadata
- Cascade profile creation with trigger on `auth.users` insert

## TypeScript Types
- Always generate types: `npx supabase gen types typescript --local > src/types/supabase.ts`
- Use typed client: `createClient<Database>(url, key)`

## Queries (TypeScript)
```typescript
// Single row — throws if missing
const { data, error } = await supabase.from('table').select('*').eq('id', id).single()

// Paginated list
const { data, count } = await supabase.from('table')
  .select('*, relation(*)', { count: 'exact' })
  .range(offset, offset + limit - 1)
  .order('created_at', { ascending: false })
```

## Edge Functions
- Use Deno, TypeScript, and Supabase client from `@supabase/supabase-js`
- Access service role key from env: `Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')`
- Always verify JWT for authenticated routes

## Migrations
- Create with: `npx supabase migration new <name>`
- Apply locally: `npx supabase db reset`
- Never edit existing migrations — add new ones
