#!/bin/bash
# ============================================================
# Claude Code Setup Script
# Sets up Claude Code configuration, agents, skills, and statusline
# across machines using this dotfiles repo.
# ============================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_CONFIG_DIR="$DOTFILES_DIR/config/claude"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════╗${RESET}"
    echo -e "${BLUE}║    Claude Code Setup                 ║${RESET}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${RESET}"
    echo ""
}

print_section() { echo -e "\n${CYAN}▸ $1${RESET}"; }
print_success() { echo -e "  ${GREEN}✓${RESET} $1"; }
print_warning() { echo -e "  ${YELLOW}⚠${RESET} $1"; }
print_error()   { echo -e "  ${RED}✗${RESET} $1"; }
print_info()    { echo -e "  ${WHITE}→${RESET} $1"; }

# ---- Prereq check ----
check_prereqs() {
    print_section "Checking prerequisites"
    local missing=0

    if ! command -v claude &>/dev/null; then
        print_warning "Claude Code (claude) not found in PATH"
        print_info "Install: https://code.claude.com"
        missing=1
    else
        print_success "Claude Code installed: $(claude --version 2>/dev/null | head -1 || echo 'unknown version')"
    fi

    if ! command -v jq &>/dev/null; then
        print_warning "jq not found — statusline may not work"
        print_info "Install: brew install jq  OR  apt install jq"
    else
        print_success "jq installed"
    fi

    if ! command -v curl &>/dev/null; then
        print_warning "curl not found — statusline usage API won't work"
    else
        print_success "curl installed"
    fi

    return $missing
}

# ---- Create ~/.claude dirs ----
setup_dirs() {
    print_section "Setting up Claude directories"
    mkdir -p "$CLAUDE_DIR/agents"
    mkdir -p "$CLAUDE_DIR/skills"
    mkdir -p "$CLAUDE_DIR/rules"
    mkdir -p "$CLAUDE_DIR/commands"
    mkdir -p "$CLAUDE_DIR/hooks"
    print_success "Directories ready: $CLAUDE_DIR/{agents,skills,rules,commands,hooks}"
}

# ---- Statusline ----
setup_statusline() {
    print_section "Setting up statusline"

    local script="$CLAUDE_CONFIG_DIR/statusline.sh"
    if [ ! -f "$script" ]; then
        print_error "statusline.sh not found at $script"
        return 1
    fi

    chmod +x "$script"
    print_success "statusline.sh is executable"

    # Update ~/.claude/settings.json
    local settings="$CLAUDE_DIR/settings.json"
    if [ ! -f "$settings" ]; then
        echo '{}' > "$settings"
        print_info "Created new $settings"
    fi

    # Use jq to safely update the statusLine key (object format required by schema)
    local tmp
    tmp=$(mktemp)
    jq '. + {statusLine: {type: "command", command: "~/.dotfiles/config/claude/statusline.sh"}}' \
        "$settings" > "$tmp" && mv "$tmp" "$settings"
    print_success "Statusline configured in $settings"
}

# ---- Settings sync ----
setup_settings() {
    print_section "Syncing settings"

    local src="$CLAUDE_CONFIG_DIR/settings.json"
    local dst="$CLAUDE_DIR/settings.json"

    if [ ! -f "$src" ]; then
        print_warning "No settings.json in dotfiles, skipping"
        return
    fi

    echo ""
    echo -e "  ${YELLOW}Sync settings from dotfiles?${RESET}"
    echo -e "  ${WHITE}Source:${RESET} $src"
    echo -e "  ${WHITE}Target:${RESET} $dst"
    echo ""
    read -rp "  Overwrite existing settings? [y/N] " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        if [ -f "$dst" ]; then
            cp "$dst" "${dst}.backup.$(date +%Y%m%d%H%M%S)"
            print_info "Backed up existing settings"
        fi
        cp "$src" "$dst"
        print_success "Settings synced"
    else
        # Just ensure statusline is set
        setup_statusline
    fi
}

# ---- Agents ----
setup_agents() {
    print_section "Installing agents"

    local agents_src="$CLAUDE_CONFIG_DIR/agents"
    local agents_dst="$CLAUDE_DIR/agents"

    if [ ! -d "$agents_src" ]; then
        print_warning "No agents directory in dotfiles"
        return
    fi

    local count=0
    for agent_file in "$agents_src"/*.md; do
        [ -f "$agent_file" ] || continue
        local name
        name=$(basename "$agent_file")
        local dst_file="$agents_dst/$name"

        # Remove old symlink/file and create fresh symlink
        [ -L "$dst_file" ] && rm "$dst_file"
        [ -f "$dst_file" ] && {
            cp "$dst_file" "${dst_file}.backup.$(date +%Y%m%d%H%M%S)"
        }
        ln -sf "$agent_file" "$dst_file"
        count=$((count + 1))
    done

    print_success "Installed $count agents (symlinked from dotfiles)"
    print_info "Add new agents to $agents_src/"
}

# ---- Skills ----
setup_skills() {
    print_section "Installing skills"

    local skills_src="$CLAUDE_CONFIG_DIR/skills"
    local skills_dst="$CLAUDE_DIR/skills"

    if [ ! -d "$skills_src" ] || [ -z "$(ls -A "$skills_src" 2>/dev/null)" ]; then
        print_info "No skills in dotfiles yet (add them to $skills_src/)"
        return
    fi

    local count=0
    for skill_dir in "$skills_src"/*/; do
        [ -d "$skill_dir" ] || continue
        local name
        name=$(basename "$skill_dir")
        local dst_dir="$skills_dst/$name"

        [ -L "$dst_dir" ] && rm "$dst_dir"
        ln -sf "$skill_dir" "$dst_dir"
        count=$((count + 1))
    done

    print_success "Installed $count skills (symlinked from dotfiles)"
}

# ---- Rules ----
setup_rules() {
    print_section "Installing rules"

    local rules_src="$CLAUDE_CONFIG_DIR/rules"
    local rules_dst="$CLAUDE_DIR/rules"

    if [ ! -d "$rules_src" ] || [ -z "$(ls -A "$rules_src" 2>/dev/null)" ]; then
        print_info "No rules in dotfiles yet (add them to $rules_src/)"
        return
    fi

    local count=0
    for rule_file in "$rules_src"/*.md; do
        [ -f "$rule_file" ] || continue
        local name
        name=$(basename "$rule_file")
        local dst_file="$rules_dst/$name"

        [ -L "$dst_file" ] && rm "$dst_file"
        ln -sf "$rule_file" "$dst_file"
        count=$((count + 1))
    done

    print_success "Installed $count rules (symlinked from dotfiles)"
}

# ---- Commands ----
setup_commands() {
    print_section "Installing commands"

    local commands_src="$CLAUDE_CONFIG_DIR/commands"
    local commands_dst="$CLAUDE_DIR/commands"

    if [ ! -d "$commands_src" ] || [ -z "$(ls -A "$commands_src" 2>/dev/null)" ]; then
        print_info "No commands in dotfiles yet (add them to $commands_src/)"
        return
    fi

    local count=0
    for cmd_file in "$commands_src"/*.md; do
        [ -f "$cmd_file" ] || continue
        local name
        name=$(basename "$cmd_file")
        local dst_file="$commands_dst/$name"

        [ -L "$dst_file" ] && rm "$dst_file"
        ln -sf "$cmd_file" "$dst_file"
        count=$((count + 1))
    done

    print_success "Installed $count commands (symlinked from dotfiles)"
}

# ---- Hooks ----
setup_hooks() {
    print_section "Installing hooks"

    local hooks_src="$CLAUDE_CONFIG_DIR/hooks"

    if [ ! -d "$hooks_src" ] || [ -z "$(ls -A "$hooks_src" 2>/dev/null)" ]; then
        print_info "No hooks in dotfiles yet (add them to $hooks_src/)"
        return
    fi

    local count=0
    for hook_file in "$hooks_src"/*.sh; do
        [ -f "$hook_file" ] || continue
        chmod +x "$hook_file"
        count=$((count + 1))
    done

    print_success "Made $count hooks executable (referenced directly from dotfiles)"
    print_info "Hooks run from: $hooks_src/"
}

# ---- Global CLAUDE.md ----
setup_global_claude_md() {
    print_section "Installing global CLAUDE.md"

    local src="$CLAUDE_CONFIG_DIR/CLAUDE.md"
    local dst="$CLAUDE_DIR/CLAUDE.md"

    if [ ! -f "$src" ]; then
        print_info "No CLAUDE.md in dotfiles yet (add it to $src)"
        return
    fi

    [ -L "$dst" ] && rm "$dst"
    if [ -f "$dst" ]; then
        cp "$dst" "${dst}.backup.$(date +%Y%m%d%H%M%S)"
        print_info "Backed up existing CLAUDE.md"
    fi

    ln -sf "$src" "$dst"
    print_success "Global CLAUDE.md symlinked"
}

# ---- Sync agents FROM live to dotfiles (for initial capture) ----
sync_agents_to_dotfiles() {
    print_section "Syncing live agents to dotfiles"

    local agents_src="$CLAUDE_DIR/agents"
    local agents_dst="$CLAUDE_CONFIG_DIR/agents"

    if [ ! -d "$agents_src" ]; then
        print_info "No agents directory found at $agents_src"
        return
    fi

    mkdir -p "$agents_dst"
    local count=0
    for agent_file in "$agents_src"/*.md; do
        [ -f "$agent_file" ] || continue
        [ -L "$agent_file" ] && continue  # skip existing symlinks
        local name
        name=$(basename "$agent_file")
        if [ ! -f "$agents_dst/$name" ]; then
            cp "$agent_file" "$agents_dst/$name"
            count=$((count + 1))
        fi
    done

    if [ "$count" -gt 0 ]; then
        print_success "Synced $count new agents to dotfiles"
        print_info "Commit them: cd $DOTFILES_DIR && git add config/claude/agents/ && git commit -m 'feat: sync claude agents'"
    else
        print_info "All agents already in dotfiles"
    fi
}

# ---- Print summary ----
print_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║    Claude Code Setup Complete!       ║${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${WHITE}Status line:${RESET}  Active on next Claude Code start"
    echo -e "  ${WHITE}Agents:${RESET}       $CLAUDE_DIR/agents/ (symlinked)"
    echo -e "  ${WHITE}Skills:${RESET}       $CLAUDE_DIR/skills/ (symlinked)"
    echo -e "  ${WHITE}Rules:${RESET}        $CLAUDE_DIR/rules/ (symlinked)"
    echo -e "  ${WHITE}Commands:${RESET}     $CLAUDE_DIR/commands/ (symlinked)"
    echo -e "  ${WHITE}Hooks:${RESET}        $CLAUDE_CONFIG_DIR/hooks/ (referenced directly)"
    echo -e "  ${WHITE}CLAUDE.md:${RESET}    $CLAUDE_DIR/CLAUDE.md (symlinked)"
    echo -e "  ${WHITE}Settings:${RESET}     $CLAUDE_DIR/settings.json"
    echo ""
    echo -e "  ${CYAN}MCP servers:${RESET} Run setup-mcp.sh to configure tokens"
    echo -e "  ${WHITE}→${RESET} ~/.dotfiles/scripts/setup-mcp.sh"
    echo ""
    echo -e "  ${CYAN}Docs:${RESET} ~/.dotfiles/docs/CLAUDE_CODE_GUIDE.md"
    echo ""
}

# ---- Interactive menu (shown when run with no args) ----
show_menu() {
    echo -e "  ${WHITE}What do you want to do?${RESET}"
    echo ""
    echo -e "  ${CYAN}1)${RESET} First-time setup      ${WHITE}—${RESET} full install, prompts for settings"
    echo -e "  ${CYAN}2)${RESET} Update / resync       ${WHITE}—${RESET} sync agents, skills, rules, commands"
    echo -e "  ${CYAN}3)${RESET} Statusline only       ${WHITE}—${RESET} just configure the statusline"
    echo -e "  ${CYAN}4)${RESET} Sync agents → dotfiles ${WHITE}—${RESET} pull live agents back into repo"
    echo -e "  ${CYAN}q)${RESET} Quit"
    echo ""
    read -rp "  Choice: " choice
    echo ""

    case "$choice" in
        1) run_mode install ;;
        2) run_mode update ;;
        3) run_mode statusline-only ;;
        4) run_mode sync ;;
        q|Q) echo "  Bye."; exit 0 ;;
        *) print_error "Invalid choice '$choice'"; exit 1 ;;
    esac
}

# ---- Run a mode ----
run_mode() {
    local mode="$1"
    case "$mode" in
        install)
            check_prereqs || true
            setup_dirs
            setup_settings
            setup_agents
            setup_skills
            setup_rules
            setup_commands
            setup_hooks
            setup_global_claude_md
            print_summary
            ;;
        update)
            # Non-interactive: resync all symlinked assets (used by update.sh)
            setup_dirs
            setup_agents
            setup_skills
            setup_rules
            setup_commands
            setup_hooks
            setup_global_claude_md
            print_success "Claude Code config synced"
            ;;
        statusline-only)
            setup_statusline
            print_success "Statusline setup complete"
            ;;
        sync)
            sync_agents_to_dotfiles
            ;;
        agents-only)
            setup_dirs
            setup_agents
            ;;
        *)
            print_error "Unknown mode: $mode"
            echo ""
            echo "  Valid modes: install | update | statusline-only | sync | agents-only"
            exit 1
            ;;
    esac
}

# ---- Main ----
main() {
    print_header

    if [ $# -eq 0 ]; then
        # No args — show interactive menu
        show_menu
    else
        # Arg provided — run directly (for scripting / update.sh)
        run_mode "$1"
    fi
}

main "$@"
