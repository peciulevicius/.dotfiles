# balances-ui

One-page form to edit the account balances on the Glance **Finance** tab
(Accounts card → "Edit balances"). Stdlib Python, no dependencies.

- URL: `http://100.81.171.49:8095` (Tailscale) or `http://127.0.0.1:8095`.
- Reads/writes `~/ai-memory/finance/balances.json`, the same file the Finance
  Manager agent edits. Only fields you changed are written (and their
  `updated` date), so a simultaneous agent edit isn't overwritten.
- `finance-refresh-on-change.sh` (cron, every 2 min) notices the file changed
  and rebuilds Glance's `finance.json`.
- Account names, the credit flag and the emergency list are not editable here;
  change them in `balances.json` or via the agent.

## Why it exists
Glance has no write path; widgets are read-only. A separate tiny service was
chosen over patching Glance. There is **no login**: access control is the
Tailscale-only port binding, plus a same-origin check on POST. Don't expose it
through the Cloudflare tunnel.

## Deploy
`services/setup-services.sh`, then `cd ~/services/balances-ui && docker compose up -d --build`.
The container runs as uid 1000; if saving fails with a permission error, check
`ls -ln ~/ai-memory/finance` (the directory must be writable by that uid).
