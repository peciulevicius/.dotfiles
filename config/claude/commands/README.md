# Slash Commands

Type these inside Claude Code to invoke them manually.

| Command | What it does |
|---------|-------------|
| `/new-project` | Conversational discovery — talks through your idea, recommends a stack, scaffolds `.claude/` |
| `/dotfiles` | Pull latest dotfiles, check status, optionally run update.sh |

`/review`, `/debug`, `/check` and `/standup` still work the same way — they are
**skills** now (`config/claude/skills/`), not commands. They used to exist as
both; the duplicate command files were removed 2026-09-24, keeping one
source of truth per workflow.

## Usage

```
/new-project
/dotfiles                     # pull latest dotfiles + optional update
/review 42                    # skill — review PR #42
/check                        # skill — run before committing
```

## Adding a command

Prefer a **skill** for anything Claude should also be able to trigger on its
own; use a command only for purely manual one-offs. Create a `.md` file here
with instructions. Use `$ARGUMENTS` to capture what follows the command name.

```bash
cat > ~/.dotfiles/config/claude/commands/my-command.md << 'EOF'
Do X for $ARGUMENTS.
...
EOF

~/.dotfiles/scripts/setup/setup-claude.sh update   # links it, prunes dead links
```
