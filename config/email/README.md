# Email signature

Signature for `dziugas@peciulevicius.com` (Purelymail). Built 2026-09-29 from
the website's own brand: the logo PNG and colours from
`~/dev/peciulevicius.com` (`public/email/logo.png`, `src/lib/email-templates.mjs`),
v2 (2026-09-29): title line removed for now; light/dark logo swap added. The
site also serves an older variant at <https://peciulevicius.com/email/signature>;
this one adds the email address and is dark-mode aware.

| File | Use |
|---|---|
| `signature.html` | macOS Mail, webmail — table + inline CSS, ~2.5 KB, no web fonts |
| `signature.txt` | iPhone Mail (plain text is the only thing it keeps reliably) |
| `install-mac-signature.sh` | optional: installs the HTML into Apple Mail raw, so the light/dark swap works |

**Why it looks the way it does:**
- Logos are hosted PNGs (mail clients block SVG and embedded images), both
  already live on the site, 96×96 shown at 36×36:
  `https://peciulevicius.com/email/logo.png` (black) and
  `https://peciulevicius.com/email/logo-dark.png` (white). Keep the URLs:
  every sent email points at them.
- **Light/dark:** only clients that support `prefers-color-scheme` *and* keep
  a style block can swap images — mainly Apple Mail (macOS/iOS) when the
  signature is installed as raw HTML. Everywhere else (Gmail, Outlook,
  anything that strips styles, or a signature pasted via Safari) the
  **fallback** shows: the black logo on a small white tile, readable on both
  light and dark backgrounds. There is no way to force the swap in Gmail.
- The name has **no colour set**, so it follows the mail app (black in light,
  white in dark); the link line uses `#71717a`, readable on both.
- Render-checked 2026-09-29 (headless Chrome): light, dark, and both with the
  style block stripped.

## Install

### macOS Mail (quick — fallback logo everywhere)
1. Open `signature.html` in **Safari** (`open -a Safari
   ~/.dotfiles/config/email/signature.html`) → **Cmd+A** → **Cmd+C**.
2. Mail → **Settings → Signatures**.
3. In the **left column, select the `dziugas@peciulevicius.com` account** —
   not "All Signatures". (Signatures made under *All Signatures* aren't
   attached to any account, which is why "Choose Signature" stays greyed
   out; drag such a signature from the middle column onto the account to
   attach it.)
4. Click **+** under the middle column → name it (e.g. `peciulevicius`) →
   click in the right-hand box, select the placeholder text, **Cmd+V**.
5. **Untick "Always match my default message font"**.
6. Under the left column, **Choose Signature** is now active for that
   account → pick `peciulevicius`. Close Settings — it saves automatically.
   Send yourself a test.

### macOS Mail (full light/dark swap — optional)
Pasting drops the style block, so the white-logo-on-dark swap needs the raw
HTML written into Mail's signature file:
1. Do steps 2–4 above but leave the placeholder text (don't paste).
2. **Quit Mail** (Cmd+Q).
3. `~/.dotfiles/config/email/install-mac-signature.sh` — rewrites the newest
   `.mailsignature` with `signature.html` and locks it (`chflags uchg`, or
   Mail overwrites it). It prints the file path; `chflags nouchg <file>`
   before editing/deleting the signature later.
4. Open Mail → Settings → Signatures → Choose Signature → `peciulevicius`.
   Test by viewing a sent mail with macOS in light and dark mode.

### iPhone Mail
Settings → **Apps → Mail → Signature** → **Per Account** → paste the
contents of `signature.txt` under the Purelymail account. (iOS drops the logo
and most styling from pasted HTML, so plain text is the clean option.)

### Purelymail webmail
Purelymail's webmail is Roundcube: **Settings → Identities** → the identity →
**Signature** → toggle the HTML editor → paste (copy from Safari as above).
If your webmail differs, skip it — Mac and iPhone are the ones that matter.

## Sender avatar (the letter circle in Gmail)

Gmail shows a letter ("d") for senders it has no picture for. Real options:

| Option | Where it shows | Cost | Trade-off |
|---|---|---|---|
| **BIMI + CMC** (Common Mark Certificate) | Gmail, Apple Mail, Yahoo — your logo as the avatar | ~$650–1,400/yr (DigiCert, GlobalSign, SSL.com; resellers from ~$649) | Logo must have been publicly used ≥ 1 year. DMARC `p=reject` + the BIMI record are already in place — only the certificate is missing. |
| **BIMI + VMC** (Verified Mark) | Same + Gmail's blue check | ~$780–1,750/yr | Needs a **registered trademark**. |
| **Google Account for this address** | Gmail only (profile photo) | Free | Create a Google Account with *"use my current email address"* (no Gmail inbox) and set a photo. Works, but adds a Google account tied to the new address — against the de-Google goal (`docs/guides/DEGOOGLE.md`). |
| **Gravatar** | Some webmails/clients (Thunderbird add-ons, many web apps, GitHub-style sites) — **not** Gmail or Apple Mail | Free | gravatar.com → sign up with `dziugas@peciulevicius.com` → upload the logo or a photo. |

**Recommendation (2026-09-29):** do **Gravatar** (free, 2 minutes, helps in
apps and some clients) and accept the letter in Gmail. BIMI certificates are
way over the ~€1/month email budget; the Google-account trick is the only
free Gmail fix but contradicts de-Googling — your call.

## Deliverability

Signature design doesn't affect spam scoring; the domain records do. The
DNS audit is recorded in `docs/HOME_SERVER_CHANGELOG.md` (2026-09-29);
mail-tester scored **10/10** on 2026-09-29 (signature changes don't move it). Second opinion any time:
open <https://www.mail-tester.com>, send an email to the address it shows
from iPhone/Mac Mail, then click *Then check your score* (aim 9–10/10).
