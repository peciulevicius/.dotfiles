# AI collaboration in this repository

This repo is the versioned source for machine configuration, operational
scripts, service runbooks, and shared repository instructions. Keep
cross-project personal context out of Git; it belongs in the private shared
memory on the Mac mini.

## Start here

1. Read the root `AGENTS.md` (Codex and compatible coding agents) or
   `CLAUDE.md` (Claude Code). Both point to this guide.
2. Check `git status` and preserve any existing edits.
3. Read the relevant service README and the matching TODO or reference entry.
4. Keep repository changes on a focused branch and open a PR.
5. Update the TODO when work remains and the changelog when work is complete.

## Which tool holds what

| Surface | Use it for | Source of truth |
|---|---|---|
| `AGENTS.md` | Durable repository rules for Codex and compatible agents | This repo |
| `CLAUDE.md` | Claude Code entry point and link to shared rules | This repo |
| `config/claude/` | Claude Code agents, skills, rules, commands, and setup | This repo; see `config/claude/README.md` |
| `~/ai-memory` on the Mac mini (`/ai-memory` in Paperclip and Odysseus) | Private cross-project context and agent handoffs | Private local Git repo; read its `README.md` first |
| Paperclip company skills and agent instructions | Company-specific role guidance and capabilities | Paperclip company configuration; mirrored selectively in this repo |
| Odysseus memories and skills | User-facing chat memory and portable `SKILL.md` capabilities | Odysseus data plus `~/ai-memory` |

The shared `~/ai-memory` mount currently connects Paperclip agents, Odysseus,
and Claude Code on the Mac mini. It is not automatically mounted in every
Codex session or on every computer. On the Mac mini, an agent with access to
that path can use it; otherwise, use the repository's versioned docs and do
not assume private memory is available.

For Paperclip, the folder is mounted into the shared container and can be
reached across companies. A mount alone does not inject memory into an agent's
prompt: each agent needs instructions to read the relevant notes. Today that
guidance was appended and verified on all **31 current agents** on 2026-09-29,
including paused department agents; retired/duplicate records were excluded.
Role instructions and pause/resume settings were preserved. The reusable text is in
[`services/paperclip/shared-ai-memory-addendum.md`](https://github.com/peciulevicius/.dotfiles/blob/main/services/paperclip/shared-ai-memory-addendum.md).
Use `python3 scripts/utils/paperclip-memory-guidance.py` for a read-only check;
`--apply` installs it on new current agents after saving private originals.
The script stops on changed guidance, concurrent edits, or running targets.
Training and finance folders are only read for relevant assigned work.

## Memory boundaries

- Read `~/ai-memory/README.md` before using or editing the private shared
  memory, when that path is available.
- Put durable, broadly useful repository facts and procedures here, where
  future contributors can review them through Git and PRs.
- Put private preferences, personal details, and cross-project handoffs in
  `~/ai-memory`; follow its inbox and ownership rules.
- Never copy secrets, credentials, health or finance records, private chat
  exports, or personal memory into this public dotfiles repository.
- Agent memory is not a substitute for current docs, live checks, or user
  confirmation for a consequential operational action.

## Routine work and approvals

The user's preference is to authorize routine implementation, commits and
PR creation as part of the task, with confirmation for destructive or major
changes. Repository instructions cannot remove client sandbox prompts.
In the desktop app, enable **Auto-review** under **Settings → General →
Permissions**, then select **Approve for me** beneath the composer. Eligible
escalations go to an automatic reviewer; major actions still need explicit
authorization when they have not already been approved. Full access removes
the sandbox boundary. See the official
[permission modes](https://learn.chatgpt.com/docs/permission-modes) and
[automatic review guide](https://learn.chatgpt.com/docs/sandboxing/auto-review).

For **Codex CLI 0.159.0** on this Mac mini, the installed CLI help confirms:

```bash
codex --approve-for-me resume --last
```

The current CLI's `/permissions` picker can also select **Approve for me**.
This uses automatic approval review with the workspace sandbox. Routine saved
command approvals are also reusable. Changing repository guidance alone does
not change the active CLI permission mode.

## Adding documentation

- Add or update a service's `README.md` for durable setup, architecture,
  operations, and recovery steps.
- Add verified machine facts to `docs/HOME_SERVER_REFERENCE.md` and active
  work to `docs/HOME_SERVER_TODO.md`.
- Move completed TODO entries into `docs/HOME_SERVER_CHANGELOG.md` with the
  completion date and a short explanation of the result.
- Add new top-level guides to the documentation navigation in `mkdocs.yml`;
  link them from `README.md` or `docs/START_HERE.md` when they are useful
  entry points.
- Use Markdown, relative links, concrete commands, and explicit notes about
  which steps need a human, credentials, or live system access.
- Treat live system state as time-sensitive: include when it was checked and
  avoid presenting an old observation as a current guarantee.

## Skills and agent handoffs

Claude Code skills are maintained in `config/claude/skills/` and installed by
`scripts/setup/setup-claude.sh`. For skills shared by Claude Code and Codex,
use `.agents/skills/<name>/SKILL.md` as the source and expose it to Claude
through `.claude/skills/`. Both tools support the open Agent Skills format;
Claude-specific frontmatter extensions and tool integrations may not work in
Codex. The existing Claude skill tree is not automatically discovered by
Codex, and this repo does not yet have a shared Codex skill installed. Paperclip
may have separately installed company skills; see `services/paperclip/README.md`.
Odysseus stores skills as `SKILL.md` directories, but still needs them imported
into its own data store. See the official [Claude Code skills guide](https://code.claude.com/docs/en/skills)
and [Codex skills guide](https://developers.openai.com/codex/skills/).

Use one reviewed source per portable skill and document any generated or
installed copies instead of letting versions drift. Keep Claude-only hooks,
agents, settings, and slash command behavior under `config/claude/`.

Agents can exchange durable notes through `~/ai-memory` only when both have
filesystem access to it. Paperclip task assignment, reports, comments, and
company instructions are separate coordination channels; they do not make
Claude and Codex sessions automatically share live conversation context.

Codex can delegate pieces of a current task to subagents when the client and
task support it. Those subagents are scoped to that Codex task; they are not
Paperclip hires and do not become persistent members of a company. Claude Code
has its own subagent and agent-team features. Cross-tool handoffs should use a
shared file, a Paperclip issue or comment, or a PR so the receiving agent can
read the context. A company organization does not by itself synchronize its
agents' context with another company or another tool.
