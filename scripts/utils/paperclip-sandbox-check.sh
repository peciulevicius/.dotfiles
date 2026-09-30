#!/usr/bin/env bash
# Verify Codex's actual command sandbox without a model call or agent wake.
set -euo pipefail

# The pinned image runs the Paperclip server as UID 1000; Docker exec defaults
# to root. Exercise the same unprivileged identity as the agent subprocesses.
docker exec --user "${PAPERCLIP_RUNTIME_USER:-1000}" -i "${PAPERCLIP_CONTAINER:-paperclip}" node <<'NODE'
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {spawnSync} = require('node:child_process');
const base = fs.mkdtempSync('/tmp/paperclip-sandbox-check-');
const work = path.join(base, 'work');
const outside = path.join(base, 'outside');
try {
  fs.mkdirSync(work);
  fs.mkdirSync(outside);
  fs.symlinkSync(outside, path.join(work, 'escape'));
  for (const network of [true, false]) {
    const proof = path.join(work, `proof-${network}`);
    const denied = path.join(outside, `denied-${network}`);
    const escape = path.join(work, 'escape', `denied-${network}`);
    const body = `
      const fs=require('node:fs');
      for(const file of ${JSON.stringify([denied, escape])}) {
        try { fs.writeFileSync(file,'escape'); process.exit(10); }
        catch(e) { if(!['EACCES','EROFS','EPERM'].includes(e.code)) throw e; }
      }
      fs.writeFileSync(${JSON.stringify(proof)}, 'WORKSPACE_ALLOWED_OUTSIDE_DENIED');
    `;
    const result = spawnSync('codex', [
      'sandbox', '-C', work, '-P', 'paperclip-runner-check',
      '-c', 'permissions.paperclip-runner-check.filesystem={":root"="read",":workspace_roots"="write"}',
      '-c', `permissions.paperclip-runner-check.network.enabled=${network}`,
      '--', 'node', '-e', body
    ], {encoding:'utf8',timeout:30000});
    if (result.status !== 0 || !fs.existsSync(proof)) {
      throw new Error(`Command sandbox failed (exit ${result.status ?? 'timeout'}). ${result.stderr || ''}`);
    }
    assert.equal(fs.readFileSync(proof,'utf8'), 'WORKSPACE_ALLOWED_OUTSIDE_DENIED');
    assert.equal(fs.existsSync(denied), false);
    console.log(`PASS: command ran, workspace writes allowed, outside and symlink writes denied; network=${network}`);
  }
  const status = fs.readFileSync('/proc/self/status','utf8');
  assert.match(status, /^Seccomp:\s+2$/m);
  assert.equal(BigInt('0x'+status.match(/^CapEff:\s+([a-f0-9]+)$/m)[1]) & (1n<<21n), 0n);
  console.log('PASS: seccomp filtering active; outer SYS_ADMIN absent. No model calls or agent tasks.');
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally {
  fs.rmSync(base, {recursive:true,force:true});
}
NODE
