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
openssl rand -base64 32
nano .env            # set COUCHDB_USER + COUCHDB_PASSWORD

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

## Remote access

Mobile Obsidian **requires HTTPS** — plain HTTP will not connect. Add to
`~/.cloudflared/config.yml`:

```yaml
  - hostname: couchdb.peciulevicius.com
    service: http://localhost:5984
```

then `cloudflared tunnel route dns <tunnel> couchdb.peciulevicius.com` and
restart the tunnel.

⚠️ **Cloudflare Access caveat:** an Access policy that challenges the browser
will also block the Obsidian plugin, which cannot complete an interactive login.
Either use an Access **service token** that the plugin sends as a header, or keep
the database Tailscale-only and skip the public hostname. CouchDB is not exposed
unauthenticated either way — `require_valid_user = true` is set in `local.ini`.

## Connecting Obsidian

1. Install **Self-hosted LiveSync** from Community Plugins on each device
2. Server URI `https://couchdb.peciulevicius.com`, the username/password from `.env`,
   database name e.g. `obsidian`
3. Turn **End-to-End Encryption** on and set a passphrase — the same one everywhere
4. ⚠️ On the **first** device, choose it as the source of truth and let it upload.
   Only then connect the others. Getting this backwards can overwrite a vault.

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
