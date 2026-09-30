# Codex command sandbox inside Docker

`codex-seccomp.json` derives from the [Moby default seccomp profile](https://github.com/moby/profiles/blob/6fe7deb1b9fb7c0397a4593480d7d22b9ee8caef/seccomp/default.json),
revision `6fe7deb1b9fb7c0397a4593480d7d22b9ee8caef`. Its Apache 2.0 license is
included as `LICENSE.moby-profiles`.

The upstream profile and its default denial action are retained. Three rules
are appended for Codex's bubblewrap command sandbox:

- `clone` with `CLONE_NEWUSER` set; s390 argument ordering is excluded.
- `unshare` limited to user, mount, PID, network, IPC and UTS namespace flags.
- `mount`, `umount2` and `pivot_root` for the sandbox's private filesystem.

Kernel capability checks still apply. Compose grants no additional
capabilities; outer `SYS_ADMIN` remains absent. The profile retains upstream
restrictions for kernel modules, BPF, keyrings, clone3 and other unrelated
operations. This expands access to namespace setup; it requires the normal
review and approval for a live security-policy change.

Verified on Docker 29.4.0, Linux arm64, the existing Paperclip image and Codex
0.155.1. Disposable tests mounted no service data or credentials. They proved
actual commands, workspace writes, denied outside writes and symlink escapes,
with both enabled and disabled sandbox network profiles. The container had
no network and only SETUID, SETGID and SETFCAP capabilities. SETFCAP is needed
for Linux's root UID mapping; all three are already Docker defaults.

Stage this directory beside the live Compose file. Docker reads the profile
on container creation, so copying it alone does not repair a running container.
Keep a backup of the previous Compose file and any previous profile. Check
for queued/running agents before recreating Paperclip, then run the diagnostic
below and check HTTP health. On failure, restore those files and recreate
with the previous Compose configuration. Keep data, image and login mounts.

```bash
bash scripts/utils/paperclip-sandbox-check.sh
```

The diagnostic makes no model calls, reads no secret values and sends no
messages. It creates and removes only its own scratch directory inside the
container. It does not establish that an agent's complete task or Discord
delivery succeeded; those require a separate run after the repair.

The diagnostic uses UID 1000, the pinned image's Paperclip server identity,
instead of Docker exec's root default. A different image must set
`PAPERCLIP_RUNTIME_USER` to its actual server UID when checking it.
