# Radicale — calendars, contacts, to-do lists

Self-hosted **CalDAV** (calendars + to-do lists) and **CardDAV** (contacts)
server. Added 2026-09-28 to move calendar and contacts off Google without
Nextcloud.

- **What it is:** a tiny server (~20 MB RAM) that stores `.ics` / `.vcf`
  files. It has only a bare admin page; the **iPhone and Mac built-in
  Calendar, Contacts and Reminders apps are the UI**.
- **Why Radicale and not Nextcloud:** the user doesn't like Nextcloud, and
  only needs sync, not a web suite. Radicale does one job, has nothing to
  maintain, and speaks the open standards, so a future GrapheneOS phone works
  too (DAVx⁵).
- **Exposure:** localhost + Tailscale only — `http://100.81.171.49:5232/`.
  No Cloudflare hostname: this is private data, and the iPhone keeps
  Tailscale on (Connect On Demand). Off Tailscale, sync simply pauses and
  catches up later.
- **Glance:** the **Today** widget (Home, right column) shows today's and
  tomorrow's events and open tasks, from `scripts/utils/calendar-status.sh`
  (cron every 5 min → `~/services/glance/assets/calendar.json`).

## Login

One user, `dziugas`. The password is in `~/.config/homelab/radicale.env`
(`RADICALE_PASSWORD`, chmod 600) — save it to Vaultwarden as *Radicale*
(URL `http://100.81.171.49:5232/`). The server checks a bcrypt hash in
`~/services/radicale/users` (gitignored, never committed).

Show it once to copy into Vaultwarden / the phone:
```bash
grep RADICALE_PASSWORD ~/.config/homelab/radicale.env | cut -d= -f2-
```

Change the password:
```bash
cd ~/services/radicale
read -rsp "New Radicale password: " PW; echo
docker run --rm -e PW="$PW" httpd:2.4-alpine sh -c 'htpasswd -nbB -C 12 dziugas "$PW"' > users
sed -i '' "s|^RADICALE_PASSWORD=.*|RADICALE_PASSWORD=$PW|" ~/.config/homelab/radicale.env; unset PW
docker compose restart radicale
```
Then update it on every device (and in Vaultwarden).

## Collections (created 2026-09-28)

| Name | Path | Holds | Used by |
|---|---|---|---|
| Personal | `/dziugas/personal/` | events (VEVENT) | Calendar |
| Reminders | `/dziugas/reminders/` | to-dos (VTODO) | Reminders |
| Contacts | `/dziugas/contacts/` | contacts (vCard) | Contacts |

Add more calendars from the phone/Mac (they're created on the server) or in
the web page at `http://100.81.171.49:5232/.web/`.

## Set up the iPhone

Tailscale must be on (it is, with Connect On Demand).

1. **Calendar + Reminders:** Settings → **Calendar** → **Accounts** → **Add
   Account** → **Other** → **Add CalDAV Account**.
   - Server: `100.81.171.49:5232`
   - User name: `dziugas`
   - Password: from Vaultwarden
   - Description: `Radicale`
   → Next. If it complains about SSL, tap **Continue** / turn off *Use SSL*
   (traffic is already encrypted inside Tailscale). In the account, make sure
   **Calendars** and **Reminders** are both on.
2. **Contacts:** Settings → **Contacts** → **Accounts** → **Add Account** →
   **Other** → **Add CardDAV Account** → same server, user, password.
3. Make Radicale the default: Settings → Calendar → **Default Calendar** →
   *Personal*; Settings → Contacts → **Default Account** → *Radicale*;
   Settings → Reminders → **Default List** → *Reminders*.

## Set up the Mac

System Settings → **Internet Accounts** → **Add Account** → **Add Other
Account** → **CalDAV account** → Account type **Manual**, user `dziugas`,
password, server `http://100.81.171.49:5232/`. Repeat with **CardDAV
account** for contacts.

## Import your existing data

⚠️ Per the 2026-09-22 check, calendar and contacts live **only on the
iPhone itself** ("On My iPhone"), not in Google — the phone is the only copy.
So **export first**, before changing any sync settings.

**Contacts (iPhone → Radicale):**
1. iPhone Contacts app → **Lists** → *All Contacts* (long-press) → **Export**
   (or select all → Share) → vCard file → AirDrop / save to Files → Mac.
2. Mac Contacts app (with the Radicale CardDAV account added) → select the
   Radicale account → File → **Import…** → the `.vcf`.
3. On the iPhone the Radicale account now shows them; set it as default
   (see above). Keep the exported `.vcf` as a backup.

**Calendar (iPhone → Radicale):** iOS has no bulk export, so go via the Mac:
1. Connect the iPhone to the Mac → Finder → the iPhone → **Info** → tick
   *Sync calendars onto this Mac* → Sync (or AirDrop individual events).
2. Mac Calendar app → select the synced calendar → File → **Export** →
   `.ics`.
3. File → **Import…** → the `.ics` → choose *Personal* (Radicale).
4. Untick the Finder sync afterwards.

**If anything *is* in Google:** Google Calendar (web) → ⚙️ → **Import &
export** → **Export** (one `.ics` per calendar) and contacts.google.com →
**Export** → **vCard** → import on the Mac as above.

**Backup test:** remove and re-add the Radicale account on one device (or add
it on the Mac) and check everything re-downloads — that proves the server has
the data, not just the phone.

## Later: GrapheneOS

Install **DAVx⁵** (F-Droid) → *Login with URL and user name* →
`http://100.81.171.49:5232/` → it syncs calendars, contacts and tasks (tasks
need the **jtx Board** or **Tasks.org** app) into Android's own apps.

## How it works / gotchas

- Config is inline in `docker-compose.yml` (`configs:`), so staging only copies
  that one file. Data: `~/services/radicale/data/collections/` — plain files,
  backed up nightly to R2 with the rest of `~/services`.
- The container isn't `read_only`: Compose's inline `configs:` refuse a
  read-only service. Other hardening stays (all caps dropped except the four
  the entrypoint needs, `no-new-privileges`, 64 MB limit).
- Startup logs warn *"Storage item mtime resolution … RISKY"*. That comes from
  the macOS bind mount's coarse timestamps and only matters if something other
  than Radicale edits the files; nothing does. Harmless here.
- Glance's monitor checks `http://radicale:5232/.web/` over the `radicale`
  Docker network; the Today widget reads a local JSON, never Radicale itself.
- A calendar file (`.ics`) may hold only one event UID — clients handle this;
  hand-made uploads with several events are rejected (400).
