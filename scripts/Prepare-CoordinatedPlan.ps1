param([Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{40}$')][string]$PlanCommit,
      [Parameter(Mandatory)][ValidatePattern('^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$')][string]$Version)
. (Join-Path $PSScriptRoot 'Distribution.Common.ps1')
if ($env:GITHUB_EVENT_NAME -cne 'workflow_dispatch' -or $env:GITHUB_REF -cne 'refs/heads/main' -or
    $env:GITHUB_REPOSITORY -cne 'NewDeriverius/MagicTheSortering-Releases') { throw 'Only trusted Releases main can coordinate publication.' }
& git merge-base --is-ancestor $PlanCommit HEAD
if ($LASTEXITCODE -ne 0) { throw 'Plan must be integrated into the trusted coordinator revision.' }
$target='.artifacts/plan/distribution'
New-Item -ItemType Directory -Path $target -Force | Out-Null
foreach ($name in @('plan.json','notes.md')) {
    $value=& git show "${PlanCommit}:distribution/$name"
    if ($LASTEXITCODE -ne 0) { throw 'Immutable plan/notes not found.' }
    [IO.File]::WriteAllText((Join-Path $target $name), ($value -join [Environment]::NewLine)+[Environment]::NewLine, [Text.UTF8Encoding]::new($false))
}
$p=Read-DistributionPlan (Join-Path $target 'plan.json')
if ($p.distributionVersion -cne $Version) { throw 'Requested version does not match immutable plan.' }
