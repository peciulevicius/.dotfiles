# Configuration Guide

This guide provides detailed information about each configuration file in this dotfiles repository.

## Table of Contents

- [Git Configuration](#git-configuration)
- [Zsh Configuration](#zsh-configuration)
- [Starship Prompt](#starship-prompt)
- [IdeaVim Configuration](#ideavim-configuration)
- [Tmux Configuration](#tmux-configuration)

---

## Git Configuration

**File**: `config/git/.gitconfig`

### What It Does

Configures global Git settings including user information, default branch, and custom aliases.

### Key Features

#### User Information
```ini
[user]
    name = Džiugas Pečiulevičius
    email = 43075730+peciulevicius@users.noreply.github.com
```

**Customization**: Update with your name and email.

#### Default Branch
```ini
[init]
    defaultBranch = main
```

Sets `main` as the default branch for new repositories.

#### Custom Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `gl` | `config --global -l` | Show global git configuration |
| `ac` | `!git add . && git commit -m` | Stage all and commit |
| `last` | `log -1 HEAD --stat` | Show last commit with stats |
| `lg` | `log --color --graph --pretty=format:...` | Beautiful git log graph |
| `lg-me` | `log --author="Pečiulevičius" --color --graph...` | Git log filtered by author |
| `log-me` | `log --author="Pečiulevičius"` | Simple author filter |

**Usage Examples**:
```bash
git gl                  # Show all global config
git ac "feat: add feature"  # Add all and commit
git last               # Show last commit
git lg                 # Show pretty log graph
```

### Work-Specific Configuration

The `config/git/work/` directory contains example configurations for managing multiple Git identities:

- `.gitconfig` - Main work config
- `.gitconfig-work` - Work-specific settings
- `.gitconfig-personal` - Personal settings

**To use work configurations**:
```bash
git config --global include.path ~/.gitconfig-work
```

---

## Zsh Configuration

**File**: `config/zsh/.zshrc`

### What It Does

Configures the Z shell with cross-platform compatibility, including theme setup, aliases, and tool integrations.

### Key Features

#### 1. Prompt Configuration

Automatically initializes the Starship prompt or falls back to a basic prompt:

**Starship Prompt (Modern)**:
- Checks if `starship` command is available
- Sets `STARSHIP_CONFIG` to point to `~/.dotfiles/config/starship/starship.toml`
- Initializes Starship with `eval "$(starship init zsh)"`
- Falls back to basic prompt if Starship not installed

**Fallback Prompt**:
- If Starship is not installed, uses a clean, informative basic prompt
- Shows current directory in cyan
- Shows Git branch in yellow (via vcs_info)
- Green arrow prompt character

#### 2. Oh My Zsh Integration

Automatically loads Oh My Zsh if installed:
```zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
  source $ZSH/oh-my-zsh.sh
fi
```

#### 3. Custom Aliases

**Git Shortcuts**:
```zsh
alias gs='git status'
alias gp='git pull'
alias gps='git push'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
```

**File Listing**:
```zsh
alias ll='ls -lah'    # Long list with hidden files
alias la='ls -A'      # All files except . and ..
alias l='ls -CF'      # Classify files
```

**Platform-Specific**:

*macOS*:
```zsh
alias brewup='brew update && brew upgrade && brew cleanup'
```

*Debian/Ubuntu*:
```zsh
alias aptup='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
```

*Arch Linux*:
```zsh
alias pacup='sudo pacman -Syu'
```

#### 4. Environment Variables

```zsh
export EDITOR='vim'
export VISUAL='vim'
```

#### 5. Node Version Manager (NVM)

Automatically loads NVM if installed:
```zsh
export NVM_DIR="$HOME/.nvm"
# Load nvm
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
# Load bash completion
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
```

#### 6. Additional Tools

**pnpm**: Adds pnpm to PATH
```zsh
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
```

**Rust/Cargo**: Sources Cargo environment if installed
```zsh
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
```

### Customization

To add your own aliases:
```zsh
# Add to the Custom Aliases section
alias myalias='my command here'
```

To add environment variables:
```zsh
# Add to the Environment Variables section
export MY_VAR='value'
```

---

## Starship Prompt

**File**: `config/starship/starship.toml`

### What It Does

Configures the Starship prompt - a modern, blazing-fast, cross-shell prompt written in Rust.

### Key Features

- **Cross-shell**: Works on zsh, bash, fish, PowerShell, and more
- **Blazing fast**: Written in Rust for maximum performance
- **Simple TOML config**: Easy to read and customize
- **Git integration**: Shows branch, status, and more
- **Language versions**: Auto-detects Node, Python, Rust, etc.
- **Nerd Font icons**: Beautiful glyphs and symbols
- **Actively maintained**: Regular updates and improvements (2025+)

### Configuration

The config file is at `~/.dotfiles/config/starship/starship.toml` and is referenced via the `STARSHIP_CONFIG` environment variable in your `.zshrc`.

### Customization

Edit `config/starship/starship.toml` directly:

**Change prompt character**:
```toml
[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
```

**Customize directory display**:
```toml
[directory]
truncation_length = 3
truncate_to_repo = true
format = "[$path]($style)[$read_only]($read_only_style) "
```

**Show/hide language versions**:
```toml
[nodejs]
symbol = " "
detect_files = ["package.json"]

[python]
symbol = " "
detect_extensions = ["py"]
```

**Add more modules**: See [Starship docs](https://starship.rs/config/) for all available modules and options.

### Presets

Starship has built-in presets you can use:
```bash
starship preset nerd-font-symbols -o ~/.dotfiles/config/starship/starship.toml
```

Available presets: nerd-font-symbols, bracketed-segments, plain-text-symbols, no-runtime-versions, pure-preset

---

## IdeaVim Configuration

**File**: `config/idea/.ideavimrc`

### What It Does

Provides comprehensive Vim keybindings for JetBrains IDEs (IntelliJ IDEA, WebStorm, PyCharm, etc.).

### Key Features

#### Basic Settings
```vim
set scrolloff=5        " Keep 5 lines visible above/below cursor
set history=1000       " Command history
set showmode          " Show current mode
set hlsearch          " Highlight search results
set incsearch         " Incremental search
set ignorecase        " Case-insensitive search
set smartcase         " Case-sensitive if uppercase used
```

#### Leader Key
```vim
let mapleader="\<space>"
```
Space is the leader key for custom shortcuts.

#### Navigation Improvements

**Better HJKL**:
```vim
map H ^    " H goes to start of line
map L $    " L goes to end of line
map J }    " J goes to next paragraph
map K {    " K goes to previous paragraph
```

**Better Escape**:
```vim
imap jk <Esc>
imap kj <Esc>
```
Type `jk` or `kj` in insert mode to escape.

#### Window/Buffer Management

**Close buffers**:
- `<leader>xx` - Close current buffer
- `<leader>xa` - Close all buffers
- `<leader>xo` - Close all except current
- `<leader>xp` - Close unpinned buffers

**Navigate tabs**:
- `Tab` - Next tab
- `Shift+Tab` - Previous tab
- `<leader>1-9` - Go to tab 1-9
- `<leader>p` - Pin/unpin tab

**Split windows**:
- `<leader>sH` - Split horizontally
- `<leader>sV` - Split vertically
- `<leader>sh/j/k/l` - Move tab to side
- `Ctrl+h/j/k/l` - Navigate splits

#### Code Actions

**Quick actions**:
- `<leader>qf` - Quick fix / Show intentions
- `<leader>c` - Comment line
- `<leader>C` - Block comment
- `<leader>rn` - Rename
- `<leader>fc` - Reformat code

**Generate**:
- `<leader>gc` - Generate menu
- `<leader>gt` - Go to test
- `<leader>om` - Override methods
- `<leader>im` - Implement methods

**Refactoring**:
- `<leader>rn` - Rename element
- `<leader>re` - Refactoring menu
- `<leader>sw` - Surround with
- `<leader>uw` - Unwrap
- `<leader>sd` - Safe delete

#### Search/Find

- `<leader>fu` - Find usages
- `<leader>fs` - File structure
- `<leader>su` - Show usages
- `<leader>fp` - Find in path
- `<leader>rp` - Replace in path

#### Run/Debug

**Run**:
- `<leader>rc` - Run context
- `<leader>rx` - Choose run configuration
- `<leader>rr` - Rerun
- `<leader>rt` - Run tests
- `<leader>rs` - Stop

**Debug**:
- `<leader>dc` - Debug context
- `<leader>dx` - Debug configuration
- `<leader>db` - Toggle breakpoint
- `<leader>de` - Edit breakpoint
- `<leader>dv` - View breakpoints

#### Navigation

**Go to**:
- `ga` - Go to action
- `gc` - Go to class
- `gf` - Go to file
- `gs` - Go to symbol
- `gd` - Go to declaration
- `gD` - Go to type declaration
- `gi` - Go to implementation

**Navigate errors**:
- `[g` - Previous error
- `]g` - Next error

**Navigate methods**:
- `[m` - Previous method
- `]m` - Next method

#### IdeaVim Plugins

The configuration enables several bundled IdeaVim plugins:

```vim
set vim-paragraph-motion  " Better paragraph navigation
set textobj-indent       " Indent text objects
set textobj-entire       " Entire file text object
set argtextobj          # Argument text objects
set easymotion          # Jump motion (requires IdeaVim-EasyMotion plugin)
set highlightedyank     # Highlight yanked text
set surround            # Surround text objects (cs, ds, ys)
set exchange            # Exchange text objects
set NERDTree            # NERDTree-like file tree
set ReplaceWithRegister # Replace with register (gr)
```

### Required IDE Plugins

For full functionality, install these JetBrains plugins:
- **IdeaVim** (required)
- **IdeaVim-EasyMotion** (for `easymotion`)
- **Translation** (for `\tt`, `\ts`, etc.)
- **String Manipulation** (for `<leader>ss`)
- **Code Screenshots** (for `<leader>cs`)

### Customization

Add your own keybindings at the end of `.ideavimrc`:

```vim
" Custom mappings
nmap <leader>custom <Action>(MyCustomAction)
```

Find available actions:
1. In IDE: `Help → Find Action`
2. Search for the action
3. Copy the action ID
4. Use in `.ideavimrc`: `<Action>(ActionID)`

---

## MCP Configuration

**File**: `config/ai-mcp/mcp.json`

### What It Does

Configures Model Context Protocol (MCP) servers for AI integrations, specifically for Claude Code and other MCP-compatible tools.

### Current Configuration

```json
{
  "mcpServers": {
    "desktop-commander": {
      "command": "npx",
      "args": ["-y", "@smithery/cli@latest", "run", "@wonderwhy-er/desktop-commander", "--key", "KEY"]
    },
    "server-sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@smithery/cli@latest", "run", "@smithery-ai/server-sequential-thinking", "--key", "KEY"]
    },
    "context7-mcp": {
      "command": "npx",
      "args": ["-y", "@smithery/cli@latest", "run", "@upstash/context7-mcp", "--key", "KEY"]
    }
  }
}
```

### MCP Servers

#### 1. Desktop Commander
**Package**: `@wonderwhy-er/desktop-commander`

**Purpose**: Provides desktop automation capabilities to AI assistants.

**Features**:
- File system operations
- Application launching
- System commands
- Desktop interactions

#### 2. Sequential Thinking
**Package**: `@smithery-ai/server-sequential-thinking`

**Purpose**: Enhances AI reasoning with step-by-step thinking patterns.

**Features**:
- Structured problem-solving
- Multi-step reasoning
- Thought process transparency

#### 3. Context7
**Package**: `@upstash/context7-mcp`

**Purpose**: Advanced context management for AI conversations.

**Features**:
- Long-term memory
- Context persistence
- Conversation history
- Smart context retrieval

### Adding New MCP Servers

To add a new MCP server:

```json
{
  "mcpServers": {
    "your-server-name": {
      "command": "npx",
      "args": [
        "-y",
        "@smithery/cli@latest",
        "run",
        "@namespace/package-name",
        "--key",
        "your-key-here"
      ]
    }
  }
}
```

### Finding MCP Servers

Browse available MCP servers:
- [Smithery MCP Directory](https://smithery.ai/)
- [MCP Awesome List](https://github.com/modelcontextprotocol/servers)
- NPM packages tagged with `mcp-server`

### Usage with Claude Code

This configuration is used by Claude Code to enable additional capabilities. The MCP servers run automatically when Claude Code starts.

**Location for Claude Code**:
- macOS: `~/Library/Application Support/Claude/mcp.json`
- Linux: `~/.config/Claude/mcp.json`
- Windows: `%APPDATA%\Claude\mcp.json`

You can symlink this file to your dotfiles:
```bash
ln -sf ~/.dotfiles/config/ai-mcp/mcp.json ~/Library/Application\ Support/Claude/mcp.json
```

---

## Maintenance

### Updating Configurations

After modifying configuration files in the repository:

1. **Test changes**:
   ```bash
   # For shell configs
   source ~/.zshrc

   # For IdeaVim
   # Restart IDE or run: :source ~/.ideavimrc
   ```

2. **Commit changes**:
   ```bash
   cd ~/.dotfiles
   git add config/
   git commit -m "Update configuration"
   git push
   ```

3. **Sync to other machines**:
   ```bash
   cd ~/.dotfiles
   git pull
   ```

### Backup Configurations

The installation scripts automatically back up existing files with `.backup` extension. To restore:

```bash
mv ~/.zshrc.backup ~/.zshrc
```

---

## Troubleshooting

### Git Aliases Not Working

Ensure the config is loaded:
```bash
git config --global --list | grep alias
```

If not found, reload:
```bash
source ~/.gitconfig
```

### Zsh Theme Not Loading

Check if Starship is installed:
```bash
# All platforms
command -v starship

# Check version
starship --version

# Test initialization
eval "$(starship init zsh)"
```

Reinstall if needed:
```bash
# macOS
brew install starship

# Linux (official installer)
curl -sS https://starship.rs/install.sh | sh

# Arch Linux
sudo pacman -S starship
```

### IdeaVim Actions Not Working

1. Ensure IdeaVim plugin is enabled: `Settings → Plugins → IdeaVim`
2. Check if action exists: `Help → Find Action`
3. Update action ID if changed in newer IDE versions

### Tmux Not Working

1. **Check if tmux is installed**:
   ```bash
   command -v tmux
   tmux -V
   ```

2. **Reload config**:
   ```bash
   tmux source-file ~/.tmux.conf
   ```

3. **Check key bindings**: See [TMUX_GUIDE.md](./TMUX_GUIDE.md) for all shortcuts

---

## Additional Resources

- [Starship Documentation](https://starship.rs)
- [IdeaVim Documentation](https://github.com/JetBrains/ideavim)
- [Git Configuration Reference](https://git-scm.com/docs/git-config)
- [Oh My Zsh Documentation](https://github.com/ohmyzsh/ohmyzsh)
- [Tmux Documentation](https://github.com/tmux/tmux/wiki)

---

**Last Updated**: 2025-11-04
