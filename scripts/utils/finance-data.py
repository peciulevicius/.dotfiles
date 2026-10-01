#!/usr/bin/env python3
"""Read-only investment account reports. No orders, transfers or Wallet totals."""
import argparse
import base64
import copy
from collections import deque
from datetime import datetime
import fcntl
import hashlib
import hmac
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
T212_POSITIONS = "https://live.trading212.com/api/v0/equity/positions"
NAMES = {"ibkr": "IBKR", "trading212": "Trading 212", "kraken": "Kraken", "ledger": "Ledger"}
MEMPOOL = "https://mempool.space/api/address/"
ETH_RPC = "https://ethereum-rpc.publicnode.com"
SOL_RPC = "https://api.mainnet-beta.solana.com"
LEDGER_COINS = {  # env key -> (symbol, Kraken EUR pair, address pattern, units per coin)
    "LEDGER_BTC_ADDRESSES": ("BTC", "XBTEUR", r"(bc1[a-z0-9]{20,87}|[13][a-km-zA-HJ-NP-Z1-9]{25,34})", 10**8),
    "LEDGER_ETH_ADDRESSES": ("ETH", "ETHEUR", r"0x[0-9a-fA-F]{40}", 10**18),
    "LEDGER_SOL_ADDRESSES": ("SOL", "SOLEUR", r"[1-9A-HJ-NP-Za-km-z]{32,44}", 10**9),
}
STALE_DAYS = 35
KRAKEN = "https://api.kraken.com"
SCHEMA = 2


class DataError(Exception):
    """Controlled messages without credential URLs or account identifiers."""


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise DataError("Unexpected API redirect; credentials were not forwarded")


def request(url, params=None, authorization=None, body=None):
    headers = {"User-Agent": "homelab-finance/2", "Accept": "application/json, application/xml"}
    if authorization:
        headers["Authorization"] = authorization
    if params:
        url += "?" + urllib.parse.urlencode(params)
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    with urllib.request.build_opener(NoRedirect()).open(urllib.request.Request(url, data=data, headers=headers), timeout=60) as response:
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
    authorization = "Basic " + base64.b64encode(credentials).decode()
    summary = json.loads(request(T212, authorization=authorization))
    cash = summary["cash"]
    data = {"nav": number(summary["totalValue"]), "currency": currency(summary["currency"]),
            "cash": sum(number(cash[key]) for key in ("availableToTrade", "inPies", "reservedForOrders")),
            "unrealized_pnl": number(summary["investments"]["unrealizedProfitLoss"]),
            "as_of": datetime.now().strftime("%Y-%m-%d %H:%M"), "positions": [],
            "holdings_error": None, "basis": "Trading 212 live account summary and positions"}
    try:
        rows = json.loads(request(T212_POSITIONS, authorization=authorization))
        if not isinstance(rows, list):
            raise DataError("Trading 212 holdings response is not a complete positions list")
        positions, tickers = [], set()
        for row in rows:
            if not isinstance(row, dict) or not isinstance(row.get("instrument"), dict) or not isinstance(row.get("walletImpact"), dict):
                raise DataError("Trading 212 returned an incomplete holding")
            instrument, impact = row["instrument"], row["walletImpact"]
            ticker = instrument.get("ticker")
            if not isinstance(ticker, str) or not ticker or ticker in tickers:
                raise DataError("Trading 212 returned missing or duplicate instrument identifiers")
            tickers.add(ticker)
            if currency(impact.get("currency")) != data["currency"]:
                raise DataError("Trading 212 holding wallet currency differs from the account; detail omitted")
            # Broker wallet amounts already include its currency conversion.
            # quantity includes pie shares; never add quantityInPies again.
            positions.append({"symbol": ticker, "quantity": number(row.get("quantity")),
                              "currency": currency(instrument.get("currency")),
                              "value_base": number(impact.get("currentValue")),
                              "pnl_base": number(impact.get("unrealizedProfitLoss"))})
        data["positions"] = positions
    except (DataError, OSError, ValueError, KeyError, TypeError) as error:
        # Keep a freshly reported account total usable. Do not copy older
        # holdings into a fresh report or publish a partly parsed list.
        data["holdings_error"] = error_text(error)
        data["basis"] = "Trading 212 live account summary; holdings unavailable"
    return data


def kraken_result(raw):
    response = json.loads(raw)
    if not isinstance(response, dict) or response.get("error") != [] or not isinstance(response.get("result"), dict):
        raise DataError("Kraken rejected the request or returned an invalid response; check read permission and nonce")
    return response["result"]


def kraken_signature(path, payload, secret):
    try:
        decoded = base64.b64decode(secret, validate=True)
    except ValueError:
        raise DataError("Kraken API secret must be valid Base64") from None
    if not decoded:
        raise DataError("Kraken API secret is empty")
    encoded = urllib.parse.urlencode(payload)
    message = path.encode() + hashlib.sha256((str(payload["nonce"]) + encoded).encode()).digest()
    return base64.b64encode(hmac.new(decoded, message, hashlib.sha512).digest()).decode()


def kraken_balance(env, cache_dir):
    # The only private endpoint in this collector reads balances. Never accept
    # a caller-supplied private route or forward signed credentials on redirects.
    path = "/0/private/Balance"
    key_hash = hashlib.sha256(env["KRAKEN_API_KEY"].encode()).hexdigest()
    nonce_file = cache_dir / f"kraken-nonce-{key_hash}.json"
    with open(cache_dir / "kraken-nonce.lock", "a") as lock:
        os.chmod(cache_dir / "kraken-nonce.lock", 0o600)
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            saved = json.loads(nonce_file.read_text())
        except FileNotFoundError:
            saved = {"nonce": 0}
        except (OSError, ValueError):
            raise DataError("Kraken nonce state is unreadable; preserve it and repair before retrying") from None
        if not isinstance(saved, dict) or type(saved.get("nonce")) is not int or not 0 <= saved["nonce"] < 2**63 - 1:
            raise DataError("Kraken nonce state is invalid; preserve it before retrying")
        nonce = max(time.time_ns() // 1_000_000, saved["nonce"] + 1)
        if nonce >= 2**63:
            raise DataError("Kraken nonce exceeded its supported range")
        payload = {"nonce": nonce}
        signature = kraken_signature(path, payload, env["KRAKEN_API_SECRET"])
        # Persist before sending, and hold the lock until the response arrives:
        # a timeout or concurrent collector must not reuse/reorder a nonce.
        atomic_json(nonce_file, {"nonce": nonce})
        req = urllib.request.Request(KRAKEN + path,
            data=urllib.parse.urlencode(payload).encode(), method="POST",
            headers={"API-Key": env["KRAKEN_API_KEY"], "API-Sign": signature,
                     "Content-Type": "application/x-www-form-urlencoded", "User-Agent": "homelab-finance/2"})
        with urllib.request.build_opener(NoRedirect()).open(req, timeout=60) as response:
            return kraken_result(response.read())


def kraken(env, cache_dir):
    balances = kraken_balance(env, cache_dir)
    if any(not isinstance(code, str) for code in balances):
        raise DataError("Kraken returned invalid asset codes")
    quantities = {code: number(quantity) for code, quantity in balances.items()}
    quantities = {code: quantity for code, quantity in quantities.items() if quantity != 0}
    if not quantities:
        return {"nav": 0.0, "cash": None, "currency": "EUR", "unrealized_pnl": None,
                "positions": [], "as_of": datetime.now().strftime("%Y-%m-%d %H:%M"),
                "basis": "Kraken default wallet balances, net of pending withdrawals"}
    assets = kraken_result(request(KRAKEN + "/0/public/Assets"))
    pairs = kraken_result(request(KRAKEN + "/0/public/AssetPairs"))
    aliases = {}
    for code, asset in assets.items():
        if not isinstance(asset, dict):
            raise DataError("Kraken returned invalid asset metadata")
        for label in (code, asset.get("altname")):
            if isinstance(label, str):
                aliases.setdefault(label, set()).add(code)

    def canonical(code):
        # Only documented staking/reward suffixes can use a base-asset price.
        # Never map ETH2 to ETH or tokenized .T equity quantities heuristically.
        if code.endswith(".T"):
            raise DataError("Kraken tokenized assets are not supported; total is unavailable")
        if code.endswith((".B", ".F", ".M", ".S")):
            code = code.rsplit(".", 1)[0]
        matches = aliases.get(code, set())
        if len(matches) != 1:
            raise DataError("A Kraken balance has no unique spot asset mapping; total is unavailable")
        return next(iter(matches))

    eur = canonical("EUR")
    graph = {}
    for name, pair in pairs.items():
        if not isinstance(pair, dict):
            raise DataError("Kraken returned invalid market metadata")
        if pair.get("status") != "online" or pair.get("aclass_base", "currency") != "currency" or pair.get("aclass_quote", "currency") != "currency":
            continue
        base, quote = pair.get("base"), pair.get("quote")
        if base not in assets or quote not in assets:
            continue
        graph.setdefault(base, []).append((quote, name, False))
        graph.setdefault(quote, []).append((base, name, True))

    def route(asset):
        # Prefer direct EUR markets, then a two-market route. Bounded traversal
        # avoids arbitrary conversion chains and unstable implicit assumptions.
        queue = deque([(asset, [])])
        visited = {asset}
        while queue:
            current, steps = queue.popleft()
            if current == eur:
                return steps
            if len(steps) == 2:
                continue
            for target, name, reverse in sorted(graph.get(current, []), key=lambda edge: (edge[0] != eur, edge[0] not in ("ZUSD", "USDT", "XXBT"), edge[1])):
                if target not in visited:
                    visited.add(target)
                    queue.append((target, steps + [(name, reverse)]))
        raise DataError("A Kraken asset has no supported EUR price route; total is unavailable")

    routes = {code: route(canonical(code)) for code in quantities}
    needed = sorted({name for steps in routes.values() for name, _ in steps})
    prices = {}
    for start in range(0, len(needed), 25):
        chunk = needed[start:start + 25]
        tickers = kraken_result(request(KRAKEN + "/0/public/Ticker", {"pair": ",".join(chunk)}))
        for name in chunk:
            ticker = tickers.get(name)
            if not isinstance(ticker, dict):
                raise DataError("Kraken did not return every required price; total is unavailable")
            if any(not isinstance(ticker.get(side), list) or not ticker[side] for side in ("a", "b")):
                raise DataError("Kraken returned an incomplete bid/ask price; total is unavailable")
            ask, bid = number(ticker["a"][0]), number(ticker["b"][0])
            if bid <= 0 or ask < bid:
                raise DataError("A Kraken market has no valid bid/ask price; total is unavailable")
            prices[name] = (bid + ask) / 2
    positions = []
    for code, quantity in quantities.items():
        value = quantity
        for name, reverse in routes[code]:
            value *= 1 / prices[name] if reverse else prices[name]
        positions.append({"symbol": code, "quantity": quantity, "currency": "EUR",
                          "value_base": value, "pnl_base": None})
    return {"nav": sum(position["value_base"] for position in positions), "cash": None,
            "currency": "EUR", "unrealized_pnl": None, "positions": positions,
            "as_of": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "basis": "Kraken default wallet balances × spot midpoints (indicative EUR value)"}


def ledger_balance(symbol, address):
    # Only the address is sent to the public endpoint; it never leaves this function in an error.
    if symbol == "BTC":
        stats = json.loads(request(MEMPOOL + address))
        funded = stats["chain_stats"]["funded_txo_sum"] + stats["mempool_stats"]["funded_txo_sum"]
        spent = stats["chain_stats"]["spent_txo_sum"] + stats["mempool_stats"]["spent_txo_sum"]
        return number(funded - spent)
    if symbol == "ETH":
        reply = json.loads(request(ETH_RPC, body={"jsonrpc": "2.0", "id": 1, "method": "eth_getBalance", "params": [address, "latest"]}))
        return number(int(reply["result"], 16))
    reply = json.loads(request(SOL_RPC, body={"jsonrpc": "2.0", "id": 1, "method": "getBalance", "params": [address]}))
    return number(reply["result"]["value"])


def ledger(env):
    positions = []
    for key, (symbol, pair, pattern, units) in LEDGER_COINS.items():
        addresses = [item.strip() for item in env.get(key, "").split(",") if item.strip()]
        if not addresses:
            continue
        if any(not re.fullmatch(pattern, address) for address in addresses):
            raise DataError(f"A Ledger {symbol} address in ledger.env is malformed; check it")
        quantity = sum(ledger_balance(symbol, address) for address in set(addresses)) / units
        if quantity == 0:
            continue
        ticker = kraken_result(request(KRAKEN + "/0/public/Ticker", {"pair": pair}))
        if len(ticker) != 1:
            raise DataError("Kraken did not return exactly one price; total is unavailable")
        quote = next(iter(ticker.values()))
        if not isinstance(quote, dict) or any(not isinstance(quote.get(side), list) or not quote[side] for side in ("a", "b")):
            raise DataError("Kraken returned an incomplete bid/ask price; total is unavailable")
        ask, bid = number(quote["a"][0]), number(quote["b"][0])
        if bid <= 0 or ask < bid:
            raise DataError("A Kraken market has no valid bid/ask price; total is unavailable")
        positions.append({"symbol": symbol, "quantity": quantity, "currency": "EUR",
                          "value_base": quantity * (bid + ask) / 2, "pnl_base": None})
    return {"nav": sum(position["value_base"] for position in positions), "cash": None,
            "currency": "EUR", "unrealized_pnl": None, "positions": positions,
            "as_of": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "basis": "Ledger public addresses (on-chain, read-only) × Kraken spot midpoints"}


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
        if not isinstance(position, dict) or not isinstance(position.get("symbol"), str):
            raise DataError("Invalid cached holding")
        number(position["value_base"])
        if position.get("pnl_base") is not None:
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
        "kraken": (lambda env: kraken(env, cache_dir), "kraken.env", (
            "KRAKEN_API_KEY",
            "KRAKEN_API_SECRET",
        ), 120),
        "ledger": (ledger, "ledger.env", tuple(LEDGER_COINS), 300),
    }
    providers = {}
    for name, (fetch, filename, keys, ttl) in definitions.items():
        env = read_env(Path.home() / ".config/homelab" / filename) if not source else {}
        present = any if name == "ledger" else all
        configured = bool(source and name == "ibkr") or present(env.get(key) for key in keys)
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
            if name == "trading212" and old is not None and "holdings_error" not in old:
                cache_fresh = False  # Upgrade a valid summary-only cache on the next refresh.
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


def balances_path():
    return Path(os.environ.get("FINANCE_BALANCES_FILE", str(Path.home() / ".config/homelab/balances.json")))


def read_balances(path):
    try:
        data = json.loads(path.read_text())
    except FileNotFoundError:
        return None
    except (OSError, ValueError):
        raise DataError("balances.json is unreadable; fix or restore it") from None
    if not isinstance(data, dict) or not isinstance(data.get("accounts"), list):
        raise DataError("balances.json needs an 'accounts' list")
    return data


def set_balance(assignment):
    name, _, amount = assignment.partition("=")
    path = balances_path()
    data = read_balances(path)
    if data is None:
        raise DataError("No balances.json yet; create it first (services/glance/README.md → Accounts)")
    matches = [account for account in data["accounts"] if str(account.get("name", "")).lower() == name.strip().lower()]
    if len(matches) != 1:
        raise DataError("No single account has that name; names: " + ", ".join(str(a.get("name")) for a in data["accounts"]))
    try:
        value = float(amount.replace(",", "."))
    except ValueError:
        raise DataError("Amount must be a number, e.g. --set 'Emergency=3200.50'") from None
    if not math.isfinite(value) or value < 0:
        raise DataError("Amount must be a non-negative number (credit cards: the amount owed)")
    matches[0]["balance"] = value
    matches[0]["updated"] = datetime.now().strftime("%Y-%m-%d")
    atomic_json(path, data)


def accounts_report(unit, investments):
    data = read_balances(balances_path())
    if data is None:
        return {"configured": False}
    if data.get("currency", unit) != unit:
        raise DataError(f"balances.json currency must be {unit}")
    today = datetime.now().date()
    rows, owned, owed = [], 0.0, 0.0
    emergency_names = {str(item).lower() for item in data.get("emergency", [])}
    emergency, emergency_set = 0.0, False
    for account in data["accounts"]:
        name, balance = str(account.get("name", "?")), account.get("balance")
        credit = account.get("type") == "credit"
        updated = account.get("updated")
        age = None
        try:
            age = (today - datetime.strptime(updated, "%Y-%m-%d").date()).days
        except (TypeError, ValueError):
            pass
        stale = balance is not None and (age is None or age > STALE_DAYS)
        if balance is not None:
            number(balance)
            if credit:
                owed += balance
            else:
                owned += balance
            if name.lower() in emergency_names:
                emergency += balance
                emergency_set = True
        rows.append({"name": name + (" (owed)" if credit else ""),
                     "value": "not set" if balance is None else f"{unit} {-balance if credit else balance:,.2f}",
                     "updated": updated or "", "stale": stale,
                     "level": "neutral" if balance is None else "bad" if credit and balance else "ok"})
    spend = data.get("monthly_spend")
    months = emergency / spend if emergency_set and isinstance(spend, (int, float)) and spend > 0 else None
    any_set = any(account.get("balance") is not None for account in data["accounts"])
    net_cash = owned - owed
    worth = net_cash + (investments or 0.0)
    return {"configured": True, "rows": rows, "any_set": any_set,
            "net_cash": f"{unit} {net_cash:,.2f}",
            "emergency": {"set": emergency_set, "value": f"{unit} {emergency:,.2f}",
                          "months": "–" if months is None else f"{months:.1f}",
                          "level": "neutral" if months is None else "ok" if months >= 6 else "warn" if months >= 3 else "bad",
                          "spend": "not set" if not spend else f"{unit} {spend:,.0f}/month"},
            "net_worth": {"value": f"{unit} {worth:,.2f}", "investments_included": investments is not None},
            "stale": any(row["stale"] for row in rows)}


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
            if position.get("pnl_base") is not None:
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
        detail_error = provider.get("holdings_error")
        if detail_error and status == "Connected":
            status = "Connected — holdings unavailable"
        warnings = [provider.get("error"), f"Holdings: {detail_error}" if detail_error else None]
        breakdown.append({"name": NAMES[name], "value": money(provider.get("nav"), provider.get("currency", unit)),
                          "cash": money(provider.get("cash"), provider.get("currency", unit)),
                          "unrealized_pnl": money(provider.get("unrealized_pnl"), provider.get("currency", unit), sign=True),
                          "status": status, "as_of": provider.get("as_of", ""), "basis": provider.get("basis", ""),
                          "warning": any(warnings), "error": "; ".join(warning for warning in warnings if warning)})
    positions = sorted((dict(position, provider=name) for name, provider in included.items()
                        for position in provider["positions"]), key=lambda position: -abs(position["value_base"]))
    try:
        accounts = accounts_report(unit, value)
    except DataError as error:
        accounts = {"configured": True, "error": str(error), "rows": [], "any_set": False}
    return {"schema": SCHEMA, "updated": datetime.now().strftime("%Y-%m-%d %H:%M"), "accounts": accounts,
            "configured": any(provider["configured"] for provider in providers.values()), "ok": bool(included),
            "coverage": sorted(included), "providers": providers, "provider_breakdown": breakdown,
            "total": {"value": money(value), "value_numeric": value, "currency": unit,
                      "cash": money(aggregate("cash")), "unrealized_pnl": money(unrealized, sign=True),
                      "unrealized_level": "neutral" if unrealized is None else "ok" if unrealized >= 0 else "bad",
                      "as_of": min((provider["as_of"] for provider in included.values()), default=""),
                      "stale": any(provider["stale"] for provider in included.values()),
                      "partial": any(provider["configured"] and name not in included for name, provider in providers.items())},
            "positions": [{"symbol": position["symbol"], "provider": NAMES[position["provider"]],
                           "value": money(position["value_base"]), "pnl": money(position.get("pnl_base"), sign=True),
                           "pct": f"{position['value_base'] / value * 100:.1f}%" if value else "–",
                           "pnl_level": "neutral" if position.get("pnl_base") is None else "ok" if position["pnl_base"] >= 0 else "bad"} for position in positions[:8]],
            "errors": [f"{NAMES[name]}: {provider['error']}" for name, provider in providers.items() if provider.get("error")]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--health", action="store_true", help="cached booleans only; no balances or API calls")
    parser.add_argument("--print", action="store_true", help="print private snapshot including balances")
    parser.add_argument("--from-file", metavar="XML", help="IBKR-only local report; no broker calls or live cache data writes")
    parser.add_argument("--set", metavar="NAME=AMOUNT", help="update one Swedbank/manual account balance, then refresh the snapshot")
    args = parser.parse_args()
    if args.set:
        set_balance(args.set)
    if args.health and (args.print or args.from_file):
        parser.error("--health reads cached status; use it alone")
    output_dir = Path(os.environ.get("OUT_DIR", str(Path.home() / "services/glance/assets")))
    output = output_dir / "finance.json"
    if args.health:
        snapshot = load(output)
        try:
            health = {name: {"ok": bool(provider.get("ok")), "configured": bool(provider.get("configured") or provider.get("ok")),
                           "stale": bool(provider.get("stale")), "error_present": bool(provider.get("error") or provider.get("holdings_error"))}
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
    except DataError as error:
        print(f"Finance snapshot generation failed: {error}", file=sys.stderr)
        sys.exit(1)
    except (OSError, ValueError):
        print("Finance snapshot generation failed; previous output was preserved.", file=sys.stderr)
        sys.exit(1)
