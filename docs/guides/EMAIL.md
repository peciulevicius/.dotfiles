# Email — running your own domain's mail

**Status (2026-09-25):** Purelymail bought · all Purelymail DNS records in place except MX · Cloudflare Email Routing still receiving until it is disabled in the dashboard
**Domain:** `peciulevicius.com` (registered + DNS at Cloudflare)
**Guide owner:** Gap 1 of [DEGOOGLE.md](./DEGOOGLE.md)

This is the from-scratch runbook. If you are reading it a year from now with a
fresh machine and no memory of the setup, start at *How email actually works*
and follow it top to bottom.

---

## 1. How email actually works (the 90 seconds that prevents every mistake)

Four moving parts. Confusing them is the source of nearly every "why is my mail
broken" afternoon.

| Part | What it does | Where it lives |
|---|---|---|
| **Domain** | The name you own — `peciulevicius.com` | Registrar (Cloudflare) |
| **MX records** | DNS saying *"mail for this domain goes to that server"* | Cloudflare DNS |
| **Mailbox provider** | Actually stores and serves the mail | Purelymail |
| **Client** | Reads it — Apple Mail, iPhone, `kindle_sync.py` | Your devices |

**Switching provider = editing MX records.** That is the entire migration. The
domain never moves, the address never changes, and nothing else in the stack
knows or cares.

> ⚠️ **Never self-host the mail server.** Residential IP, blocklists, and a
> blocked port 25 mean outbound mail lands in spam or nowhere. This is a
> standing decision — do not relitigate it. Rent the mailbox, own the domain.
> Owning the *domain* is what gives you portability: providers become
> interchangeable.

### Receiving vs sending — the distinction that matters here

- **Receiving** needs only MX records. Cloudflare Email Routing does this free.
- **Sending as you** needs SMTP plus SPF/DKIM/DMARC so other servers believe
  the mail is really from your domain. **Email Routing cannot do this.**

That gap is the whole reason to buy a mailbox: today mail arrives at
`@peciulevicius.com` but every reply goes out as `@gmail.com`.

---

## 2. What depends on email in this homelab

Audited 2026-09-21. ⚠️ **Three things depend on Gmail, and two of them store
their SMTP settings in a SQLite database, not in environment variables** — an
`env`-based check reports a clean bill of health and is wrong.

| Thing | Uses email | Stored where | Effect of the migration |
|---|---|---|---|
| `pkm/kindle_sync.py` | **IMAP** `imap.gmail.com` | `pkm/config.py` (gitignored) | 3-line change |
| **Calibre-Web** Send-to-Kindle | **SMTP** `smtp.gmail.com:587` | ⚠️ `/config/app.db` | Re-enter in the UI |
| **Uptime Kuma** alerts | **SMTP** `smtp.gmail.com` | ⚠️ `/app/data/kuma.db` | Re-enter in the UI |
| Uptime Kuma Discord alerts | ❌ webhook | — | none |
| `scripts/lib/notify.sh` | ❌ webhook | — | none |
| Vaultwarden + 39 others | ❌ none | — | none |

🔴 **Revoking the Gmail app password breaks Calibre-Web's Send-to-Kindle and
Uptime Kuma's email alerts** unless both are repointed first. Kuma also notifies
over Discord, so it stays audible either way; Calibre-Web has no fallback and
fails silently.

### How to audit this properly

Environment variables are only half the picture:

```bash
# 1. env-configured senders
for c in $(docker ps --format '{{.Names}}'); do
  e=$(docker exec "$c" sh -c 'env 2>/dev/null | grep -iE "^(SMTP|MAIL)_" | cut -d= -f1' 2>/dev/null)
  [ -n "$e" ] && echo "$c: $e"
done

# 2. database-configured senders — the ones step 1 misses
docker exec calibre_web sh -c 'cat /config/app.db' > /tmp/cw.db &&   sqlite3 /tmp/cw.db "select mail_server,mail_port,mail_login from settings;"
docker exec uptime_kuma sh -c 'cat /app/data/kuma.db' > /tmp/k.db &&   sqlite3 /tmp/k.db "select name,active,config from notification;"
```

> 💡 Services here notify over **Discord** by preference. When you repoint these
> two, consider whether they need email at all — Kuma's Discord notification
> already covers alerting, and Calibre-Web's SMTP exists only to push books to
> the Kindle, which the jailbreak's OPDS route now largely replaces.

---

## 3. Provider choice — decided, don't re-research

**Purelymail, $10/yr (~€0.77/mo).** Verified 2026-09-21.

| | **Purelymail** | Migadu Micro | Mailbox.org | Proton | Tuta |
|---|---|---|---|---|---|
| Price/yr | **$10** | $19 | €12 | €48+ | €36+ |
| Custom domain | ✅ | ✅ | ❌ on €1 tier | ✅ | ✅ |
| **Native IMAP** | ✅ | ✅ | ✅ | ❌ Bridge only | ❌ none |
| Domains/users | **unlimited, no per-user fee** | limited | 1 | per-user | per-user |
| Catch-all | ✅ | ✅ | ✅ | limited | limited |
| Send limit | none stated | ⚠️ **20/day** | fine | fine | fine |

**The hard requirement is native IMAP**, because `kindle_sync.py` and
Odysseus's mail client both speak plain IMAP and nothing else:

- ❌ **Proton** — IMAP only through Bridge, a desktop GUI app. A headless Mac
  mini cron job cannot rely on it.
- ❌ **Tuta** — no IMAP at all, by design.
- ❌ **Zoho free** — webmail only.
- ❌ **Migadu Micro** — works, but **20 outgoing messages/day** is a real ceiling.
- ❌ **Mailbox.org €1 tier** — no custom domain; the tier that has one costs more.
- ❌ **Posteo** — never supports custom domains, by design.
- ❌ **Fastmail** — fine technically, ~$60/yr blows the ~€1/mo budget.

⚠️ **Budget ceiling is ~€1/month.** That single constraint eliminates most of
the popular r/degoogle recommendations. They are not wrong, they are out of scope.

**Storage caveat:** $10/yr covers ~3 GB, then pay-as-you-go. Ample for live
mail, *not* an archive for 15 years of Gmail. Keep the bulk Takeout export on
disk or in Paperless — do not try to import it into the mailbox.

---

## 4. Signup — the one confusing step

The signup form shows a domain dropdown:

```
purelymail.com · cheapermail.com · placeq.com · rethinkmail.com · worldofmail.com
```

⚠️ **This is NOT your mail domain.** It is the address of the **account admin
user** — the login that manages billing, domains and mailboxes. Your real
identity (`@peciulevicius.com`) is added afterwards, in the admin portal.

- Pick any of them; `purelymail.com` is fine. It is a management login you will
  rarely type.
- 💡 **Choose a longer username.** Shared-domain names carry a small
  anti-squatting charge of **$0–$1.20/yr scaled by length** — short names cost
  more. A long one is free.
- Users on **your own** domain have **no per-user charge** at all.

Then: **Account Admin → Domains → Add New Domain →** `peciulevicius.com`.

---

## 5. DNS records

Seven records in Cloudflare DNS. ⚠️ Set every one of these to **DNS only (grey
cloud)** — proxying mail records through Cloudflare breaks them.

| # | Type | Host | Value | Priority |
|---|---|---|---|---|
| 1 | MX | `@` | `mailserver.purelymail.com` | **50** |
| 2 | TXT | `@` | `v=spf1 include:_spf.purelymail.com ~all` | — |
| 3 | TXT | `@` | *ownership token from the portal* | — |
| 4 | CNAME | `purelymail1._domainkey` | `key1.dkimroot.purelymail.com` | — |
| 5 | CNAME | `purelymail2._domainkey` | `key2.dkimroot.purelymail.com` | — |
| 6 | CNAME | `purelymail3._domainkey` | `key3.dkimroot.purelymail.com` | — |
| 7 | CNAME | `_dmarc` | `dmarcroot.purelymail.com` | — |

What each is for:

- **MX** — where mail is delivered. This is the switch.
- **SPF** — lists which servers may send as your domain.
- **DKIM** (3 CNAMEs) — cryptographic signature; Purelymail rotates keys behind
  the CNAMEs so you never touch them again.
- **DMARC** — tells receivers to trust SPF+DKIM and what to do on failure.

Without 2/4/5/6/7, mail you send lands in spam. They are not optional.

### ⚠️ Turn OFF Cloudflare Email Routing first

Email Routing installs **its own MX records**. Leaving it on means two providers
claim your mail and delivery becomes non-deterministic.

**Cloudflare → `peciulevicius.com` → Email → Email Routing → disable**, confirm
its MX records are gone, *then* add Purelymail's.

This step is a **dashboard click, not an API call**. While Email Routing is on,
the API refuses to add or delete any MX record (`890190` / `1046 — managed by
Email Routing`), and the `/email/routing/disable` endpoint rejects a token that
only has *Email Routing Rules: Edit* (`10000 Authentication error`). Found
2026-09-25: every other record went in via the API, the MX swap waited for the
click. Everything except MX can go in first — the ownership TXT is all
Purelymail needs to accept the domain.

---

## 6. Catch-all — why the credential sweep gets cheap

Enable catch-all so **any** `*@peciulevicius.com` lands in one mailbox without
being created first.

This means during the service-by-service pass you can type `immich@`,
`linkwarden@`, `jellyfin@` straight into each service and they work instantly.
Two payoffs:

1. **Leak attribution** — spam to `immich@` means Immich leaked it. Nobody else
   was ever given that address.
2. **Surgical revocation** — a compromised alias gets a routing rule to /dev/null
   without touching anything else.

> ⚠️ Catch-all also means spammers guessing `info@`, `admin@`, `sales@` reach
> you. If that gets noisy, switch to explicitly-created aliases — the addresses
> you already use keep working.

---

## 7. Migration runbook

⚠️ **Do this on an evening you are not expecting a password reset.** MX changes
propagate over minutes to hours, and mail sent during the gap can bounce.

- [ ] **1. Sign up** (§4). Long username on a shared domain.
- [ ] **2. Add `peciulevicius.com`**, get the ownership token.
- [ ] **3. Create the real mailbox** — `dziugas@peciulevicius.com`.
      Password generated in Bitwarden, saved with the autofill URL.
- [ ] **4. Disable Cloudflare Email Routing**, verify its MX records are gone.
- [ ] **5. Add all seven records** (§5), grey cloud.
- [ ] **6. Verify** the domain in the portal (§8).
- [ ] **7. Enable catch-all.**
- [ ] **8. Test both directions** — send in from Gmail, reply out, confirm the
      reply's `From:` is `@peciulevicius.com`.
- [ ] **9. Check the SPF/DKIM/DMARC verdict** — mail yourself at Gmail and read
      "Show original", or use <https://www.mail-tester.com> and target 9+/10.
- [ ] **10. Repoint `kindle_sync.py`** (§9).
- [ ] **11a. Repoint Calibre-Web** — Admin → Edit E-mail Server Settings →
      `smtp.purelymail.com:465` (SSL), your Purelymail address + password.
      Use the **Send test email** button; it fails silently otherwise.
- [ ] **11b. Repoint Uptime Kuma** — Settings → Notifications → the `smtp` one →
      same server details, then **Test**. (Its Discord notification is
      unaffected and keeps working throughout.)
- [ ] **11c. Revoke the Gmail app password** at
      <https://myaccount.google.com/apppasswords> — only after 10, 11a and 11b
      are each tested green.
- [ ] **12. Set up the Gmail funnel** (§10).
- [ ] **13. Add to Apple Mail / iPhone** — IMAP `imap.purelymail.com:993` (TLS),
      SMTP `smtp.purelymail.com:465` (TLS).

### Rollback

If mail stops arriving and the cause is not obvious: **re-enable Cloudflare
Email Routing**. It restores its own MX records and forwarding to Gmail resumes.
You lose nothing but the sending identity, and you can retry another evening.

> 💡 Keep the Gmail forward alive through the whole migration. There is no
> reason to cut it early, and it is the safety net that makes step 4 reversible.

---

## 8. Verification

```bash
# MX must be Purelymail, and nothing else
dig +short MX peciulevicius.com

# SPF present
dig +short TXT peciulevicius.com | grep spf

# DKIM + DMARC resolve
dig +short CNAME purelymail1._domainkey.peciulevicius.com
dig +short CNAME _dmarc.peciulevicius.com

# IMAP reachable and credentials valid (prompts for the password)
python3 - <<'PY'
import imaplib, getpass
m = imaplib.IMAP4_SSL("imap.purelymail.com", 993)
m.login(input("address: "), getpass.getpass("password: "))
print(m.list()[1][:5]); m.logout()
PY
```

⚠️ **Two MX records from different providers = broken mail.** If `dig MX` shows
anything from Cloudflare's Email Routing alongside Purelymail, step 4 did not
take. Fix that before debugging anything else.

---

## 9. Repointing `kindle_sync.py`

`pkm/config.py` is **gitignored and lives only on the Mac mini** — it is not in
this repo and never has been (verified: the committed template always had an
empty password). Edit it in place:

```python
IMAP_SERVER   = "imap.purelymail.com"
IMAP_PORT     = 993
EMAIL_ADDRESS = "kindle@peciulevicius.com"
EMAIL_PASSWORD = "..."   # Purelymail password, from Bitwarden
```

Then point the Kindle's *Share → Searchable PDF* destination at
`kindle@peciulevicius.com` and run one sync by hand before trusting the cron.

> ⚠️ The Scribe's only provider-neutral export route is **email** — its
> Drive/OneDrive options are 2025+ models only and are the services being left.
> So this IMAP path is load-bearing for the whole notes pipeline, not a
> convenience. Amazon's share links expire after **7 days**, which is why the
> job runs hourly.

---

## 10. The Gmail funnel — never delete, stop using

⚠️ **Never delete the Google account.** It breaks every remaining "Sign in with
Google" login and frees the address for someone else to register in your name.

The end state is Gmail as a **write-only-to-you funnel**:

```
unknown senders ─→ @gmail.com ─(forward)─→ @peciulevicius.com   ← you read here
                                           you reply FROM here  ← your identity
```

- [ ] Gmail → Settings → **Forwarding and POP/IMAP** → forward to
      `@peciulevicius.com`, **keep Gmail's copy** (belt and braces)
- [ ] Set an auto-reply for a few months: *"I now use
      `peciulevicius@peciulevicius.com` — please update your records."*
- [ ] Stop creating **any** new account with the Gmail address
- [ ] Never send *from* Gmail again — that is what re-teaches contacts the wrong
      address

### The unknown-contacts problem

You cannot enumerate who has your Gmail address. Some are known (the Lithuanian
military, banks, employers); most are not, and you only discover them when they
write.

**Do not try to solve this up front — it is not solvable.** Solve it over time:

1. **Forwarding means you never miss anything**, indefinitely. There is no
   deadline and no risk in waiting.
2. **Tell the ones that matter, deliberately** — anything legal, financial,
   medical or governmental. Keep a list as you go.
3. **Let the rest arrive.** Each forwarded mail identifies a contact who has the
   old address. Update that one, move on.
4. **Re-evaluate in a year.** Whatever still arrives at Gmail is the true
   remaining set, and it will be short.

> 💡 This is why the funnel is permanent, not transitional. Gmail keeps
> receiving forever; you simply stop *being* a Gmail user.

| Priority | Who | When |
|---|---|---|
| 🔴 High | Military, banks, government, employer, insurance | Deliberately, week 1 |
| 🟡 Medium | Services with a login (see the credential pass) | Same pass as the password change |
| 🟢 Low | Everyone else | Reactively, as mail forwards in |

---

## 11. Do it in ONE pass with the credential migration

Both the password change and the address change need you logged into the same
~14 remaining services. **Doing them separately means 28 logins instead of 14.**

Per service, one visit:

1. Log in
2. Generate a password in Bitwarden, save with the **autofill URL**
3. Change the address to `<service>@peciulevicius.com`
4. Confirm the verification mail arrives (proves catch-all works)
5. Tick it off in [../CREDENTIAL_MIGRATION.md](../CREDENTIAL_MIGRATION.md)

⚠️ **Change Bitwarden/Vaultwarden's own address last.** It is the account that
recovers all the others; do not move it while you still depend on it to log in.

⚠️ **Google Authenticator migration comes first, before any of this.** Its TOTP
seeds sync to the account being left, so it is an active lockout risk. Move to
Ente Auth or Vaultwarden — see [DEGOOGLE.md](./DEGOOGLE.md).

---

## 12. Known blockers, so they are not rediscovered

| Symptom | Cause | Fix |
|---|---|---|
| Mail silently stops | Two providers' MX records coexist | Disable Email Routing (§5) |
| Sent mail lands in spam | SPF/DKIM/DMARC missing or proxied | All 7 records, **grey cloud** |
| MX record won't save | Cloudflare proxy (orange cloud) on | Mail records are **DNS only** |
| `kindle_sync.py` stops | Still on the revoked Gmail app password | §9 |
| Calibre-Web Send-to-Kindle silently fails | SMTP still Gmail, in `app.db` not env | §7 step 11a |
| Uptime Kuma email alerts stop | SMTP still Gmail, in `kuma.db` not env | §7 step 11b |
| An `env` audit says "nothing uses email" | Kuma + Calibre-Web store SMTP in SQLite | §2, run **both** checks |
| Can't find a mailbox for the signup dropdown | Expecting your own domain there | It's the *admin user* (§4) |
| Storage full fast | Tried to import Gmail Takeout | Keep the archive on disk (§3) |
| Catch-all flooded | Spammers guessing `admin@`, `info@` | Switch to explicit aliases (§6) |

---

## See also

- [DEGOOGLE.md](./DEGOOGLE.md) — the wider effort; email is Gap 1
- [DEGOOGLE_ALTERNATIVES.md](./DEGOOGLE_ALTERNATIVES.md) — per-service replacements
- [../CREDENTIAL_MIGRATION.md](../CREDENTIAL_MIGRATION.md) — the one-pass checklist
- [NOTES.md](./NOTES.md) — why the IMAP requirement is load-bearing
- [../HOME_SERVER_TODO.md](../HOME_SERVER_TODO.md) — live task list
