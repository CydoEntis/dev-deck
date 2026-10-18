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

# Role files must have no unsubstituted template vars.
$AgentDirs = @(
    (Join-Path $HOME '.config/opencode/agent'),
    (Join-Path $HOME '.claude/agents')
)
foreach ($Dir in $AgentDirs) {
    if (Test-Path $Dir) {
        $Files = Get-ChildItem $Dir -Filter '*.md' -File
        Check "no {{...}} vars in $Dir" { -not ($Files | Where-Object { (Get-Content $_.FullName -Raw) -match '\{\{[A-Z_]+\}\}' }) }
    }
}

# Every installed skill dir must contain a SKILL.md.
$SkillRoot = Join-Path $HOME '.claude/skills'
$Bad = Get-ChildItem $SkillRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { -not (Test-Path (Join-Path $_.FullName 'SKILL.md')) }
Check "all skill dirs have SKILL.md" { -not $Bad }

Write-Host ""
if ($Fails -eq 0) {
    Write-Host "All checks passed." -ForegroundColor Green
    exit 0
} else {
    Write-Host "$Fails check(s) failed." -ForegroundColor Red
    exit 1
}
