#Requires -Version 5.1
# Dev Deck installer (Windows). Pulls pinned upstream skills, installs them plus
# the personal pipeline/init skills into the host skill dirs, writes role agent
# files (models substituted from dev-deck.config.json), and registers MCP servers.
# Idempotent: safe to re-run. Personal skills always win on name conflicts.

param([string]$Root = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = 'Stop'
$Home = $HOME
$SkillTargets = @((Join-Path $Home '.claude/skills'))
$Issues = @()

function Read-Json([string]$Path) {
    if (-not (Test-Path $Path)) { throw "missing file: $Path" }
    Get-Content $Path -Raw | ConvertFrom-Json
}

# --- config -------------------------------------------------------------
$CfgPath = Join-Path $Root 'dev-deck.config.json'
if (-not (Test-Path $CfgPath)) {
    Copy-Item (Join-Path $Root 'dev-deck.config.json.example') $CfgPath
    Write-Host "Created $CfgPath from the example. Edit it (model slots, hosts), then re-run." -ForegroundColor Yellow
    exit 1
}
$Cfg = Read-Json $CfgPath
$Hosts = @($Cfg.hosts)
function Get-Model([string]$Key) {
    $v = $Cfg.$Key
    if ($null -eq $v -or $v -eq '') { return '' }
    return $v
}

# --- fetch upstreams ----------------------------------------------------
$Up = Read-Json (Join-Path $Root 'upstream.json')
$CacheDir = Join-Path $Root 'cache'
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
$Manifest = @{ skills = @{}; agents = @{}; mcp = @{}; installedAt = (Get-Date).ToString('o') }
$SkillNames = @{}

foreach ($Pin in $Up.pins) {
    if (-not $Pin.url -and -not $Pin.localPath) {
        Write-Host "skip    $($Pin.name) (no url or localPath yet)" -ForegroundColor DarkGray
        continue
    }
    if ($Pin.url) {
        $Dest = Join-Path $CacheDir $Pin.name
        if (-not (Test-Path (Join-Path $Dest '.git'))) {
            $Args = @('clone', '--depth', '1')
            if ($Pin.ref -and $Pin.ref -ne 'main' -and $Pin.ref -ne 'master') { $Args += @('--branch', $Pin.ref) }
            $Args += @($Pin.url, $Dest)
            & git @Args 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { $Issues += "clone failed: $($Pin.name) ($($Pin.url))"; continue }
            Write-Host "fetched $($Pin.name) ($($Pin.url))"
        } else {
            if ($Pin.ref -and $Pin.ref -ne 'main' -and $Pin.ref -ne 'master') {
                & git -C $Dest fetch --depth 1 origin $Pin.ref 2>&1 | Out-Null
                & git -C $Dest reset --hard "origin/$($Pin.ref)" 2>&1 | Out-Null
            } else {
                & git -C $Dest pull --ff-only 2>&1 | Out-Null
            }
            if ($LASTEXITCODE -ne 0) { $Issues += "update failed: $($Pin.name)"; continue }
            Write-Host "updated $($Pin.name)"
        }
        $Src = $Dest
    } else {
        $Src = $Pin.localPath
        if (-not (Test-Path $Src)) { $Issues += "local path missing: $($Pin.name) -> $Src"; continue }
        Write-Host "using local $($Pin.name) ($Src)"
    }
    $Sp = Join-Path $Src $Pin.skillsPath
    if (-not (Test-Path $Sp)) { $Issues += "skillsPath not found in $($Pin.name): $Sp"; continue }
    Get-ChildItem -Path $Sp -Recurse -Depth 3 -Filter 'SKILL.md' -File | ForEach-Object {
        $Dir = $_.Directory
        $SkillNames[$Dir.Name] = @{ source = $Pin.name; path = $Dir.FullName }
    }
}

# --- install skills -------------------------------------------------------
# Personal skills ship from the repo itself: pipeline, init.
$ManifestSkills = @{}
$Personal = @()
Get-ChildItem -Path (Join-Path $Root 'skills') -Directory | ForEach-Object {
    $ManifestSkills[$_.Name] = 'dev-deck'
    $Personal += $_
}
foreach ($K in $SkillNames.Keys) { $ManifestSkills[$K] = $SkillNames[$K].source }

$Installed = 0
$Skipped = 0
foreach ($Name in $ManifestSkills.Keys) {
    if ($ManifestSkills[$Name] -eq 'dev-deck') {
        $SrcDir = (Get-ChildItem (Join-Path $Root 'skills') -Directory | Where-Object Name -eq $Name).FullName
    } else {
        $SrcDir = $SkillNames[$Name].path
    }
    foreach ($Target in $SkillTargets) {
        if (-not (Test-Path $Target)) { New-Item -ItemType Directory -Force -Path $Target | Out-Null }
        $Dst = Join-Path $Target $Name
        $Marker = Join-Path $Dst '.devdeck'
        if ((Test-Path $Dst) -and (-not (Test-Path $Marker))) {
            # exists but not installed by us (no marker) -> personal or link: leave alone
            Write-Host "skip    '$Name' already present without dev-deck marker - personal wins" -ForegroundColor Yellow
            $Skipped++
            continue
        }
        if (Test-Path $Dst) { Remove-Item $Dst -Recurse -Force }   # ours (marker) or link: refresh
        Copy-Item $SrcDir $Dst -Recurse -Force
        Set-Content -Path $Marker -Value $ManifestSkills[$Name] -NoNewline
        $Installed++
    }
}
Write-Host "installed $Installed skill copies, skipped $Skipped personal conflict(s)"

# --- role agent files -----------------------------------------------------
$AgentTemplates = Get-ChildItem (Join-Path $Root 'agents') -Filter '*.md' -File
foreach ($Host in $Hosts) {
    switch ($Host) {
        'opencode' { $AgentDir = Join-Path $Home '.config/opencode/agent' }
        'claude'   { $AgentDir = Join-Path $Home '.claude/agents' }
        default    {
            Write-Host "note    host '$Host': roles stay as instruction files in the repo" -ForegroundColor DarkGray
            continue
        }
    }
    New-Item -ItemType Directory -Force -Path $AgentDir | Out-Null
    foreach ($Tpl in $AgentTemplates) {
        $Content = Get-Content $Tpl.FullName -Raw
        $Role = $Tpl.BaseName
        $Model = switch ($Role) {
            'planner'  { Get-Model 'planner' }
            'builder'  { Get-Model 'builder' }
            'reviewer' { Get-Model 'reviewer' }
            default    { '' }
        }
        if ($Host -eq 'claude') {
            if ($Model -eq '') { $Model = 'inherit' }
            $Content = $Content -replace '\{\{\w+\}\}', $Model
        } else {
            if ($Model -eq '') { $Content = $Content -replace '(?m)^model:\s*\{\{\w+\}\}\s*$', '' }
            else { $Content = $Content -replace '\{\{\w+\}\}', $Model }
        }
        Set-Content -Path (Join-Path $AgentDir "$Role.md") -Value $Content -NoNewline
        $Manifest.agents[$Role] = $AgentDir
    }
    Write-Host "agents  wrote $($AgentTemplates.Count) role files -> $AgentDir"
}

# --- MCP registration (opencode) ------------------------------------------
$McpFile = Join-Path $Root 'mcp/context-mode.json'
$Mcp = Read-Json $McpFile
if ($Hosts -contains 'opencode') {
    $Ocfg = Join-Path $Home '.config/opencode/opencode.json'
    if (Test-Path $Ocfg) {
        $Backup = "$Ocfg.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
        Copy-Item $Ocfg $Backup
        $Oj = Read-Json $Ocfg
        if (-not ($Oj.PSObject.Properties.Name -contains 'mcp')) {
            $Oj | Add-Member -NotePropertyName mcp -NotePropertyValue ([PSCustomObject]@{})
        }
        foreach ($S in $Mcp.servers.PSObject.Properties) {
            $CmdText = "$($S.Value.command)"
            if ($CmdText -match 'REPLACE-WITH') {
                Write-Host "warn    MCP '$($S.Name)' has a placeholder command - not registered. Edit mcp/context-mode.json, re-run." -ForegroundColor Yellow
                continue
            }
            $Oj.mcp | Add-Member -NotePropertyName $S.Name -NotePropertyValue $S.Value -Force
            $Manifest.mcp[$S.Name] = $Ocfg
        }
        $Oj | ConvertTo-Json -Depth 12 | Set-Content $Ocfg
        Write-Host "mcp     merged $($Mcp.servers.PSObject.Properties.Count) server(s) into $Ocfg (backup: $Backup)"
    } else {
        $Issues += "opencode config not found at $Ocfg - MCP not registered"
    }
}

# --- manifest -------------------------------------------------------------
$Manifest.skills = $ManifestSkills
$Manifest | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $Root 'installed.json')

# --- report ---------------------------------------------------------------
if ($Issues.Count -gt 0) {
    Write-Host "`nIssues ($($Issues.Count)):" -ForegroundColor Red
    $Issues | ForEach-Object { Write-Host " - $_" }
    exit 1
}
Write-Host "`nDone. Run install\doctor.ps1 to verify." -ForegroundColor Green
