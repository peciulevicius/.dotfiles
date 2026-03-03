# Start Here

If you are new to this repo, use this order.

## 1) Install on Current Mac

- Main entrypoint: `./install.sh` (auto-detects macOS and calls unified mac installer)
- Direct unified installer: `./os/mac/install.sh`
- Non-interactive mode (accept default prompts): `./os/mac/install.sh --yes`
- Optional OS defaults script: `./os/mac/setup_macos_preferences.sh`

Then run:

```bash
scripts/dev-check.sh
```

## 2) Learn the Tools

- [Mac Setup Guide](./MAC_SETUP.md) — installer, tools, local AI, remote access
- [Beginner Tool Setup Guide](./BEGINNER_TOOL_SETUP_GUIDE.md) — step-by-step for each tool
- [Tool Coverage Matrix](./TOOL_COVERAGE_MATRIX.md) — what's installed and documented
- [Modern CLI Tools](./MODERN_CLI_TOOLS.md) — bat, eza, fzf, zoxide, etc.
- [Tool Tutorials](./tutorials/TOOL_TUTORIALS.md) — official docs + video links

## 3) Daily Commands

- Update system and packages: `scripts/update.sh`
- Health check: `scripts/dev-check.sh`
- Backup configs: `scripts/backup.sh`
