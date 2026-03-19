Manage the dotfiles repository at ~/.dotfiles.

## Step 1 — Status check

```bash
cd ~/.dotfiles && git status && git log origin/main..HEAD --oneline
```

Report: any uncommitted changes, any unpushed commits, current branch.

## Step 2 — Pull latest from remote

```bash
cd ~/.dotfiles && git pull --rebase
```

If there are local uncommitted changes, stash them first:
```bash
cd ~/.dotfiles && git stash && git pull --rebase && git stash pop
```

Report what changed (new commits pulled, if any).

## Step 3 — Ask about running update script

Ask: "Run the full update script too? This updates Homebrew packages, CLI tools, and other managed dependencies."

If yes:
```bash
~/.dotfiles/scripts/update.sh
```

## Step 4 — Summary

Report:
- Whether the repo was already up to date or pulled new changes
- Whether update.sh was run and if it succeeded
- Any errors encountered
