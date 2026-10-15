// Studio preview runner. One preview slot: the most recently requested branch
// of a Studio repo runs as a dev server — an Expo app (phone via Expo Go + web
// build) or a website (Astro / Next / Vite) — and Playwright can screenshot it. Agents call it from the `paperclip`
// network (http://studio-preview:7301); the PR bot calls it from the host.
//
//   POST /preview {repo, branch}  check the branch out and start it (async)
//   POST /test    {}              screenshot the running preview (async)
//   GET  /status                  slot state, links, last test result
//   GET  /open                    302 to exp://… (tap on the phone; Expo apps)
//   GET  /qr.png                  QR of the exp:// link (Expo apps)
//   GET  /artifacts/…             screenshots and their index.html
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
const METRO_PORT = 8081;
const WT_ROOT = path.join(STUDIO, ".previews");
const ARTIFACTS = path.join(WT_ROOT, "artifacts");
const BRANCH_RE = /^[A-Za-z0-9._\/-]{1,120}$/;

const slot = { repo: null, branch: null, sha: null, kind: null, state: "idle", error: null, startedAt: null, test: null, log: [] };
let metro = null;

const links = () => ({
  ...(slot.kind === "expo" ? {
    phone: `exp://${HOST}:${METRO_PORT}`,
    phoneTap: `http://${HOST}:${API_PORT}/open`,
    qr: `http://${HOST}:${API_PORT}/qr.png`,
  } : {}),
  web: `http://${HOST}:${METRO_PORT}`,
});

// How to run a checkout: Expo apps via `expo start`, websites via their dev
// script with host/port flags their framework understands.
function devCommand(wt) {
  const pkg = JSON.parse(fs.readFileSync(path.join(wt, "package.json"), "utf8"));
  const deps = { ...pkg.dependencies, ...pkg.devDependencies };
  const env = { CI: "1", EXPO_NO_TELEMETRY: "1", NEXT_TELEMETRY_DISABLED: "1", ASTRO_TELEMETRY_DISABLED: "1" };
  if (deps.expo)
    return { kind: "expo", args: ["exec", "expo", "start", "--port", String(METRO_PORT), "--lan"], env: { ...env, REACT_NATIVE_PACKAGER_HOSTNAME: HOST } };
  if (deps.next) return { kind: "web", args: ["exec", "next", "dev", "--hostname", "0.0.0.0", "--port", String(METRO_PORT)], env };
  if (!pkg.scripts?.dev) throw new Error("no expo dependency and no `dev` script — don't know how to run this repo");
  return { kind: "web", args: ["run", "dev", "--host", "0.0.0.0", "--port", String(METRO_PORT)], env }; // Astro, Vite, SvelteKit
}

function log(line) {
  slot.log.push(`${new Date().toISOString().slice(11, 19)} ${line}`);
  if (slot.log.length > 200) slot.log.splice(0, slot.log.length - 200);
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

async function stopMetro() {
  if (!metro) return;
  const p = metro;
  metro = null;
  p.kill("SIGTERM");
  await new Promise((r) => setTimeout(r, 1500));
  if (p.exitCode === null) p.kill("SIGKILL");
}

async function waitForMetro(ms) {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    try {
      if (slot.kind === "expo") {
        const r = await fetch(`http://127.0.0.1:${METRO_PORT}/status`);
        if ((await r.text()).includes("packager-status:running")) return true;
      } else {
        await fetch(`http://127.0.0.1:${METRO_PORT}/`); // any HTTP answer means the dev server is up
        return true;
      }
    } catch {}
    await new Promise((r) => setTimeout(r, 2000));
  }
  return false;
}

async function startPreview(repo, branch) {
  await stopMetro();
  Object.assign(slot, { repo, branch, sha: null, kind: null, state: "preparing", error: null, startedAt: new Date().toISOString(), test: null, log: [] });
  const repoDir = path.join(STUDIO, repo);
  const wt = path.join(WT_ROOT, repo);
  try {
    log(`checkout ${branch}`);
    await run("git", ["-C", repoDir, "worktree", "remove", "--force", wt]).catch(() => {});
    await run("git", ["-C", repoDir, "worktree", "prune"]);
    await run("git", ["-C", repoDir, "worktree", "add", "--force", "--detach", wt, branch]);
    slot.sha = (await run("git", ["-C", wt, "rev-parse", "--short", "HEAD"])).trim();
    log(`installing dependencies (${slot.sha})`);
    slot.state = "installing";
    await run("pnpm", ["install", "--frozen-lockfile"], { cwd: wt }).catch(async (e) => {
      log("frozen install failed, retrying without --frozen-lockfile");
      await run("pnpm", ["install"], { cwd: wt });
    });
    const cmd = devCommand(wt);
    slot.kind = cmd.kind;
    slot.state = "starting";
    log(`starting ${cmd.kind} dev server: pnpm ${cmd.args.join(" ")}`);
    metro = spawn("pnpm", cmd.args, { cwd: wt, env: { ...process.env, ...cmd.env } });
    metro.stdout.on("data", (d) => log(String(d).trim().slice(0, 300)));
    metro.stderr.on("data", (d) => log(String(d).trim().slice(0, 300)));
    metro.on("close", (code) => {
      if (slot.state !== "stopped") Object.assign(slot, { state: "crashed", error: `dev server exited ${code}` });
    });
    if (!(await waitForMetro(240_000))) throw new Error("dev server did not come up in 4 min");
    slot.state = "running";
    log(`running: ${links().web}`);
  } catch (e) {
    await stopMetro();
    Object.assign(slot, { state: "failed", error: String(e.message || e).slice(0, 2000) });
    log(`failed: ${slot.error.split("\n")[0]}`);
  }
}

async function runTest() {
  if (slot.state !== "running") throw new Error(`no running preview (state: ${slot.state})`);
  const out = path.join(ARTIFACTS, slot.repo, `${slot.sha}-${Date.now()}`);
  fs.mkdirSync(out, { recursive: true });
  slot.test = { state: "running", dir: out };
  try {
    const res = await run("node", ["smoke.mjs", `http://127.0.0.1:${METRO_PORT}`, out], { cwd: "/srv" });
    const shots = fs.readdirSync(out).filter((f) => f.endsWith(".png"));
    const rel = path.relative(ARTIFACTS, out);
    slot.test = { state: "passed", shots: shots.map((f) => `http://${HOST}:${API_PORT}/artifacts/${rel}/${f}`),
                  index: `http://${HOST}:${API_PORT}/artifacts/${rel}/index.html`, output: res.slice(-1500) };
  } catch (e) {
    slot.test = { state: "failed", error: String(e.message || e).slice(0, 2000) };
  }
}

function send(res, code, body, type = "application/json") {
  res.writeHead(code, { "Content-Type": type, "Cache-Control": "no-store" });
  res.end(type === "application/json" ? JSON.stringify(body, null, 2) : body);
}

async function readJson(req) {
  let b = "";
  for await (const c of req) b += c;
  return b ? JSON.parse(b) : {};
}

http.createServer(async (req, res) => {
  const url = new URL(req.url, "http://x");
  try {
    if (req.method === "GET" && url.pathname === "/health") return send(res, 200, { ok: true });
    if (req.method === "GET" && url.pathname === "/status") return send(res, 200, { ...slot, links: links() });
    if (req.method === "GET" && url.pathname === "/open") {
      if (slot.kind !== "expo") return send(res, 409, { error: "the running preview is a website; open links.web" });
      res.writeHead(302, { Location: links().phone });
      return res.end();
    }
    if (req.method === "GET" && url.pathname === "/qr.png") {
      return send(res, 200, await QRCode.toBuffer(links().phone, { width: 512, margin: 2 }), "image/png");
    }
    if (req.method === "GET" && url.pathname.startsWith("/artifacts/")) {
      const file = path.normalize(path.join(ARTIFACTS, decodeURIComponent(url.pathname.slice("/artifacts/".length))));
      if (!file.startsWith(ARTIFACTS + path.sep) || !fs.existsSync(file)) return send(res, 404, { error: "not found" });
      const type = file.endsWith(".png") ? "image/png" : file.endsWith(".html") ? "text/html" : "text/plain";
      return send(res, 200, fs.readFileSync(file), type);
    }
    if (req.method === "POST" && url.pathname === "/preview") {
      const { repo, branch } = await readJson(req);
      if (!repos().includes(repo)) return send(res, 400, { error: `repo must be one of ${repos().join(", ")}` });
      if (!BRANCH_RE.test(branch || "") || branch.includes("..")) return send(res, 400, { error: "bad branch name" });
      if (["preparing", "installing", "starting"].includes(slot.state))
        return send(res, 409, { error: `busy: ${slot.state} ${slot.repo}@${slot.branch}` });
      startPreview(repo, branch);
      return send(res, 202, { accepted: true, poll: "/status" });
    }
    if (req.method === "POST" && url.pathname === "/test") {
      if (slot.test?.state === "running") return send(res, 409, { error: "test already running" });
      runTest().catch((e) => (slot.test = { state: "failed", error: String(e.message || e) }));
      return send(res, 202, { accepted: true, poll: "/status" });
    }
    return send(res, 404, { error: "not found" });
  } catch (e) {
    return send(res, 500, { error: String(e.message || e) });
  }
}).listen(API_PORT, () => console.log(`studio-preview on :${API_PORT}, repos ${repos().join(",")}, host ${HOST}`));

process.on("SIGTERM", async () => {
  slot.state = "stopped";
  await stopMetro();
  process.exit(0);
});
