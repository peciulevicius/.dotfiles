#!/usr/bin/env python3
"""
Kindle Scribe → Obsidian sync

Fetches Kindle export emails via IMAP, extracts TXT content,
routes it to the correct Obsidian vault folder, and saves as .md.

Usage:
    python3 kindle_sync.py           # process all unread export emails
    python3 kindle_sync.py --dry-run # show what would happen, don't write files

Setup:
    1. Fill in config.py (VAULT_PATH, EMAIL_ADDRESS, EMAIL_PASSWORD)
    2. pip3 install -r requirements.txt
    3. Run: python3 kindle_sync.py
"""

import email
import imaplib
import os
import re
import sys
import subprocess
from datetime import date, datetime
from email.header import decode_header

import requests

import config

DRY_RUN = "--dry-run" in sys.argv

KINDLE_SENDER = "do-not-reply@amazon.com"
KINDLE_SUBJECT_MARKER = "from your Kindle"

# Matches the "Download text file" link Amazon puts in the export email body.
# The link is usually inside an <a> tag or a plain URL in the text part.
DOWNLOAD_URL_RE = re.compile(
    r"https://[^\s\"'>]+/GenerateKindleNotebookExport[^\s\"'>]*",
    re.IGNORECASE,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def log(msg: str) -> None:
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {msg}")


def decode_str(value: str | bytes | None) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return value


def decode_subject(raw_subject: str) -> str:
    parts = decode_header(raw_subject)
    decoded = []
    for part, enc in parts:
        if isinstance(part, bytes):
            decoded.append(part.decode(enc or "utf-8", errors="replace"))
        else:
            decoded.append(part)
    return "".join(decoded)


def extract_notebook_name(subject: str) -> str:
    """
    Subject format: 'You sent a file "NOTEBOOK NAME" from your Kindle'
    Returns the notebook name, or the full subject if pattern doesn't match.
    """
    m = re.search(r'"([^"]+)"', subject)
    return m.group(1) if m else subject


def route(notebook_name: str) -> str:
    """
    Returns the destination path (relative to VAULT_PATH) for this notebook.
    Uses ROUTING_RULES from config — first keyword match wins.
    """
    lower = notebook_name.lower()
    for keyword, dest in config.ROUTING_RULES.items():
        if keyword in lower:
            return dest
    return config.FALLBACK_FOLDER


def resolve_dest_path(notebook_name: str, today: str) -> str:
    """
    Turns a routing destination into a full absolute file path.
    Folder destinations get a dated filename; .md destinations are used directly.
    """
    dest = route(notebook_name)
    safe_name = re.sub(r'[\\/:*?"<>|]', "_", notebook_name)

    if dest.endswith("/"):
        filename = f"{today}_{safe_name}.md"
        return os.path.join(config.VAULT_PATH, dest, filename)
    else:
        return os.path.join(config.VAULT_PATH, dest)


def unique_path(path: str) -> str:
    """Appends _v2, _v3, … until the path doesn't exist."""
    if not os.path.exists(path):
        return path
    base, ext = os.path.splitext(path)
    counter = 2
    while True:
        candidate = f"{base}_v{counter}{ext}"
        if not os.path.exists(candidate):
            return candidate
        counter += 1


def build_frontmatter(notebook_name: str, today: str) -> str:
    return (
        f"---\n"
        f"source: Kindle Scribe\n"
        f"exported: {today}\n"
        f"notebook: {notebook_name}\n"
        f"---\n\n"
    )


def download_txt(url: str) -> str | None:
    """Downloads the TXT export from Amazon. Returns content or None on failure."""
    try:
        r = requests.get(url, timeout=30)
        r.raise_for_status()
        return r.text
    except requests.RequestException as e:
        log(f"  Download failed: {e}")
        # Retry once
        try:
            r = requests.get(url, timeout=30)
            r.raise_for_status()
            return r.text
        except requests.RequestException:
            return None


def save_note(path: str, content: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a", encoding="utf-8") as f:
        f.write(content)


def git_push() -> None:
    if DRY_RUN:
        log("  [dry-run] would git commit + push")
        return
    today = date.today().isoformat()
    try:
        subprocess.run(
            ["git", "add", "."],
            cwd=config.VAULT_PATH,
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["git", "commit", "-m", f"kindle sync {today}"],
            cwd=config.VAULT_PATH,
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["git", "push"],
            cwd=config.VAULT_PATH,
            check=True,
            capture_output=True,
        )
        log("  Git push done")
    except subprocess.CalledProcessError as e:
        log(f"  Git push failed: {e.stderr.decode().strip()}")


# ---------------------------------------------------------------------------
# Email parsing
# ---------------------------------------------------------------------------

def get_email_body_parts(msg: email.message.Message) -> tuple[str, str]:
    """Returns (plain_text, html_text) from a message."""
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


def find_download_url(plain: str, html: str) -> str | None:
    """Searches both plain and HTML parts for the Kindle download URL."""
    for text in (plain, html):
        m = DOWNLOAD_URL_RE.search(text)
        if m:
            return m.group(0)
    return None


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def validate_config() -> list[str]:
    errors = []
    if not config.VAULT_PATH:
        errors.append("VAULT_PATH is not set in config.py")
    elif not os.path.isdir(config.VAULT_PATH):
        errors.append(f"VAULT_PATH does not exist: {config.VAULT_PATH}")
    if not config.EMAIL_ADDRESS:
        errors.append("EMAIL_ADDRESS is not set in config.py")
    if not config.EMAIL_PASSWORD:
        errors.append("EMAIL_PASSWORD is not set in config.py")
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
    saved = skipped_expired = error_count = 0

    log(f"Connecting to {config.IMAP_SERVER}…")
    try:
        imap = imaplib.IMAP4_SSL(config.IMAP_SERVER, config.IMAP_PORT)
        imap.login(config.EMAIL_ADDRESS, config.EMAIL_PASSWORD)
    except imaplib.IMAP4.error as e:
        log(f"IMAP login failed: {e}")
        sys.exit(1)

    imap.select("INBOX")

    # Search for unread Kindle export emails
    _, data = imap.search(
        None,
        f'(UNSEEN FROM "{KINDLE_SENDER}" SUBJECT "{KINDLE_SUBJECT_MARKER}")',
    )
    msg_ids = data[0].split() if data[0] else []

    if not msg_ids:
        log("No new Kindle export emails found.")
        imap.logout()
        return

    log(f"Found {len(msg_ids)} export email(s) to process.")

    for msg_id in msg_ids:
        _, raw = imap.fetch(msg_id, "(RFC822)")
        msg = email.message_from_bytes(raw[0][1])

        subject = decode_subject(msg.get("Subject", ""))
        notebook_name = extract_notebook_name(subject)
        log(f'Processing: "{notebook_name}"')

        plain, html = get_email_body_parts(msg)
        download_url = find_download_url(plain, html)

        if not download_url:
            log("  No download URL found — email may be expired, skipping.")
            skipped_expired += 1
            continue

        log(f"  Downloading from Amazon…")
        txt_content = download_txt(download_url)

        if txt_content is None:
            log("  Download failed after retry — skipping.")
            error_count += 1
            continue

        dest = route(notebook_name)
        file_path = resolve_dest_path(notebook_name, today)

        # For folder destinations: always a new dated file (unique path).
        # For .md file destinations: append to the existing note.
        is_folder_dest = dest.endswith("/")
        if is_folder_dest:
            file_path = unique_path(file_path)
            note_content = build_frontmatter(notebook_name, today) + txt_content.strip() + "\n"
            action = "create"
        else:
            note_content = (
                f"\n\n---\n\n"
                + build_frontmatter(notebook_name, today)
                + txt_content.strip()
                + "\n"
            )
            action = "append"

        log(f"  → {action} {os.path.relpath(file_path, config.VAULT_PATH)}")

        if not DRY_RUN:
            save_note(file_path, note_content)
            # Mark email as read
            imap.store(msg_id, "+FLAGS", "\\Seen")

        saved += 1

    imap.logout()

    if not DRY_RUN and config.GIT_AUTOPUSH and saved > 0:
        log("Pushing vault to GitHub…")
        git_push()

    log(
        f"\nDone — {saved} saved, {skipped_expired} skipped (expired link), {error_count} error(s)"
    )
    if error_count:
        sys.exit(1)


if __name__ == "__main__":
    main()
