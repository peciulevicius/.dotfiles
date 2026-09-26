#!/usr/bin/env node
// GDPR data-subject requests (access + erasure) for a Supabase project.
//
//   node gdpr-export.mjs --config gdpr.config.json export someone@example.com [--out file.json]
//   node gdpr-export.mjs --config gdpr.config.json delete someone@example.com [--yes]
//
// export  Writes one JSON file with every row the config maps to that person,
//         plus their auth user (secrets stripped). Nothing found -> no file.
// delete  Dry run by default: prints what would go, per table. --yes deletes.
//         Refuses when the address matches nothing.
//
// Env (real env wins, then .env.local, then .env in the current directory):
//   SUPABASE_URL          (fallbacks: PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_URL)
//   SUPABASE_SERVICE_KEY  (fallback:  SUPABASE_SERVICE_ROLE_KEY)
// The service key bypasses RLS. Run this locally only; never ship it.
//
// Exit codes: 0 ok, 1 usage/config/API error, 2 no data found for that address.
//
// Dependency-free, Node >= 22. Docs: ~/.dotfiles/docs/UTILITY_SCRIPTS.md

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const PAGE_SIZE = 1000;
const IDENT = /^[A-Za-z_][A-Za-z0-9_]*$/;
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const SECRET_KEY = /(password|token|secret)/i;

// ---------------------------------------------------------------------------
// Args

function usage(message) {
  if (message) console.error(`Error: ${message}\n`);
  console.error(
    'Usage:\n' +
      '  gdpr-export.mjs --config gdpr.config.json export <email> [--out file.json]\n' +
      '  gdpr-export.mjs --config gdpr.config.json delete <email> [--yes]',
  );
  process.exit(1);
}

function parseArgs(argv) {
  const args = { config: 'gdpr.config.json', out: null, yes: false, positional: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--config') args.config = argv[++i] ?? usage('--config needs a path');
    else if (a === '--out') args.out = argv[++i] ?? usage('--out needs a path');
    else if (a === '--yes') args.yes = true;
    else if (a === '-h' || a === '--help') usage();
    else if (a.startsWith('--')) usage(`unknown flag ${a}`);
    else args.positional.push(a);
  }
  const [command, email, ...rest] = args.positional;
  if (rest.length) usage(`unexpected argument ${rest[0]}`);
  if (command !== 'export' && command !== 'delete') usage('command must be "export" or "delete"');
  if (!email || !EMAIL.test(email)) usage('a valid email address is required');
  if (command === 'delete' && args.out) usage('--out only applies to export');
  if (command === 'export' && args.yes) usage('--yes only applies to delete');
  return { ...args, command, email: email.trim().toLowerCase() };
}

// ---------------------------------------------------------------------------
// Env + config

function loadEnv() {
  // process.loadEnvFile never overrides a variable that is already set, so
  // loading .env.local first makes it win over .env, and the real env wins
  // over both.
  for (const file of ['.env.local', '.env']) {
    if (existsSync(file)) process.loadEnvFile(file);
  }
  const url =
    process.env.SUPABASE_URL ?? process.env.PUBLIC_SUPABASE_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_KEY ?? process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url) usage('SUPABASE_URL is not set (env, .env.local or .env)');
  if (!key) usage('SUPABASE_SERVICE_KEY is not set (env, .env.local or .env)');
  return { url: url.replace(/\/+$/, ''), key };
}

function loadConfig(path) {
  const full = resolve(path);
  if (!existsSync(full)) usage(`config not found: ${full}`);
  let raw;
  try {
    raw = JSON.parse(readFileSync(full, 'utf8'));
  } catch (e) {
    usage(`config is not valid JSON: ${e.message}`);
  }
  const fail = (msg) => usage(`config: ${msg}`);

  const auth =
    raw.authUser === true
      ? { export: true, delete: false }
      : raw.authUser && typeof raw.authUser === 'object'
        ? { export: raw.authUser.export !== false, delete: raw.authUser.delete === true }
        : { export: false, delete: false };

  if (raw.notes !== undefined && !(Array.isArray(raw.notes) && raw.notes.every((n) => typeof n === 'string'))) {
    fail('"notes" must be an array of strings');
  }
  if (!Array.isArray(raw.tables)) fail('"tables" must be an array');

  const seen = new Set();
  const tables = raw.tables.map((t, i) => {
    const where = `tables[${i}]`;
    if (!t || typeof t !== 'object') fail(`${where} must be an object`);
    if (!IDENT.test(t.table ?? '')) fail(`${where}.table must be a plain identifier`);
    if (seen.has(t.table)) fail(`${where}: table "${t.table}" listed twice`);
    const m = t.match ?? {};
    if (!IDENT.test(m.column ?? '')) fail(`${where}.match.column must be a plain identifier`);
    if (!['email', 'auth_user_id', 'ref'].includes(m.by)) {
      fail(`${where}.match.by must be "email", "auth_user_id" or "ref"`);
    }
    if (m.by === 'ref') {
      // Match on a column of rows already found in an earlier table, e.g.
      // newsletter_sends.subscriber_id -> newsletter_subscribers.id.
      if (!m.ref || !seen.has(m.ref.table)) fail(`${where}.match.ref.table must name an earlier table`);
      if (!IDENT.test(m.ref.column ?? '')) fail(`${where}.match.ref.column must be a plain identifier`);
    }
    const omit = t.omit ?? [];
    if (!Array.isArray(omit) || !omit.every((c) => IDENT.test(c))) fail(`${where}.omit must be column names`);
    seen.add(t.table);
    return { table: t.table, match: m, delete: t.delete === true, omit };
  });

  const needsAuth = auth.export || auth.delete || tables.some((t) => t.match.by === 'auth_user_id');
  return { notes: raw.notes ?? [], auth, tables, needsAuth };
}

// ---------------------------------------------------------------------------
// HTTP

function client({ url, key }) {
  const headers = { apikey: key, Authorization: `Bearer ${key}` };

  async function call(method, path, extra = {}) {
    const res = await fetch(`${url}${path}`, { method, headers: { ...headers, ...extra } });
    const text = await res.text();
    if (!res.ok) {
      // PostgREST/GoTrue error bodies never echo the key; safe to show.
      throw new Error(`${method} ${path.split('?')[0]} -> HTTP ${res.status}: ${text.slice(0, 300)}`);
    }
    return text ? JSON.parse(text) : null;
  }

  return {
    async select(table, filter) {
      const rows = [];
      for (let offset = 0; ; offset += PAGE_SIZE) {
        const page = await call('GET', `/rest/v1/${table}?select=*&${filter}&limit=${PAGE_SIZE}&offset=${offset}`);
        rows.push(...page);
        if (page.length < PAGE_SIZE) return rows;
      }
    },
    async remove(table, filter) {
      const rows = await call('DELETE', `/rest/v1/${table}?${filter}`, { Prefer: 'return=representation' });
      return rows.length;
    },
    async findAuthUser(email) {
      // The admin API has no reliable exact-email filter, so page through and
      // match. Fine for the user counts a personal/small project has.
      for (let page = 1; ; page++) {
        const body = await call('GET', `/auth/v1/admin/users?page=${page}&per_page=${PAGE_SIZE}`);
        const users = body?.users ?? [];
        const hit = users.find((u) => (u.email ?? '').toLowerCase() === email);
        if (hit) return hit;
        if (users.length < PAGE_SIZE) return null;
      }
    },
    async deleteAuthUser(id) {
      await call('DELETE', `/auth/v1/admin/users/${encodeURIComponent(id)}`);
    },
  };
}

// PostgREST filter values: quote so commas/parens/dots inside a value are literal.
const quote = (v) => `"${String(v).replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
// ilike without wildcards = exact, case-insensitive. Escape the ones in the address.
const exactIlike = (v) => encodeURIComponent(v.replace(/\\/g, '\\\\').replace(/[%_*]/g, '\\$&'));

function stripSecrets(value) {
  if (Array.isArray(value)) return value.map(stripSecrets);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value)
        .filter(([k]) => !SECRET_KEY.test(k))
        .map(([k, v]) => [k, stripSecrets(v)]),
    );
  }
  return value;
}

// ---------------------------------------------------------------------------
// Collect everything that belongs to the subject

async function collect(api, config, email) {
  const authUser = config.needsAuth ? await api.findAuthUser(email) : null;
  const found = {}; // table -> { filter, rows }

  for (const t of config.tables) {
    let filter = null;
    if (t.match.by === 'email') {
      filter = `${t.match.column}=ilike.${exactIlike(email)}`;
    } else if (t.match.by === 'auth_user_id') {
      if (authUser) filter = `${t.match.column}=eq.${encodeURIComponent(authUser.id)}`;
    } else {
      const values = [...new Set(found[t.match.ref.table].rows.map((r) => r[t.match.ref.column]))].filter(
        (v) => v !== null && v !== undefined,
      );
      if (values.length) filter = `${t.match.column}=in.(${encodeURIComponent(values.map(quote).join(','))})`;
    }
    found[t.table] = { filter, rows: filter ? await api.select(t.table, filter) : [] };
  }

  const total = Object.values(found).reduce((n, f) => n + f.rows.length, 0);
  return { authUser, found, empty: total === 0 && !authUser };
}

function printCounts(config, { authUser, found }) {
  const width = Math.max(10, ...config.tables.map((t) => t.table.length));
  for (const t of config.tables) {
    const n = found[t.table].rows.length;
    const action = t.delete ? 'delete' : t.match.by === 'ref' ? 'cascade/keep' : 'keep';
    console.log(`  ${t.table.padEnd(width)}  ${String(n).padStart(5)}  (${action})`);
  }
  if (config.needsAuth) {
    const action = config.auth.delete ? 'delete' : 'keep';
    console.log(`  ${'auth user'.padEnd(width)}  ${String(authUser ? 1 : 0).padStart(5)}  (${action})`);
  }
}

// ---------------------------------------------------------------------------
// Commands

async function runExport(api, config, args) {
  const result = await collect(api, config, args.email);
  if (result.empty) {
    console.log(`No data found for ${args.email}. Nothing written.`);
    process.exit(2);
  }

  const data = {};
  const withheld = [];
  for (const t of config.tables) {
    data[t.table] = result.found[t.table].rows.map((row) => {
      const copy = { ...row };
      for (const c of t.omit) delete copy[c];
      return copy;
    });
    for (const c of t.omit) withheld.push(`${t.table}.${c}`);
  }
  const notes = [...config.notes];
  if (withheld.length) {
    notes.push(`Withheld because they are security credentials, not personal data: ${withheld.join(', ')}.`);
  }

  const doc = {
    subject: args.email,
    generated_at: new Date().toISOString(),
    notes,
    data,
    ...(config.auth.export ? { auth_user: result.authUser ? stripSecrets(result.authUser) : null } : {}),
  };

  const out = resolve(
    args.out ?? `gdpr-export-${args.email.replace(/[^a-z0-9._-]+/g, '_')}-${doc.generated_at.slice(0, 10)}.json`,
  );
  // wx: never overwrite an earlier export; 0600: it is someone's personal data.
  writeFileSync(out, `${JSON.stringify(doc, null, 2)}\n`, { flag: 'wx', mode: 0o600 });

  console.log(`Export for ${args.email}:`);
  printCounts(config, result);
  console.log(`\nWrote ${out}\nSend it only to ${args.email}, then delete the local copy.`);
}

async function runDelete(api, config, args) {
  const result = await collect(api, config, args.email);
  if (result.empty) {
    console.log(`No data found for ${args.email}. Refusing to delete anything.`);
    process.exit(2);
  }

  console.log(`${args.yes ? 'Deleting' : 'Dry run'} for ${args.email}:`);
  printCounts(config, result);
  if (!args.yes) {
    console.log('\nNothing deleted. Re-run with --yes to delete the rows marked "delete".');
    return;
  }

  // Reverse config order: tables that reference earlier ones go first.
  const summary = [];
  for (const t of [...config.tables].reverse()) {
    const f = result.found[t.table];
    if (!t.delete || !f.filter || f.rows.length === 0) continue;
    summary.push([t.table, await api.remove(t.table, f.filter)]);
  }
  if (config.auth.delete && result.authUser) {
    await api.deleteAuthUser(result.authUser.id);
    summary.push(['auth user', 1]);
  }

  console.log('\nDeleted:');
  if (!summary.length) console.log('  nothing (no rows in tables marked "delete")');
  for (const [name, n] of summary) console.log(`  ${name}: ${n}`);
}

const args = parseArgs(process.argv.slice(2));
const config = loadConfig(args.config);
const api = client(loadEnv());

try {
  await (args.command === 'export' ? runExport : runDelete)(api, config, args);
} catch (e) {
  console.error(`Error: ${e.message}`);
  process.exit(1);
}
