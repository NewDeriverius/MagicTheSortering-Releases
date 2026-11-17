Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Read-DistributionPlan([string]$Path) {
    $p = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    $semver = '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$'
    if ($p.schemaVersion -ne 1 -or $p.distributionVersion -notmatch $semver) { throw 'Unsupported distribution plan/version.' }
    foreach ($product in @($p.web, $p.companion)) {
        if ($product.version -notmatch $semver -or $product.commit -cnotmatch '^[a-f0-9]{40}$') { throw 'Use SemVer and immutable full commit SHAs.' }
    }
    if ($p.sharedUI.commit -cnotmatch '^[a-f0-9]{40}$') { throw 'SharedUI requires a full commit SHA.' }
    if ($p.distributionVersion -cne $p.web.version) { throw 'The distribution tag must follow Web for the existing update checker.' }
    if (($p.companion.androidVersionCode -isnot [int] -and $p.companion.androidVersionCode -isnot [long]) -or $p.companion.androidVersionCode -lt 1 -or $p.companion.androidVersionCode -gt 2100000000) { throw 'Invalid Android versionCode.' }
    # Current consumers reject versions other than 1. Widen only with executable compatibility tests.
    if ($p.protocol.minimum -ne 1 -or $p.protocol.maximum -ne 1) { throw 'Only direct-sync protocol v1 has been validated.' }
    return $p
}
function Assert-DistributionSource([string]$Root, [string]$Commit, [string]$SharedCommit) {
    $head = & git -C $Root rev-parse HEAD
    if ($LASTEXITCODE -ne 0 -or $head -cne $Commit) { throw 'Source commit differs from the plan.' }
    $link = & git -C $Root rev-parse 'HEAD:external/SharedUI'
    if ($LASTEXITCODE -ne 0 -or $link -cne $SharedCommit) { throw 'SharedUI gitlink differs from the plan.' }
    $sharedHead = & git -C (Join-Path $Root 'external/SharedUI') rev-parse HEAD
    if ($LASTEXITCODE -ne 0 -or $sharedHead -cne $SharedCommit) { throw 'SharedUI checkout differs from its gitlink.' }
    foreach ($path in @($Root, (Join-Path $Root 'external/SharedUI'))) {
        $dirty = & git -C $path status --porcelain
        if ($LASTEXITCODE -ne 0 -or $dirty) { throw "Build from a clean checkout: $path" }
    }
    $validation = Get-Content -LiteralPath (Join-Path $Root 'external/SharedUI/src/MagicTheSortering.Shared.Contracts/DeviceSync/SyncValidation.cs') -Raw
    if ($validation -notmatch 'public const int Version = 1;') { throw 'Protocol declaration must be reviewed.' }
}
function Get-DistributionAssetNames($Plan) {
    @(
        "MagicTheSortering-Setup-$($Plan.web.version)-win-x64.exe"
        "MagicTheSortering-$($Plan.web.version)-win-x64-portable.zip"
        "MagicTheSortering-$($Plan.web.version)-linux-x64.tar.gz"
        "MagicTheSortering-$($Plan.web.version)-linux-arm64.tar.gz"
        "MagicTheSortering-Companion-$($Plan.companion.version).apk"
    )
}
function Get-DistributionHash([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Write-DistributionJson($Value, [string]$Path) {
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 15) + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
}
