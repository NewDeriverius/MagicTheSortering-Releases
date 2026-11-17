param([string]$ExampleManifestPath)
. (Join-Path $PSScriptRoot 'Distribution.Common.ps1')
$root=Join-Path ([IO.Path]::GetTempPath()) ('mts-distribution-tests-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root|Out-Null
$passed=0
function Expect-Failure([scriptblock]$Action) {
    $failed=$false
    try { & $Action | Out-Null } catch {$failed=$true}
    if(-not $failed){throw 'Expected rejection did not occur.'}
    $script:passed++
}
try {
    $web=Join-Path $root 'web';$android=Join-Path $root 'android';$out=Join-Path $root 'out'
    New-Item -ItemType Directory -Path $web,$android|Out-Null
    $p=[ordered]@{schemaVersion=1;distributionVersion='1.2.3-beta';web=@{version='1.2.3-beta';commit=('a'*40)};companion=@{version='0.8.1';commit=('b'*40);androidVersionCode=8002};sharedUI=@{commit=('c'*40)};protocol=@{minimum=1;maximum=1}}
    $plan=Join-Path $root 'plan.json';Write-DistributionJson $p $plan
    $p=Read-DistributionPlan $plan
    $names=@(Get-DistributionAssetNames $p)
    $assets=@()
    foreach($name in $names){
        $dir=if($name.EndsWith('.apk')){$android}else{$web}
        $f=Join-Path $dir $name
        [IO.File]::WriteAllText($f,"Synthetic test fixture $name")
        $assets+=@{name=$name;bytes=(Get-Item -LiteralPath $f).Length;sha256=(Get-DistributionHash $f)}
    }
    Write-DistributionJson @{commit=$p.web.commit;version=$p.web.version;dirty=$false;artifacts=@($assets|Where-Object name -NotLike '*.apk')} (Join-Path $web "MagicTheSortering-$($p.web.version)-release.json")
    $wp=@{version=$p.web.version;commit=$p.web.commit;sharedUI=$p.sharedUI.commit;protocol=1;validated=$true;checks=@('synthetic-web');sharedChecks=@('synthetic-shared')}
    $ap=@{version=$p.companion.version;commit=$p.companion.commit;sharedUI=$p.sharedUI.commit;protocol=1;validated=$true;androidVersionCode=8002;signingCertificateSha256=('d'*64);apkSha256=$assets[-1].sha256;checks=@('synthetic-android')}
    Write-DistributionJson $wp (Join-Path $web 'web-provenance.json')
    Write-DistributionJson $ap (Join-Path $android 'companion-provenance.json')
    $notes=Join-Path $root 'notes.md';[IO.File]::WriteAllText($notes,'Synthetic release notes.')
    $args=@{PlanPath=$plan;PlanCommit=('e'*40);WebPackagesPath=$web;AndroidPackagesPath=$android;NotesPath=$notes;OutputPath=$out}
    & (Join-Path $PSScriptRoot 'New-Distribution.ps1') @args
    $passed++ # Successful aggregation with different product versions.
    # No GitHub command is reachable without -Publish, even without a GH token.
    & (Join-Path $PSScriptRoot 'Publish-Distribution.ps1') -Path $out -PlanPath $plan -PlanCommit ('e'*40)
    $passed++
    Expect-Failure { & (Join-Path $PSScriptRoot 'New-Distribution.ps1') @args }
    $verify={& (Join-Path $PSScriptRoot 'Test-Distribution.ps1') -Path $out -PlanPath $plan -PlanCommit ('e'*40)}
    $apk=Join-Path $out $names[-1];$original=[IO.File]::ReadAllBytes($apk)
    [IO.File]::AppendAllText($apk,'tamper');Expect-Failure $verify;[IO.File]::WriteAllBytes($apk,$original)
    $secret=Join-Path $out 'private.keystore';[IO.File]::WriteAllText($secret,'secret');Expect-Failure $verify;Remove-Item -LiteralPath $secret
    $p.web.commit='main';Write-DistributionJson $p $plan;Expect-Failure {Read-DistributionPlan $plan};$p.web.commit='a'*40
    $p.protocol.maximum=2;Write-DistributionJson $p $plan;Expect-Failure {Read-DistributionPlan $plan};$p.protocol.maximum=1
    $p.companion.androidVersionCode=0;Write-DistributionJson $p $plan;Expect-Failure {Read-DistributionPlan $plan};$p.companion.androidVersionCode=8002
    $p.distributionVersion='9.9.9';Write-DistributionJson $p $plan;Expect-Failure {Read-DistributionPlan $plan};$p.distributionVersion=$p.web.version
    Write-DistributionJson $p $plan
    # Use fresh output directories; the aggregator never deletes previous results.
    $args.OutputPath=Join-Path $root 'missing';$sourceApk=Join-Path $android $names[-1]
    Move-Item -LiteralPath $sourceApk -Destination ($sourceApk+'.saved')
    Expect-Failure {& (Join-Path $PSScriptRoot 'New-Distribution.ps1') @args}
    Move-Item -LiteralPath ($sourceApk+'.saved') -Destination $sourceApk
    $ap.commit='f'*40;Write-DistributionJson $ap (Join-Path $android 'companion-provenance.json')
    Expect-Failure {& (Join-Path $PSScriptRoot 'New-Distribution.ps1') @args};$ap.commit='b'*40
    $ap.validated=$false;Write-DistributionJson $ap (Join-Path $android 'companion-provenance.json')
    Expect-Failure {& (Join-Path $PSScriptRoot 'New-Distribution.ps1') @args}
    # Mock the CLI: publication state machine is tested without any network or credentials.
    $global:mtsFake=[ordered]@{root=$out;commit=('e'*40);draft=$false;writes=0;assets=@();notes='Synthetic release notes.';corrupt=$false;tagExists=$true;targetCommitish=('e'*40)}
    $global:mtsFake.assets=@(Get-ChildItem -LiteralPath $out -File|ForEach-Object {@{name=$_.Name;size=$_.Length}})
    function global:gh {
        param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Arguments)
        $global:LASTEXITCODE=0
        if($Arguments[0] -eq 'repo'){return 'PUBLIC'}
        if($Arguments[0] -eq 'api'){
            if($Arguments[1] -eq 'graphql'){
                if($global:mtsFake.tagExists){return 'existing-tag-object'}
                return ''
            }
            if($Arguments -contains 'POST'){
                if($global:mtsFake.tagExists){throw 'Ref already exists.'}
                $global:mtsFake.commit=($Arguments|Where-Object {$_ -like 'sha=*'}).Substring(4)
                $global:mtsFake.tagExists=$true;$global:mtsFake.writes++
                return '{}'
            }
            if(-not $global:mtsFake.tagExists){$global:LASTEXITCODE=1;return ''}
            return $global:mtsFake.commit
        }
        switch($Arguments[1]){
            'view' { return (@{isDraft=$global:mtsFake.draft;assets=$global:mtsFake.assets;body=$global:mtsFake.notes;targetCommitish=$global:mtsFake.targetCommitish}|ConvertTo-Json -Depth 6) }
            'download' {
                $name=$Arguments[[Array]::IndexOf($Arguments,'--pattern')+1]
                $dir=$Arguments[[Array]::IndexOf($Arguments,'--dir')+1]
                Copy-Item -LiteralPath (Join-Path $global:mtsFake.root $name) -Destination (Join-Path $dir $name)
                if($global:mtsFake.corrupt){[IO.File]::AppendAllText((Join-Path $dir $name),'tampered')}
            }
            'upload' {
                $global:mtsFake.writes++
                $f=Get-Item -LiteralPath $Arguments[3]
                $global:mtsFake.assets+=@{name=$f.Name;size=$f.Length}
            }
            'edit' {$global:mtsFake.writes++;$global:mtsFake.draft=$false}
            default {throw 'Unexpected GitHub operation in publication test.'}
        }
    }
    try {
        $publish={& (Join-Path $PSScriptRoot 'Publish-Distribution.ps1') -Publish -Path $out -PlanPath $plan -PlanCommit ('e'*40)}
        & $publish
        if($global:mtsFake.writes -ne 0){throw 'Idempotent publication wrote remote state.'};$passed++
        $global:mtsFake.corrupt=$true
        Expect-Failure $publish
        if($global:mtsFake.writes -ne 0){throw 'Conflicting publication changed remote state.'}
        $global:mtsFake.corrupt=$false
        $global:mtsFake.draft=$true
        $global:mtsFake.assets=@($global:mtsFake.assets|Select-Object -First 2)
        & $publish
        if($global:mtsFake.draft -or $global:mtsFake.assets.Count -ne 8 -or $global:mtsFake.writes -ne 7){throw 'Interrupted draft was not completed and published exactly once.'};$passed++
        # GitHub does not materialize a new tag while the release remains a draft.
        $global:mtsFake.draft=$true;$global:mtsFake.tagExists=$false;$global:mtsFake.writes=0
        & $publish
        if($global:mtsFake.draft -or -not $global:mtsFake.tagExists -or $global:mtsFake.commit -cne ('e'*40) -or $global:mtsFake.writes -ne 2){throw 'Draft without a tag was not completed safely.'};$passed++
        & $publish
        if($global:mtsFake.writes -ne 2){throw 'Published recovery was not idempotent.'};$passed++
        $global:mtsFake.draft=$true;$global:mtsFake.tagExists=$false;$global:mtsFake.targetCommitish='f'*40;$global:mtsFake.writes=0
        Expect-Failure $publish
        if($global:mtsFake.tagExists -or $global:mtsFake.writes){throw 'A different draft target was changed.'}
        $global:mtsFake.targetCommitish='e'*40;$global:mtsFake.corrupt=$true
        Expect-Failure $publish
        if($global:mtsFake.tagExists -or $global:mtsFake.writes){throw 'Tag was created before asset verification.'}
        $global:mtsFake.corrupt=$false;$global:mtsFake.draft=$false
        Expect-Failure $publish
        if($global:mtsFake.tagExists -or $global:mtsFake.writes){throw 'Published release without a tag was modified.'}
        $global:mtsFake.tagExists=$true
        $global:mtsFake.commit='f'*40
        Expect-Failure $publish
    } finally {Remove-Item Function:\gh;Remove-Variable mtsFake -Scope Global}

    if($ExampleManifestPath){
        & (Join-Path $PSScriptRoot 'Test-Distribution.ps1') -Path $out -PlanPath $plan -PlanCommit ('e'*40)
        Copy-Item -LiteralPath (Join-Path $out 'distribution-manifest.json') -Destination $ExampleManifestPath
    }
    Write-Output "$passed distribution contract tests passed (synthetic fixtures; no public release)."
} finally {
    $resolved=[IO.Path]::GetFullPath($root)
    $parent=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
    if(-not $resolved.StartsWith($parent,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($resolved) -notmatch '^mts-distribution-tests-[a-f0-9]{32}$'){throw 'Unsafe test cleanup path.'}
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
