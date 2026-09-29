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
BUDGETBAKERS_ENV="$HOME/.config/homelab/budgetbakers.env"

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

IBKR_ENV="$IBKR_ENV" BUDGETBAKERS_ENV="$BUDGETBAKERS_ENV" FROM_FILE="$from_file" PREV="$OUT" OUT_DIR="$OUT_DIR" python3 - > "$tmp" <<'PY'
import json, os, re, sys, time, urllib.parse, urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime

FLEX = "https://ndcdyn.interactivebrokers.com/AccountManagement/FlexWebService"
WALLET = "https://rest.budgetbakers.com/wallet/v1/api"
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


def get_json(url, params=None, token=None):
    headers = {**UA, "Accept": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    query = "?" + urllib.parse.urlencode(params or {}) if params else ""
    req = urllib.request.Request(url + query, headers=headers)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


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


def wallet_pages(endpoint, key, token, extra=None, page_limit=200):
    items, offset = [], 0
    while True:
        params = {"limit": page_limit, "offset": offset, **(extra or {})}
        page = get_json(f"{WALLET}/{endpoint}", params, token)
        items.extend(page.get(key, []))
        next_offset = page.get("nextOffset")
        if next_offset is None:
            return items
        offset = next_offset


def fetch_budgetbakers():
    env = read_env(os.environ["BUDGETBAKERS_ENV"])
    token = env.get("BUDGETBAKERS_API_TOKEN")
    if not token:
        raise LookupError("not configured")
    accounts = wallet_pages("accounts", "accounts", token, {"archived": "false"})
    # The budgets endpoint has a lower cap than the other Wallet collections.
    budgets = wallet_pages("budgets", "budgets", token, {"closed": "false"}, page_limit=20)
    categories = wallet_pages("categories", "categories", token)
    category_names = {str(c.get("id")): c.get("name", "Budget") for c in categories}
    balances = []
    for a in accounts:
        if a.get("excludeFromStats") or not isinstance(a.get("balance"), dict):
            continue
        b = a["balance"]
        balances.append({"symbol": a.get("name") or "Wallet account",
                         "description": a.get("accountType", ""), "qty": 1,
                         "currency": b.get("currencyCode") or a.get("currencyCode", "EUR"),
                         "native_value": f(b.get("currentBalance"))})
    currencies = {x["currency"] for x in balances}
    if len(currencies) > 1:
        raise RuntimeError("Wallet accounts use multiple currencies; set them to one reporting currency before combining")
    currency = next(iter(currencies), "EUR")
    positions = [{"symbol": x["symbol"], "description": x["description"], "qty": x["qty"],
                  "currency": currency, "value_base": x["native_value"], "pnl_base": 0.0}
                 for x in balances]
    month = datetime.now().strftime("%Y-%m")
    budget_rows = []
    for budget in budgets:
        period = ((budget.get("spending") or {}).get("current") or {})
        period_start = period.get("periodStart") or ""
        if period_start[:7] != month:
            continue
        spent = period.get("spent")
        limit = period.get("effectiveLimit")
        names = [category_names.get(str(cid), "Budget") for cid in budget.get("categoryIds", [])]
        budget_rows.append({"name": budget.get("name") or (", ".join(names) or "Budget"),
                            "currency": budget.get("currencyCode") or currency,
                            "spent": f(spent), "limit": f(limit) if limit is not None else None,
                            "month": month})
    return {"ok": True, "error": None, "as_of": datetime.now().strftime("%Y-%m-%d"),
            "currency": currency, "nav": sum(x["value_base"] for x in positions),
            "cash": sum(x["value_base"] for x in positions), "day_pnl": None,
            "unrealized_pnl": 0.0, "positions": positions, "budgets": budget_rows,
            "configured": True}


PROVIDERS = {"ibkr": (fetch_ibkr, 1800), "budgetbakers": (fetch_budgetbakers, 21600)}

try:
    prev = json.load(open(os.environ["PREV"])).get("providers", {})
except (FileNotFoundError, ValueError):
    prev = {}

providers = {}
for name, (fn, ttl) in PROVIDERS.items():
    try:
        cache_path = os.path.join(os.environ["OUT_DIR"], f"finance-{name}-cache.json")
        config_path = os.environ["IBKR_ENV"] if name == "ibkr" else os.environ["BUDGETBAKERS_ENV"]
        configured = bool(os.environ.get("FROM_FILE")) if name == "ibkr" else bool(read_env(config_path).get("BUDGETBAKERS_API_TOKEN"))
        if name == "ibkr":
            configured = configured or all(read_env(config_path).get(k) for k in ("IBKR_FLEX_TOKEN", "IBKR_FLEX_QUERY_ID"))
        if not configured:
            raise LookupError("not configured")
        try:
            cache = json.load(open(cache_path))
        except (FileNotFoundError, ValueError):
            cache = {}
        if (not os.environ.get("FROM_FILE") and cache.get("saved_at", 0) + ttl > time.time()
                and cache.get("data", {}).get("ok")):
            providers[name] = cache["data"]
        else:
            data = fn()
            providers[name] = data
            with open(cache_path, "w") as cf:
                json.dump({"saved_at": time.time(), "data": data}, cf)
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
for p in live:
    if p["currency"] != currency:
        try:
            fx = get_json("https://api.frankfurter.app/latest", {"from": p["currency"], "to": currency})["rates"][currency]
        except Exception as e:
            p["ok"] = False
            p["error"] = f"FX conversion unavailable: {type(e).__name__}"
            continue
        for key in ("nav", "cash", "unrealized_pnl", "day_pnl"):
            if p.get(key) is not None:
                p[key] *= fx
        for pos in p.get("positions", []):
            pos["value_base"] *= fx
            pos["pnl_base"] *= fx
        for budget in p.get("budgets", []):
            if budget["currency"] != currency:
                try:
                    rate = get_json("https://api.frankfurter.app/latest", {"from": budget["currency"], "to": currency})["rates"][currency]
                    budget["spent"] *= rate
                    if budget["limit"] is not None:
                        budget["limit"] *= rate
                    budget["currency"] = currency
                except Exception:
                    pass
    p["currency"] = currency
live = [p for p in providers.values() if p.get("ok")]
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
provider_breakdown = [{"name": n.upper() if n == "ibkr" else "BudgetBakers",
                       "value": money(p["nav"]), "currency": currency,
                       "ok": True, "stale": bool(p.get("stale"))}
                      for n, p in providers.items() if p.get("ok")]
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
        "value_numeric": total_nav if live else None,
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
    "provider_breakdown": provider_breakdown,
    "budget_categories": [{"name": b["name"], "currency": b["currency"],
                           "spent": money(b["spent"]),
                           "limit": money(b["limit"]) if b["limit"] is not None else "–",
                           "remaining": money(b["limit"] - b["spent"]) if b["limit"] is not None else "–",
                           "spent_numeric": b["spent"], "limit_numeric": b["limit"]}
                          for p in providers.values() if p.get("ok")
                          for b in p.get("budgets", [])[:6]],
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
