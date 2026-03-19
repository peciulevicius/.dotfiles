# Slash Commands

Type these inside Claude Code to invoke them manually.

| Command | What it does |
|---------|-------------|
| `/new-project` | Conversational discovery — talks through your idea, recommends a stack, scaffolds `.claude/` |
| `/review` | Reviews local changes or a PR by number — bugs, security, types, conventions |
| `/standup` | Generates a standup summary from yesterday's git activity |
| `/debug` | Systematic debugging — evidence gathering, root cause, smallest fix |
| `/check` | Pre-commit checks — lint, types, tests, secret scan |
| `/dotfiles` | Pull latest dotfiles, check status, optionally run update.sh |

## Usage

```
/new-project
/review
/review 42                    # review PR #42
/debug login keeps logging me out
/check                        # run before committing
/dotfiles                     # pull latest dotfiles + optional update
```

## Adding a command

Create a `.md` file here with instructions. Use `$ARGUMENTS` to capture what follows the command name.

```bash
cat > ~/.dotfiles/config/claude/commands/my-command.md << 'EOF'
Do X for $ARGUMENTS.
...
EOF

~/.dotfiles/scripts/setup/setup-claude.sh update
```
