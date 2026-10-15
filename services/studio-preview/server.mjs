// Studio preview runner. Two preview slots, each running one branch of a
// Studio repo as a dev server — an Expo app (phone via Expo Go + web build)
// or a website (Astro / Next / Vite) — which Playwright can screenshot:
//   owner  port 8081, published on Tailscale; only the host PR bot uses it, so
//          the links posted on a PR keep showing that PR (2026-10-15: one
//          shared slot let an agent's own test replace a PR's preview).
//   agent  port 8082, internal (`paperclip` network); agents try their work.
//
//   POST /preview {repo, branch, slot?, app?}  check out + start (async; slot defaults to "agent";
//                                        app picks apps/<app> in a monorepo, default: the Expo app)
//   POST /test    {slot?}                screenshot the running preview (async)
//   GET  /status[?slot=owner|agent]      slot state, links, log tail, last test
//   GET  /p?repo=…&branch=…              per-PR link: opens that branch (starts it in the owner
//                                        slot if needed, with a self-refreshing wait page)
//   GET  /open                           owner slot: 302 to exp://… (tap on the phone)
//   GET  /qr.png                         owner slot: QR of the exp:// link
//   GET  /artifacts/…                    screenshots and their index.html
//   POST /publish {repo, branch, channel} publish the branch's Expo app to EAS Update (async)
//   GET  /publish                        last publish: state, group id, links
//   GET  /u?p=<projectId>&g=<groupId>    302 to exp://u.expo.dev/… (opens that update in Expo Go)
import { spawn } from "node:child_process";
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import QRCode from "qrcode";

const HOST = process.env.PREVIEW_HOST || "100.81.171.49";
const STUDIO = process.env.STUDIO_DIR; // host path of ~/dev/studio, mounted at the same path
// Every git repo directly under ~/dev/studio can be previewed; no config per repo.
const repos = () => fs.readdirSync(STUDIO).filter((d) => !d.startsWith(".") && fs.existsSync(path.join(STUDIO, d, ".git")));
const API_PORT = 7301;
const PREVIEWS = path.join(STUDIO, ".previews");
const ARTIFACTS = path.join(PREVIEWS, "artifacts");
const BRANCH_RE = /^[A-Za-z0-9._\/-]{1,120}$/;
const APP_RE = /^[a-z0-9][a-z0-9_-]{0,40}$/;
const BUSY = ["preparing", "installing", "starting"];

const newSlot = (name, port, publicHost) => ({
  name, port, publicHost, proc: null, app: null,
  repo: null, branch: null, sha: null, kind: null, state: "idle", error: null, startedAt: null, test: null, log: [],
});
const slots = { owner: newSlot("owner", 8081, HOST), agent: newSlot("agent", 8082, "studio-preview") };

function links(s) {
  const web = `http://${s.publicHost}:${s.port}`;
  if (s.kind !== "expo") return { web };
  return s.name === "owner"
    ? { phone: `exp://${HOST}:${s.port}`, phoneTap: `http://${HOST}:${API_PORT}/open`, qr: `http://${HOST}:${API_PORT}/qr.png`, web }
    : { web };
}

const view = (s) => { const { proc, ...rest } = s; return { ...rest, links: links(s) }; };

// Which folder to run. A monorepo (pnpm workspace / Turborepo) has only
// tooling at its root, so run the app inside it: the Expo app first (the
// phone preview is the point), otherwise the first website. Single-app repos
// run from the root as before.
function appDir(wt, app) {
  const read = (d) => { try { return JSON.parse(fs.readFileSync(path.join(d, "package.json"), "utf8")); } catch { return null; } };
  const root = read(wt) || {};
  const isMono = fs.existsSync(path.join(wt, "pnpm-workspace.yaml")) || Array.isArray(root.workspaces) || root.workspaces?.packages;
  if (!isMono) return wt;
  if (app) {
    // Explicit choice (e.g. "web" for apps/web): the PR comment links both.
    for (const top of ["apps", "packages"]) {
      const d = path.join(wt, top, app);
      if (read(d)) return d;
    }
    throw new Error(`no app "${app}" under apps/ or packages/`);
  }
  const candidates = [];
  for (const top of ["apps", "packages"]) {
    const base = path.join(wt, top);
    if (!fs.existsSync(base)) continue;
    for (const d of fs.readdirSync(base).sort()) {
      const pkg = read(path.join(base, d));
      if (pkg) candidates.push({ dir: path.join(base, d), deps: { ...pkg.dependencies, ...pkg.devDependencies }, scripts: pkg.scripts || {} });
    }
  }
  const pick = candidates.find((c) => c.deps.expo) || candidates.find((c) => c.deps.next || c.scripts.dev);
  if (!pick) throw new Error("monorepo without an Expo app or a website under apps/ — don't know what to preview");
  return pick.dir;
}

// How to run a checkout: Expo apps via `expo start`, websites via their dev
// script with host/port flags their framework understands.
function devCommand(wt, s) {
  const pkg = JSON.parse(fs.readFileSync(path.join(wt, "package.json"), "utf8"));
  const deps = { ...pkg.dependencies, ...pkg.devDependencies };
  const env = { CI: "1", EXPO_NO_TELEMETRY: "1", NEXT_TELEMETRY_DISABLED: "1", ASTRO_TELEMETRY_DISABLED: "1" };
  const port = String(s.port);
  if (deps.expo)
    return { kind: "expo", args: ["exec", "expo", "start", "--port", port, "--lan"], env: { ...env, REACT_NATIVE_PACKAGER_HOSTNAME: s.publicHost } };
  if (deps.next) return { kind: "web", args: ["exec", "next", "dev", "--hostname", "0.0.0.0", "--port", port], env };
  if (!pkg.scripts?.dev) throw new Error("no expo dependency and no `dev` script — don't know how to run this repo");
  return { kind: "web", args: ["run", "dev", "--host", "0.0.0.0", "--port", port], env }; // Astro, Vite, SvelteKit
}

function log(s, line) {
  s.log.push(`${new Date().toISOString().slice(11, 19)} ${line}`);
  if (s.log.length > 200) s.log.splice(0, s.log.length - 200);
}

function run(cmd, args, opts = {}) {
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, args, { ...opts, env: { ...process.env, ...opts.env } });
    let out = "";
    p.stdout.on("data", (d) => (out += d));
    p.stderr.on("data", (d) => (out += d));
    p.on("close", (code) => (code === 0 ? resolve(out) : reject(new Error(`${cmd} ${args.join(" ")} -> ${code}\n${out.slice(-1500)}`))));
  });
}

// Dev servers run in their own process group: `pnpm run dev` starts the real
// server (next, astro, metro) as a grandchild, and killing only pnpm left it
// holding the port — the next preview then never came up (2026-10-15).
function killGroup(p, sig) {
  try { process.kill(-p.pid, sig); } catch {}
}

async function stop(s) {
  if (!s.proc) return freePort(s.port);
  const p = s.proc;
  s.proc = null;
  killGroup(p, "SIGTERM");
  await new Promise((r) => setTimeout(r, 2000));
  killGroup(p, "SIGKILL");
  await freePort(s.port);
}

// Belt and braces: whatever still listens on the slot's port gets killed
// (from /proc, so no lsof/fuser needed in the image).
async function freePort(port) {
  const hex = port.toString(16).toUpperCase().padStart(4, "0");
  const inodes = new Set();
  for (const f of ["/proc/net/tcp", "/proc/net/tcp6"]) {
    try {
      for (const line of fs.readFileSync(f, "utf8").split("\n").slice(1)) {
        const c = line.trim().split(/\s+/);
        if (c[1]?.endsWith(":" + hex) && c[3] === "0A") inodes.add(c[9]);
      }
    } catch {}
  }
  if (!inodes.size) return;
  for (const pid of fs.readdirSync("/proc").filter((d) => /^\d+$/.test(d))) {
    try {
      for (const fd of fs.readdirSync(`/proc/${pid}/fd`)) {
        const m = /socket:\[(\d+)\]/.exec(fs.readlinkSync(`/proc/${pid}/fd/${fd}`));
        if (m && inodes.has(m[1])) { process.kill(Number(pid), "SIGKILL"); break; }
      }
    } catch {}
  }
  await new Promise((r) => setTimeout(r, 500));
}

async function waitForServer(s, ms) {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    if (!s.proc) return false; // the dev server already exited; its output is in s.error
    try {
      if (s.kind === "expo") {
        const r = await fetch(`http://127.0.0.1:${s.port}/status`);
        if ((await r.text()).includes("packager-status:running")) return true;
      } else {
        await fetch(`http://127.0.0.1:${s.port}/`); // any HTTP answer means the dev server is up
        return true;
      }
    } catch {}
    await new Promise((r) => setTimeout(r, 2000));
  }
  return false;
}

async function startPreview(s, repo, branch, app = null) {
  await stop(s);
  Object.assign(s, { repo, branch, app, sha: null, kind: null, state: "preparing", error: null, startedAt: new Date().toISOString(), test: null, log: [] });
  const repoDir = path.join(STUDIO, repo);
  const wt = path.join(PREVIEWS, s.name, repo);
  try {
    log(s, `checkout ${branch}`);
    await run("git", ["-C", repoDir, "worktree", "remove", "--force", wt]).catch(() => {});
    await run("git", ["-C", repoDir, "worktree", "prune"]);
    await run("git", ["-C", repoDir, "worktree", "add", "--force", "--detach", wt, branch]);
    s.sha = (await run("git", ["-C", wt, "rev-parse", "--short", "HEAD"])).trim();
    log(s, `installing dependencies (${s.sha})`);
    s.state = "installing";
    await run("pnpm", ["install", "--frozen-lockfile"], { cwd: wt }).catch(async () => {
      log(s, "frozen install failed, retrying without --frozen-lockfile");
      await run("pnpm", ["install"], { cwd: wt });
    });
    const dir = appDir(wt, s.app);
    const cmd = devCommand(dir, s);
    s.kind = cmd.kind;
    s.state = "starting";
    log(s, `starting ${cmd.kind} dev server in ${path.relative(wt, dir) || "."}: pnpm ${cmd.args.join(" ")}`);
    await freePort(s.port);
    const p = spawn("pnpm", cmd.args, { cwd: dir, env: { ...process.env, ...cmd.env }, detached: true });
    s.proc = p;
    p.stdout.on("data", (d) => log(s, String(d).trim().slice(0, 300)));
    p.stderr.on("data", (d) => log(s, String(d).trim().slice(0, 300)));
    p.on("close", (code) => {
      if (s.proc === p) Object.assign(s, { proc: null, state: "crashed", error: `dev server exited ${code}\n${s.log.slice(-8).join("\n")}` });
    });
    if (!(await waitForServer(s, 240_000))) throw new Error("dev server did not come up in 4 min");
    s.state = "running";
    log(s, `running: ${links(s).web}`);
  } catch (e) {
    const crash = s.state === "crashed" ? s.error : null;
    await stop(s);
    Object.assign(s, { state: "failed", error: (crash || String(e.message || e)).slice(0, 2000) });
    log(s, `failed: ${s.error.split("\n")[0]}`);
  }
}

async function runTest(s) {
  if (s.state !== "running") throw new Error(`no running preview in the ${s.name} slot (state: ${s.state})`);
  const sha = s.sha;
  const out = path.join(ARTIFACTS, s.repo, `${sha}-${Date.now()}`);
  fs.mkdirSync(out, { recursive: true });
  s.test = { state: "running", sha };
  try {
    const res = await run("node", ["smoke.mjs", `http://127.0.0.1:${s.port}`, out], { cwd: "/srv" });
    const shots = fs.readdirSync(out).filter((f) => f.endsWith(".png"));
    const rel = path.relative(ARTIFACTS, out);
    s.test = { state: "passed", sha, shots: shots.map((f) => `http://${HOST}:${API_PORT}/artifacts/${rel}/${f}`),
               index: `http://${HOST}:${API_PORT}/artifacts/${rel}/index.html`, output: res.slice(-1500) };
  } catch (e) {
    s.test = { state: "failed", sha, error: String(e.message || e).slice(0, 2000) };
  }
}

function send(res, code, body, type = "application/json") {
  if (type === "text/html") type = "text/html; charset=utf-8";
  res.writeHead(code, { "Content-Type": type, "Cache-Control": "no-store" });
  res.end(type.startsWith("application/json") ? JSON.stringify(body, null, 2) : body);
}

async function readJson(req) {
  let b = "";
  for await (const c of req) b += c;
  return b ? JSON.parse(b) : {};
}

const esc = (t) => String(t ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);

// Small phone-friendly page that reloads itself until the preview is ready.
function waitPage(title, detail, refresh = 4) {
  return `<!doctype html><meta name=viewport content="width=device-width,initial-scale=1">
${refresh ? `<meta http-equiv=refresh content="${refresh}">` : ""}<title>${esc(title)}</title>
<style>body{font:17px -apple-system,system-ui;margin:0;padding:32px 24px;background:#0b0d12;color:#e8eaf0}
h1{font-size:22px;margin:0 0 12px}p{color:#9aa3b2;line-height:1.5}pre{white-space:pre-wrap;font-size:12px;color:#6b7385}</style>
<h1>${esc(title)}</h1>${detail}`;
}

// Per-PR link. The PR bot posts this, so a link never goes stale: tapping it
// shows that branch even if another PR took the owner slot since.
function prLink(res, repo, branch, app = null) {
  const s = slots.owner;
  const same = s.repo === repo && s.branch === branch && (s.app || null) === app;
  if (same && s.state === "running") {
    res.writeHead(302, { Location: s.kind === "expo" ? links(s).phone : links(s).web });
    return res.end();
  }
  if (!same && BUSY.includes(s.state))
    return send(res, 200, waitPage("Another preview is starting…", `<p>${esc(s.repo)} @ ${esc(s.branch)} is building. This page retries by itself.</p>`, 8), "text/html");
  if (same && s.state === "failed")
    return send(res, 200, waitPage("This preview failed to start", `<p>The agents fix it on the PR.</p><pre>${esc(s.error)}</pre>`, 0), "text/html");
  if (!same || ["idle", "crashed", "stopped"].includes(s.state)) startPreview(s, repo, branch, app);
  return send(res, 200, waitPage(`Starting ${repo}…`, `<p>${esc(branch)}<br>Usually about a minute. Expo Go opens by itself when it's ready.</p>
<pre>${esc(s.log.slice(-4).join("\n"))}</pre>`), "text/html");
}

// EAS Update publishing: the bundle goes to Expo's CDN, so the owner's phone
// opens it instantly in Expo Go (no dev server, no Mac mini in the loop). Uses
// the Expo login stored in the expo-state volume.
const pub = { state: "idle", repo: null, branch: null, channel: null, sha: null, error: null, group: null, links: null, startedAt: null };
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

async function runPublish(repo, branch, channel) {
  Object.assign(pub, { state: "preparing", repo, branch, channel, sha: null, error: null, group: null, links: null, startedAt: new Date().toISOString() });
  const repoDir = path.join(STUDIO, repo);
  const wt = path.join(PREVIEWS, "publish", repo);
  try {
    await run("git", ["-C", repoDir, "worktree", "remove", "--force", wt]).catch(() => {});
    await run("git", ["-C", repoDir, "worktree", "prune"]);
    await run("git", ["-C", repoDir, "worktree", "add", "--force", "--detach", wt, branch]);
    pub.sha = (await run("git", ["-C", wt, "rev-parse", "--short", "HEAD"])).trim();
    pub.state = "installing";
    await run("pnpm", ["install", "--frozen-lockfile"], { cwd: wt }).catch(() => run("pnpm", ["install"], { cwd: wt }));
    const dir = appDir(wt);
    const cfg = JSON.parse(fs.readFileSync(path.join(dir, "app.json"), "utf8")).expo || {};
    const projectId = cfg.extra?.eas?.projectId;
    if (!projectId || !cfg.updates?.url) throw new Error("this app has no EAS Update set up (no extra.eas.projectId / updates.url in app.json)");
    // Bundling for EAS needs ~1.5 GB; with a dev server running it hit the
    // container's 2.5 GB cap and got SIGKILLed (2026-10-15). Stop the dev
    // servers first (a link tap restarts them) and bundle for iOS only: the
    // owner tests on an iPhone.
    for (const sl of Object.values(slots)) if (sl.proc) { await stop(sl); sl.state = "idle"; log(sl, "stopped to free memory for an EAS publish"); }
    pub.state = "publishing";
    const out = await run("eas", ["update", "--branch", channel, "--environment", "preview", "--message", `${branch} @ ${pub.sha}`,
                                  "--platform", "ios", "--non-interactive", "--json"],
                          { cwd: dir, env: { EAS_NO_VCS: "1", CI: "1", EAS_SKIP_AUTO_FINGERPRINT: "1" } });
    // stdout and stderr are merged and progress lines start with "[expo-cli]",
    // so take the JSON array of update objects at the end of the output.
    const m = out.match(/\[\s*\{[\s\S]*\}\s*\]\s*$/);
    if (!m) throw new Error(`no JSON in eas output: ${out.slice(-400)}`);
    const updates = JSON.parse(m[0]);
    const group = updates[0]?.group;
    if (!UUID.test(group || "")) throw new Error(`unexpected eas output: ${out.slice(-400)}`);
    const owner = cfg.owner, slug = cfg.slug;
    Object.assign(pub, {
      state: "published", group,
      links: {
        phone: `http://${HOST}:${API_PORT}/u?p=${projectId}&g=${group}`,
        expoGo: `exp://u.expo.dev/${projectId}/group/${group}`,
        page: owner && slug ? `https://expo.dev/accounts/${owner}/projects/${slug}/updates/${group}` : null,
      },
    });
  } catch (e) {
    Object.assign(pub, { state: "failed", error: String(e.message || e).slice(-2000) });
  }
}

function pickSlot(name) {
  const s = slots[name || "agent"];
  if (!s) throw Object.assign(new Error("slot must be owner or agent"), { status: 400 });
  return s;
}

http.createServer(async (req, res) => {
  const url = new URL(req.url, "http://x");
  try {
    if (req.method === "GET" && url.pathname === "/health") return send(res, 200, { ok: true });
    if (req.method === "GET" && url.pathname === "/status") {
      const name = url.searchParams.get("slot");
      return send(res, 200, name ? view(pickSlot(name)) : { owner: view(slots.owner), agent: view(slots.agent) });
    }
    if (req.method === "POST" && url.pathname === "/publish") {
      const { repo, branch, channel } = await readJson(req);
      if (!repos().includes(repo)) return send(res, 400, { error: `repo must be one of ${repos().join(", ")}` });
      if (!BRANCH_RE.test(branch || "") || branch.includes("..")) return send(res, 400, { error: "bad branch name" });
      if (!/^[a-z0-9][a-z0-9-]{0,60}$/.test(channel || "")) return send(res, 400, { error: "channel: lowercase letters, digits, dashes" });
      if (["preparing", "installing", "publishing"].includes(pub.state)) return send(res, 409, { error: `busy publishing ${pub.repo}@${pub.branch}` });
      const building = Object.values(slots).find((sl) => BUSY.includes(sl.state));
      if (building) return send(res, 409, { error: `a preview is building (${building.repo}@${building.branch}); retry shortly` });
      runPublish(repo, branch, channel);
      return send(res, 202, { accepted: true, poll: "/publish" });
    }
    if (req.method === "GET" && url.pathname === "/publish") return send(res, 200, pub);
    if (req.method === "GET" && url.pathname === "/u") {
      const p = url.searchParams.get("p"), g = url.searchParams.get("g");
      if (!UUID.test(p || "") || !UUID.test(g || "")) return send(res, 400, { error: "bad project or group id" });
      res.writeHead(302, { Location: `exp://u.expo.dev/${p}/group/${g}` });
      return res.end();
    }
    if (req.method === "GET" && url.pathname === "/p") {
      const repo = url.searchParams.get("repo"), branch = url.searchParams.get("branch");
      const app = url.searchParams.get("app") || null;
      if (!repos().includes(repo) || !BRANCH_RE.test(branch || "") || branch.includes("..") || (app && !APP_RE.test(app)))
        return send(res, 400, waitPage("Unknown preview", "<p>That repo, branch or app doesn't exist.</p>", 0), "text/html");
      return prLink(res, repo, branch, app);
    }
    if (req.method === "GET" && (url.pathname === "/open" || url.pathname === "/qr.png")) {
      const s = slots.owner;
      if (s.kind !== "expo" || s.state !== "running")
        return send(res, 409, { error: s.kind === "web" ? `the preview for ${s.repo}@${s.branch} is a website: open ${links(s).web}`
          : `no app preview is running right now (state: ${s.state}); try again in a minute` });
      if (url.pathname === "/qr.png") return send(res, 200, await QRCode.toBuffer(links(s).phone, { width: 512, margin: 2 }), "image/png");
      res.writeHead(302, { Location: links(s).phone });
      return res.end();
    }
    if (req.method === "GET" && url.pathname.startsWith("/artifacts/")) {
      const file = path.normalize(path.join(ARTIFACTS, decodeURIComponent(url.pathname.slice("/artifacts/".length))));
      if (!file.startsWith(ARTIFACTS + path.sep) || !fs.existsSync(file)) return send(res, 404, { error: "not found" });
      const type = file.endsWith(".png") ? "image/png" : file.endsWith(".html") ? "text/html" : "text/plain";
      return send(res, 200, fs.readFileSync(file), type);
    }
    if (req.method === "POST" && url.pathname === "/preview") {
      const { repo, branch, slot, app } = await readJson(req);
      const s = pickSlot(slot);
      if (app && !APP_RE.test(app)) return send(res, 400, { error: "app: a folder name under apps/ (e.g. mobile, web)" });
      if (!repos().includes(repo)) return send(res, 400, { error: `repo must be one of ${repos().join(", ")}` });
      if (!BRANCH_RE.test(branch || "") || branch.includes("..")) return send(res, 400, { error: "bad branch name" });
      if (BUSY.includes(s.state)) return send(res, 409, { error: `busy: ${s.state} ${s.repo}@${s.branch}` });
      if (["preparing", "installing", "publishing"].includes(pub.state)) return send(res, 409, { error: `busy: publishing ${pub.repo}@${pub.branch} to EAS` });
      startPreview(s, repo, branch, app || null);
      return send(res, 202, { accepted: true, slot: s.name, app: app || null, poll: `/status?slot=${s.name}` });
    }
    if (req.method === "POST" && url.pathname === "/test") {
      const s = pickSlot((await readJson(req)).slot);
      if (s.test?.state === "running") return send(res, 409, { error: "test already running" });
      runTest(s).catch((e) => (s.test = { state: "failed", error: String(e.message || e) }));
      return send(res, 202, { accepted: true, slot: s.name, poll: `/status?slot=${s.name}` });
    }
    return send(res, 404, { error: "not found" });
  } catch (e) {
    return send(res, e.status || 500, { error: String(e.message || e) });
  }
}).listen(API_PORT, () => console.log(`studio-preview on :${API_PORT}, repos ${repos().join(",")}, host ${HOST}`));

process.on("SIGTERM", async () => {
  for (const s of Object.values(slots)) { s.state = "stopped"; await stop(s); }
  process.exit(0);
});
