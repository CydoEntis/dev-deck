#Requires -Version 5.1
# Dev Deck one-time cleanup.
#   1. Retires the old personal workflow skills (the ones Dev Deck replaces).
#      - If a skill is a JUNCTION (link to a C:\dev source), the link is removed
#        but the C:\dev source is preserved.
#      - If a skill is a real directory, it is MOVED to dev-deck/retired/
#        (reversible) rather than hard-deleted.
#   2. Disables the Aevox Playbook plugins in Claude Code (enabledPlugins ->
#      false) WITHOUT touching C:\Work\Aevox-Playbook (work code stays on disk).
#
# Run once, after install.ps1. Safe to re-run (idempotent).

param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'

$SkillRoots = @(
    (Join-Path $HOME '.claude/skills'),
    (Join-Path $HOME '.agents/skills')
)

# The personal skills Dev Deck replaces. (roadmap and professor are KEPT —
# they are pinned in upstream.json, so they are NOT in this list.)
$Retire = @(
    'research',
    'grilling',
    'grill-me',
    'interview',
    'project-planning',
    'teach',
    'hbr',
    'tug',
    'starter'
)

$RetiredDir = Join-Path $Root 'retired'
New-Item -ItemType Directory -Force -Path $RetiredDir | Out-Null

Write-Host "Dev Deck retire"
Write-Host "Skills:"
foreach ($s in $SkillRoots) {
    if (-not (Test-Path $s)) { continue }
    foreach ($name in $Retire) {
        $p = Join-Path $s $name
        if (-not (Test-Path $p)) { continue }
        $item = Get-Item $p -Force
        if ($item.LinkType) {
            $target = ($item.Target -join ', ')
            [System.IO.Directory]::Delete($p)
            Write-Host "  junction removed: $s/$name  (source kept: $target)"
        } elseif ((Get-Item $p).PSIsContainer) {
            Move-Item $p (Join-Path $RetiredDir "$name") -Force
            Write-Host "  moved to retired: $s/$name -> retired/$name"
        }
    }
}

# --- disable Aevox Playbook plugins in Claude Code -------------------------
$Settings = Join-Path $HOME '.claude/settings.json'
if (Test-Path $Settings) {
    $Backup = "$Settings.bak-devdeck-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item $Settings $Backup
    $raw = Get-Content $Settings -Raw
    $obj = $raw | ConvertFrom-Json
    if ($obj.PSObject.Properties.Name -contains 'enabledPlugins') {
        $changed = 0
        foreach ($prop in $obj.enabledPlugins.PSObject.Properties) {
            if ($prop.Name -like '*@aevox-playbook' -or $prop.Name -like 'aevox-*') {
                $prop.Value = $false
                $changed++
            }
        }
        if ($changed -gt 0) {
            $obj | ConvertTo-Json -Depth 10 | Set-Content $Settings
            Write-Host "Disabled $changed Aevox plugin(s) in $Settings (backup: $Backup)"
        } else {
            Write-Host "No Aevox plugins found to disable in $Settings"
        }
    } else {
        Write-Host "No enabledPlugins section in $Settings (nothing to disable)"
    }
} else {
    Write-Host "No $Settings found (skipped plugin disable)"
}

Write-Host ""
Write-Host "Note: C:\Work\Aevox-Playbook was NOT touched (work code preserved)." -ForegroundColor Yellow
Write-Host "Done. Run install\doctor.ps1 to verify."
