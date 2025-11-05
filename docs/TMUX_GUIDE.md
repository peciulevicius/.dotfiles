# Tmux Guide

A beginner-friendly guide to tmux (terminal multiplexer).

## 🤔 What is Tmux?

**Tmux** is a terminal multiplexer - it lets you:
- **Split your terminal** into multiple panes (side-by-side or top/bottom)
- **Create multiple windows** (like tabs in a browser)
- **Detach and reattach** sessions (keep things running when you disconnect)

Think of it as "advanced terminal management" for power users.

---

## ❓ Do I Need Tmux?

### **You DON'T need tmux if:**
- ✅ You use an IDE with built-in terminal (WebStorm, VS Code) ← **Most people**
- ✅ Your terminal app has tabs/splits (Mac Terminal, iTerm2, Warp)
- ✅ You don't SSH into remote servers often
- ✅ You prefer GUI tools

### **You MIGHT want tmux if:**
- 🖥️ You work on remote servers via SSH
- 👨‍💻 You live in the terminal (vim/neovim users)
- 🔌 You need processes to keep running when you disconnect
- 📊 You want multiple terminal panes in a single window
- ⌨️ You prefer keyboard-driven workflows

---

## 🎯 Common Use Cases

### **1. Remote Server Work (Most Common)**

Tmux shines when working on remote servers:

```bash
# SSH into server
ssh user@server.com

# Start tmux
tmux

# Run a long process
npm run build  # Takes 1 hour

# Detach (Ctrl+b, then d)
# Close your laptop, go home

# Later, SSH back in
ssh user@server.com

# Reattach to tmux
tmux attach

# Your build is still running!
```

**Without tmux:** Process dies when SSH disconnects
**With tmux:** Process keeps running in the background

### **2. Multiple Terminal Panes**

Split your terminal without multiple windows:

```
┌─────────────────────────────────┐
│ $ npm run dev                   │
│ Server running on port 3000     │
│                                 │
├─────────────────────────────────┤
│ $ git status                    │
│ On branch main                  │
│                                 │
└─────────────────────────────────┘
```

**Without tmux:** Open multiple terminal tabs/windows
**With tmux:** Split within one window

### **3. Session Persistence**

Keep your workspace exactly as you left it:

```bash
# Monday morning - set up your workspace
tmux new -s work
# Open multiple panes, run servers, etc.

# End of day - detach
Ctrl+b, d

# Tuesday morning - reattach
tmux attach -t work
# Everything is exactly as you left it!
```

---

## 🚀 Quick Start

### **Installation**

Tmux is installed automatically by the dotfiles installer. To install manually:

```bash
# macOS
brew install tmux

# Arch Linux
sudo pacman -S tmux

# Ubuntu/Debian
sudo apt install tmux
```

### **Basic Usage**

```bash
# Start tmux
tmux

# You're now in a tmux session!
# Green bar at bottom = tmux is running

# Exit tmux (kills session)
exit

# Or detach (keeps session running)
Ctrl+b, then d
```

### **Key Bindings (Our Custom Config)**

All tmux commands start with the **prefix key**: `Ctrl+b`

**Windows (like tabs):**
```bash
Ctrl+b c        # Create new window
Ctrl+b n        # Next window
Ctrl+b p        # Previous window
Ctrl+b 0-9      # Switch to window 0-9
Ctrl+b ,        # Rename window
```

**Panes (splits):**
```bash
Ctrl+b |        # Split vertically (side-by-side)
Ctrl+b -        # Split horizontally (top/bottom)

Ctrl+b h        # Move to left pane
Ctrl+b j        # Move to bottom pane
Ctrl+b k        # Move to top pane
Ctrl+b l        # Move to right pane

Ctrl+b x        # Close current pane
```

**Sessions:**
```bash
Ctrl+b d        # Detach from session
Ctrl+b s        # List sessions
```

### **Session Management**

```bash
# Create named session
tmux new -s myproject

# List sessions
tmux ls

# Attach to session
tmux attach -t myproject

# Kill session
tmux kill-session -t myproject
```

---

## 🎨 Our Configuration

Your dotfiles include a pre-configured `.tmux.conf` with:

### **Vim-Style Navigation**
- `h j k l` to move between panes
- `H J K L` to resize panes

### **Better Split Keys**
- `|` for vertical split (more intuitive than `%`)
- `-` for horizontal split (more intuitive than `"`)

### **Mouse Support**
- Click to select pane
- Scroll to see history
- Drag to resize panes

### **Better Colors**
- 256 color support
- True color support (if your terminal supports it)

### **Status Bar**
- Shows date and time
- Shows current window
- Highlights active window

---

## 📚 Workflow Examples

### **Example 1: Web Development**

```bash
tmux new -s dev

# Top pane: Run dev server
npm run dev

# Split horizontal (Ctrl+b -)
# Bottom pane: Git operations
git status

# Split vertical (Ctrl+b |)
# Right pane: Run tests
npm test
```

**Result:**
```
┌─────────────────────────────────┐
│ npm run dev                     │
│ Server running...               │
├──────────────────┬──────────────┤
│ git status       │ npm test     │
│                  │              │
└──────────────────┴──────────────┘
```

### **Example 2: Server Management**

```bash
# SSH into server
ssh user@server.com

# Start named tmux session
tmux new -s server

# Window 1: Monitor logs
tail -f /var/log/app.log

# New window (Ctrl+b c)
# Window 2: Run commands
htop

# Detach (Ctrl+b d)
# Close SSH connection

# Later, SSH back in and reattach
ssh user@server.com
tmux attach -t server
# Everything still running!
```

---

## 🔧 Customization

Our config is at: `~/.dotfiles/config/tmux/.tmux.conf`

**Change prefix key** (default is `Ctrl+b`):
```bash
# In .tmux.conf
unbind C-b
set-option -g prefix C-a    # Use Ctrl+a instead
bind-key C-a send-prefix
```

**Change status bar position:**
```bash
set -g status-position top  # Put status bar at top
```

**Reload config:**
```bash
# Prefix + r (Ctrl+b, then r)
# Or manually:
tmux source-file ~/.tmux.conf
```

---

## 💡 Tips & Tricks

### **Scrolling (Copy Mode)**

```bash
Ctrl+b [        # Enter copy mode (scroll with arrow keys)
q               # Exit copy mode
```

### **Copying Text**

```bash
Ctrl+b [        # Enter copy mode
v               # Start selection
y               # Copy selection
Ctrl+b p        # Paste
```

### **Synchronize Panes**

Run the same command in all panes:

```bash
Ctrl+b S        # Toggle synchronize (custom binding)
# Now typing goes to all panes!
# Ctrl+b S again to turn off
```

### **Zoom a Pane**

```bash
Ctrl+b m        # Maximize current pane (toggle)
```

---

## 🆚 Tmux vs Alternatives

| Feature | Tmux | iTerm2/Warp | VS Code Terminal |
|---------|------|-------------|------------------|
| **Splits** | ✅ | ✅ | ✅ |
| **Tabs** | ✅ | ✅ | ✅ |
| **Session persistence** | ✅ | ❌ | ❌ |
| **Works over SSH** | ✅ | ❌ | ❌ |
| **Mouse support** | ✅ | ✅ | ✅ |
| **Keyboard-driven** | ✅ | ⚠️ | ⚠️ |
| **GUI** | ❌ | ✅ | ✅ |

**When to use Tmux:**
- Working on remote servers
- Want session persistence
- Prefer keyboard over mouse

**When to use iTerm2/Warp:**
- Local development
- Want GUI features
- Prefer mouse

**When to use IDE terminal:**
- Integrated with your code editor
- Local development
- Want simplicity

---

## 🚫 Common Mistakes

### **Nested Tmux Sessions**

Don't run tmux inside tmux:

```bash
# On remote server
ssh user@server.com
tmux            # Start tmux on server

# DON'T do this:
tmux            # Starting tmux inside tmux = confusion!
```

### **Prefix Key Confusion**

Remember: **ALL tmux commands** need the prefix key first (`Ctrl+b`)

```bash
# Wrong:
h               # Just types 'h'

# Right:
Ctrl+b, then h  # Moves to left pane
```

### **Not Detaching**

Closing terminal without detaching kills the session:

```bash
# Wrong:
exit            # Kills everything in tmux

# Right:
Ctrl+b d        # Detach (keeps running)
```

---

## 📖 Quick Reference Card

```
┌─────────────────────────────────────────────────┐
│ Tmux Quick Reference (Prefix: Ctrl+b)          │
├─────────────────────────────────────────────────┤
│ SESSIONS                                        │
│   Ctrl+b d      Detach                         │
│   Ctrl+b s      List sessions                  │
│                                                 │
│ WINDOWS                                         │
│   Ctrl+b c      Create window                  │
│   Ctrl+b n      Next window                    │
│   Ctrl+b p      Previous window                │
│   Ctrl+b 0-9    Switch to window #             │
│                                                 │
│ PANES                                           │
│   Ctrl+b |      Split vertical                 │
│   Ctrl+b -      Split horizontal               │
│   Ctrl+b h/j/k/l  Navigate panes (vim-style)  │
│   Ctrl+b x      Close pane                     │
│   Ctrl+b m      Maximize pane (toggle)         │
│                                                 │
│ OTHER                                           │
│   Ctrl+b ?      Show all keybindings           │
│   Ctrl+b r      Reload config                  │
└─────────────────────────────────────────────────┘
```

---

## 🎓 Learning Resources

**Official:**
- [Tmux Manual](https://man.openbsd.org/tmux)
- [Tmux GitHub](https://github.com/tmux/tmux)

**Tutorials:**
- [A Quick and Easy Guide to tmux](https://www.hamvocke.com/blog/a-quick-and-easy-guide-to-tmux/)
- [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)

**Books:**
- "tmux 2: Productive Mouse-Free Development" by Brian P. Hogan

---

## 🎯 Bottom Line

**Do you need tmux right now?**
- Probably not, since you use WebStorm/VS Code

**Should you keep the config?**
- Yes! It's pre-configured and ready if you ever need it

**When would you use it?**
- SSH into servers
- Long-running processes
- Terminal-heavy workflows

**How to try it:**
```bash
# Just run:
tmux

# Play around with splits:
Ctrl+b |        # Vertical split
Ctrl+b -        # Horizontal split

# Exit:
exit
```

---

## 📝 See Also

- [CONFIG_GUIDE.md](./CONFIG_GUIDE.md) - All configuration files explained
- [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md) - Modern CLI tools guide

---

**TL;DR:**
- 🖥️ **Tmux = terminal multiplexer** (splits, tabs, sessions)
- 🤷 **You probably don't need it** (WebStorm/VS Code user)
- ✅ **Keep the config** (doesn't hurt, useful if needed)
- 🎯 **Main use: SSH into servers** and session persistence
- 🚀 **Try it:** Just run `tmux` and experiment!
