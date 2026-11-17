param(
    [Parameter(Mandatory)][string]$PlanPath,
    [Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{40}$')][string]$PlanCommit,
    [Parameter(Mandatory)][string]$WebPackagesPath,
    [Parameter(Mandatory)][string]$AndroidPackagesPath,
    [Parameter(Mandatory)][string]$NotesPath,
    [Parameter(Mandatory)][string]$OutputPath
)
. (Join-Path $PSScriptRoot 'Distribution.Common.ps1')
$p = Read-DistributionPlan $PlanPath
if ((Test-Path -LiteralPath $OutputPath) -and @(Get-ChildItem -LiteralPath $OutputPath -Force).Count) { throw 'Output must be empty; do not mix distributions.' }
$web = Get-Content -LiteralPath (Join-Path $WebPackagesPath 'web-provenance.json') -Raw | ConvertFrom-Json
$android = Get-Content -LiteralPath (Join-Path $AndroidPackagesPath 'companion-provenance.json') -Raw | ConvertFrom-Json
foreach ($item in @(@($web,$p.web), @($android,$p.companion))) {
    $actual=$item[0]; $expected=$item[1]
    if ($actual.commit -cne $expected.commit -or $actual.version -cne $expected.version -or $actual.sharedUI -cne $p.sharedUI.commit -or $actual.protocol -ne 1 -or $actual.validated -ne $true) { throw 'Product validation/provenance does not match the plan.' }
}
if ($android.androidVersionCode -ne $p.companion.androidVersionCode -or $android.signingCertificateSha256 -cnotmatch '^[a-f0-9]{64}$') { throw 'Missing signed Android provenance.' }
$webManifest = Get-Content -LiteralPath (Join-Path $WebPackagesPath "MagicTheSortering-$($p.web.version)-release.json") -Raw | ConvertFrom-Json
if ($webManifest.commit -cne $p.web.commit -or $webManifest.dirty -ne $false -or $webManifest.version -cne $p.web.version) { throw 'Web package manifest is stale or dirty.' }
$names = @(Get-DistributionAssetNames $p)
$artifacts = @()
foreach ($name in $names) {
    $isAndroid = $name.EndsWith('.apk')
    $source = Join-Path $(if ($isAndroid) { $AndroidPackagesPath } else { $WebPackagesPath }) $name
    $file = Get-Item -LiteralPath $source
    if ($file.Length -le 0 -or $file.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Empty or linked artifact.' }
    $hash = Get-DistributionHash $source
    if ($isAndroid) {
        if ($hash -cne $android.apkSha256) { throw 'APK changed after signature validation.' }
    } else {
        $entry = @($webManifest.artifacts | Where-Object name -CEQ $name)
        if ($entry.Count -ne 1 -or $entry[0].sha256.ToLowerInvariant() -cne $hash -or $entry[0].bytes -ne $file.Length) { throw "Web payload changed after validation: $name" }
    }
    $artifacts += [ordered]@{name=$name; bytes=$file.Length; sha256=$hash; product=$(if($isAndroid){'companion'}else{'web'})}
}
$notes = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $NotesPath))
if ([string]::IsNullOrWhiteSpace($notes) -or $notes.Length -gt 65536) { throw 'Missing or oversized public release notes.' }
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
# Allowlist only. Never upload a workspace, source archive, keystore or test logs.
foreach ($name in $names) {
    $source = Join-Path $(if($name.EndsWith('.apk')){$AndroidPackagesPath}else{$WebPackagesPath}) $name
    Copy-Item -LiteralPath $source -Destination (Join-Path $OutputPath $name)
}
[IO.File]::WriteAllText((Join-Path $OutputPath 'RELEASE-NOTES.md'), $notes, [Text.UTF8Encoding]::new($false))
$notesFile=Get-Item -LiteralPath (Join-Path $OutputPath 'RELEASE-NOTES.md')
$artifacts += [ordered]@{name='RELEASE-NOTES.md';bytes=$notesFile.Length;sha256=(Get-DistributionHash $notesFile.FullName);product='distribution'}
$manifest = [ordered]@{
    schemaVersion=1; distributionVersion=$p.distributionVersion; planCommit=$PlanCommit
    web=[ordered]@{version=$p.web.version;commit=$p.web.commit;sharedUI=$p.sharedUI.commit}
    companion=[ordered]@{version=$p.companion.version;commit=$p.companion.commit;sharedUI=$p.sharedUI.commit;androidVersionCode=$p.companion.androidVersionCode;signingCertificateSha256=$android.signingCertificateSha256}
    protocol=$p.protocol
    validation=[ordered]@{web=$web.checks;companion=$android.checks;sharedUI=$web.sharedChecks}
    artifacts=$artifacts
}
Write-DistributionJson $manifest (Join-Path $OutputPath 'distribution-manifest.json')
$lines=@($artifacts | ForEach-Object { "$($_.sha256)  $($_.name)" })
$lines += "$(Get-DistributionHash (Join-Path $OutputPath 'distribution-manifest.json'))  distribution-manifest.json"
[IO.File]::WriteAllLines((Join-Path $OutputPath 'SHA256SUMS.txt'), $lines, [Text.Encoding]::ASCII)
& (Join-Path $PSScriptRoot 'Test-Distribution.ps1') -Path $OutputPath -PlanPath $PlanPath -PlanCommit $PlanCommit
