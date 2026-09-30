#!/usr/bin/env python3
"""Direct broker reports for Glance. No orders, transfers or Wallet totals."""
import argparse
import base64
import copy
from datetime import datetime
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import re
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

FLEX = "https://ndcdyn.interactivebrokers.com/AccountManagement/FlexWebService"
T212 = "https://live.trading212.com/api/v0/equity/account/summary"
NAMES = {"ibkr": "IBKR", "trading212": "Trading 212"}
SCHEMA = 2


class DataError(Exception):
    """Controlled messages without credential URLs or account identifiers."""


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise DataError("Unexpected API redirect; credentials were not forwarded")


def request(url, params=None, authorization=None):
    headers = {"User-Agent": "homelab-finance/2", "Accept": "application/json, application/xml"}
    if authorization:
        headers["Authorization"] = authorization
    if params:
        url += "?" + urllib.parse.urlencode(params)
    with urllib.request.build_opener(NoRedirect()).open(urllib.request.Request(url, headers=headers), timeout=60) as response:
        return response.read()


def read_env(path):
    values = {}
    try:
        with open(path) as source:
            for line in source:
                match = re.match(r"\s*([A-Z][A-Z0-9_]*)=(.*)$", line)
                if match:
                    values[match[1]] = match[2].strip().strip("\"'")
    except FileNotFoundError:
        pass
    return values


def number(value):
    try:
        result = float(value) if not isinstance(value, bool) else float("nan")
    except (TypeError, ValueError):
        raise DataError("Required broker amount is missing; check report fields") from None
    if not math.isfinite(result):
        raise DataError("Broker returned an invalid amount")
    return result


def currency(value):
    if not isinstance(value, str) or not re.fullmatch(r"[A-Z]{3}", value):
        raise DataError("Account base currency is missing; include Account Information in the report")
    return value


def date_stamp(value):
    if re.fullmatch(r"\d{8}", value or ""):
        value = f"{value[:4]}-{value[4:6]}-{value[6:]}"
    try:
        return datetime.strptime(value, "%Y-%m-%d").strftime("%Y-%m-%d")
    except (TypeError, ValueError):
        raise DataError("Report date is missing or invalid") from None


def ibkr(env, source=None):
    if source:
        body = Path(source).read_bytes()
    else:
        token, query = env["IBKR_FLEX_TOKEN"], env["IBKR_FLEX_QUERY_ID"]
        response = ET.fromstring(request(FLEX + "/SendRequest", {"t": token, "q": query, "v": 3}))
        if response.findtext("Status") != "Success" or not response.findtext("ReferenceCode"):
            raise DataError("IBKR could not generate the report; check token and query")
        # Use the documented endpoint, never a server-supplied credential URL.
        for _ in range(12):
            time.sleep(5)
            body = request(FLEX + "/GetStatement", {"t": token, "q": response.findtext("ReferenceCode"), "v": 3})
            root = ET.fromstring(body)
            if root.tag == "FlexQueryResponse":
                break
            if root.findtext("ErrorCode") not in ("1019", "1018", "1009"):
                raise DataError("IBKR rejected the report request; check Flex configuration")
        else:
            raise DataError("IBKR report was not ready within one minute")
    statements = ET.fromstring(body).findall(".//FlexStatement")
    if len(statements) != 1:
        raise DataError("Select exactly one IBKR account in the Flex query; no accounts were silently omitted")
    statement = statements[0]
    equity = list(statement.iter("EquitySummaryByReportDateInBase"))
    latest = max(equity, key=lambda row: row.get("reportDate", "")) if equity else None
    nav = statement.find(".//ChangeInNAV")
    info = statement.find(".//AccountInformation")
    base = currency((nav.get("currency") if nav is not None else None)
                    or (latest.get("currency") if latest is not None else None)
                    or ((info.get("currency") or info.get("baseCurrency")) if info is not None else None))
    if nav is not None and nav.get("endingValue") is not None:
        value = number(nav.get("endingValue"))
    elif latest is not None:
        value = number(latest.get("total"))
    else:
        raise DataError("Include NAV in Base or Change in NAV; holdings are not reported NAV")
    cash = number(latest.get("cash")) if latest is not None and latest.get("cash") is not None else None
    if cash is None:
        rows = [row for row in statement.iter("CashReportCurrency") if row.get("currency") == "BASE_SUMMARY"]
        if rows:
            cash = number(rows[-1].get("endingCash"))
    positions = []
    position_rows = list(statement.iter("OpenPosition"))
    if position_rows and not any(row.get("levelOfDetail", "SUMMARY") == "SUMMARY" for row in position_rows):
        raise DataError("Select Summary for Open Positions; lot-only reports are not complete holdings")
    for position in position_rows:
        if position.get("levelOfDetail", "SUMMARY") != "SUMMARY":
            continue
        native = currency(position.get("currency"))
        fx = number(position.get("fxRateToBase")) if native != base else 1.0
        if fx <= 0:
            raise DataError("A position's FX rate is invalid")
        positions.append({"symbol": position.get("symbol", "?"), "currency": native,
                          "value_base": number(position.get("positionValue")) * fx,
                          "pnl_base": number(position.get("fifoPnlUnrealized")) * fx})
    unrealized = sum(p["pnl_base"] for p in positions) if statement.find(".//OpenPositions") is not None or positions else None
    return {"nav": value, "cash": cash, "currency": base, "as_of": date_stamp(statement.get("toDate")),
            "unrealized_pnl": unrealized, "positions": positions, "basis": "IBKR end-of-day Flex report"}


def trading212(env):
    credentials = f"{env['TRADING212_API_KEY']}:{env['TRADING212_API_SECRET']}".encode()
    summary = json.loads(request(T212, authorization="Basic " + base64.b64encode(credentials).decode()))
    cash = summary["cash"]
    return {"nav": number(summary["totalValue"]), "currency": currency(summary["currency"]),
            "cash": sum(number(cash[key]) for key in ("availableToTrade", "inPies", "reservedForOrders")),
            "unrealized_pnl": number(summary["investments"]["unrealizedProfitLoss"]),
            "as_of": datetime.now().strftime("%Y-%m-%d %H:%M"), "positions": [],
            "basis": "Trading 212 live account summary; holdings detail not collected"}


def load(path):
    try:
        result = json.loads(Path(path).read_text())
        return result if isinstance(result, dict) else {}
    except (OSError, ValueError):
        return {}


def atomic_json(path, value, mode=0o600):
    descriptor, temporary = tempfile.mkstemp(prefix=".finance-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w") as output:
            json.dump(value, output, ensure_ascii=False, allow_nan=False, indent=2)
            output.flush()
            os.fsync(output.fileno())
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def validate(data):
    currency(data["currency"])
    for key in ("nav", "cash", "unrealized_pnl"):
        if data.get(key) is not None:
            if type(data[key]) not in (int, float):
                raise DataError("Invalid cached broker amount")
            number(data[key])
        elif key == "nav":
            raise DataError("Missing cached broker NAV")
    if not isinstance(data["positions"], list) or not data.get("as_of"):
        raise DataError("Incomplete cached broker report")
    for position in data["positions"]:
        number(position["value_base"])
        number(position["pnl_base"])


def error_text(error):
    if isinstance(error, DataError):
        return str(error)
    if isinstance(error, urllib.error.HTTPError):
        return f"Broker request returned HTTP {error.code}; check credentials, permissions and rate limit"
    if isinstance(error, (urllib.error.URLError, TimeoutError)):
        return "Broker request failed or timed out"
    return "Broker response could not be parsed; review account/report configuration"


def collect(cache_dir, source=None):
    definitions = {
        "ibkr": (ibkr, "ibkr-flex.env", ("IBKR_FLEX_TOKEN", "IBKR_FLEX_QUERY_ID"), 1800),
        "trading212": (trading212, "trading212.env", (
            "TRADING212_API_KEY",
            "TRADING212_API_SECRET",
        ), 120),
    }
    providers = {}
    for name, (fetch, filename, keys, ttl) in definitions.items():
        env = read_env(Path.home() / ".config/homelab" / filename) if not source else {}
        configured = bool(source and name == "ibkr") or all(env.get(key) for key in keys)
        if not configured:
            providers[name] = {"ok": False, "configured": False, "stale": False, "error": None}
            continue
        fingerprint = hashlib.sha256(json.dumps({key: env.get(key) for key in keys}, sort_keys=True).encode()).hexdigest()
        cached = load(cache_dir / f"{name}.json") if not source else {}
        if cached.get("schema") != SCHEMA or cached.get("identity") != fingerprint:
            cached = {}
        old = cached.get("data")
        try:
            validate(old)
        except (DataError, KeyError, TypeError):
            old = None
        try:
            saved_at = cached.get("saved_at")
            cache_fresh = type(saved_at) in (int, float) and math.isfinite(saved_at) and saved_at <= time.time() < saved_at + ttl
            if old is not None and cache_fresh:
                data = copy.deepcopy(old)
            else:
                data = fetch(env, source) if name == "ibkr" else fetch(env)
                validate(data)
                if not source:
                    atomic_json(cache_dir / f"{name}.json", {"schema": SCHEMA, "identity": fingerprint,
                                "saved_at": time.time(), "data": data})
            providers[name] = {**data, "ok": True, "configured": True, "stale": False, "error": None}
        except (DataError, OSError, ValueError, KeyError, TypeError, ET.ParseError) as error:
            providers[name] = {**(copy.deepcopy(old) or {}), "ok": old is not None,
                              "configured": True, "stale": old is not None, "error": error_text(error)}
    return providers


def render(providers, unit):
    included = {}
    for name, provider in providers.items():
        if not provider["ok"]:
            continue
        converted = copy.deepcopy(provider)
        rate = 1.0
        if provider["currency"] != unit:
            try:
                reference = json.loads(request("https://api.frankfurter.app/latest", {"from": provider["currency"], "to": unit}))
                rate = number(reference["rates"][unit])
                if rate <= 0:
                    raise DataError("Invalid reference FX rate")
                provider["fx_date"] = date_stamp(reference["date"])
            except (DataError, OSError, ValueError, KeyError, TypeError):
                provider["error"] = "Reference FX unavailable; native broker balance is excluded from combined total"
                continue
        for key in ("nav", "cash", "unrealized_pnl"):
            if converted.get(key) is not None:
                converted[key] *= rate
        for position in converted["positions"]:
            position["value_base"] *= rate
            position["pnl_base"] *= rate
        included[name] = converted

    def money(value, currency_code=unit, sign=False):
        if value is None:
            return "–"
        return f"{currency_code} {value:+,.2f}" if sign else f"{currency_code} {value:,.2f}"

    def aggregate(key):
        if not included or any(provider.get(key) is None for provider in included.values()):
            return None
        return sum(provider[key] for provider in included.values())

    value, unrealized = aggregate("nav"), aggregate("unrealized_pnl")
    breakdown = []
    for name, provider in providers.items():
        status = "Not configured" if not provider["configured"] else "Unavailable" if not provider["ok"] else "Stale — last fetch failed" if provider["stale"] else "Connected"
        if provider["ok"] and name not in included:
            status = "Native value only — FX unavailable"
        breakdown.append({"name": NAMES[name], "value": money(provider.get("nav"), provider.get("currency", unit)),
                          "status": status, "as_of": provider.get("as_of", ""), "basis": provider.get("basis", ""),
                          "warning": bool(provider.get("error")), "error": provider.get("error") or ""})
    positions = sorted((dict(position, provider=name) for name, provider in included.items()
                        for position in provider["positions"]), key=lambda position: -abs(position["value_base"]))
    return {"schema": SCHEMA, "updated": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "configured": any(provider["configured"] for provider in providers.values()), "ok": bool(included),
            "coverage": sorted(included), "providers": providers, "provider_breakdown": breakdown,
            "total": {"value": money(value), "value_numeric": value, "currency": unit,
                      "cash": money(aggregate("cash")), "unrealized_pnl": money(unrealized, sign=True),
                      "unrealized_level": "neutral" if unrealized is None else "ok" if unrealized >= 0 else "bad",
                      "as_of": min((provider["as_of"] for provider in included.values()), default=""),
                      "stale": any(provider["stale"] for provider in included.values()),
                      "partial": any(provider["configured"] and name not in included for name, provider in providers.items())},
            "positions": [{"symbol": position["symbol"], "provider": NAMES[position["provider"]],
                           "value": money(position["value_base"]), "pnl": money(position["pnl_base"], sign=True),
                           "pct": f"{position['value_base'] / value * 100:.1f}%" if value else "–",
                           "pnl_level": "ok" if position["pnl_base"] >= 0 else "bad"} for position in positions[:8]],
            "errors": [f"{NAMES[name]}: {provider['error']}" for name, provider in providers.items() if provider.get("error")]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--health", action="store_true", help="cached booleans only; no balances or API calls")
    parser.add_argument("--print", action="store_true", help="print private snapshot including balances")
    parser.add_argument("--from-file", metavar="XML", help="IBKR-only local report; no broker calls or live cache data writes")
    args = parser.parse_args()
    if args.health and (args.print or args.from_file):
        parser.error("--health reads cached status; use it alone")
    output_dir = Path(os.environ.get("OUT_DIR", str(Path.home() / "services/glance/assets")))
    output = output_dir / "finance.json"
    if args.health:
        snapshot = load(output)
        try:
            health = {name: {"ok": bool(provider.get("ok")), "configured": bool(provider.get("configured") or provider.get("ok")),
                           "stale": bool(provider.get("stale")), "error_present": bool(provider.get("error"))}
                      for name, provider in snapshot["providers"].items()}
            print(json.dumps({"updated": snapshot.get("updated"), "ok": bool(snapshot.get("ok")), "providers": health}, indent=2))
        except (KeyError, TypeError, AttributeError):
            print(json.dumps({"ok": False, "error": "Snapshot missing or unreadable; run finance-status.sh first."}))
            return 1
        return 0
    cache_dir = Path(os.environ.get("FINANCE_CACHE_DIR", str(Path.home() / ".config/homelab/finance-cache")))
    cache_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(cache_dir, 0o700)
    output_dir.mkdir(parents=True, exist_ok=True)
    with open(cache_dir / "operation.lock", "a") as lock:
        os.chmod(cache_dir / "operation.lock", 0o600)
        fcntl.flock(lock, fcntl.LOCK_EX)
        snapshot = render(collect(cache_dir, args.from_file), currency(os.environ.get("FINANCE_REPORT_CURRENCY", "EUR")))
        atomic_json(output, snapshot, 0o644)
    if args.print:
        print(json.dumps(snapshot, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, DataError):
        print("Finance snapshot generation failed; previous output was preserved.", file=sys.stderr)
        sys.exit(1)
