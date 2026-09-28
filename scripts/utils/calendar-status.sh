#!/bin/bash
# Snapshot of today's + tomorrow's events and open tasks from Radicale, for
# the Glance "Today" widget (services/glance/glance.yml, Home right column).
#
# Reads the CalDAV collections with REPORT calendar-query: events in a
# today..day-after-tomorrow window with server-side recurrence expansion
# (Radicale's <expand>), and every VTODO, filtered here to open tasks that are
# overdue, due within 7 days, or undated. Writes JSON into Glance's assets dir
# (served at /assets/calendar.json). Radicale is always-on and Glance only
# reads the local file, so nothing here wakes a sleeping app.
#
# Credentials: ~/.config/homelab/radicale.env (RADICALE_URL, RADICALE_USER,
# RADICALE_PASSWORD) — never printed. Cron: every 5 min (scripts/cron/crontab).
# Usage: calendar-status.sh [--print]

set -uo pipefail

ENV_FILE="$HOME/.config/homelab/radicale.env"
OUT="$HOME/services/glance/assets/calendar.json"

if [[ ! -r "$ENV_FILE" ]]; then
  echo "calendar-status: $ENV_FILE missing" >&2
  exit 1
fi
# shellcheck disable=SC1090
set -a; . "$ENV_FILE"; set +a

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

python3 - > "$tmp" <<'PY'
import base64, json, os, re, sys, urllib.request
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

TZ = ZoneInfo("Europe/Vilnius")
base = os.environ["RADICALE_URL"].rstrip("/")
user = os.environ["RADICALE_USER"]
auth = "Basic " + base64.b64encode(f"{user}:{os.environ['RADICALE_PASSWORD']}".encode()).decode()
now = datetime.now(TZ)
today = now.date()

def dav(method, path, body, depth="1"):
    req = urllib.request.Request(base + path, data=body.encode(), method=method, headers={
        "Authorization": auth, "Depth": depth, "Content-Type": "application/xml; charset=utf-8"})
    with urllib.request.urlopen(req, timeout=15) as r:
        return r.read().decode("utf-8", "replace")

def calendars():
    xml = dav("PROPFIND", f"/{user}/", '<?xml version="1.0"?><propfind xmlns="DAV:" '
              'xmlns:C="urn:ietf:params:xml:ns:caldav"><prop><resourcetype/><displayname/>'
              '<C:supported-calendar-component-set/></prop></propfind>')
    out = []
    for resp in re.findall(r"<(?:\w+:)?response>(.*?)</(?:\w+:)?response>", xml, re.S):
        href = re.search(r"<(?:\w+:)?href>([^<]+)</", resp).group(1)
        if re.search(r"<(?:\w+:)?calendar\s*/>", resp):
            name = re.search(r"<(?:\w+:)?displayname>([^<]*)</", resp)
            out.append((href, name.group(1) if name else href))
    return out

def ical_blobs(xml):
    return [b.replace("&#13;", "").replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")
            for b in re.findall(r"<(?:\w+:)?calendar-data[^>]*>(.*?)</(?:\w+:)?calendar-data>", xml, re.S)]

def components(ics, kind):
    ics = re.sub(r"\r?\n[ \t]", "", ics)  # unfold
    for block in re.findall(rf"BEGIN:{kind}\r?\n(.*?)END:{kind}", ics, re.S):
        props = {}
        for line in block.splitlines():
            m = re.match(r"([A-Z-]+)((?:;[^:]*)?):(.*)", line)
            if m and m.group(1) not in props:
                props[m.group(1)] = (m.group(2), m.group(3).strip())
        yield props

def when(prop):
    """(datetime-in-Vilnius or date, is_all_day) from an iCal DTSTART/DUE/DTEND."""
    if not prop:
        return None, False
    params, value = prop
    if "VALUE=DATE" in params or re.fullmatch(r"\d{8}", value):
        return datetime.strptime(value[:8], "%Y%m%d").date(), True
    fmt = "%Y%m%dT%H%M%S"
    if value.endswith("Z"):
        return datetime.strptime(value[:-1], fmt).replace(tzinfo=timezone.utc).astimezone(TZ), False
    tzid = re.search(r"TZID=([^;:]+)", params)
    try:
        zone = ZoneInfo(tzid.group(1)) if tzid else TZ
    except Exception:
        zone = TZ
    return datetime.strptime(value[:15], fmt).replace(tzinfo=zone).astimezone(TZ), False

def text(s):
    return s.replace("\\,", ",").replace("\\;", ";").replace("\\n", " ").replace("\\\\", "\\")

start = datetime.combine(today, datetime.min.time(), TZ).astimezone(timezone.utc)
end = start + timedelta(days=2)
rng = f'start="{start:%Y%m%dT%H%M%SZ}" end="{end:%Y%m%dT%H%M%SZ}"'
ev_query = ('<?xml version="1.0"?><C:calendar-query xmlns="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">'
            f'<prop><C:calendar-data><C:expand {rng}/></C:calendar-data></prop>'
            '<C:filter><C:comp-filter name="VCALENDAR"><C:comp-filter name="VEVENT">'
            f'<C:time-range {rng}/></C:comp-filter></C:comp-filter></C:filter></C:calendar-query>')
todo_query = ('<?xml version="1.0"?><C:calendar-query xmlns="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">'
              '<prop><C:calendar-data/></prop><C:filter><C:comp-filter name="VCALENDAR">'
              '<C:comp-filter name="VTODO"/></C:comp-filter></C:filter></C:calendar-query>')

status = {"updated": now.strftime("%H:%M"), "ok": True, "today": [], "tomorrow": [], "tasks": []}
try:
    events, tasks = [], []
    for href, cal in calendars():
        xml = dav("REPORT", href, ev_query)
        for ics in ical_blobs(xml):
            for p in components(ics, "VEVENT"):
                dt, allday = when(p.get("DTSTART"))
                if dt is None:
                    continue
                day = dt if allday else dt.date()
                events.append({"day": day.isoformat(), "sort": "" if allday else dt.strftime("%H:%M"),
                               "time": "all day" if allday else dt.strftime("%H:%M"),
                               "title": text(p.get("SUMMARY", ("", "(no title)"))[1]), "calendar": cal})
        xml = dav("REPORT", href, todo_query)
        for ics in ical_blobs(xml):
            for p in components(ics, "VTODO"):
                if p.get("STATUS", ("", ""))[1] in ("COMPLETED", "CANCELLED") or "COMPLETED" in p:
                    continue
                due, allday = when(p.get("DUE"))
                due_day = (due if allday else due.date()) if due else None
                if due_day and due_day > today + timedelta(days=7):
                    continue
                tasks.append({"title": text(p.get("SUMMARY", ("", "(no title)"))[1]),
                              "due": due_day.strftime("%a %d %b") if due_day else "",
                              "overdue": bool(due_day and due_day < today),
                              "sort": due_day.isoformat() if due_day else "9999"})
    events.sort(key=lambda e: (e["day"], e["sort"]))
    status["today"] = [e for e in events if e["day"] == today.isoformat()]
    status["tomorrow"] = [e for e in events if e["day"] == (today + timedelta(days=1)).isoformat()]
    status["tasks"] = sorted(tasks, key=lambda t: t["sort"])[:8]
except Exception as exc:  # show the failure on the widget instead of stale data
    status.update(ok=False, error=f"{type(exc).__name__}: {exc}"[:160])
print(json.dumps(status, ensure_ascii=False, indent=1))
PY

if python3 -m json.tool "$tmp" > /dev/null 2>&1; then
  mv "$tmp" "$OUT.tmp" && mv "$OUT.tmp" "$OUT" && chmod 644 "$OUT"
else
  echo "$(date '+%F %T') calendar.json generation failed" >&2
  exit 1
fi

[[ "${1:-}" == "--print" ]] && cat "$OUT"
exit 0
