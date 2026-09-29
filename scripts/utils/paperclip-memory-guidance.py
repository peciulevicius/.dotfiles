#!/usr/bin/env python3
"""Preview or append shared memory guidance to current Paperclip instructions."""
import argparse
import datetime
import hashlib
import http.cookiejar
import json
import os
from pathlib import Path
import shlex
import sys
import urllib.error
import urllib.parse
import urllib.request

START = "<!-- homelab-shared-memory:v1 -->"
END = "<!-- /homelab-shared-memory:v1 -->"


def read_env(path):
    values = {}
    for line in path.read_text().splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        key, value = line.split("=", 1)
        parts = shlex.split(value, comments=True)
        values[key.strip()] = parts[0] if parts else ""
    return values


def fingerprint(value):
    return hashlib.sha256(value.encode()).hexdigest()


def current(agent):
    name = agent["name"].lower()
    return agent["status"] != "terminated" and "retired" not in name and "duplicate hire" not in name


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--base-url", default="http://127.0.0.1:3100")
    parser.add_argument("--credentials", type=Path,
        default=Path.home() / ".config/homelab/paperclip-admin.env")
    parser.add_argument("--backup-dir", type=Path,
        default=Path.home() / ".config/homelab/paperclip-instruction-backups")
    parser.add_argument("--addendum", type=Path,
        default=Path(__file__).resolve().parents[2] / "services/paperclip/shared-ai-memory-addendum.md")
    args = parser.parse_args()
    # Board credentials must never be sent to a caller-supplied remote host.
    parsed = urllib.parse.urlparse(args.base_url)
    if parsed.scheme != "http" or parsed.hostname not in {"127.0.0.1", "localhost", "::1"} or parsed.path not in {"", "/"}:
        raise ValueError("Use the local Paperclip HTTP endpoint")
    base = args.base_url.rstrip("/")
    guidance = args.addendum.read_text().strip()
    if not guidance.startswith("# Shared AI memory") or START in guidance or END in guidance:
        raise ValueError("Unexpected shared memory addendum")
    addition = "\n\n" + START + "\n" + guidance + "\n" + END + "\n"
    credentials = read_env(args.credentials)
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

    def api(method, path, body=None):
        req = urllib.request.Request(base + path, method=method,
            headers={"Origin": base, "Content-Type": "application/json"},
            data=json.dumps(body).encode() if body is not None else None)
        with opener.open(req, timeout=30) as response:
            return json.load(response)

    api("POST", "/api/auth/sign-in/email", {
        "email": credentials.get("PAPERCLIP_ADMIN_EMAIL", "dziugas@peciulevicius.com"),
        "password": credentials.pop("PAPERCLIP_ADMIN_PASSWORD")})
    try:
        plan = []
        configured = 0
        for company in api("GET", "/api/companies"):
            for agent in api("GET", "/api/companies/" + company["id"] + "/agents"):
                if not current(agent):
                    continue
                endpoint = "/api/agents/" + agent["id"]
                bundle = api("GET", endpoint + "/instructions-bundle")
                path = bundle["entryFile"]
                query = urllib.parse.urlencode({"path": path})
                entry = api("GET", endpoint + "/instructions-bundle/file?" + query)
                content = entry["content"]
                if START in content or END in content:
                    if content.count(START) != 1 or content.count(END) != 1 or addition.strip() not in content:
                        raise ValueError("Existing shared guidance differs; review before updating")
                    configured += 1
                    print(company["name"] + " / " + agent["name"] + ": already configured")
                    continue
                if not entry["editable"] or not content.strip():
                    raise ValueError("Instructions are empty or not editable")
                plan.append({"id": agent["id"], "name": agent["name"],
                    "company": company["name"], "path": path, "content": content,
                    "root": bundle["rootPath"], "status": agent["status"]})
                print(company["name"] + " / " + agent["name"] + ": append guidance (" + agent["status"] + ")")
        print(f"Already configured: {configured}; pending: {len(plan)}")
        if not args.apply or not plan:
            print("No writes." if not args.apply else "All current agents verified.")
            return 0
        if any(item["status"] == "running" for item in plan):
            raise ValueError("An affected agent is running; retry after its run completes")
        stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
        backup = args.backup_dir / stamp
        backup.mkdir(parents=True, mode=0o700)
        os.chmod(args.backup_dir, 0o700)
        # Save every original before the first API mutation. These files can
        # contain private role context and must never be committed.
        for item in plan:
            with open(backup / (item["id"] + ".json"), "x",
                    opener=lambda path, flags: os.open(path, flags, 0o600)) as output:
                json.dump(item, output)
        print("Private originals saved under " + str(backup))
        updated = set()
        for item in plan:
            endpoint = "/api/agents/" + item["id"]
            fresh = api("GET", endpoint)
            if not current(fresh) or fresh["status"] == "running":
                raise ValueError("Agent changed or started running; stop and rerun preview")
            bundle = api("GET", endpoint + "/instructions-bundle")
            if bundle["rootPath"] != item["root"] or bundle["entryFile"] != item["path"]:
                raise ValueError("Instruction location changed; stop and review")
            query = urllib.parse.urlencode({"path": item["path"]})
            latest = api("GET", endpoint + "/instructions-bundle/file?" + query)["content"]
            target = item["content"].rstrip() + addition
            key = (item["root"], item["path"])
            if key in updated and latest == target:
                print(item["company"] + " / " + item["name"] + ": shared instruction file verified")
                continue
            if fingerprint(latest) != fingerprint(item["content"]):
                raise ValueError("Instructions changed concurrently; stop and review")
            api("PUT", endpoint + "/instructions-bundle/file", {"path": item["path"], "content": target})
            verified = api("GET", endpoint + "/instructions-bundle/file?" + query)["content"]
            if verified != target:
                raise ValueError("Instruction verification failed")
            updated.add(key)
            print(item["company"] + " / " + item["name"] + ": appended and verified")
        print("Completed. Models, assignments and pause/resume settings were not edited.")
        return 0
    finally:
        api("POST", "/api/auth/sign-out", {})


if __name__ == "__main__":
    try:
        sys.exit(main())
    except urllib.error.HTTPError as error:
        print(f"Paperclip refused the operation (HTTP {error.code}); rerun preview before retrying.", file=sys.stderr)
        sys.exit(1)
    except Exception as error:
        # Do not expose credentials or instruction contents in tracebacks.
        print(f"Memory guidance failed ({type(error).__name__}: {error}); completed writes remain retryable.", file=sys.stderr)
        sys.exit(1)
