"""Tiny form to edit the hand-entered account balances shown on the Glance Finance tab.

Reads and writes balances.json (the same file the Finance Manager agent edits).
Only changed fields are touched, so a concurrent agent edit is not clobbered.
Bound to localhost + Tailscale by the compose file; no other auth.
"""

import html
import json
import math
import os
import tempfile
from datetime import date
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

FILE = Path(os.environ.get("BALANCES_FILE", "/finance/balances.json"))

PAGE = """<!doctype html><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
<title>Balances</title>
<style>
body{{background:#16171d;color:#c4c8d4;font:15px/1.5 ui-monospace,monospace;max-width:460px;margin:24px auto;padding:0 16px}}
h1{{font-size:14px;letter-spacing:.1em;text-transform:uppercase;color:#8b90a0}}
label{{display:flex;justify-content:space-between;align-items:center;gap:12px;margin:10px 0}}
small{{color:#6b7080;display:block}}
input{{background:#1f212a;color:#e6e8ee;border:1px solid #333745;border-radius:6px;padding:7px 9px;width:130px;text-align:right;font:inherit}}
button{{background:#d9b86a;color:#16171d;border:0;border-radius:6px;padding:9px 16px;font:inherit;font-weight:600;cursor:pointer;margin-top:12px}}
a{{color:#8b90a0}} .ok{{color:#7fc88a}} .bad{{color:#e07a7a}}
</style>
<h1>Account balances ({currency})</h1>{note}
<form method=post>{rows}<button>Save</button></form>
<p><small>Credit card: amount owed, positive. Empty = not tracked. <a href="javascript:history.back()">back</a></small></p>
"""


def load() -> dict:
    return json.loads(FILE.read_text())


def save(data: dict) -> None:
    fd, tmp = tempfile.mkstemp(dir=FILE.parent, prefix=".balances-")
    with os.fdopen(fd, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.chmod(tmp, 0o644)
    os.replace(tmp, FILE)


def render(note: str = "") -> bytes:
    data = load()
    rows = "".join(
        f'<label><span>{html.escape(a["name"])}{" (owed)" if a.get("type") == "credit" else ""}'
        f'<small>updated {html.escape(str(a.get("updated", "never")))}</small></span>'
        f'<input name="a{i}" inputmode="decimal" value="{"" if a.get("balance") is None else a["balance"]}"></label>'
        for i, a in enumerate(data["accounts"])
    )
    return PAGE.format(currency=html.escape(data.get("currency", "EUR")), rows=rows, note=note).encode()


class Handler(BaseHTTPRequestHandler):
    def reply(self, body: bytes, status: int = 200) -> None:
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        if urlparse(self.path).path != "/":
            return self.reply(b"not found", 404)
        self.reply(render())

    def do_POST(self) -> None:
        origin = self.headers.get("Origin")
        if origin and urlparse(origin).netloc != self.headers.get("Host"):
            return self.reply(b"forbidden", 403)
        form = parse_qs(self.rfile.read(int(self.headers.get("Content-Length", 0))).decode())
        data = load()
        changed, today = 0, date.today().isoformat()
        for i, a in enumerate(data["accounts"]):
            raw = form.get(f"a{i}", [""])[0].strip().replace(",", ".")
            try:
                value = None if raw == "" else float(raw)
            except ValueError:
                return self.reply(render(f'<p class=bad>"{html.escape(raw)}" is not a number.</p>'), 400)
            if value is not None and (not math.isfinite(value) or value < 0):
                return self.reply(render('<p class=bad>Amounts must be non-negative.</p>'), 400)
            if value != a.get("balance"):
                a["balance"], a["updated"] = value, today
                changed += 1
        if changed:
            save(data)
        self.reply(render(f'<p class=ok>Saved {changed} change(s). Glance updates within ~2 minutes.</p>'))


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 8095), Handler).serve_forever()
