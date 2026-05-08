#!/usr/bin/env python3
"""
Kindle Scribe → Obsidian sync

Fetches Kindle export emails via IMAP, downloads the text content,
and saves each notebook as a dated .md file in the Imports folder.

Usage:
    python3 kindle_sync.py           # process new export emails
    python3 kindle_sync.py --dry-run # show what would happen, don't write files

Setup:
    1. Fill in config.py (VAULT_PATH, EMAIL_ADDRESS, EMAIL_PASSWORD)
    2. Export from Scribe: Share → Searchable PDF (gives both PDF + text links)
    3. Script runs hourly via cron, picks up the text file automatically
"""

import email
import imaplib
import os
import re
import sys
from datetime import date, datetime
from email.header import decode_header
from pathlib import Path
from urllib.parse import urlparse, parse_qs, unquote

import requests

import config

DRY_RUN = "--dry-run" in sys.argv

KINDLE_SENDER = "do-not-reply@amazon.com"
KINDLE_SUBJECT_MARKER = "from your Kindle"

AMAZON_REDIRECT_RE = re.compile(
    r"https://www\.amazon\.com/gp/f\.html\?[^\s\"'<>]*kindle-content-requests[^\s\"'<>]*",
    re.IGNORECASE,
)

PROCESSED_IDS_FILE = Path(__file__).parent / ".processed_ids"


def log(msg: str) -> None:
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")


def decode_str(value: str | bytes | None) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return value


def decode_subject(raw: str) -> str:
    parts = decode_header(raw)
    return "".join(
        p.decode(e or "utf-8", errors="replace") if isinstance(p, bytes) else p
        for p, e in parts
    )


def extract_notebook_name(subject: str) -> str:
    m = re.search(r'"([^"]+)"', subject)
    return m.group(1) if m else subject


def load_processed_ids() -> set[str]:
    if not PROCESSED_IDS_FILE.exists():
        return set()
    return set(PROCESSED_IDS_FILE.read_text().splitlines())


def mark_processed(uid: str) -> None:
    with open(PROCESSED_IDS_FILE, "a") as f:
        f.write(uid + "\n")


def extract_s3_url(redirect_url: str) -> str:
    parsed = urlparse(redirect_url)
    params = parse_qs(parsed.query)
    u = params.get("U", [])
    return unquote(u[0]) if u else redirect_url


def find_text_url(plain: str, html: str) -> str | None:
    """
    Finds the text file download URL from the email.
    Searchable PDF export gives two links — prefers .txt over .pdf.
    """
    for text in (plain, html):
        matches = AMAZON_REDIRECT_RE.findall(text)
        if not matches:
            continue
        s3_urls = [extract_s3_url(m) for m in matches]
        txt = [u for u in s3_urls if u.lower().endswith(".txt")]
        if txt:
            return txt[0]
    return None


def get_body_parts(msg: email.message.Message) -> tuple[str, str]:
    plain, html = "", ""
    if msg.is_multipart():
        for part in msg.walk():
            ct = part.get_content_type()
            if ct == "text/plain" and not plain:
                plain = decode_str(part.get_payload(decode=True))
            elif ct == "text/html" and not html:
                html = decode_str(part.get_payload(decode=True))
    else:
        payload = decode_str(msg.get_payload(decode=True))
        if msg.get_content_type() == "text/html":
            html = payload
        else:
            plain = payload
    return plain, html


def download_text(url: str) -> str | None:
    try:
        r = requests.get(url, timeout=30)
        r.raise_for_status()
        return r.text
    except requests.RequestException as e:
        log(f"  Download failed: {e}")
        return None


def save_note(notebook_name: str, content: str, today: str) -> str:
    imports_dir = os.path.join(config.VAULT_PATH, "📥 Imports")
    os.makedirs(imports_dir, exist_ok=True)

    safe_name = re.sub(r'[\\/:*?"<>|]', "_", notebook_name)
    filename = f"{today}_{safe_name}.md"
    path = os.path.join(imports_dir, filename)

    # Avoid overwriting — append _v2, _v3 if needed
    if os.path.exists(path):
        base = os.path.splitext(path)[0]
        counter = 2
        while os.path.exists(f"{base}_v{counter}.md"):
            counter += 1
        path = f"{base}_v{counter}.md"

    frontmatter = f"---\nsource: Kindle Scribe\nexported: {today}\nnotebook: {notebook_name}\n---\n\n"
    with open(path, "w", encoding="utf-8") as f:
        f.write(frontmatter + content.strip() + "\n")

    return path


def validate_config() -> list[str]:
    errors = []
    if not config.VAULT_PATH or not os.path.isdir(config.VAULT_PATH):
        errors.append(f"VAULT_PATH invalid: {config.VAULT_PATH!r}")
    if not config.EMAIL_ADDRESS:
        errors.append("EMAIL_ADDRESS not set")
    if not config.EMAIL_PASSWORD:
        errors.append("EMAIL_PASSWORD not set")
    return errors


def main() -> None:
    if DRY_RUN:
        log("=== DRY RUN — no files will be written ===")

    errors = validate_config()
    if errors:
        for e in errors:
            print(f"Config error: {e}")
        sys.exit(1)

    today = date.today().isoformat()
    processed_ids = load_processed_ids()
    saved = skipped = errors_count = 0

    log(f"Connecting to {config.IMAP_SERVER}…")
    try:
        imap = imaplib.IMAP4_SSL(config.IMAP_SERVER, config.IMAP_PORT)
        imap.login(config.EMAIL_ADDRESS, config.EMAIL_PASSWORD)
    except imaplib.IMAP4.error as e:
        log(f"IMAP login failed: {e}")
        sys.exit(1)

    imap.select("INBOX")
    _, data = imap.search(None, f'(FROM "{KINDLE_SENDER}" SUBJECT "{KINDLE_SUBJECT_MARKER}")')
    all_ids = data[0].split() if data[0] else []
    msg_ids = [mid for mid in all_ids if mid.decode() not in processed_ids]

    if not msg_ids:
        log("No new Kindle export emails.")
        imap.logout()
        return

    log(f"Found {len(msg_ids)} new export email(s).")

    for msg_id in msg_ids:
        _, raw = imap.fetch(msg_id, "(RFC822)")
        msg = email.message_from_bytes(raw[0][1])
        notebook_name = extract_notebook_name(decode_subject(msg.get("Subject", "")))
        log(f'Processing: "{notebook_name}"')

        plain, html = get_body_parts(msg)
        url = find_text_url(plain, html)

        if not url:
            log("  No text file link found — use 'Searchable PDF' export on Scribe (not plain PDF).")
            skipped += 1
            if not DRY_RUN:
                mark_processed(msg_id.decode())
            continue

        log("  Downloading…")
        content = download_text(url)

        if content is None:
            log("  Download failed — link may have expired (valid 7 days).")
            errors_count += 1
            continue

        if DRY_RUN:
            log(f"  → would save to 📥 Imports/{today}_{notebook_name}.md")
        else:
            path = save_note(notebook_name, content, today)
            mark_processed(msg_id.decode())
            log(f"  → saved to {os.path.relpath(path, config.VAULT_PATH)}")

        saved += 1

    imap.logout()
    log(f"\nDone — {saved} saved, {skipped} skipped (no text link), {errors_count} error(s)")
    if errors_count:
        sys.exit(1)


if __name__ == "__main__":
    main()
