param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$PlanPath,
    [Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{40}$')][string]$PlanCommit
)
. (Join-Path $PSScriptRoot 'Distribution.Common.ps1')
$p=Read-DistributionPlan $PlanPath
$m=Get-Content -LiteralPath (Join-Path $Path 'distribution-manifest.json') -Raw | ConvertFrom-Json
if($m.schemaVersion -ne 1 -or $m.planCommit -cne $PlanCommit -or $m.distributionVersion -cne $p.distributionVersion) {throw 'Distribution identity mismatch.'}
foreach($name in @('web','companion')) {
    if($m.$name.commit -cne $p.$name.commit -or $m.$name.version -cne $p.$name.version -or $m.$name.sharedUI -cne $p.sharedUI.commit) {throw 'Source provenance mismatch.'}
}
if($m.companion.androidVersionCode -ne $p.companion.androidVersionCode -or $m.companion.signingCertificateSha256 -cnotmatch '^[a-f0-9]{64}$' -or $m.protocol.minimum -ne 1 -or $m.protocol.maximum -ne 1) {throw 'Invalid signing/protocol metadata.'}
$expected=@(Get-DistributionAssetNames $p)+@('RELEASE-NOTES.md')
if(@($m.artifacts).Count -ne $expected.Count) {throw 'Unexpected artifact count.'}
$all=@($expected)+@('distribution-manifest.json','SHA256SUMS.txt')
$found=@(Get-ChildItem -LiteralPath $Path -Force)
if($found.Count -ne $all.Count -or @($found | Where-Object { $_.PSIsContainer -or $_.Name -cnotin $all -or ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) }).Count) {throw 'Only explicitly allowed public assets may be distributed.'}
$checksumLines=@(Get-Content -LiteralPath (Join-Path $Path 'SHA256SUMS.txt'))
$expectedLines=@()
foreach($name in $expected) {
    $a=@($m.artifacts | Where-Object name -CEQ $name)
    $f=Get-Item -LiteralPath (Join-Path $Path $name)
    $hash=Get-DistributionHash $f.FullName
    if($a.Count -ne 1 -or $a[0].sha256 -cne $hash -or $a[0].bytes -ne $f.Length -or $f.Length -le 0) {throw "Asset mismatch: $name"}
    $expectedLines += "$hash  $name"
}
$expectedLines += "$(Get-DistributionHash (Join-Path $Path 'distribution-manifest.json'))  distribution-manifest.json"
if(($checksumLines -join [char]10) -cne ($expectedLines -join [char]10)) {throw 'Checksum list mismatch.'}
Write-Output "Distribution $($p.distributionVersion): five product packages, notes, provenance and hashes verified."
