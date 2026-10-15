#!/usr/bin/env python3
"""Studio PR bot (cron, every 2 min): agents commit to `agent/*` branches in
~/dev/studio/<repo>; this pushes them, opens a PR per branch, previews the newest
change on studio-preview and posts the links on the PR and in #ai-studio.

Runs on the host with the owner's git/gh credentials. It only ever pushes
`agent/*` branches — never main — except when it creates the private GitHub
repo for a brand-new Studio product (initial push of its `main`). See services/studio-preview/README.md.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

HOME = Path.home()
STUDIO = HOME / "dev/studio"  # every git repo directly under it is handled
PREVIEW = "http://127.0.0.1:7301"
STATE = HOME / ".config/homelab/studio-pr-bot.json"
LOCK = HOME / ".config/homelab/studio-pr-bot.lock"
GAME_MODE = HOME / ".config/homelab/game-mode.state"
os.environ["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + os.environ.get("PATH", "")
# gh keeps its login in the macOS Keychain, which cron can't read (every PR
# call failed with HTTP 401 on 2026-10-15). A copy of the token lives in a
# 0600 file: `umask 077; gh auth token > ~/.config/homelab/gh-token`.
_TOKEN = HOME / ".config/homelab/gh-token"
if _TOKEN.exists() and "GH_TOKEN" not in os.environ:
    os.environ["GH_TOKEN"] = _TOKEN.read_text().strip()


def sh(*args, cwd=None, check=True):
    r = subprocess.run(args, cwd=cwd, capture_output=True, text=True)
    if check and r.returncode:
        raise RuntimeError(f"{' '.join(args)}: {r.stderr.strip() or r.stdout.strip()}")
    return r.stdout.strip()


def api(method, path, body=None):
    req = urllib.request.Request(PREVIEW + path, method=method,
                                 data=json.dumps(body).encode() if body is not None else None,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return {"httpError": e.code, **json.loads(e.read() or b"{}")}


def wait(pred, timeout):
    end = time.time() + timeout
    while time.time() < end:
        s = api("GET", "/status?slot=owner")
        if pred(s):
            return s
        time.sleep(5)
    return api("GET", "/status?slot=owner")


def discord(text):
    env = HOME / ".config/homelab/studio-discord.env"
    if not env.exists():
        return
    url = next((l.split("=", 1)[1].strip().strip("'\"") for l in env.read_text().splitlines()
                if l.startswith("STUDIO_DISCORD_WEBHOOK=")), None)
    if url:
        req = urllib.request.Request(url, data=json.dumps({"content": text[:1900]}).encode(),
                                     headers={"Content-Type": "application/json", "User-Agent": "studio-pr-bot"})
        urllib.request.urlopen(req, timeout=15).read()


# Posted with the owner's own GitHub login (the only one the bot has), so make
# authorship obvious; a separate identity would need a GitHub App.
SIGNED = "\n\n<sub>🤖 Posted by the Studio PR bot (automation on Džiugas's account), not by Džiugas.</sub>"


def preview_and_report(repo, branch, sha, pr):
    r = api("POST", "/preview", {"repo": repo, "branch": branch, "slot": "owner"})
    if r.get("httpError"):
        print(f"{repo}@{branch}: preview busy/refused: {r}")
        return False
    mine = lambda s: s.get("repo") == repo and s.get("branch") == branch
    s = wait(lambda s: not mine(s) or s["state"] in ("running", "failed", "crashed"), 600)
    if not mine(s):
        print(f"{repo}@{branch}: preview superseded by {s.get('repo')}@{s.get('branch')}; retrying next run")
        return False
    if s["state"] != "running":
        body = f"⚠️ Preview failed for `{sha[:7]}`:\n```\n{(s.get('error') or '')[:1500]}\n```" + SIGNED
        sh("gh", "pr", "comment", pr["url"], "--body", body)
        discord(f"⚠️ **{repo}** PR #{pr['number']} preview failed: {pr['url']}")
        return True
    api("POST", "/test", {"slot": "owner"})
    done = wait(lambda s: not mine(s) or ((s.get("test") or {}).get("sha") == s.get("sha")
                                           and (s.get("test") or {}).get("state") in ("passed", "failed")), 600)
    if not mine(done):
        print(f"{repo}@{branch}: preview replaced during the screenshot run; retrying next run")
        return False
    t = done.get("test") or {}
    L = s["links"]
    # Per-PR link: keeps working after another PR takes the slot (it restarts this branch on demand).
    tap = "http://100.81.171.49:7301/p?" + urllib.parse.urlencode({"repo": repo, "branch": branch})
    phone = (f"- **iPhone:** tap {tap} (Tailscale on, Expo Go installed). Opens Expo Go; if another PR is "
             f"running it starts this one first (~1 min)\n" if "phoneTap" in L else "")
    tested = (f"✅ {len(t.get('shots', []))} screens: {t['index']}" if t.get("state") == "passed"
              else f"❌ smoke test failed:\n```\n{(t.get('error') or 'timed out')[:1200]}\n```")
    body = (f"### 📱 Preview of `{sha[:7]}` is live\n{phone}"
            f"- **Web:** {tap if 'phoneTap' not in L else L['web']}\n- **Screenshots:** {tested}\n\n"
            f"_The link above always opens this PR's branch._" + SIGNED)
    sh("gh", "pr", "comment", pr["url"], "--body", body)
    discord(f"📱 **{repo}** PR #{pr['number']}: {pr['title']}\n"
            + (f"Tap on iPhone (opens Expo Go): {tap}\n" if "phoneTap" in L else f"Open: {tap}\n") + (f"Screenshots: {t['index']}\n" if t.get("state") == "passed" else "Smoke test ❌\n")
            + pr["url"])
    return True


def main():
    if GAME_MODE.exists():
        return
    try:
        LOCK.mkdir()
    except FileExistsError:
        if time.time() - LOCK.stat().st_mtime < 1800:
            return
        shutil.rmtree(LOCK)
        LOCK.mkdir()
    try:
        state = json.loads(STATE.read_text()) if STATE.exists() else {}
        for path in sorted(p for p in STUDIO.iterdir() if (p / ".git").exists() and not p.name.startswith(".")):
            repo = path.name
            if not sh("git", "remote", cwd=path, check=False):
                # A new Studio product an agent started with `git init`: give it
                # a private GitHub repo. Names are restricted so a folder can't
                # smuggle options or odd characters into `gh`.
                if not re.fullmatch(r"[a-z0-9][a-z0-9-]{1,60}", repo):
                    print(f"skip {repo}: repo names must be lowercase letters, digits and dashes")
                    continue
                if not sh("git", "rev-parse", "-q", "--verify", "main", cwd=path, check=False):
                    continue  # nothing committed on main yet
                url = sh("gh", "repo", "create", f"peciulevicius/{repo}", "--private", "--source", ".",
                         "--remote", "origin", "--push", cwd=path)
                print(f"created private repo for {repo}: {url}")
                discord(f"🆕 New Studio repo **{repo}** (private): https://github.com/peciulevicius/{repo}")
            sh("git", "fetch", "-q", "--prune", "origin", cwd=path)
            newest = None
            for line in sh("git", "for-each-ref", "--sort=-committerdate", "refs/heads/agent/",
                           "--format=%(refname:short) %(objectname)", cwd=path).splitlines():
                branch, sha = line.split()
                try:
                    if not sh("git", "log", "--format=%h", "-1", f"origin/main..{branch}", cwd=path):
                        continue  # nothing new vs main (merged, or empty): no PR to open
                    remote = sh("git", "rev-parse", "-q", "--verify", f"origin/{branch}", cwd=path, check=False)
                    if remote != sha:
                        sh("git", "push", "-q", "--force-with-lease", "origin", f"{branch}:{branch}", cwd=path)
                        print(f"pushed {repo}@{branch} {sha[:7]}")
                        continue  # let GitHub catch up; the PR opens on the next run
                    prs = json.loads(sh("gh", "pr", "list", "--head", branch, "--state", "open",
                                        "--json", "number,url,title", cwd=path) or "[]")
                    if not prs and json.loads(sh("gh", "pr", "list", "--head", branch, "--state", "closed",
                                                 "--json", "number", cwd=path) or "[]"):
                        continue  # someone closed this branch's PR on purpose: never reopen it
                    if not prs:
                        title = sh("git", "log", "--format=%s", "-1", f"origin/main..{branch}", cwd=path) or branch
                        log = sh("git", "log", "--format=- %s", f"origin/main..{branch}", cwd=path)
                        url = sh("gh", "pr", "create", "--base", "main", "--head", branch, "--title", title,
                                 "--body", f"Opened by the Studio PR bot for an agent branch.\n\n{log}\n\n"
                                           "A preview with an iPhone link and screenshots follows in a comment." + SIGNED, cwd=path)
                        prs = [json.loads(sh("gh", "pr", "view", url, "--json", "number,url,title", cwd=path))]
                        print(f"opened {url}")
                except Exception as e:  # one bad branch must not stop the others (or the state save)
                    print(f"{time.strftime('%F %T')} {repo}@{branch}: {e}", file=sys.stderr)
                    continue
                key = f"{repo}@{branch}"
                if state.get(key) != sha and newest is None:
                    newest = (branch, sha, prs[0], key)
            if newest:
                branch, sha, pr, key = newest
                if preview_and_report(repo, branch, sha, pr):
                    state[key] = sha
                    STATE.write_text(json.dumps(state, indent=1))  # saved now: a later error can't redo this preview
        STATE.write_text(json.dumps(state, indent=1))
    finally:
        shutil.rmtree(LOCK, ignore_errors=True)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # cron: one line in the log, the next run retries
        print(f"{time.strftime('%F %T')} error: {e}", file=sys.stderr)
        sys.exit(1)
