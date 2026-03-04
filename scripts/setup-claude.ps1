# Claude Code Setup — Windows (PowerShell)
# Sets up Claude Code config: agents, skills, rules, commands, CLAUDE.md
#
# Usage:
#   .\scripts\setup-claude.ps1           # first-time setup
#   .\scripts\setup-claude.ps1 update    # resync (used by update.ps1)
#
# Requirements: PowerShell 5.1+ (built into Windows 10/11)
# Note: Run once to allow scripts: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$ErrorActionPreference = "Stop"

$DotfilesDir   = Split-Path -Parent $PSScriptRoot
$ClaudeDir     = Join-Path $HOME ".claude"
$ConfigDir     = Join-Path $DotfilesDir "config\claude"

# ---- Output helpers ----
function Write-Header {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║    Claude Code Setup (Windows)       ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

function Write-Section($msg) { Write-Host "`n  > $msg" -ForegroundColor Cyan }
function Write-Ok($msg)      { Write-Host "    [+] $msg" -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "    [!] $msg" -ForegroundColor Yellow }
function Write-Err($msg)     { Write-Host "    [x] $msg" -ForegroundColor Red }
function Write-Info($msg)    { Write-Host "    --> $msg" -ForegroundColor Gray }

# ---- Create base dirs ----
function Setup-Dirs {
    Write-Section "Setting up Claude directories"
    @("$ClaudeDir", "$ClaudeDir\hooks") | ForEach-Object {
        New-Item -ItemType Directory -Force -Path $_ | Out-Null
    }
    Write-Ok "Directories ready: $ClaudeDir"
}

# ---- Link a directory via junction (no admin needed) ----
function Link-Dir($src, $dst) {
    if (-not (Test-Path $src)) {
        Write-Warn "Source not found: $src"
        return
    }
    # Remove existing junction or bail if it's a real directory with content
    if (Test-Path $dst) {
        $item = Get-Item $dst -Force
        if ($item.LinkType -eq "Junction" -or $item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            Remove-Item $dst -Force -Recurse
        } else {
            # Real directory — only remove if empty
            if ((Get-ChildItem $dst -Force).Count -eq 0) {
                Remove-Item $dst -Force
            } else {
                Write-Warn "Skipped $dst — real directory with content (remove manually to link)"
                return
            }
        }
    }
    cmd /c mklink /J "$dst" "$src" | Out-Null
}

# ---- Agents ----
function Setup-Agents {
    Write-Section "Installing agents"
    $src = Join-Path $ConfigDir "agents"
    $dst = Join-Path $ClaudeDir "agents"
    Link-Dir $src $dst
    $count = if (Test-Path $src) { (Get-ChildItem $src -Filter "*.md" -ErrorAction SilentlyContinue).Count } else { 0 }
    Write-Ok "Linked $count agents (junction -> dotfiles)"
}

# ---- Skills ----
function Setup-Skills {
    Write-Section "Installing skills"
    $src = Join-Path $ConfigDir "skills"
    $dst = Join-Path $ClaudeDir "skills"
    Link-Dir $src $dst
    $count = if (Test-Path $src) { (Get-ChildItem $src -Directory -ErrorAction SilentlyContinue).Count } else { 0 }
    Write-Ok "Linked $count skills (junction -> dotfiles)"
}

# ---- Rules ----
function Setup-Rules {
    Write-Section "Installing rules"
    $src = Join-Path $ConfigDir "rules"
    $dst = Join-Path $ClaudeDir "rules"
    Link-Dir $src $dst
    $count = if (Test-Path $src) { (Get-ChildItem $src -Filter "*.md" -ErrorAction SilentlyContinue).Count } else { 0 }
    Write-Ok "Linked $count rules (junction -> dotfiles)"
}

# ---- Commands ----
function Setup-Commands {
    Write-Section "Installing commands"
    $src = Join-Path $ConfigDir "commands"
    $dst = Join-Path $ClaudeDir "commands"
    Link-Dir $src $dst
    $count = if (Test-Path $src) { (Get-ChildItem $src -Filter "*.md" -ErrorAction SilentlyContinue).Count } else { 0 }
    Write-Ok "Linked $count commands (junction -> dotfiles)"
}

# ---- Global CLAUDE.md ----
function Setup-ClaudeMd {
    Write-Section "Installing global CLAUDE.md"
    $src = Join-Path $ConfigDir "CLAUDE.md"
    $dst = Join-Path $ClaudeDir "CLAUDE.md"
    if (-not (Test-Path $src)) {
        Write-Warn "No CLAUDE.md in dotfiles"
        return
    }
    if (Test-Path $dst) {
        $backup = "$dst.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item $dst $backup
        Write-Info "Backed up existing CLAUDE.md"
    }
    Copy-Item $src $dst -Force
    Write-Ok "CLAUDE.md installed"
}

# ---- Settings ----
function Setup-Settings {
    Write-Section "Syncing settings.json"
    $src = Join-Path $ConfigDir "settings.json"
    $dst = Join-Path $ClaudeDir "settings.json"
    if (-not (Test-Path $src)) {
        Write-Warn "No settings.json in dotfiles, skipping"
        return
    }
    $choice = Read-Host "    Overwrite existing settings.json? [y/N]"
    if ($choice -match "^[Yy]$") {
        if (Test-Path $dst) {
            $backup = "$dst.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item $dst $backup
            Write-Info "Backed up existing settings"
        }
        Copy-Item $src $dst -Force
        Write-Ok "Settings synced"
    } else {
        Write-Info "Skipped — keeping existing settings"
    }
}

# ---- Prereq check ----
function Check-Prereqs {
    Write-Section "Checking prerequisites"
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        $ver = (claude --version 2>$null) | Select-Object -First 1
        Write-Ok "Claude Code: $ver"
    } else {
        Write-Warn "Claude Code not found — install from https://claude.ai/code"
    }
}

# ---- Summary ----
function Print-Summary {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║    Setup Complete!                   ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "    Agents:    $ClaudeDir\agents  (junction)" -ForegroundColor White
    Write-Host "    Skills:    $ClaudeDir\skills  (junction)" -ForegroundColor White
    Write-Host "    Rules:     $ClaudeDir\rules   (junction)" -ForegroundColor White
    Write-Host "    Commands:  $ClaudeDir\commands (junction)" -ForegroundColor White
    Write-Host "    CLAUDE.md: $ClaudeDir\CLAUDE.md (copy)" -ForegroundColor White
    Write-Host "    Settings:  $ClaudeDir\settings.json" -ForegroundColor White
    Write-Host ""
    Write-Host "    Note: statusline is macOS/Linux-only, skipped here." -ForegroundColor DarkGray
    Write-Host ""
}

# ---- Main ----
Write-Header

$mode = if ($args.Count -gt 0) { $args[0] } else { "install" }

switch ($mode) {
    "install" {
        Check-Prereqs
        Setup-Dirs
        Setup-Settings
        Setup-Agents
        Setup-Skills
        Setup-Rules
        Setup-Commands
        Setup-ClaudeMd
        Print-Summary
    }
    "update" {
        Setup-Dirs
        Setup-Agents
        Setup-Skills
        Setup-Rules
        Setup-Commands
        Setup-ClaudeMd
        Write-Ok "Claude Code config synced"
    }
    default {
        Write-Err "Unknown mode: $mode"
        Write-Host "  Valid: install | update"
        exit 1
    }
}
