# Claude Code Configuration

This directory contains Claude Code settings and configurations that can be synced across machines.

## Configuration Locations

### macOS
```
~/Library/Application Support/Claude/
├── User/
│   ├── settings.json          # Claude Code settings
│   ├── keybindings.json       # Custom keybindings
│   └── snippets/              # Code snippets
└── Claude Code.app/
```

### Linux
```
~/.config/Claude/
├── User/
│   ├── settings.json          # Claude Code settings
│   ├── keybindings.json       # Custom keybindings
│   └── snippets/              # Code snippets
```

### Windows
```
%APPDATA%\Claude\
├── User\
│   ├── settings.json          # Claude Code settings
│   ├── keybindings.json       # Custom keybindings
│   └── snippets\              # Code snippets
```

## Files in This Directory

### `settings.json` (when created)
Your custom Claude Code settings. To sync:

**macOS:**
```bash
# Backup existing settings
cp ~/Library/Application\ Support/Claude/User/settings.json ~/Library/Application\ Support/Claude/User/settings.json.backup

# Create symlink
ln -sf ~/.dotfiles/config/claude/settings.json ~/Library/Application\ Support/Claude/User/settings.json
```

**Linux:**
```bash
# Backup existing settings
cp ~/.config/Claude/User/settings.json ~/.config/Claude/User/settings.json.backup

# Create symlink
ln -sf ~/.dotfiles/config/claude/settings.json ~/.config/Claude/User/settings.json
```

**Windows (PowerShell):**
```powershell
# Backup existing settings
Copy-Item $env:APPDATA\Claude\User\settings.json $env:APPDATA\Claude\User\settings.json.backup

# Create symlink (requires admin)
New-Item -ItemType SymbolicLink -Path $env:APPDATA\Claude\User\settings.json -Target $HOME\.dotfiles\config\claude\settings.json
```

### `keybindings.json` (when created)
Custom keybindings for Claude Code.

## MCP (Model Context Protocol) Configuration

MCP servers are configured in `../ai-mcp/mcp.json`. See that directory for details.

## Current Setup

As of now, this directory is a placeholder for future Claude Code settings sync.

**To add your settings:**
1. Customize Claude Code to your liking
2. Copy settings from the location above
3. Add to this directory
4. Create symlinks on other machines
5. Commit and push to sync

## Recommended Settings (To Add Later)

Consider backing up these settings:
- Font preferences
- Theme preferences
- Editor settings
- Keybindings
- MCP server configurations (already in `../ai-mcp/`)

## Notes

- Claude Code settings are stored per-user
- Settings are in JSON format
- Extensions/plugins are separate (not synced here)
- MCP configurations are already managed in `config/ai-mcp/mcp.json`
