. (Join-Path $PSScriptRoot 'Orchestration.ps1')
. (Join-Path $PSScriptRoot 'Android-Signing.ps1')
$passed=0
function Reject([scriptblock]$Action) {
    $rejected=$false; try { & $Action | Out-Null } catch { $rejected=$true }
    if (!$rejected) { throw 'An unsafe orchestration input was accepted.' }; $script:passed++
}
$plan=[pscustomobject]@{web=@{version='1.0.4';commit=('a'*40)};companion=@{version='1.0.4';commit=('b'*40)};sharedUI=@{commit=('c'*40)}}
function Reset-Build {
    $global:buildFake=[pscustomobject]@{
        run=[pscustomobject]@{id=123;head_repository=@{full_name='NewDeriverius/MagicTheSortering'};event='workflow_dispatch';path='.github/workflows/release.yml';head_branch='main';head_sha=('a'*40);status='completed';conclusion='success';run_attempt=2}
        artifact=[pscustomobject]@{id=456;name='web-packages-123-2';expired=$false;size_in_bytes=100;expires_at=[DateTimeOffset]::UtcNow.AddHours(1).ToString('o');digest=('sha256:'+('d'*64));workflow_run=@{id=123;head_sha=('a'*40);head_branch='main'}}
        main=('a'*40);shared=('c'*40);workflowState='active';fail=$false;body=$null
    }
}
function global:gh {
    param([Parameter(ValueFromRemainingArguments=$true,Position=0)][string[]]$Arguments,
          [Parameter(ValueFromPipeline=$true)][string]$Body)
    $global:LASTEXITCODE=0
    if ($global:buildFake.fail) { $global:LASTEXITCODE=1; return '' }
    $endpoint=$Arguments | Where-Object { $_ -like 'repos/*' } | Select-Object -First 1
    switch -Wildcard ($endpoint) {
        '*/runs/123/artifacts?per_page=100' { return @{artifacts=@($global:buildFake.artifact)} | ConvertTo-Json -Depth 8 }
        '*/runs/123' { return $global:buildFake.run | ConvertTo-Json -Depth 8 }
        '*/commits/main' { return @{sha=$global:buildFake.main} | ConvertTo-Json }
        '*/contents/external/SharedUI?ref=*' { return @{sha=$global:buildFake.shared} | ConvertTo-Json }
        '*/actions/workflows/release.yml' { return @{state=$global:buildFake.workflowState} | ConvertTo-Json }
        '*/dispatches' {
            $global:buildFake.body=$Body | ConvertFrom-Json
            return '{"workflow_run_id":123,"html_url":"https://github.com/example/actions/runs/123"}'
        }
        default { throw 'Unexpected API call in isolated test.' }
    }
}
$root=Join-Path ([IO.Path]::GetTempPath()) ('mts-orchestration-tests-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
try {
    Reset-Build
    $artifact=Resolve-ProductArtifact web $plan '123'
    if ($artifact.id -ne 456) { throw 'Wrong artifact resolved.' }; $passed++
    $id=Start-ProductBuild web $plan ('e'*40) ''
    if ($id -cne '123' -or $global:buildFake.body.ref -cne 'main' -or $global:buildFake.body.inputs.plan_commit -cne ('e'*40)) { throw 'Dispatch binding failed.' }; $passed++
    if ((Start-ProductBuild web $plan ('e'*40) '123') -cne '123') { throw 'Recovery changed run identity.' }; $passed++
    Wait-ProductBuild web $plan '123'; $passed++ # Already completed, no sleep/API polling.
    Assert-ProductBuildRequest web $plan ''; $passed++
    Assert-ProductBuildRequest web $plan '123'; $passed++
    $global:buildFake.shared='f'*40; Reject { Assert-ProductBuildRequest web $plan '' }; Reset-Build
    $global:buildFake.workflowState='disabled_manually'; Reject { Assert-ProductBuildRequest web $plan '' }; Reset-Build
    $mutations=@(
        {$global:buildFake.run.head_sha='f'*40}, {$global:buildFake.run.head_branch='feature/untrusted'},
        {$global:buildFake.run.path='.github/workflows/ci.yml'}, {$global:buildFake.run.event='pull_request'},
        {$global:buildFake.run.head_repository.full_name='other/repository'}, {$global:buildFake.run.conclusion='failure'},
        {$global:buildFake.run.status='in_progress'}, {$global:buildFake.artifact.name='web-packages-123-1'},
        {$global:buildFake.artifact.expired=$true}, {$global:buildFake.artifact.digest='unknown'},
        {$global:buildFake.artifact.expires_at=[DateTimeOffset]::UtcNow.AddMinutes(-1).ToString('o')},
        {$global:buildFake.artifact.workflow_run.id=789}, {$global:buildFake.artifact.workflow_run.head_sha='f'*40},
        {$global:buildFake.artifact.workflow_run.head_branch='feature/untrusted'}, {$global:buildFake.artifact.size_in_bytes=0},
        {$global:buildFake.fail=$true}
    )
    foreach ($mutation in $mutations) { Reset-Build; & $mutation; Reject { Resolve-ProductArtifact web $plan '123' } }
    Reset-Build; $global:buildFake.main='f'*40; Reject { Start-ProductBuild web $plan ('e'*40) '' }
    Reject { Start-ProductBuild web $plan ('e'*40) '123;echo unsafe' }
    Reject { Start-ProductBuild unknown $plan ('e'*40) '' }
    Reject { Start-ProductBuild web $plan 'main' '' }
    # Artifact extraction rejects unexpected/duplicate/traversing entries, without deleting any existing output.
    foreach ($names in @(@('file.txt'),@('../file.txt'),@('file.txt','file.txt'),@('private.keystore'))) {
        $zip=Join-Path $root ([Guid]::NewGuid().ToString('N')+'.zip')
        $stream=[IO.File]::Create($zip)
        $archive=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create)
        foreach ($name in $names) { $entry=$archive.CreateEntry($name); $writer=[IO.StreamWriter]::new($entry.Open()); $writer.Write('synthetic'); $writer.Dispose() }
        $archive.Dispose(); $stream.Dispose()
        $out=Join-Path $root ([Guid]::NewGuid().ToString('N'))
        if ($names.Count -eq 1 -and $names[0] -ceq 'file.txt') {
            Expand-ProductArtifact $zip $out @('file.txt')
            if ((Get-Content (Join-Path $out 'file.txt') -Raw) -cne 'synthetic') { throw 'Valid artifact extraction failed.' }; $passed++
            Reject { Expand-ProductArtifact $zip $out @('file.txt') }
        } else { Reject { Expand-ProductArtifact $zip $out @('file.txt') } }
    }
    $signature="Verifies`nNumber of signers: 1`nSigner #1 certificate SHA-256 digest: $('a'*64)"
    if ((Get-VerifiedApkSigningCertificate $signature 0) -cne ('a'*64)) { throw 'Signature parser regression.' }; $passed++
    Reject { Get-VerifiedApkSigningCertificate $signature 1 }
    Reject { Get-VerifiedApkSigningCertificate ($signature+"`nCN=Android Debug") 0 }
    Reject { Get-VerifiedApkSigningCertificate ($signature.Replace('signers: 1','signers: 2')) 0 }
    Write-Output "$passed orchestration contracts passed (mock APIs, no credentials or dispatch)."
} finally {
    Remove-Item Function:\gh
    Remove-Variable buildFake -Scope Global
    $resolved=[IO.Path]::GetFullPath($root)
    $parent=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
    if (!$resolved.StartsWith($parent,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($resolved) -notmatch '^mts-orchestration-tests-[a-f0-9]{32}$') { throw 'Unsafe cleanup target.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
$global:LASTEXITCODE=0
