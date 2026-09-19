# CouchDB — Obsidian LiveSync backend

Backing store for the [Self-hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync)
Obsidian plugin. Real-time, end-to-end encrypted vault sync across macOS, iOS and
Android, with no subscription and no Apple dependency.

**Port:** 5984 · **Replaces:** Obsidian Sync (~€4/mo), iCloud

## Why CouchDB and not Syncthing

Syncthing already syncs the vault between the Mac mini and the MacBook and stays
in place for that. It is not the mobile answer while the phone is an iPhone —
iOS background limits make it unreliable. LiveSync talks HTTPS, so it works
everywhere Obsidian runs.

## Setup

```bash
~/.dotfiles/services/setup-services.sh couchdb
cd ~/services/couchdb

# Generate a real password
nano .env            # set COUCHDB_USER + COUCHDB_PASSWORD
# Use a 6-word passphrase, not random characters — you type this on a phone

docker compose up -d
```

Then initialise the single-node cluster (once):

```bash
source .env
curl -X POST http://127.0.0.1:5984/_cluster_setup \
  -H 'Content-Type: application/json' \
  -u "$COUCHDB_USER:$COUCHDB_PASSWORD" \
  -d '{"action":"enable_single_node","bind_address":"0.0.0.0","singlenode":true}'
```

Verify: `curl -u "$COUCHDB_USER:$COUCHDB_PASSWORD" http://127.0.0.1:5984/_up`

## Remote access — both paths are live

| From | URL |
|---|---|
| Anywhere (HTTPS, via the tunnel) | `https://couchdb.peciulevicius.com` |
| On the tailnet | `http://100.81.171.49:5984` |
| On the Mac mini | `http://127.0.0.1:5984` |

Use the public HTTPS URL in the plugin — mobile Obsidian **requires HTTPS**, and
it means sync works with Tailscale off. The tunnel ingress rule lives in
`~/.cloudflared/config.yml`; the DNS record was created with
`cloudflared tunnel route dns <tunnel-id> couchdb.peciulevicius.com`.

**This is a sync endpoint, not a notes site.** Opening the hostname in a browser
gives CouchDB's API and Fauxton admin UI — not your notes. Obsidian is still the
app on each device; the tunnel only carries the sync traffic.

⚠️ **Deliberately *not* behind Cloudflare Access.** An Access policy that
challenges the browser also blocks the Obsidian plugin, which cannot complete an
interactive login. The gate is CouchDB's own auth: `require_valid_user = true`
plus a six-word passphrase (~62 bits), and anonymous requests get a 401 —
verified from the public hostname. If you later want Access in front, it has to
be a **service token** whose `CF-Access-Client-Id` / `CF-Access-Client-Secret`
the plugin sends as custom headers.

## Connecting Obsidian

1. Install **Self-hosted LiveSync** from Community Plugins on each device
2. Server URI `https://couchdb.peciulevicius.com`, the username/password from
   `~/services/couchdb/.env` (user `peciulevicius`), database `obsidian`
   (already created)
3. Turn **End-to-End Encryption** on and set a passphrase — the same one
   everywhere. Without it the server sees your notes in the clear.
4. ⚠️ Start on the **Mac mini**, the device holding the real vault, and let it
   finish uploading before connecting anything else. LiveSync asks which side is
   the source of truth on first connect; answering with an empty device wipes
   the vault. A snapshot is in `~/backups/vault-snapshots/` if that happens.

**Syncthing stays as it is.** It handles the Mac mini ↔ MacBook leg fine.
LiveSync exists for the iPhone, which Syncthing has never served well.
Don't point both at the same vault on the same device.

Back the vault up before the first connection:

```bash
tar -czf ~/backups/vault-snapshots/obsidian-vault-$(date +%Y%m%d-%H%M).tar.gz \
  -C ~ obsidian-vault
```

## Config

The `[cors]` block in `local.ini` is not optional — mobile Obsidian runs from
the `app://obsidian.md` origin and cannot connect without it.

⚠️ **Do not bind-mount `local.ini` straight into `/opt/couchdb/etc/local.d/`.**
The stock entrypoint runs

```bash
find /opt/couchdb \! \( -user couchdb -group couchdb \) -exec chown -f couchdb:couchdb '{}' +
```

under `set -e`. On macOS a bind-mounted file appears root-owned and cannot be
chowned, so `find` exits non-zero and the container dies — **with completely
empty `docker logs`**, which makes it look like an image problem rather than a
mount problem. The compose file therefore mounts the file at `/config/local.ini`
(outside the scanned tree) and copies it into place in the entrypoint.

## Backup

`./data` is on the internal SSD deliberately — never put a database on the NAS
SMB mount. The directory is covered by `services/rclone/rclone-backup.sh` along
with the rest of `~/services/`.
