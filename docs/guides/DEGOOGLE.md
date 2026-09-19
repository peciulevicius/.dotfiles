# Degoogle Guide

Replace Google services with self-hosted or privacy-respecting alternatives.

Companions: [SELF_HOSTED_AI.md](SELF_HOSTED_AI.md) covers the AI half.
[DEGOOGLE_ALTERNATIVES.md](DEGOOGLE_ALTERNATIVES.md) is the annotated
replacement list — **check it before swapping any individual service.**

---

## Read this first — you are further along than you think

PewDiePie's *"I'm DONE with Google"* is 22 minutes of a guy discovering
Vaultwarden, Nextcloud, Tailscale, per-service subdomains and a home server.
**You finished all of that months ago.** His setup is a Raspberry Pi 5 and a
Steam Deck; yours is a Mac mini M4 with 42 containers and an 11TiB RAID 5 NAS.

So don't restart the journey from step one. Here is the honest scoreboard:

| What he did | Your status |
|---|---|
| Self-hosted password manager (Vaultwarden) | ✅ Running |
| Self-hosted files/Drive replacement | ✅ Nextcloud + Syncthing + NAS |
| Self-hosted notes (Joplin) | ✅ Obsidian + Syncthing |
| Self-hosted photos | ✅ Immich (he didn't even get here) |
| Own domain, per-service subdomains | ✅ `*.peciulevicius.com` via Cloudflare Tunnel |
| Tailscale + zero trust + fail2ban | ✅ Tailscale + Cloudflare Access |
| Calendar / Contacts / Docs off Google | ⚠️ Nextcloud is running, **not migrated** |
| Search engine | ⚠️ Check your default |
| Browser | ⚠️ Brave is installed, is it the default? |
| **Email off Gmail** | ❌ **Not started — the real gap** |
| **Phone OS** | ❌ iPhone 13 mini, fully Apple/Google |
| Local AI | ❌ Tried Ollama, removed for RAM — see AI guide |
| Maps | ❌ Still Google |

**The remaining work is four things: email, phone, calendar/contacts, AI.**
Everything below that line is already done. Skip to the section you need.

---

## Replacement Map

| Google Service | Self-Hosted | Hosted Alternative |
|---------------|------------|-------------------|
| Google Photos | Immich ✅ | — |
| Google Drive | Nextcloud ✅ | Proton Drive |
| Google Docs | Nextcloud + Collabora | Notion, Coda |
| Gmail | *don't* — see below | Purelymail, Migadu, Fastmail, Proton |
| Google Calendar | Nextcloud Calendar | Proton Calendar, Fastmail |
| Google Contacts | Nextcloud Contacts | Fastmail |
| Chrome Sync | — | Firefox Sync |
| Google Password Manager | Vaultwarden ✅ | Bitwarden Cloud |
| YouTube | — | FreeTube / Grayjay (clients, not replacements) |
| Google Maps | — | Apple Maps, OsmAnd, Organic Maps |
| Google Analytics | PostHog | Plausible Cloud |
| Google Search | — | DuckDuckGo, Kagi |
| Google Fonts | — | bunny.net/fonts, self-host |
| Google News | FreshRSS ✅ | — |
| Google Home | — | Home Assistant |
| Google/ChatGPT AI | Odysseus + local models | see [SELF_HOSTED_AI.md](SELF_HOSTED_AI.md) |

---

## Gap 0 — Accounts, logins and 2FA (do this FIRST)

This is the part that actually bites, and it's where people lock themselves out.

### ⚠️ Google Authenticator is the highest-priority item in this whole guide

You have it on your phone. It holds the 2FA codes for who-knows-how-many
accounts, and modern versions **sync to your Google account**. That means your
2FA — the thing protecting everything else — currently depends on the exact
account you're trying to leave.

If you lose that account or that phone before migrating, you are locked out of
every service whose TOTP lives there. **Do this first, before any email change.**

- [ ] Google Authenticator → ⋯ → **Transfer accounts → Export accounts**.
      It produces QR codes containing all your TOTP seeds.
- [ ] Import them into a replacement (options below)
- [ ] **Verify a few logins actually work** with the new app before deleting anything
- [ ] Keep Google Authenticator installed but unused for a month as a safety net

**Where to put them:**

| Option | Verdict |
|---|---|
| **Ente Auth** | ✅ **Recommended.** Open source, E2E encrypted, free, cross-platform (iOS + Android + desktop), works on GrapheneOS. Keeps 2FA *separate* from your passwords. |
| **Vaultwarden** (yours) | ✅ Works, and **self-hosting unlocks Bitwarden's premium TOTP for free**. But storing codes beside passwords means one compromised vault = both factors gone. Convenient; slightly weaker. |
| Aegis | ✅ Excellent, Android-only — an option later if you go Pixel |

Pick Ente Auth if you want it done properly, Vaultwarden if you value having
everything in one place and accept the trade.

### "Sign in with Google" — the real lock-in

Two different things are tangled together in your password manager:

**1. Accounts where Gmail is just the username.** `d…@gmail.com` + a password.
These are easy — the login keeps working forever, and you change the email
address at each service whenever you get round to it. No urgency.

**2. Accounts using "Sign in with Google" (OAuth).** These have **no password of
their own** — Google *is* the login. If the Google account ever goes away, so
do they, and there's often no recovery path.

- [ ] List them: Google Account → **Security** → *"Your connections to
      third-party apps & services"*. Every entry there is a dependency.
- [ ] For each one that matters: log in, go to account settings, **set a
      password**, then change the email to your new address. Most services
      support this — it converts OAuth into a normal login you control.
- [ ] For the ones that don't matter, leave them. They'll keep working.

### Never delete the Google account

Worth stating plainly, because "delete Google" sounds like the goal:

- Deleting it **breaks every remaining "Sign in with Google" account**, often
  irrecoverably
- It frees `dziugaspeciulevicius@gmail.com` for someone else to register — who
  could then attempt password resets on accounts you forgot to migrate
- It costs you nothing to keep a dormant, logged-out account

**The goal is to stop *using* Google, not to delete the account.** Strip it
back to an empty shell that forwards mail and anchors old OAuth logins.

### Will mail still go to the Gmail address? Yes — and here's how to redirect it

Every service you've ever signed up for still has `…@gmail.com` on file. That
doesn't change until you change it at each one. But you don't have to read two
inboxes while you work through them.

**Phase A — new address forwards *to* Gmail** (Cloudflare Email Routing).
You start handing out `dziugas@peciulevicius.com` immediately, but keep reading
everything in Gmail. Nothing changes about your daily habits. Zero risk.

**Phase B — flip it: Gmail forwards *to* the new address.** Once your real
mailbox exists:

- [ ] Gmail → Settings → **Forwarding and POP/IMAP** → add forwarding address →
      verify → **Forward a copy of incoming mail to** your new address
- [ ] Choose **"keep Gmail's copy in the Inbox"** — belt and braces during transition
- [ ] Gmail → Settings → Accounts → set the new address as the default
      **"Send mail as"** so replies go out from the right place

From that moment **everything lands in the new inbox**, regardless of which
address the sender used. You read one inbox. Old accounts keep working
untouched.

**Phase C — update accounts gradually.** Sort Vaultwarden by importance and do
5–10 a day. Banks, Apple ID, GitHub, Cloudflare, Stripe first.

**Phase D — after ~6 months** of nothing important arriving only at Gmail, stop
the forwarding, set a vacation responder pointing at the new address, and let
the account go dormant. **Don't delete it.**

### Your phone's Google apps — what each becomes

| App | Replacement | Notes |
|---|---|---|
| **Authenticator** | **Ente Auth** | ⚠️ Do this first — lockout risk |
| **Gmail** | Purelymail via Apple Mail | After the migration above |
| **Calendar** | Nextcloud Calendar (CalDAV) | Gap 3 — already running |
| **Drive** | Nextcloud | Already running |
| **Chrome** | Brave or Safari | Already installed on your Mac |
| **Maps** | Apple Maps / Organic Maps | Accept some loss — see below |
| **Translate** | Apple Translate, or DeepL | DeepL is better for Lithuanian |
| **Sheets / Slides** | Nextcloud Office (OnlyOffice) | Or Apple Numbers/Keynote |
| **Meet** | Jitsi (self-hostable) | Keep for work if others use it |
| **Home** | Home Assistant | Only if you have smart devices |

Delete them in that order — Authenticator is the one with real risk attached;
the rest are just habit.

---

## Gap 1 — Email (the only genuinely unfinished one)

### How email actually works

Worth spelling out, because it drives every decision below.

> **What `pkm/kindle_sync.py` is, since it keeps driving these decisions:** you
> write notes on the Kindle Scribe, share them as a Searchable PDF to your own
> email address, and an **hourly cron job** fetches those Amazon emails over
> **IMAP**, extracts the text, and files each notebook into
> `📥 Imports/` in your Obsidian vault. It has run since May 2026 and logs to
> `~/logs/kindle-sync.log`. It authenticates with a Gmail app password in
> `pkm/config.py`. **Plain IMAP is the only way it can reach a mailbox** — which
> is why a provider without IMAP silently kills this automation.

- **Your address is yours because the *domain* is yours.** `dziugas@peciulevicius.com`
  belongs to you forever. Providers are interchangeable plumbing behind it.
- **MX records** (DNS, in Cloudflare) say *"mail for this domain goes to that server."*
  Switching provider = editing MX records. That is the whole migration.
- **SPF / DKIM / DMARC** are TXT/CNAME records that prove outbound mail is
  genuinely authorised by you. Without them Gmail and Outlook bin your mail.
- `mail.peciulevicius.com` is just a *hostname*. You don't need one with a
  hosted provider — it's only relevant if you run the mail server yourself.

**The single highest-leverage move is getting onto your own domain.** Which
provider sits behind it matters far less, and can change later for free.

### Do NOT self-host the mail server

You asked about "a service running" on the Mac mini. Don't. Mail is the one
service where self-hosting is actively worse:

- Residential IPs sit on Spamhaus PBL by default — your mail silently lands in
  spam at Gmail and Outlook, and **you never find out**.
- Most ISPs block outbound port 25 entirely.
- You can't set reverse DNS on a residential connection, and receivers check it.
- Every other service here degrades gracefully when the Mac mini is down.
  A mail server that's down **bounces mail you never learn about**.
- Note PewDiePie didn't self-host mail either — he bought a domain and paid a
  provider. That's the correct call.

Self-hosting mail is a fine hobby project on a VPS with a clean IP. It is not
a way to receive your bank's 2FA codes.

### Step 1 — Free, today: Cloudflare Email Routing

You already run `peciulevicius.com` on Cloudflare. Email Routing is **free,
unlimited addresses, ~15 minutes**, and it gets you onto your own domain
immediately without choosing a provider or paying anything.

- [ ] Cloudflare dashboard → `peciulevicius.com` → **Email** → Email Routing → enable
- [ ] Let it add the MX + SPF records automatically
- [ ] Create `dziugas@peciulevicius.com` → forwards to your current Gmail
- [ ] Add a catch-all → same destination (so nothing is ever lost)
- [ ] Create throwaway aliases per service: `bank@`, `shopping@`, `github@`.
      When one starts getting spam you know exactly who sold you out, and you
      delete just that alias.

From this moment you start **giving out the new address everywhere**, while
still reading mail in Gmail. Nothing breaks, nothing costs money, and every
future provider switch is a DNS edit.

**Limitation to understand:** Email Routing only *receives*. Replying still
goes out through Gmail unless you configure "Send mail as", which keeps Google
in the loop. That's acceptable for a transition phase — not as the end state.

### Step 2 — When ready to actually leave: pick a mailbox

Your requirement is *"easy access on my phone and every other device."* That
single line does most of the filtering: it means **native IMAP** (so any client
on any OS works) or genuinely good first-party apps on every platform.

Truly free + own domain + real IMAP no longer exists — Zoho's free tier is
webmail-only, which would break `pkm/kindle_sync.py`. But it gets close to free.

| Provider | Cost/yr | IMAP/SMTP | Apps | Watch out for |
|---|---|---|---|---|
| **Fastmail** | ~$60 | ✅ native + JMAP | Excellent iOS/Android/web | Australian, not E2E |
| **Migadu Micro** | $19 | ✅ native | None — bring your own client | **20 outgoing msgs/day cap** |
| **Purelymail** | ~$10 | ✅ native | None | 3GB on the base tier; tiny indie operation |
| **MXroute** | $59 | ✅ native | None | Unlimited domains + mailboxes, flat fee |
| **Proton Mail Plus** | ~$50 | ⚠️ **Bridge only** | Excellent, all platforms | 15GB, 1 custom domain |
| ~~iCloud+~~ | ~€12 | ✅ native | — | ❌ **Rejected** — subscription (already cancelled) + Apple lock-in |
| **Tuta** | ~$36 | ❌ **none** | Own apps only | No IMAP at all — rules it out |

#### The three that actually deserve consideration

**Fastmail — the "just works everywhere" pick.** Native IMAP *and* JMAP, strong
first-party apps on every platform, unlimited aliases, masked email. Critically
for you, its **CalDAV/CardDAV is best-in-class — it could replace Nextcloud
Calendar + Contacts entirely**, closing Gap 3 at the same time. It's the most
expensive of the sane options at ~$60/yr and it's the least "de-Googled" in
spirit (Australian company, no E2E). But it is the one that will never make you
fight your own email.

**Migadu Micro or Purelymail — the cheap picks.** Both ~€1–2/month, both plain
IMAP so every client and `kindle_sync.py` work unchanged. Neither has apps; you
use Apple Mail, Thunderbird, or whatever you like. **Migadu Micro's 20
outgoing-messages/day cap is a real limit** — fine for personal mail, painful if
you ever do anything bursty. Purelymail's base tier is only 3GB, so check your
Gmail archive size before committing.

**iCloud+ — ruled out.** Custom domain email is included with any iCloud+ tier
(~€0.99/mo) and it does work via app-specific password, on Android too. But
**the iCloud subscription was cancelled in early 2026** — the NAS and Mac mini
exist precisely to avoid monthly fees — and it would deepen Apple lock-in right
as a Pixel is under consideration. Listed only so it isn't re-proposed.

#### "But r/degoogle recommends Proton and Tuta"

They do, and they're not wrong — they're answering a different question. The
subreddit optimises for **FOSS purity and privacy ideology**. Two extra
constraints apply here that flip the answer:

1. **Native IMAP is mandatory** — `kindle_sync.py` and Odysseus's mail
   integration connect headless, over plain IMAP.
2. **~€1/month budget.**

Against those, most of the popular picks fall out on price *before* the
technical objection even matters:

| Popular pick | Why it fails here |
|---|---|
| Proton Mail | ~$48/yr — **4× budget** — *and* Bridge-only IMAP |
| Tuta Mail | ~$36/yr — **3× budget** — *and* **no IMAP at all** |
| mailbox.org | €1 Light tier has IMAP but **no custom domain** (needs €3 Standard) |
| Posteo | €1/mo, but **never supports custom domains by design** — it would force them to store customer identity data, breaking their privacy model |
| Disroot | Free, but no custom domains |

Neither Proton nor Tuta offers a custom domain on its free tier either, so
"just use the free version" doesn't rescue them.

**Purelymail at $10/yr is the only real mailbox that clears both constraints.**

**Is Proton's ~$48/yr just for email?** Essentially yes — Mail Plus is mail plus
calendar, 15GB, one custom domain. Drive, VPN and Pass need **Proton Unlimited**
at roughly $120/yr. So you'd be paying 4× budget for the mail piece alone.

**And note PewDiePie did not use Proton.** From the video: *"there are free
alternatives out there like Proton. I haven't tried it out. I decided to get my
own email. I paid a small fee."* He bought a domain and paid a small provider —
which is exactly the Purelymail path recommended here, not the Proton one the
subreddit pushes.

#### Why not Proton, given it's the famous privacy one

Proton Mail Plus includes IMAP "via Bridge" — and Bridge is a **desktop
application**. On your headless Mac mini that means running a GUI app just so
`kindle_sync.py` and Odysseus's email integration can reach your mailbox. It
fights your setup at every turn.

And be clear-eyed about what the encryption buys you: **email to and from Gmail
users is not end-to-end encrypted regardless of provider.** Proton's E2E only
applies between Proton accounts. For a mailbox whose job is receiving bank
codes, invoices and newsletters, you'd pay more for less compatibility and get
encryption that mostly doesn't apply. Proton is excellent if E2E-between-Proton-
users is a goal. It isn't yours.

Tuta is worse on this axis — **no IMAP at all**, so `kindle_sync.py` and
Odysseus simply cannot connect. Rule it out.

#### "Is there no free one?" — client vs provider

Two different things get confused here:

- **Mail clients are free.** Apple Mail, Thunderbird, K-9/Thunderbird for
  Android. You never pay for these and you can use any of them with any
  provider below.
- **The mailbox** — the server that holds and sends your mail — is what costs.

Free, with your own domain:

| Option | Cost | Catch |
|---|---|---|
| **Cloudflare Email Routing** | **€0** | **Receive only.** Cannot send from your address. |
| ImprovMX | €0 | Same — forwarding only |
| Forward Email (free tier) | €0 | Same — forwarding only. Sending is $3/mo. |
| Zoho free | €0 | Webmail only, **no IMAP** — breaks `kindle_sync.py` and Odysseus |

The catch every "free email" list buries: **plain forwarding only receives.**
To *reply* from `dziugas@peciulevicius.com` you need a real mailbox with SMTP.

#### Which mail *client* should you use?

Free, and independent of the provider — swap either without touching the other:

| Where | Client |
|---|---|
| **iPhone + Mac** | ⭐ **Apple Mail** — built in, free, speaks IMAP, already on every device you own. No reason to install anything. |
| **Desktop power use** | Thunderbird — free, open source, better for rules, multiple accounts, and search |
| **Android (if a Pixel happens)** | Thunderbird for Android (formerly K-9 Mail) |

Any of these works with Purelymail, Migadu or Fastmail. None works with
Tuta (no IMAP), and all need Bridge running for Proton.

#### Recommendation for a ~€1/month budget

**Purelymail — $10/year, about €0.77/month.** It fits your ceiling with room to
spare and it is a real mailbox, not forwarding:

- Native IMAP/SMTP/POP3 — every client works, and `kindle_sync.py` plus
  Odysseus's mail integration both connect with no special software
- **No hard limits** on users, custom domains, addresses or storage — you stay
  at $10/yr as long as usage costs them under $10/yr in resources
- Custom domains at no extra charge

Caveats worth knowing: it's a small indie operation (fine, but it *is* small),
and their 2026 roadmap says the **pricing model is being redesigned** — so
verify the price when you sign up.

**Migadu Micro ($19/yr, ~€1.50/mo)** is the backup if Purelymail's pricing
changes or you want a more established operator — but note its hard **20
outgoing messages/day cap**.

**Fastmail is out** at ~$60/yr — that's 6× your budget. Skip it. The only thing
you lose is its excellent CalDAV/CardDAV, and Nextcloud already covers that.

#### The €0 path, if you want to start without paying anything

Cloudflare Email Routing (receive) + Gmail's "Send mail as" (reply). Costs
nothing, gets you onto your own domain immediately, and keeps Google only in
the *sending* path. Perfectly reasonable as a transition — just not the end
state, since Google still sees outbound mail.

### Step 3 — Cutover

- [ ] Point MX records at the chosen provider (replaces Cloudflare Routing)
- [ ] Add SPF, DKIM, DMARC records the provider gives you
- [ ] Import Gmail archive — Takeout `.mbox`, or the provider's Gmail importer
- [ ] Set Gmail to forward to the new address, keep a copy
- [ ] Update `pkm/config.py` → new `IMAP_SERVER`
- [ ] Update critical accounts first: Apple ID, banks, GitHub, Cloudflare,
      Stripe, Vercel, Supabase, domain registrar, Vaultwarden vault email
- [ ] Then 5–10 lesser accounts per day — don't try to do it in one sitting
- [ ] After ~6 months: stop forwarding, set a vacation responder pointing at the
      new address, take a final Takeout, **keep the Google account** (deleting it
      lets someone else claim the address)

---

## Gap 2 — Phone

### Your iPhone 13 mini cannot run a custom OS. At all.

To be unambiguous, since you asked about "a few OSes on iPhone":

- iPhones cannot dual-boot and cannot run alternative operating systems.
- The bootloader cannot be unlocked. There is no `fastboot unlock` equivalent.
- The checkm8 bootrom exploit — the only thing that ever made this semi-viable —
  covers **A11 and earlier**. Your 13 mini is **A15**. Not applicable.
- Projects like Project Sandcastle only ever booted crippled Linux on old
  hardware. Nothing usable as a daily phone has ever existed.

So it's binary: harden iOS, or buy an Android.

### Does it have to be GrapheneOS, and does it have to be a Pixel? No.

GrapheneOS is the most hardened option, but it is **not the only one**, and
**Fairphone is a genuine non-Pixel path**.

| OS | Security | Devices | Notes |
|---|---|---|---|
| **GrapheneOS** | Strongest | **Pixel only** | Storage Scopes, per-app network permission, profiles |
| **CalyxOS** | Good | **Pixel, Fairphone 5, some Motorola** | ⭐ Keeps verified boot **and relocks the bootloader**. Uses microG. The best non-Pixel option. |
| **iodéOS** | Moderate | **Fairphone 6**, others | LineageOS-based, built-in ad blocker |
| **/e/OS** | Moderate | **Fairphone 6**, wide | Android 16 base, friendliest, sold preinstalled on Murena phones |
| LineageOS | Weakest | Widest | Usually **cannot relock the bootloader** — often *less* secure than stock |

**Why the relocking point keeps coming up.** Installing a custom OS means
unlocking the bootloader. If you can't *re*-lock it afterwards with your own
signing key, you permanently lose verified boot — the hardware check that the
OS hasn't been tampered with. Pixels allow this. **Fairphone allows this.**
Most other phones do not, which is why LineageOS on a random handset is a
downgrade rather than an upgrade.

**So the honest device options are:**

1. **Pixel + GrapheneOS** — strongest security, cheapest (Pixel 8a €233), but
   Google hardware, which some find ironic
2. **Fairphone 5 + CalyxOS** — repairable, ethical, Dutch company, ~10-year
   parts support, verified boot preserved. Costs more (~€550+) and the hardware
   security is below a Pixel's Titan M2. ⭐ **The pick if avoiding Google
   hardware matters to you.**
3. **Fairphone 6 + /e/OS or iodéOS** — easiest to live with, weakest of the three

GrapheneOS also announced a **Motorola partnership for 2027 devices** — so the
Pixel-only constraint may loosen right around when you'd actually be buying.
Another reason not to rush.

The four things PewDiePie highlighted are all real and all genuinely good:

1. **Storage Scopes** — grant an app one folder, not your whole device.
2. **Network permission** — apps ask for internet access at install; most don't
   need it, and you can just say no. Nothing else offers this.
3. **Closing an app actually kills it** — no silent background activity.
4. **User profiles** — fully isolated containers. Put the apps you're obliged
   to use (work, banking, a Google app) in a separate profile where they can't
   see anything else. His unexpected takeaway was that the friction of
   switching profiles *reduced his phone usage* — the privacy feature
   doubled as a focus feature.

### Should you buy a Pixel at all? — the actual call

**No, not right now.** Buy one when the iPhone genuinely needs replacing
(~2028–2030), or buy a cheap 8a *only* if the tinkering itself is the point.

The reasoning, because "no" needs justifying more than "yes" does:

**You already captured ~90% of the win.** Your photos, files, passwords, notes,
documents, bookmarks and books are on your own hardware. That's the part that
actually determines who has "track of your own things", and it's done. The phone
OS is the last 10% — and it's the 10% with by far the most daily friction.

**A de-Googled iPhone gets you almost all the way to your stated goal.** Delete
the Google apps, switch search to DuckDuckGo, use Immich instead of Google
Photos, Nextcloud instead of Drive, Vaultwarden instead of Google Passwords,
enable Advanced Data Protection. At that point **Google is genuinely out of your
phone.** What remains is *Apple* telemetry — which is a real concern, but it is
a different and smaller one than the Google problem you set out to solve.

**The switching costs land on things you actually use:**

- **€403**, to replace a phone with 4+ years of support left
- **Apple Wallet** — you said it yourself. Cards *and* coupons in one place is
  genuinely convenient, and **there is no good GrapheneOS answer**: Google
  Wallet refuses to run, so you lose tap-to-pay *and* the loyalty/coupon layer.
  You carry a physical wallet anyway, so the payment half is survivable — but
  this is a pure convenience loss with no privacy upside *for you specifically*,
  since you're already carrying the cards.
- **A bigger phone than you chose.** You bought a *mini*. The 10a is ~6.3".
- **You need the iPhone anyway** for Expo/React Native iOS testing — so the
  Pixel would be a *second* phone to carry, not a replacement.
- Unverified: your banks' attestation checks, HeliBoard's Lithuanian swipe typing

**What GrapheneOS would genuinely add** over a hardened iPhone — these are real,
just incremental next to what you've already done:

- **Per-app network permission.** Nothing else on any platform does this. Deny
  internet to apps that have no business having it.
- **Storage Scopes** — one folder, not your whole device
- **No Apple telemetry**, and a system you can actually audit
- **User profiles** — isolation, plus the focus side effect

#### So: the two honest paths

| If your goal is… | Do this |
|---|---|
| **"De-Google and own my data"** | **Don't buy.** Harden the iPhone (free, one evening), finish email and calendar/contacts. You're done — that's the goal met. |
| **"I enjoy this and want to learn it"** | **Buy the Pixel 8a at €233**, not the 10a. Test device, low regret, keeps the iPhone as daily driver. Perfectly good reason to spend €233. |

Either way, **don't buy the 10a at €403 today.** If it's a daily driver you'd be
retiring a phone with years of life left; if it's an experiment, the 8a costs
€170 less. Revisit the 10a (or whatever replaces it) when the 13 mini actually
ages out — the support windows only get longer.

#### The highest-value thing you can do this evening costs €0

Enable **Advanced Data Protection** on iCloud (free — it works on the base tier,
no subscription needed), delete the Google apps, and switch your default search. That captures most of the realistic privacy gain
available to you, immediately, with no hardware purchase and no friction. Do
that first and see whether the remaining gap still bothers you in three months.

### Which Pixel to buy (real prices, Sep 2026)

GrapheneOS only runs on Pixels still receiving firmware and driver updates from
Google. **When Google's support window closes, GrapheneOS drops the device** —
so the support end date is the single most important number when buying.

As of September 2026 GrapheneOS has production support for 21 Pixels, from the
Pixel 6 generation through the **Pixel 10a**. No Pixel 11 model is supported yet.

| Model | Price | Support ends | Years left | €/year | Verdict |
|---|---|---|---|---|---|
| **Pixel 10a** (new, Telia) | **€403** | **March 2033** | **6.5** | €62 | ✅ **Best if it's your daily driver** |
| **Pixel 8a** (refurb) | **€233** | ~May 2031 | 4.6 | €51 | ✅ **Best if it's a test device** |
| Pixel 8 (refurb) | €249 | ~Oct 2030 | 4.1 | €61 | Fine, no advantage over the 8a |
| Pixel 10 (refurb) | €545 | ~2032 | 5.5 | €99 | Overpriced against the 10a |
| **Pixel 6 Pro** (refurb) | €205 | **October 2026** | **~0** | — | ❌ **Do not buy** |

**Yes, the Pixel 10a works with GrapheneOS** — and it currently has the
*furthest* support date of any supported device, March 2033.

#### Is the 10a worth €170 more than the 8a?

Depends entirely on what the phone is *for*, and the headline €/year figure is
misleading:

- The 8a looks cheaper per year (€51 vs €62) — but it's **refurbished with an
  aged battery**. Budget €70–90 for a replacement inside that window and it
  becomes ~€67/year, i.e. *worse* than the 10a.
- The 10a is **new**, from a Lithuanian retailer, with full local warranty and
  easy recourse. No carrier-lock risk, no seller-grading lottery, no unknown
  battery cycles.
- 6.5 years of support means you likely don't think about phones again until
  2033.

**If this replaces your daily phone: buy the Pixel 10a at €403.** The extra
€170 buys a new battery, a real warranty, two more years of support, and
removes every refurbished-market risk below.

**If you're testing GrapheneOS before committing: buy the Pixel 8a at €233.**
Cheap enough to be a low-regret experiment, and still supported to 2031 if you
end up keeping it.

**The Pixel 6 Pro at €205 is the trap in that list.** Google's support for the
Pixel 6 series ends **October 2026** — this month. GrapheneOS will drop it
shortly after. Avoid regardless of price.

#### If buying refurbished — the thing that can ruin the whole plan

- [ ] **Confirm carrier-unlocked, and not a US carrier model.** Carrier-locked
      Pixels (Verizon especially) have a **bootloader that cannot be unlocked**,
      making GrapheneOS permanently impossible. The most common way to waste
      money here. Doesn't apply to the new Telia 10a.
- [ ] Check the battery health grade
- [ ] refurbed is a legitimate EU marketplace (12-month warranty, 30-day
      returns) but **individual sellers vary in grading** — read the seller
      rating. Compare against Back Market and Swappie.

### What daily life actually feels like vs your iPhone

The honest version, because this is where people get surprised.

**Mostly the same.** GrapheneOS with sandboxed Google Play is a normal, fast,
polished Android phone. Sandboxed Play Services means push notifications and
the vast majority of Play Store apps work normally — Google just runs as a
regular app with no special system privileges.

**What you'd genuinely lose:**

| | Impact |
|---|---|
| **Contactless payment** | ⚠️ **The big one.** Google Wallet refuses to run on GrapheneOS — it demands a Play Integrity level a custom OS can't pass. **Tap-to-pay stops working.** In Lithuania, where contactless is universal, this is the friction you'd feel daily. *Verify current status before buying — this is the one to check first.* |
| **iMessage / FaceTime** | Gone. Less painful here than in the US — Lithuania runs on WhatsApp, Messenger and Telegram, which are all cross-platform. |
| **AirDrop, Handoff, Continuity with your Macs** | Gone. You'd lean on Syncthing and Nextcloud instead — which you already run. |
| **Find My** | Gone. |
| **Some banking apps** | Those doing hardware attestation may refuse. **Check your specific Lithuanian banks and Revolut before buying.** |
| **Swipe keyboard** | He hit this exactly — no open-source swipe keyboard with his languages. For you that's Lithuanian + English. HeliBoard is the FOSS option; **verify Lithuanian swipe quality before buying**. Otherwise you're back on Google's or Microsoft's internet-connected keyboard. |
| **Phone size** | You deliberately chose a *mini*. The 13 mini is 5.4"; the 10a is ~6.3". **No modern Pixel is small.** If you like the mini form factor, this is a real, permanent downgrade — and it's the one nobody warns you about. |

**Mullvad works on GrapheneOS** — GrapheneOS's own FAQ names it as a
recommended VPN client, and it installs from F-Droid with no Play Store
involved. One quirk: Android only allows **always-on VPN in one user profile at
a time**, so if you use profiles heavily, the VPN applies to whichever profile
you enabled it in. (This is separate from the Transmission/gluetun VPN plan for
the Mac mini — different machine, different purpose, both fine.)

**What gets better:** per-app network permission (deny internet to apps that
don't need it — nothing on iOS does this), Storage Scopes, apps that actually
die when closed, and user profiles for the apps you're obliged to use.

**What transfers cleanly:** Immich, Nextcloud, Vaultwarden, Jellyfin and
Syncthing all have solid Android apps. Your self-hosted stack is the easy part.

### Would you still need the iPhone? Yes — and that's fine

Three independent reasons, one of which is non-negotiable:

1. **You build Expo / React Native apps.** You need a physical iPhone to test
   iOS builds. That alone settles it — the 13 mini isn't going anywhere
   regardless of what you decide about Google.
2. **Contactless payments and stubborn banking apps** — keep the iPhone as the
   fallback for the things GrapheneOS can't do.
3. **Gradual migration.** Running both for a few months is how you find out
   whether you'd actually live with GrapheneOS, without a risky cutover.

So don't frame this as *replace the iPhone*. Frame it as **Pixel becomes the
daily driver, iPhone stays as a dev device and payment fallback.** That's not a
compromise — it's the sensible configuration, and it's what most people in this
position actually end up doing.

### Don't bin the 13 mini — you're right

It's on **iOS 26.5** today and will get **iOS 27**. Major updates run to roughly
2027–2028, security patches to about **2029–2030**. It is a perfectly secure,
fully supported phone and will remain one for years.

Replacing a €90 battery on a phone with four-plus years of security updates left
is obviously better than throwing it away. Keep it.

### But if you de-Google, is Apple still tracking you?

Yes — less than Google, but "privacy" is partly Apple's *marketing position*,
not a complete description of what the device does.

**Genuinely better than Google:** Apple's core business is hardware, not ad
targeting. On-device processing for Siri and photo analysis. App Tracking
Transparency really did damage third-party tracking. And **Advanced Data
Protection makes your iCloud data end-to-end encrypted** — that one toggle is a
real, substantial win, and it's free.

**But be clear-eyed:**

- Apple runs a **growing ads business** (App Store, News, Stocks), and
  personalised ads are on by default in some regions.
- Device analytics are tied to your Apple ID via an identifier. Researchers have
  repeatedly shown Apple's own first-party analytics are more identifiable than
  the marketing implies.
- **Without** Advanced Data Protection, Apple holds the keys to your iCloud
  backups and can hand them to law enforcement.
- You cannot audit any of it, block it, or deny Apple's own services network
  access. It is a closed system you're trusting.

**The honest ranking:** Google (ads are the business model) → Apple
(meaningfully better, still closed and still commercial) → GrapheneOS (the only
one where *you* decide what talks to the network).

If your goal is *"de-Google and get control of my own things"* — you've already
done the part that matters most by self-hosting your photos, files, passwords
and notes. The phone OS is the last mile, and it's the step with the most
day-to-day friction. Take it deliberately, not because of a YouTube video.

### On the Minimal Phone 2 — you answered this yourself

At **€599 for 256GB / €699 for 512GB**, it costs **2.5–3× the Pixel 8a**. And
it is not a Pixel, so it has no Titan M2 security chip and **cannot run
GrapheneOS** — it ships Android with Google Play Services. For a de-Googling
project it is the wrong purchase at triple the price.

Your instinct was right: the Pixel is both cheaper and the only one you can
actually install anything on. The 12GB RAM spec is irrelevant here — phone RAM
does nothing for privacy, and the 8a's 8GB is plenty.

That said, don't dismiss what the Minimal Phone is *for*. E-Ink plus a physical
keyboard is an **attention** product, not a privacy one. If what actually
bothers you is the phone being a distraction machine, that's a different
purchase with a different justification — and note PewDiePie considered a
dumbphone, rejected it, and got the focus benefit from **GrapheneOS user
profiles** instead. Same outcome, €233 instead of €599, and you get the privacy
too.

### The plan that fits your timeline

You said you were thinking of a new iPhone in a couple of years and that a
fresh battery would do for now. That's a good instinct — it lets you test
before committing.

- [ ] **Now (~€90):** replace the 13 mini battery. Buys you 2+ more years.
- [ ] **Now (free):** harden iOS — see below. Gets most of the privacy win.
- [ ] **Optional (€233):** buy the **refurbished Pixel 8a** as a second device
      and flash GrapheneOS. Install is browser-based and takes ~20 minutes.
      Run it for a month with your real apps. This is the only honest way to
      find out if you'd live with it — and it costs a fraction of committing.
      Verify it is carrier-unlocked first (see above).
- [ ] **In ~2 years:** decide Pixel vs iPhone with actual experience instead of
      a YouTube video.

### Harden iOS in the meantime (free, do this regardless)

- [ ] Enable **Advanced Data Protection** (Settings → Apple ID → iCloud) —
      makes iCloud data E2E. Biggest single iOS privacy win, one toggle, and
      **free — it does not need a paid iCloud+ plan.**
- [ ] Delete Google apps: Gmail, Maps, Drive, Photos, Chrome
- [ ] Safari or Brave → default search **DuckDuckGo** or Kagi
- [ ] Settings → Privacy → Tracking → **disable "Allow Apps to Request to Track"**
- [ ] Add Immich, Nextcloud, Vaultwarden apps — replace the Google ones
- [ ] Nextcloud CalDAV + CardDAV (Gap 3 below)
- [ ] Lock screen: Settings → Face ID & Passcode → turn off Control Center and
      Siri on the lock screen

---

## Gap 3 — Calendar + Contacts

> **"Doesn't Nextcloud include email too?"** No — and this is the common
> mistake. **Nextcloud Mail is an IMAP *client*, not a mail *server*.** It
> displays mail from an account you already have elsewhere; it gives you no
> address and cannot receive mail from the internet. Nextcloud replaces Drive,
> Calendar, Contacts, Docs, Notes and Meet — **email still needs a provider.**
>
> PewDiePie hit exactly this: Nextcloud for *"PDFs, Google Docs, calendar,
> contacts — all baked in one"*, but for mail, *"I decided to get my own email.
> I paid a small fee. It was fiddly as hell."* Even in the video that started
> this, **email was the one thing he paid someone else to host.**
>
> Full breakdown of what Nextcloud does and doesn't cover:
> [DEGOOGLE_ALTERNATIVES.md](DEGOOGLE_ALTERNATIVES.md).

Nextcloud is already running. This is unblocked work, maybe an hour.

- [ ] Nextcloud → Apps → enable **Calendar** and **Contacts**
- [ ] Export Google Calendar (Settings → Import & Export → Export) → import `.ics`
- [ ] Export Google Contacts (contacts.google.com → Export → vCard) → import `.vcf`
- [ ] iPhone → Settings → Calendar → Accounts → Add → Other → **Add CalDAV Account**
      → server `cloud.peciulevicius.com`
- [ ] iPhone → Settings → Contacts → Accounts → Add → Other → **Add CardDAV Account**
- [ ] Verify two-way sync, then delete the Google calendar from the phone

> If you pick **Fastmail** for email, it does CalDAV/CardDAV natively and very
> well — you could skip Nextcloud for this entirely. Decide email first.

---

## Gap 4 — Local AI

Covered separately in **[SELF_HOSTED_AI.md](SELF_HOSTED_AI.md)** — including
Odysseus, what your 16GB hardware can genuinely run, and how to pull your
Claude and ChatGPT history onto the NAS.

---

## Quick wins (if not already done)

- [ ] Default search → DuckDuckGo or Kagi, **in every browser and on the phone**
- [ ] Default browser → Brave (already installed via `os/mac/install.sh`) or Firefox
- [ ] Remove Google Fonts from personal sites → self-host or bunny.net/fonts
- [ ] Remove Google Analytics → PostHog or Plausible
- [ ] Point the router at Pi-hole (see the Pi-hole section in HOME_SERVER_TODO.md)
- [ ] Remove Google as a Cloudflare Access identity provider — **after** email migration
- [ ] Audit "Sign in with Google" — Google Account → Security → Your connections
      to third-party apps. Each one is a service that breaks if you ever delete
      the account. Migrate to email+password before touching Gmail.

---

## Maps — the one that actually loses

PewDiePie's most honest moment: he switched to an open-source maps app and was
**30 minutes late**, because Google's traffic prediction is genuinely excellent
and it's excellent *because* of the surveillance. He gave up and used his car's
built-in GPS.

Realistic options, in order:

1. **Apple Maps** — good in Lithuania now, far better privacy than Google, zero effort
2. **Organic Maps / OsmAnd** — fully offline OpenStreetMap, excellent for hiking
   and travel, weak on live traffic
3. Keep Google Maps in a browser tab, signed out, when you truly need traffic

Don't pretend this one is a clean win. It isn't.

---

## Services we're not escaping (and that's fine)

| Service | Why |
|---------|-----|
| **YouTube** | No replacement exists. PewDiePie is *on* YouTube and said so. Use FreeTube or Grayjay as a client if you want to cut tracking. |
| **Meta/Messenger** | Social graph. Keep for people who won't move to Signal. |
| **Apple** | Meaningfully better than Google on privacy, and your Macs depend on it. |
| **GitHub** | Microsoft-owned, developer ecosystem, irreplaceable. |
| **Amazon** | Shopping. No practical alternative. |

---

## Google Takeout

1. takeout.google.com
2. Select Photos, Drive, Mail, Calendar, Contacts
3. Download and store the archive — it goes to Cloudflare R2 with everything
   else via `~/.dotfiles/services/rclone/rclone-backup.sh`

---

## Notes

- The goal is not zero Google overnight. You're ~80% done; finish the four gaps.
- **Own your domain for email.** That single step makes everything else reversible.
- PewDiePie's actual thesis: *use the hardware you already have.* You have far
  more than he does — the bottleneck is decisions, not equipment.
- Keep a migration log in the TODO so you know what's genuinely cut over.

## Resources

- privacyguides.org — vetted alternatives
- grapheneos.org — install guide and supported devices
- `/r/degoogle`, `/r/selfhosted`
