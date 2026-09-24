#!/usr/bin/env python3
"""Report pinned Docker images that have newer releases upstream.

    check-image-updates.py              # table of every pinned image
    check-image-updates.py --outdated   # only images with a newer release
    check-image-updates.py --quiet      # one line per outdated image (for the audit)

Why: most of the stack pins an exact tag, and a pinned tag never moves, so
Watchtower silently does nothing for it. On 2026-09-21 a Vaultwarden pin three
releases behind broke the Bitwarden iOS app for four hours. Pinning is still
the right call; this makes the "review pins quarterly" step cheap.

It only reads registries — it never changes a compose file or pulls an image.
Bump deliberately, one service at a time, after reading the release notes.

Comparison rules:
  - a tag is compared only against tags of the same shape: same number of
    version components and the same suffix (`16-alpine` against `17-alpine`,
    never against `16.4` or `16-bookworm`); a trailing 7-hex-digit build hash
    (`-7d94e11`) is treated as part of the shape, not the version
  - `latest`, untagged and variable (`${VAR}`) images are skipped — they are
    not pinned, so there is nothing to compare
  - date-style versions (2024.07.0) are only compared with date-style ones
  - the jump is classified as patch, minor or major by the first component
    that differs; majors of databases (postgres, mariadb, redis, couchdb)
    need a data migration and are marked as such
"""

import argparse
import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SERVICES = REPO_ROOT / "services"
TIMEOUT = 20
DATABASES = {"postgres", "mariadb", "redis", "couchdb", "mysql"}
# Registries with legacy tags that look like newer versions but are not.
# image → regex of tags to ignore. Keep each entry commented with the reason.
IGNORE_TAGS = {
    # LinuxServer once tagged this image with *Calibre's* version (5.29.0 …
    # 5.33.2); Calibre-Web itself is 0.6.x.
    "lscr.io/linuxserver/calibre-web": re.compile(r"^[1-9]\d*\."),
}
HASH_SUFFIX = re.compile(r"-[0-9a-f]{7,}$")
VERSION = re.compile(r"^v?(\d+(?:\.\d+)*)(.*)$")


def http_json(url, headers=None):
    req = urllib.request.Request(url, headers=headers or {})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        link = resp.headers.get("Link", "")
        return json.load(resp), link


# ── Registry clients ────────────────────────────────────────────────────────

def dockerhub_tags(repo, pages=6):
    """Most recently updated tags from Docker Hub (library images need 'library/')."""
    if "/" not in repo:
        repo = f"library/{repo}"
    url = f"https://hub.docker.com/v2/repositories/{repo}/tags?page_size=100&ordering=last_updated"
    tags = []
    for _ in range(pages):
        data, _ = http_json(url)
        tags += [t["name"] for t in data.get("results", [])]
        url = data.get("next")
        if not url:
            break
    return tags


def oci_tags(registry, repo):
    """Full tag list from an OCI registry that allows anonymous pulls (ghcr, gitlab)."""
    token_url = {
        "ghcr.io": f"https://ghcr.io/token?scope=repository:{repo}:pull",
        "registry.gitlab.com": f"https://gitlab.com/jwt/auth?service=container_registry&scope=repository:{repo}:pull",
    }[registry]
    token, _ = http_json(token_url)
    auth = {"Authorization": f"Bearer {token.get('token') or token.get('access_token')}"}
    url = f"https://{registry}/v2/{repo}/tags/list?n=1000"
    tags = []
    while url:
        data, link = http_json(url, auth)
        tags += data.get("tags") or []
        m = re.search(r"<([^>]+)>;\s*rel=\"next\"", link)
        url = f"https://{registry}{m.group(1)}" if m else None
    return tags


def list_tags(image):
    name = image
    if name.startswith("lscr.io/"):                 # LinuxServer's alias for ghcr.io
        name = "ghcr.io/" + name[len("lscr.io/"):]
    first = name.split("/", 1)[0]
    if first in ("ghcr.io", "registry.gitlab.com"):
        return oci_tags(first, name.split("/", 1)[1])
    if first == "docker.io":
        name = name.split("/", 1)[1]
    return dockerhub_tags(name)


# ── Tag comparison ──────────────────────────────────────────────────────────

def parse(tag):
    """(version tuple, shape) or None for tags that are not versions."""
    base = HASH_SUFFIX.sub("", tag)
    hashed = base != tag
    m = VERSION.match(base)
    if not m:
        return None
    nums = tuple(int(p) for p in m.group(1).split("."))
    prefix_v = tag.startswith("v")
    return nums, (len(nums), m.group(2), prefix_v, hashed)


def is_calver(nums):
    """Date-style versions (2024.07.0) never compare against semver (4.0.6).
    LinuxServer images still carry old date tags like 2021.12.16, which would
    otherwise look newer than every real release."""
    return nums[0] >= 1900


def classify(old, new):
    for i, (a, b) in enumerate(zip(old, new)):
        if a != b:
            return ("major", "minor", "patch")[min(i, 2)]
    return "same"


def newest(current, tags):
    cur = parse(current)
    if not cur:
        return None
    cur_nums, shape = cur
    best = None
    for t in tags:
        p = parse(t)
        if not p or p[1] != shape or is_calver(p[0]) != is_calver(cur_nums):
            continue
        if p[0] > cur_nums and (best is None or p[0] > best[0]):
            best = (p[0], t)
    return best[1] if best else None


# ── Compose scanning ────────────────────────────────────────────────────────

def pinned_images():
    found = []
    for compose in sorted(SERVICES.glob("*/docker-compose.yml")):
        for line in compose.read_text().splitlines():
            m = re.match(r"\s*image:\s*[\"']?([^\"'\s#]+)", line)
            if not m:
                continue
            ref = m.group(1)
            if "$" in ref or ":" not in ref.rsplit("/", 1)[-1]:
                continue                               # variable or untagged
            image, tag = ref.rsplit(":", 1)
            if tag == "latest":
                continue
            found.append((compose.parent.name, image, tag))
    return found


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--outdated", action="store_true", help="only show images with a newer release")
    ap.add_argument("--quiet", action="store_true", help="one line per outdated image; exit 1 if any")
    args = ap.parse_args()

    rows, errors = [], []
    for service, image, tag in pinned_images():
        try:
            tags = list_tags(image)
            if image in IGNORE_TAGS:
                tags = [t for t in tags if not IGNORE_TAGS[image].match(t)]
            latest = newest(tag, tags)
        except (urllib.error.URLError, KeyError, ValueError, TimeoutError) as e:
            errors.append(f"{service}: {image} — registry lookup failed ({e})")
            continue
        kind = classify(parse(tag)[0], parse(latest)[0]) if latest and parse(tag) else ""
        repo_name = image.rsplit("/", 1)[-1]
        note = "data migration" if kind == "major" and repo_name in DATABASES else ""
        rows.append((service, image, tag, latest or "", kind, note))

    outdated = [r for r in rows if r[3]]
    if args.quiet:
        for s, img, tag, new, kind, note in outdated:
            print(f"{s}: {img} {tag} → {new} ({kind}{', ' + note if note else ''})")
        for e in errors:
            print(e, file=sys.stderr)
        return 1 if outdated else 0

    shown = outdated if args.outdated else rows
    if shown:
        w = [max(len(str(r[i])) for r in shown + [("service", "image", "pinned", "newer", "jump", "")]) for i in range(5)]
        print(f"{'service':<{w[0]}}  {'image':<{w[1]}}  {'pinned':<{w[2]}}  {'newer':<{w[3]}}  jump")
        for s, img, tag, new, kind, note in shown:
            flag = f"{kind}{' (' + note + ')' if note else ''}" if new else "up to date"
            print(f"{s:<{w[0]}}  {img:<{w[1]}}  {tag:<{w[2]}}  {new or '-':<{w[3]}}  {flag}")
    print(f"\n{len(outdated)} of {len(rows)} pinned images have a newer release.")
    for e in errors:
        print(f"! {e}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
