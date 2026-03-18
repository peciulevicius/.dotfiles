# Universal Update Script - Windows (PowerShell)
# Updates: winget, npm, pnpm, dotfiles, Claude Code config, Claude Code CLI
#
# Usage: .\scripts\update.ps1
#
# First run (allow scripts): Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$ErrorActionPreference = "SilentlyContinue"

function Write-Header($msg) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "  $msg" -ForegroundColor Blue
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""
}

function Write-Ok($msg)   { Write-Host "  [+] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Write-Info($msg) { Write-Host "  --> $msg" -ForegroundColor Gray }

Write-Header "Windows Update Script"

# ---- winget ----
Write-Header "Updating Windows packages (winget)"
if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget upgrade --all --accept-source-agreements --accept-package-agreements
    Write-Ok "winget packages updated"
} else {
    Write-Warn "winget not found - install App Installer from Microsoft Store"
}

# ---- npm ----
if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Header "Updating npm"
    npm install -g npm@latest
    npm update -g
    Write-Ok "npm updated"
}

# ---- pnpm ----
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    Write-Header "Updating pnpm"
    pnpm self-update
    pnpm update -g
    Write-Ok "pnpm updated"
}

# ---- Dotfiles ----
$DotfilesDir = Join-Path $HOME ".dotfiles"
if (Test-Path $DotfilesDir) {
    Write-Header "Updating Dotfiles"
    Push-Location $DotfilesDir

    $gitStatus = git status --short 2>$null
    if ($gitStatus) {
        Write-Warn "Dotfiles have uncommitted changes - skipping git pull"
    } else {
        git pull
        Write-Ok "Dotfiles updated"
    }

    # Resync Claude Code config
    $setupScript = Join-Path $DotfilesDir "scripts\setup\setup-claude.ps1"
    if (Test-Path $setupScript) {
        Write-Host ""
        Write-Info "Syncing Claude Code config..."
        & $setupScript update
    }

    Pop-Location
}

# ---- Claude Code CLI ----
if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Header "Updating Claude Code"
    claude update
    Write-Ok "Claude Code updated"
}

# ---- Summary ----
Write-Header "Update Complete!"
Write-Ok "Windows packages (winget)"
Write-Ok "npm / pnpm"
Write-Ok "Dotfiles"
Write-Ok "Claude Code config (agents, skills, rules)"
Write-Ok "Claude Code CLI"
Write-Host ""
