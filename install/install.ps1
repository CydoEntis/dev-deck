#Requires -Version 5.1
# Dev Deck installer (Windows). Pulls pinned upstream skills, installs them plus
# the personal pipeline/init skills into the host skill dirs, writes role agent
# files (models substituted from dev-deck.config.json), and registers MCP servers.
# Idempotent: safe to re-run. Personal skills always win on name conflicts.

param([string]$Root = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = 'Stop'
$SkillTargets = @((Join-Path $HOME '.claude/skills'))
$Issues = @()

function Read-Json([string]$Path) {
    if (-not (Test-Path $Path)) { throw "missing file: $Path" }
    Get-Content $Path -Raw | ConvertFrom-Json
}

# Run git without its stderr tripping ErrorActionPreference=Stop.
# git writes progress ("Cloning into…", "From …") to stderr; under EAP=Stop
# PowerShell surfaces that as a terminating NativeCommandError. Drop the
# preference around the call, discard stderr, and return the real exit code.
function Invoke-Git([string[]]$GitArgs) {
    $prev = $global:ErrorActionPreference
    try {
        $global:ErrorActionPreference = 'SilentlyContinue'
        & git @GitArgs 2>$null | Out-Null
        return $LASTEXITCODE
    } finally {
        $global:ErrorActionPreference = $prev
    }
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
$Decks = @($Cfg.decks)
function Get-Model([string]$HostName, [string]$Role) {
    $v = $Cfg.models.$HostName.$Role
    if ($null -eq $v -or $v -eq '') { return '' }
    return $v
}

# "include" takes only the named skills; "exclude" drops the named ones.
function Test-PinSkill($Pin, [string]$Skill) {
    if ($Pin.include) { return $Pin.include -contains $Skill }
    return -not ($Pin.exclude -contains $Skill)
}

# --- fetch upstreams ----------------------------------------------------
$Up = Read-Json (Join-Path $Root 'upstream.json')
$CacheDir = Join-Path $Root 'cache'
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
$Manifest = @{ skills = @{}; agents = @{}; mcp = @{}; installedAt = (Get-Date).ToString('o') }
$SkillNames = @{}

foreach ($Pin in $Up.pins) {
    if (-not (@($Pin.decks) | Where-Object { $Decks -contains $_ })) {
        Write-Host "skip    $($Pin.name) (deck not enabled)" -ForegroundColor DarkGray
        continue
    }
    if (-not $Pin.url -and -not $Pin.localPath) {
        Write-Host "skip    $($Pin.name) (no url or localPath yet)" -ForegroundColor DarkGray
        continue
    }
    if ($Pin.url) {
        $Dest = Join-Path $CacheDir $Pin.name
        if (-not (Test-Path (Join-Path $Dest '.git'))) {
            $gitArgs = @('clone', '--depth', '1')
            if ($Pin.ref -and $Pin.ref -ne 'main' -and $Pin.ref -ne 'master') { $gitArgs += @('--branch', $Pin.ref) }
            $gitArgs += @($Pin.url, $Dest)
            $code = Invoke-Git $gitArgs
            if ($code -ne 0) { $Issues += "clone failed: $($Pin.name) ($($Pin.url))"; continue }
            Write-Host "fetched $($Pin.name) ($($Pin.url))"
        } else {
            if ($Pin.ref -and $Pin.ref -ne 'main' -and $Pin.ref -ne 'master') {
                $code = Invoke-Git @('-C', $Dest, 'fetch', '--depth', '1', 'origin', $Pin.ref)
                if ($code -eq 0) { $code = Invoke-Git @('-C', $Dest, 'reset', '--hard', "origin/$($Pin.ref)") }
            } else {
                $code = Invoke-Git @('-C', $Dest, 'pull', '--ff-only')
            }
            if ($code -ne 0) { $Issues += "update failed: $($Pin.name)"; continue }
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
        if (Test-PinSkill $Pin $Dir.Name) { $SkillNames[$Dir.Name] = @{ source = $Pin.name; path = $Dir.FullName } }
    }
}

# --- install skills -------------------------------------------------------
# Personal skills ship from the repo, one folder per deck: skills/<deck>/<name>.
$ManifestSkills = @{}
$PersonalSrc = @{}
foreach ($Deck in $Decks) {
    $DeckDir = Join-Path $Root "skills/$Deck"
    if (-not (Test-Path $DeckDir)) { continue }  # a deck may be made only of upstream pins
    Get-ChildItem -Path $DeckDir -Directory | ForEach-Object {
        $ManifestSkills[$_.Name] = $Deck
        $PersonalSrc[$_.Name] = $_.FullName
    }
}
# Upstream skills fill in names not claimed by a personal skill (personal wins).
foreach ($K in $SkillNames.Keys) {
    if (-not $PersonalSrc.ContainsKey($K)) { $ManifestSkills[$K] = $SkillNames[$K].source }
}

$Installed = 0
$Skipped = 0
foreach ($Name in $ManifestSkills.Keys) {
    if ($PersonalSrc.ContainsKey($Name)) {
        $SrcDir = $PersonalSrc[$Name]
    } else {
        $SrcDir = $SkillNames[$Name].path
    }
    foreach ($Target in $SkillTargets) {
        if (-not (Test-Path $Target)) { New-Item -ItemType Directory -Force -Path $Target | Out-Null }
        $Dst = Join-Path $Target $Name
        $Marker = Join-Path $Dst '.devdeck'
        if ((Test-Path $Dst) -and (-not (Test-Path $Marker))) {
            $IsLink = [bool]((Get-Item $Dst -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)
            if ($IsLink -and -not $PersonalSrc.ContainsKey($Name)) {
                # Link from an earlier manual setup, now owned by a pinned upstream.
                # rmdir removes the link only, never what it points at.
                cmd /c rmdir "$Dst" | Out-Null
            } else {
                # personal skill or unmanaged link: leave alone
                Write-Host "skip    '$Name' already present without dev-deck marker - personal wins" -ForegroundColor Yellow
                $Skipped++
                continue
            }
        }
        if (Test-Path $Dst) { Remove-Item $Dst -Recurse -Force }   # ours (marker) or link: refresh
        Copy-Item $SrcDir $Dst -Recurse -Force
        Set-Content -Path $Marker -Value $ManifestSkills[$Name] -NoNewline
        $Installed++
    }
}
Write-Host "installed $Installed skill copies, skipped $Skipped personal conflict(s)"

# Remove skills we installed earlier that are no longer selected.
Get-ChildItem -Path (Join-Path $HOME '.claude/skills') -Directory | Where-Object {
    (Test-Path (Join-Path $_.FullName '.devdeck')) -and -not $ManifestSkills.ContainsKey($_.Name)
} | ForEach-Object {
    Remove-Item $_.FullName -Recurse -Force
    Write-Host "remove  '$($_.Name)' is no longer selected"
}

# --- role agent files -----------------------------------------------------
# Each host gets roles in its own format: Claude Code as markdown, Codex as TOML.
function Write-Utf8([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding $false))
}

function ConvertTo-MarkdownAgent([string]$Raw, [string]$Model, [string]$HostName) {
    $Content = $Raw
    if ($Model) { return $Content -replace '\{\{\w+\}\}', $Model }
    if ($HostName -eq 'claude') { return $Content -replace '\{\{\w+\}\}', 'inherit' }
    return $Content -replace '(?m)^model:\s*\{\{\w+\}\}\s*\r?\n', ''
}

function ConvertTo-CodexAgent([string]$Raw, [string]$Role, [string]$Model) {
    if ($Raw -notmatch '(?s)\A---\r?\n(.*?)\r?\n---\r?\n(.*)\z') { throw "role '$Role' has no frontmatter" }
    $Front = $Matches[1]
    $Body = $Matches[2].TrimEnd()
    if ($Body -match "'''") { throw "role '$Role' body contains ''' (breaks the TOML literal string)" }
    $Desc = ([regex]::Match($Front, '(?m)^description:\s*(.+?)\s*$')).Groups[1].Value
    $Desc = $Desc -replace '\\', '\\' -replace '"', '\"'
    $Lines = @("name = `"$Role`"", "description = `"$Desc`"")
    if ($Model) { $Lines += "model = `"$Model`"" }
    $Lines += "developer_instructions = '''", $Body, "'''"
    return (($Lines -join "`n") + "`n")
}

# Role files belong to the dev-deck deck only.
$AgentTemplates = @()
if ($Decks -contains 'developer') { $AgentTemplates = @(Get-ChildItem (Join-Path $Root 'agents') -Filter '*.md' -File) }
foreach ($hostName in $Hosts) {
    $AgentDir = switch ($hostName) {
        'claude'   { Join-Path $HOME '.claude/agents' }
        'codex'    { Join-Path $HOME '.codex/agents' }
        default    { $null }
    }
    if ($null -eq $AgentDir) {
        Write-Host "note    host '$hostName': no subagent format; skills only" -ForegroundColor DarkGray
        continue
    }
    New-Item -ItemType Directory -Force -Path $AgentDir | Out-Null
    foreach ($Tpl in $AgentTemplates) {
        $Role = $Tpl.BaseName
        $Raw = Get-Content $Tpl.FullName -Raw -Encoding UTF8
        $Model = Get-Model $hostName $Role
        if ($hostName -eq 'codex') {
            $File = Join-Path $AgentDir "$Role.toml"
            $Content = ConvertTo-CodexAgent $Raw $Role $Model
        } else {
            $File = Join-Path $AgentDir "$Role.md"
            $Content = ConvertTo-MarkdownAgent $Raw $Model $hostName
        }
        Write-Utf8 $File $Content
        $Manifest.agents["$hostName/$Role"] = $AgentDir
    }
    Write-Host "agents  wrote $($AgentTemplates.Count) $hostName role files -> $AgentDir"
}

# --- MCP registration (claude, codex) --------------------------------------
$McpFile = Join-Path $Root 'mcp/context-mode.json'
$Mcp = Read-Json $McpFile
# Both hosts are configured through their own CLIs, so the installer calls
# those instead of editing their config files. Remove first so re-runs refresh.
function Invoke-Quiet([string]$Exe, [string[]]$CmdArgs) {
    $ErrorActionPreference = 'Continue'
    & $Exe @CmdArgs *>$null
    return $LASTEXITCODE
}

foreach ($hostName in @('claude', 'codex')) {
    if ($Hosts -notcontains $hostName -or $Decks -notcontains 'developer') { continue }
    if (-not (Get-Command $hostName -ErrorAction SilentlyContinue)) {
        $Issues += "$hostName CLI not found - MCP not registered for $hostName"
        continue
    }
    foreach ($S in $Mcp.servers.PSObject.Properties) {
        $Cmd = @($S.Value.command)
        if (($Cmd -join ' ') -match 'REPLACE-WITH') { continue }
        if ($hostName -eq 'claude') {
            Invoke-Quiet 'claude' @('mcp', 'remove', '--scope', 'user', $S.Name) | Out-Null
            $Code = Invoke-Quiet 'claude' (@('mcp', 'add', '--scope', 'user', $S.Name, '--') + $Cmd)
        } else {
            Invoke-Quiet 'codex' @('mcp', 'remove', $S.Name) | Out-Null
            $Code = Invoke-Quiet 'codex' (@('mcp', 'add', $S.Name, '--') + $Cmd)
        }
        if ($Code -ne 0) { $Issues += "mcp add failed in ${hostName}: $($S.Name)" }
        else { Write-Host "mcp     $hostName registered $($S.Name)" }
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

