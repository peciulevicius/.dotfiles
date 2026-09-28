#!/bin/bash
# Write a JSON snapshot of investment holdings for the Glance Finance page.
#
#   finance-status.sh                     # fetch every configured provider
#   finance-status.sh --print             # also print the JSON
#   finance-status.sh --from-file X.xml   # parse a saved IBKR Flex statement
#                                         # instead of calling IBKR (testing)
#
# Cron (see scripts/cron/crontab): daily at 07:00. IBKR Flex statements are
# end-of-day data, so more often gains nothing.
#
# Output: ~/services/glance/assets/finance.json (served by Glance at /assets/,
# read by the "Portfolio" custom-api widget). Holdings never touch the repo.
#
# Providers — one key each under "providers", same shape:
#   {"ok": bool, "error": str|null, "as_of": "YYYY-MM-DD", "currency": "EUR",
#    "nav": float, "cash": float, "day_pnl": float|null,
#    "unrealized_pnl": float, "positions": [{symbol, description, qty,
#    value_base, pnl_base, currency}]}
# "total" and the combined top "positions" list are computed from every
# provider with ok=true, so adding one means: write a fetch_<name>() in the
# Python block returning that dict, add it to PROVIDERS. Candidates (not built
# yet): trading212 (API key), kraken (read-only API key), capitalcom (API
# key), ledger (public addresses → price lookup), and a manual CSV for banks
# without an API (Swedbank, Revolut). All values are converted to the IBKR
# base currency; a second provider must convert to it too.
#
# IBKR: Flex Web Service v3 with a read-only Flex token. Needs
# ~/.config/homelab/ibkr-flex.env (chmod 600) with IBKR_FLEX_TOKEN and
# IBKR_FLEX_QUERY_ID — setup steps in services/glance/README.md → Finance.
# The token is read into the Python process only, never printed or logged.
#
# A failed fetch keeps the last good provider data (marked stale) instead of
# blanking the widget.

set -uo pipefail

OUT_DIR="${OUT_DIR:-$HOME/services/glance/assets}"
OUT="$OUT_DIR/finance.json"
IBKR_ENV="$HOME/.config/homelab/ibkr-flex.env"

from_file=""
print=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --print) print=1 ;;
    --from-file) from_file="${2:-}"; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

mkdir -p "$OUT_DIR"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

IBKR_ENV="$IBKR_ENV" FROM_FILE="$from_file" PREV="$OUT" python3 - > "$tmp" <<'PY'
import json, os, re, sys, time, urllib.parse, urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime

FLEX = "https://ndcdyn.interactivebrokers.com/AccountManagement/FlexWebService"
UA = {"User-Agent": "homelab-finance-status/1.0 (Python urllib)"}


def read_env(path):
    vals = {}
    try:
        for line in open(path):
            m = re.match(r"\s*([A-Z_]+)=(.*)", line)
            if m:
                vals[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    except FileNotFoundError:
        pass
    return vals


def get(url, params):
    req = urllib.request.Request(url + "?" + urllib.parse.urlencode(params), headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def f(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return 0.0


def ibkr_statement():
    src = os.environ.get("FROM_FILE")
    if src:
        return open(src, "rb").read()
    env = read_env(os.environ["IBKR_ENV"])
    token, query = env.get("IBKR_FLEX_TOKEN"), env.get("IBKR_FLEX_QUERY_ID")
    if not token or not query:
        raise LookupError("not configured")
    resp = ET.fromstring(get(f"{FLEX}/SendRequest", {"t": token, "q": query, "v": 3}))
    if resp.findtext("Status") != "Success":
        raise RuntimeError(f"SendRequest: {resp.findtext('ErrorCode')} {resp.findtext('ErrorMessage')}")
    ref, url = resp.findtext("ReferenceCode"), resp.findtext("Url") or f"{FLEX}/GetStatement"
    for _ in range(12):  # statement generation takes a few seconds to ~1 min
        time.sleep(5)
        body = get(url, {"t": token, "q": ref, "v": 3})
        root = ET.fromstring(body)
        if root.tag == "FlexQueryResponse":
            return body
        code = root.findtext("ErrorCode")
        if code not in ("1019", "1018", "1009"):  # in progress / throttled / busy
            raise RuntimeError(f"GetStatement: {code} {root.findtext('ErrorMessage')}")
    raise TimeoutError("statement not ready after 60 s")


def fetch_ibkr():
    root = ET.fromstring(ibkr_statement())
    st = root.find(".//FlexStatement")
    if st is None:
        raise RuntimeError("no FlexStatement in response (check the query sections)")
    positions = []
    for p in st.iter("OpenPosition"):
        if p.get("levelOfDetail", "SUMMARY") != "SUMMARY":
            continue
        fx = f(p.get("fxRateToBase")) or 1.0
        positions.append({
            "symbol": p.get("symbol", "?"),
            "description": p.get("description", ""),
            "qty": f(p.get("position")),
            "currency": p.get("currency", ""),
            "value_base": f(p.get("positionValue")) * fx,
            "pnl_base": f(p.get("fifoPnlUnrealized")) * fx,
        })
    eq = list(st.iter("EquitySummaryByReportDateInBase"))
    last_eq = eq[-1] if eq else None
    nav_node = st.find(".//ChangeInNAV")
    cash = next((f(c.get("endingCash")) for c in st.iter("CashReportCurrency")
                 if c.get("currency") == "BASE_SUMMARY"), None)
    nav = f(nav_node.get("endingValue")) if nav_node is not None else \
        f(last_eq.get("total")) if last_eq is not None else \
        sum(p["value_base"] for p in positions) + (cash or 0)
    day = None
    if nav_node is not None and nav_node.get("startingValue") is not None:
        day = f(nav_node.get("endingValue")) - f(nav_node.get("startingValue")) \
            - f(nav_node.get("depositsWithdrawals"))
    if cash is None and last_eq is not None:
        cash = f(last_eq.get("cash"))
    currency = (nav_node.get("currency") if nav_node is not None else None) or \
        (last_eq.get("currency") if last_eq is not None else None) or "EUR"
    as_of = st.get("toDate") or (last_eq.get("reportDate") if last_eq is not None else "")
    if re.fullmatch(r"\d{8}", as_of or ""):
        as_of = f"{as_of[:4]}-{as_of[4:6]}-{as_of[6:]}"
    return {"ok": True, "error": None, "as_of": as_of, "currency": currency,
            "nav": nav, "cash": cash or 0.0, "day_pnl": day,
            "unrealized_pnl": sum(p["pnl_base"] for p in positions),
            "positions": positions}


PROVIDERS = {"ibkr": fetch_ibkr}

try:
    prev = json.load(open(os.environ["PREV"])).get("providers", {})
except (FileNotFoundError, ValueError):
    prev = {}

providers = {}
for name, fn in PROVIDERS.items():
    try:
        providers[name] = fn()
    except LookupError as e:
        providers[name] = {"ok": False, "error": str(e), "configured": False}
    except Exception as e:  # keep last good data, flag it stale
        err = f"{type(e).__name__}: {e}"[:200]
        old = prev.get(name)
        if old and old.get("ok"):
            providers[name] = {**old, "stale": True, "error": err}
        else:
            providers[name] = {"ok": False, "error": err, "configured": True}

live = [p for p in providers.values() if p.get("ok")]
currency = live[0]["currency"] if live else "EUR"
sym = {"EUR": "€", "USD": "$", "GBP": "£"}.get(currency, currency + " ")


def money(x, sign=False):
    if x is None:
        return "–"
    s = f"{abs(x):,.0f}".replace(",", " ")
    pre = ("+" if x >= 0 else "−") if sign else ("−" if x < 0 else "")
    return f"{pre}{sym}{s}"


total_nav = sum(p["nav"] for p in live)
day = [p["day_pnl"] for p in live if p.get("day_pnl") is not None]
day_pnl = sum(day) if day else None
unreal = sum(p["unrealized_pnl"] for p in live)
cost = total_nav - unreal
combined = sorted((dict(pos, provider=n) for n, p in providers.items() if p.get("ok")
                   for pos in p["positions"]), key=lambda x: -abs(x["value_base"]))
top = [{"symbol": x["symbol"], "provider": x["provider"],
        "value": money(x["value_base"]),
        "pct": f"{100 * x['value_base'] / total_nav:.0f}%" if total_nav else "–",
        "pnl": money(x["pnl_base"], sign=True),
        "pnl_level": "ok" if x["pnl_base"] >= 0 else "bad"} for x in combined[:8]]
level = lambda x: "neutral" if x is None else "ok" if x >= 0 else "bad"

out = {
    "updated": datetime.now().strftime("%Y-%m-%d %H:%M"),
    "configured": any(p.get("ok") or p.get("configured") for p in providers.values()),
    "ok": bool(live),
    "total": {
        "value": money(total_nav) if live else "–",
        "currency": currency,
        "day_pnl": money(day_pnl, sign=True), "day_level": level(day_pnl),
        "unrealized_pnl": money(unreal, sign=True) if live else "–",
        "unrealized_pct": f"{100 * unreal / cost:+.1f}%" if live and cost else "",
        "unrealized_level": level(unreal if live else None),
        "cash": money(sum(p.get("cash") or 0 for p in live)) if live else "–",
        "as_of": min((p.get("as_of") or "" for p in live), default=""),
        "stale": any(p.get("stale") for p in live),
    },
    "positions": top,
    "errors": [f"{n}: {p['error']}" for n, p in providers.items() if p.get("error")],
    "providers": providers,
}
print(json.dumps(out, ensure_ascii=False, indent=1))
PY
rc=$?

if [[ $rc -eq 0 ]] && python3 -m json.tool "$tmp" > /dev/null 2>&1; then
  mv "$tmp" "$OUT.tmp" && mv "$OUT.tmp" "$OUT"
  chmod 644 "$OUT"
else
  echo "$(date '+%F %T') finance.json generation failed" >&2
  exit 1
fi

[[ $print -eq 1 ]] && cat "$OUT"
exit 0
