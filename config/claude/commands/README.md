# Slash Commands

Type these inside Claude Code to invoke them manually.

| Command | What it does |
|---------|-------------|
| `/new-project` | Conversational discovery session — talks through your idea, recommends a stack, then scaffolds `.claude/` for the project |
| `/pr` | Creates a GitHub PR with a conventional commit-style title and structured body |
| `/review` | Reviews local changes or a PR by number — checks for bugs, security issues, type safety, and convention violations |
| `/standup` | Generates a standup summary from yesterday's git activity |
| `/debug` | Systematic debugging — gathers evidence, forms hypotheses, finds root cause, applies the smallest fix |
| `/docs` | Generates or updates documentation for a file, function, feature, or the project README |

## Usage

```
/new-project                 # start a new project discovery
/pr                          # create a PR for current branch
/review                      # review local changes
/review 42                   # review PR #42
/debug login keeps logging me out
/docs src/lib/stripe.ts
```

## Adding a command

Create a `.md` file here. Use `$ARGUMENTS` to capture whatever the user types after the command name.

```bash
cat > ~/.dotfiles/config/claude/commands/my-command.md << 'EOF'
Do X for $ARGUMENTS.

1. Step one
2. Step two
EOF

~/.dotfiles/scripts/setup-claude.sh update
```
