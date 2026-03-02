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

## 2) Learn the Tools Quickly

Open:
- [Mac Workstation Guide](./MAC_WORKSTATION_GUIDE.md)
- [Beginner Tool Setup Guide](./BEGINNER_TOOL_SETUP_GUIDE.md)
- [Tool Coverage Matrix](./TOOL_COVERAGE_MATRIX.md)
- [Local AI Setup](./ai/LOCAL_AI_SETUP.md)
- [Tool Tutorials](./tutorials/TOOL_TUTORIALS.md)
- [Docs Site Setup](./SETUP_DOCS_SITE.md)
- [Modern CLI Tools](./MODERN_CLI_TOOLS.md)
- [Mac Setup + Local AI](./MAC_SETUP_AND_LOCAL_AI.md)

## 3) Daily Commands

- Update system and packages: `scripts/update.sh`
- Sync dotfiles symlinks/config: `scripts/sync.sh`
- Health check: `scripts/dev-check.sh`
- Set wallpaper: `scripts/wallpapers/set-wallpaper.sh`

## 4) New Mac Mini Setup (next week)

Use:
- [New Mac Mini Checklist](./NEW_MAC_MINI_CHECKLIST.md)
