# Slash Commands

Type these inside Claude Code to invoke them manually.

| Command | What it does |
|---------|-------------|
| `/new-project` | Conversational discovery — talks through your idea, recommends a stack, scaffolds `.claude/` |
| `/pr` | Creates a GitHub PR with a conventional commit-style title and structured body |
| `/review` | Reviews local changes or a PR by number — bugs, security, types, conventions |
| `/standup` | Generates a standup summary from yesterday's git activity |
| `/debug` | Systematic debugging — evidence gathering, root cause, smallest fix |
| `/docs` | Generates or updates documentation for a file, function, feature, or README |
| `/deploy` | Deploy to Vercel/Cloudflare/EAS — runs checks first, confirms before production |
| `/check` | Pre-commit checks — lint, types, tests, secret scan |

## Usage

```
/new-project
/pr
/review
/review 42                    # review PR #42
/debug login keeps logging me out
/docs src/lib/stripe.ts
/deploy                       # deploy to production
/deploy staging               # deploy to staging
/check                        # run before committing
```

## Note on `/deploy`

`/deploy` has `disable-model-invocation: true` — Claude will **never** auto-trigger it. You must type it explicitly. This prevents accidental deployments.

## Adding a command

Create a `.md` file here with instructions. Use `$ARGUMENTS` to capture what follows the command name.

```bash
cat > ~/.dotfiles/config/claude/commands/my-command.md << 'EOF'
Do X for $ARGUMENTS.
...
EOF

~/.dotfiles/scripts/setup/setup-claude.sh update
```
