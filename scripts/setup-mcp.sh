#!/bin/bash
# ============================================================
# MCP Server Setup
# Configures environment variables for Claude Code MCP servers
# ============================================================

set +e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSHRC="$HOME/.zshrc"

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
    echo -e "${BLUE}║    MCP Server Setup                  ║${RESET}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${RESET}"
    echo ""
}

print_section() { echo -e "\n${CYAN}▸ $1${RESET}"; }
print_success() { echo -e "  ${GREEN}✓${RESET} $1"; }
print_warning() { echo -e "  ${YELLOW}⚠${RESET} $1"; }
print_info()    { echo -e "  ${WHITE}→${RESET} $1"; }
print_skip()    { echo -e "  ${YELLOW}–${RESET} $1 (skipped)"; }

# ---- Write env var to ~/.zshrc ----
write_env_var() {
    local key="$1"
    local value="$2"

    # Remove existing line if present
    if grep -q "^export ${key}=" "$ZSHRC" 2>/dev/null; then
        sed -i '' "/^export ${key}=/d" "$ZSHRC"
    fi

    echo "export ${key}=\"${value}\"" >> "$ZSHRC"
    export "${key}=${value}"
}

# ---- GitHub MCP ----
setup_github() {
    print_section "GitHub MCP"
    echo ""
    echo -e "  ${WHITE}Gives Claude access to:${RESET} repos, issues, PRs, search, file contents"
    echo -e "  ${WHITE}Needs:${RESET} GitHub Personal Access Token"
    echo -e "  ${WHITE}Create at:${RESET} https://github.com/settings/tokens/new"
    echo -e "  ${WHITE}Scopes needed:${RESET} repo, read:user, read:org"
    echo ""

    if [ -n "${GITHUB_TOKEN:-}" ]; then
        print_warning "GITHUB_TOKEN already set — overwrite?"
        read -rp "  [y/N]: " ow
        [[ ! "$ow" =~ ^[Yy]$ ]] && { print_skip "GitHub MCP"; return; }
    fi

    read -rp "  Paste your GitHub token (ghp_...): " token
    if [ -z "$token" ]; then
        print_skip "GitHub MCP (no token provided)"
        return
    fi

    write_env_var "GITHUB_TOKEN" "$token"
    print_success "GITHUB_TOKEN saved to $ZSHRC"
}

# ---- Postgres / Supabase MCP ----
setup_postgres() {
    print_section "Postgres MCP (Supabase)"
    echo ""
    echo -e "  ${WHITE}Gives Claude access to:${RESET} query your DB, inspect schema, run SQL"
    echo -e "  ${WHITE}Needs:${RESET} Supabase direct connection string"
    echo -e "  ${WHITE}Find it at:${RESET} Supabase Dashboard → Settings → Database → Connection string (URI)"
    echo -e "  ${WHITE}Use:${RESET} 'Direct connection' (not Supavisor/pooler)"
    echo ""
    print_warning "Use your DEV/staging project — not production"
    echo ""

    if [ -n "${SUPABASE_DB_URL:-}" ]; then
        print_warning "SUPABASE_DB_URL already set — overwrite?"
        read -rp "  [y/N]: " ow
        [[ ! "$ow" =~ ^[Yy]$ ]] && { print_skip "Postgres MCP"; return; }
    fi

    read -rp "  Paste your DB URL (postgresql://postgres:...): " url
    if [ -z "$url" ]; then
        print_skip "Postgres MCP (no URL provided)"
        return
    fi

    write_env_var "SUPABASE_DB_URL" "$url"
    print_success "SUPABASE_DB_URL saved to $ZSHRC"
}

# ---- Filesystem MCP ----
setup_filesystem() {
    print_section "Filesystem MCP"
    echo ""
    echo -e "  ${WHITE}Gives Claude access to:${RESET} ~/code and ~/Downloads (read/write)"
    echo -e "  ${WHITE}No token needed${RESET} — configured automatically in settings.json"
    echo ""
    print_success "Filesystem MCP ready (~/code, ~/Downloads)"
    echo -e "  ${WHITE}Edit paths in:${RESET} config/claude/settings.json → mcpServers.filesystem.args"
}

# ---- Fetch MCP ----
setup_fetch() {
    print_section "Fetch MCP"
    echo ""
    echo -e "  ${WHITE}Gives Claude access to:${RESET} fetch any URL as a native tool"
    echo -e "  ${WHITE}No token needed${RESET} — works automatically"
    echo ""
    print_success "Fetch MCP ready (no setup required)"
}

# ---- Brave Search MCP ----
setup_brave() {
    print_section "Brave Search MCP (optional)"
    echo ""
    echo -e "  ${WHITE}Gives Claude access to:${RESET} real-time web search"
    echo -e "  ${WHITE}Needs:${RESET} Brave Search API key (free tier: 2,000 queries/month)"
    echo -e "  ${WHITE}Get one at:${RESET} https://api.search.brave.com"
    echo ""

    read -rp "  Set up Brave Search? [y/N]: " want
    if [[ ! "$want" =~ ^[Yy]$ ]]; then
        print_skip "Brave Search MCP"
        return
    fi

    if [ -n "${BRAVE_API_KEY:-}" ]; then
        print_warning "BRAVE_API_KEY already set — overwrite?"
        read -rp "  [y/N]: " ow
        [[ ! "$ow" =~ ^[Yy]$ ]] && { print_skip "Brave Search MCP"; return; }
    fi

    read -rp "  Paste your Brave API key (BSA...): " key
    if [ -z "$key" ]; then
        print_skip "Brave Search MCP (no key provided)"
        return
    fi

    write_env_var "BRAVE_API_KEY" "$key"
    print_success "BRAVE_API_KEY saved to $ZSHRC"
}

# ---- Verify npx works ----
check_npx() {
    print_section "Checking prerequisites"
    if ! command -v npx &>/dev/null; then
        print_warning "npx not found — MCP servers use npx to run"
        print_info "Install Node.js: brew install node  OR  nvm install --lts"
        return 1
    fi
    print_success "npx available"
}

# ---- Summary ----
print_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║    MCP Setup Complete                ║${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${WHITE}Next steps:${RESET}"
    echo ""
    echo -e "  1. Reload your shell:  ${CYAN}source ~/.zshrc${RESET}"
    echo -e "  2. Sync settings:      ${CYAN}~/.dotfiles/scripts/setup-claude.sh update${RESET}"
    echo -e "  3. Restart Claude Code — MCP servers start automatically"
    echo ""
    echo -e "  ${WHITE}Verify in Claude Code:${RESET}"
    echo -e "  Type '/mcp' or check the tools menu for github, postgres, filesystem, fetch"
    echo ""
    echo -e "  ${WHITE}Troubleshooting:${RESET}"
    echo -e "  If an MCP server fails to start, the env var is probably not set."
    echo -e "  Check: ${CYAN}echo \$GITHUB_TOKEN${RESET}"
    echo -e "  Then:  ${CYAN}source ~/.zshrc && claude${RESET}"
    echo ""
}

# ---- Main ----
main() {
    print_header
    check_npx || true
    setup_github
    setup_postgres
    setup_filesystem
    setup_fetch
    setup_brave
    print_summary
}

main "$@"
