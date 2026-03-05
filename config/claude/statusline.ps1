# Claude Code Status Line (Windows/PowerShell)
# Line 1: Model | tokens used/total | % used <fullused> | % remain <fullremain> | thinking: on/off
# Line 2: current: <progressbar> % | weekly: <progressbar> % | extra: <progressbar> $used/$limit
# Line 3: resets <time> | resets <datetime> | resets <date>

[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Read stdin — try pipeline $Input first, fall back to Console.In
$input = @($Input) -join "`n"
if (-not $input) {
    $input = [Console]::In.ReadToEnd()
}

if (-not $input) {
    Write-Host -NoNewline "Claude"
    exit 0
}

# ANSI colors matching oh-my-posh theme (PS 5.1 compatible)
$esc    = [char]0x1B
$blue   = "${esc}[38;2;0;153;255m"
$orange = "${esc}[38;2;255;176;85m"
$green  = "${esc}[38;2;0;160;0m"
$cyan   = "${esc}[38;2;46;149;153m"
$red    = "${esc}[38;2;255;85;85m"
$yellow = "${esc}[38;2;230;200;0m"
$white  = "${esc}[38;2;220;220;220m"
$dim    = "${esc}[2m"
$rst    = "${esc}[0m"

function Format-Tokens([long]$num) {
    if ($num -ge 1000000) { return "{0:F1}m" -f ($num / 1000000) }
    if ($num -ge 1000)    { return "{0:F0}k" -f ($num / 1000) }
    return "$num"
}

function Format-Commas([long]$num) {
    return $num.ToString("N0")
}

function Build-Bar([int]$pct, [int]$width) {
    $pct = [Math]::Max(0, [Math]::Min(100, $pct))
    $filled = [int][Math]::Floor($pct * $width / 100)
    $empty  = $width - $filled

    $barColor = if ($pct -ge 90) { $red }
                elseif ($pct -ge 70) { $yellow }
                elseif ($pct -ge 50) { $orange }
                else { $green }

    $filledStr = [string]::new([char]0x25CF, $filled)  # bullet
    $emptyStr  = [string]::new([char]0x25CB, $empty)   # circle
    return "${barColor}${filledStr}${dim}${emptyStr}${rst}"
}

function Pad-Column([string]$text, [int]$visLen, [int]$colWidth) {
    $pad = $colWidth - $visLen
    if ($pad -gt 0) { return $text + (" " * $pad) }
    return $text
}

# ===== Parse JSON input =====
try { $data = $input | ConvertFrom-Json } catch { Write-Host -NoNewline "Claude"; exit 0 }

$modelName = if ($data.model.display_name) { $data.model.display_name } else { "Claude" }

# Context window
$size = if ($data.context_window.context_window_size) { [long]$data.context_window.context_window_size } else { 200000 }
if ($size -eq 0) { $size = 200000 }

# Token usage
$inputTokens = if ($data.context_window.current_usage.input_tokens) { [long]$data.context_window.current_usage.input_tokens } else { 0 }
$cacheCreate = if ($data.context_window.current_usage.cache_creation_input_tokens) { [long]$data.context_window.current_usage.cache_creation_input_tokens } else { 0 }
$cacheRead   = if ($data.context_window.current_usage.cache_read_input_tokens) { [long]$data.context_window.current_usage.cache_read_input_tokens } else { 0 }
$current = $inputTokens + $cacheCreate + $cacheRead

$usedTokens  = Format-Tokens $current
$totalTokens = Format-Tokens $size
$pctUsed   = if ($size -gt 0) { [int][Math]::Floor($current * 100 / $size) } else { 0 }
$pctRemain = 100 - $pctUsed
$usedComma   = Format-Commas $current
$remainComma = Format-Commas ($size - $current)

# Thinking status
$thinkingOn = $false
$settingsPath = Join-Path $env:USERPROFILE ".claude\settings.json"
if (Test-Path $settingsPath) {
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        if ($settings.alwaysThinkingEnabled -eq $true) { $thinkingOn = $true }
    } catch {}
}

# ===== LINE 1 =====
$thinkingStr = if ($thinkingOn) { "${orange}On${rst}" } else { "${dim}Off${rst}" }
$sep = " ${dim}|${rst} "
$line1 = "${blue}${modelName}${rst}${sep}${orange}${usedTokens} / ${totalTokens}${rst}${sep}${green}${pctUsed}% used ${orange}${usedComma}${rst}${sep}${cyan}${pctRemain}% remain ${blue}${remainComma}${rst}${sep}thinking: ${thinkingStr}"

# ===== OAuth token resolution =====
function Get-OAuthToken {
    # 1. Env var override
    if ($env:CLAUDE_CODE_OAUTH_TOKEN) { return $env:CLAUDE_CODE_OAUTH_TOKEN }

    # 2. Windows Credential Manager
    try {
        $cred = Get-StoredCredential -Target "Claude Code-credentials" -ErrorAction Stop 2>$null
        if ($cred) {
            $blob = $cred.Password | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -AsPlainText
            $json = $blob | ConvertFrom-Json
            if ($json.claudeAiOauth.accessToken) { return $json.claudeAiOauth.accessToken }
        }
    } catch {}

    # 3. Try cmdkey-based credential via .NET
    try {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class CredManager {
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool CredRead(string target, int type, int flags, out IntPtr credential);
    [DllImport("advapi32.dll")]
    public static extern void CredFree(IntPtr buffer);
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags; public int Type;
        public string TargetName; public string Comment;
        public long LastWritten; public int CredentialBlobSize;
        public IntPtr CredentialBlob; public int Persist;
        public int AttributeCount; public IntPtr Attributes;
        public string TargetAlias; public string UserName;
    }
    public static string Read(string target) {
        IntPtr ptr;
        if (CredRead(target, 1, 0, out ptr)) {
            var cred = (CREDENTIAL)Marshal.PtrToStructure(ptr, typeof(CREDENTIAL));
            var blob = new byte[cred.CredentialBlobSize];
            Marshal.Copy(cred.CredentialBlob, blob, 0, blob.Length);
            CredFree(ptr);
            return Encoding.Unicode.GetString(blob);
        }
        return null;
    }
}
"@ -ErrorAction SilentlyContinue
        $blob = [CredManager]::Read("Claude Code-credentials")
        if ($blob) {
            $json = $blob | ConvertFrom-Json
            if ($json.claudeAiOauth.accessToken) { return $json.claudeAiOauth.accessToken }
        }
    } catch {}

    # 4. Credentials file fallback
    $credsFile = Join-Path $env:USERPROFILE ".claude\.credentials.json"
    if (Test-Path $credsFile) {
        try {
            $json = Get-Content $credsFile -Raw | ConvertFrom-Json
            if ($json.claudeAiOauth.accessToken) { return $json.claudeAiOauth.accessToken }
        } catch {}
    }

    return $null
}

# ===== LINE 2 & 3: Usage with progress bars (cached) =====
$cacheDir  = Join-Path $env:TEMP "claude"
$cacheFile = Join-Path $cacheDir "statusline-usage-cache.json"
$cacheMaxAge = 60

if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null }

$needsRefresh = $true
$usageData = $null

if (Test-Path $cacheFile) {
    $cacheAge = ((Get-Date) - (Get-Item $cacheFile).LastWriteTime).TotalSeconds
    if ($cacheAge -lt $cacheMaxAge) {
        $needsRefresh = $false
        try { $usageData = Get-Content $cacheFile -Raw | ConvertFrom-Json } catch {}
    }
}

if ($needsRefresh) {
    $token = Get-OAuthToken
    if ($token) {
        try {
            $headers = @{
                "Accept"         = "application/json"
                "Content-Type"   = "application/json"
                "Authorization"  = "Bearer $token"
                "anthropic-beta" = "oauth-2025-04-20"
                "User-Agent"     = "claude-code/2.1.34"
            }
            $resp = Invoke-RestMethod -Uri "https://api.anthropic.com/api/oauth/usage" -Headers $headers -TimeoutSec 5 -ErrorAction Stop
            if ($resp -and $resp.type -ne "error") {
                $usageData = $resp
                $resp | ConvertTo-Json -Depth 10 | Set-Content $cacheFile -Force
            }
        } catch {}
    }
    # Fall back to stale cache
    if (-not $usageData -and (Test-Path $cacheFile)) {
        try { $usageData = Get-Content $cacheFile -Raw | ConvertFrom-Json } catch {}
    }
}

function Format-ResetTime([string]$isoStr, [string]$style) {
    if (-not $isoStr) { return "" }
    try {
        $dt = [DateTimeOffset]::Parse($isoStr).LocalDateTime
        switch ($style) {
            "time"     { return $dt.ToString("h:mmtt").ToLower() }
            "datetime" { return $dt.ToString("MMM d, h:mmtt").ToLower() }
            default    { return $dt.ToString("MMM d").ToLower() }
        }
    } catch { return "" }
}

$line2 = ""
$line3 = ""

if ($usageData) {
    $barWidth = 10
    $col1w = 23
    $col2w = 22

    # 5-hour (current)
    $fhUtil = $usageData.five_hour.utilization; if ($null -eq $fhUtil) { $fhUtil = 0 }
    $fiveHourPct = [int][Math]::Round([double]$fhUtil)
    $fiveHourResetIso = $usageData.five_hour.resets_at
    $fiveHourReset = Format-ResetTime $fiveHourResetIso "time"
    $fiveHourBar = Build-Bar $fiveHourPct $barWidth

    $col1BarVisLen = 9 + $barWidth + 1 + "$fiveHourPct".Length + 1
    $col1Bar = Pad-Column "${white}current:${rst} ${fiveHourBar} ${cyan}${fiveHourPct}%${rst}" $col1BarVisLen $col1w

    $col1ResetPlain = "resets $fiveHourReset"
    $col1Reset = Pad-Column "${white}resets ${fiveHourReset}${rst}" $col1ResetPlain.Length $col1w

    # 7-day (weekly)
    $sdUtil = $usageData.seven_day.utilization; if ($null -eq $sdUtil) { $sdUtil = 0 }
    $sevenDayPct = [int][Math]::Round([double]$sdUtil)
    $sevenDayResetIso = $usageData.seven_day.resets_at
    $sevenDayReset = Format-ResetTime $sevenDayResetIso "datetime"
    $sevenDayBar = Build-Bar $sevenDayPct $barWidth

    $col2BarVisLen = 8 + $barWidth + 1 + "$sevenDayPct".Length + 1
    $col2Bar = Pad-Column "${white}weekly:${rst} ${sevenDayBar} ${cyan}${sevenDayPct}%${rst}" $col2BarVisLen $col2w

    $col2ResetPlain = "resets $sevenDayReset"
    $col2Reset = Pad-Column "${white}resets ${sevenDayReset}${rst}" $col2ResetPlain.Length $col2w

    # Extra usage
    $col3Bar = ""
    $col3Reset = ""
    if ($usageData.extra_usage.is_enabled -eq $true) {
        $exUtil = $usageData.extra_usage.utilization; if ($null -eq $exUtil) { $exUtil = 0 }
        $exUsed = $usageData.extra_usage.used_credits; if ($null -eq $exUsed) { $exUsed = 0 }
        $exLim  = $usageData.extra_usage.monthly_limit; if ($null -eq $exLim) { $exLim = 0 }
        $extraPct   = [int][Math]::Round([double]$exUtil)
        $extraUsed  = "{0:F2}" -f ([double]$exUsed / 100)
        $extraLimit = "{0:F2}" -f ([double]$exLim / 100)
        $extraBar   = Build-Bar $extraPct $barWidth

        $nextMonth  = (Get-Date).AddMonths(1)
        $extraReset = (Get-Date -Year $nextMonth.Year -Month $nextMonth.Month -Day 1).ToString("MMM d").ToLower()

        $col3Bar   = "${white}extra:${rst} ${extraBar} ${cyan}`$${extraUsed}/`$${extraLimit}${rst}"
        $col3Reset = "${white}resets ${extraReset}${rst}"
    }

    # Assemble lines
    $line2 = "${col1Bar}${sep}${col2Bar}"
    if ($col3Bar) { $line2 += "${sep}${col3Bar}" }

    $line3 = "${col1Reset}${sep}${col2Reset}"
    if ($col3Reset) { $line3 += "${sep}${col3Reset}" }
}

# Output
Write-Host -NoNewline $line1
if ($line2) { Write-Host ""; Write-Host -NoNewline $line2 }
if ($line3) { Write-Host ""; Write-Host -NoNewline $line3 }

exit 0
