#Requires -Version 5.1
# Dev Deck health check. Verifies the install is consistent: config present,
# upstream cache at pinned refs, skills installed, role files substituted,
# MCP registered. Exits non-zero if anything is off.

param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$Fails = 0

function Check([string]$Label, [scriptblock]$Test) {
    try {
        if (& $Test) { Write-Host "  ok   $Label" }
        else { Write-Host "  FAIL $Label" -ForegroundColor Red; $script:Fails++ }
    } catch {
        Write-Host "  FAIL $Label ($($_.Exception.Message))" -ForegroundColor Red
        $script:Fails++
    }
}

Write-Host "Dev Deck doctor"
$Cfg = Join-Path $Root 'dev-deck.config.json'
Check "config present" { Test-Path $Cfg }
if (-not (Test-Path $Cfg)) {
    Write-Host "Run install.ps1 first (it creates the config from the example)." -ForegroundColor Yellow
    exit 1
}

# Dev Deck role files (named after agents/*.md) must have no unsubstituted
# template vars. Other agents in the same dir are not ours to check.
$Packs = @((Get-Content $Cfg -Raw | ConvertFrom-Json).packs)
$Roles = @()
if ($Packs -contains 'dev-deck') { $Roles = (Get-ChildItem (Join-Path $Root 'agents') -Filter '*.md' -File).BaseName }
$AgentDirs = @(
    (Join-Path $HOME '.claude/agents'),
    (Join-Path $HOME '.codex/agents')
)
foreach ($Dir in $AgentDirs) {
    if (Test-Path $Dir) {
        $Files = Get-ChildItem $Dir -File | Where-Object { $_.BaseName -in $Roles }
        Check "no {{...}} vars in $Dir" { -not ($Files | Where-Object { (Get-Content $_.FullName -Raw) -match '\{\{[A-Z_]+\}\}' }) }
    }
}

# Every skill dir the installer wrote (marked .devdeck) must contain a SKILL.md.
# Unmarked dirs are personal skills or links; the installer never touches them.
$SkillRoot = Join-Path $HOME '.claude/skills'
$Bad = Get-ChildItem $SkillRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { (Test-Path (Join-Path $_.FullName '.devdeck')) -and -not (Test-Path (Join-Path $_.FullName 'SKILL.md')) }
Check "all skill dirs have SKILL.md" { -not $Bad }

# Pins marked "required" in upstream.json must be installed as skills.
$Up = Get-Content (Join-Path $Root 'upstream.json') -Raw | ConvertFrom-Json
foreach ($Pin in ($Up.pins | Where-Object { $_.required -and (@($_.packs | Where-Object { $Packs -contains $_ }).Count -gt 0) })) {
    Check "required skill '$($Pin.name)' installed" { Test-Path (Join-Path $SkillRoot "$($Pin.name)/SKILL.md") }
}

# Context Mode must be registered in each enabled host that takes MCP servers.
$Enabled = if ($Packs -contains 'dev-deck') { @((Get-Content $Cfg -Raw | ConvertFrom-Json).hosts) } else { @() }
if ($Enabled -contains 'claude') {
    Check "context-mode registered in claude" { cmd /c "claude mcp get context-mode >nul 2>&1"; $LASTEXITCODE -eq 0 }
}
if ($Enabled -contains 'codex') {
    Check "context-mode registered in codex" { (cmd /c "codex mcp list 2>nul") -match 'context-mode' }
}

Write-Host ""
if ($Fails -eq 0) {
    Write-Host "All checks passed." -ForegroundColor Green
    exit 0
} else {
    Write-Host "$Fails check(s) failed." -ForegroundColor Red
    exit 1
}
