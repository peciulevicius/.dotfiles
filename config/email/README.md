# Email signature

Signature for `dziugas@peciulevicius.com` (Purelymail). Built 2026-09-29 from
the website's own brand: the logo PNG and colours from
`~/dev/peciulevicius.com` (`public/email/logo.png`, `src/lib/email-templates.mjs`),
with the website's wording ("Full-stack developer"). The site also serves an
older variant at <https://peciulevicius.com/email/signature>; this one adds the
email address and is dark-mode safe.

| File | Use |
|---|---|
| `signature.html` | macOS Mail, webmail — table + inline CSS, ~1.6 KB, no web fonts |
| `signature.txt` | iPhone Mail (plain text is the only thing it keeps reliably) |

**Why it looks the way it does:**
- The logo is a hosted PNG (`https://peciulevicius.com/email/logo.png`,
  96×96 shown at 36×36): mail clients block or strip SVG and embedded images.
  It's a black mark on transparency, so it sits on its own **white tile** —
  otherwise it disappears in dark mode.
- The name has **no colour set**, so it follows the mail app (black in light
  mode, white in dark). Secondary lines use `#71717a`, a grey that reads on
  both backgrounds. `<style>` blocks and `prefers-color-scheme` are stripped
  when a signature is pasted, so everything is inline.
- If the logo ever changes, keep the URL: every sent email points at it.

## Install

### macOS Mail
1. Open `signature.html` in **Safari** (double-click, or `open -a Safari
   ~/.dotfiles/config/email/signature.html`).
2. **Cmd+A**, **Cmd+C**.
3. Mail → **Settings → Signatures** → pick the `dziugas@peciulevicius.com`
   account → **+** → name it → click in the right-hand box, select its
   placeholder text, **Cmd+V**.
4. **Untick "Always match my default message font"** (otherwise Mail
   flattens the styling).
5. Choose it as that account's default signature. Send a test to yourself.

### iPhone Mail
Settings → **Apps → Mail → Signature** → **Per Account** → paste the
contents of `signature.txt` under the Purelymail account. (iOS drops the logo
and most styling from pasted HTML, so plain text is the clean option.)

### Purelymail webmail
Purelymail's webmail is Roundcube: **Settings → Identities** → the identity →
**Signature** → toggle the HTML editor → paste (copy from Safari as above).
If your webmail differs, skip it — Mac and iPhone are the ones that matter.

## Deliverability

Signature design doesn't affect spam scoring; the domain records do. The
check-auth results for this domain are recorded in
`docs/HOME_SERVER_CHANGELOG.md` (2026-09-29). Second opinion any time:
open <https://www.mail-tester.com>, send an email to the address it shows
from iPhone/Mac Mail, then click *Then check your score* (aim 9–10/10).
