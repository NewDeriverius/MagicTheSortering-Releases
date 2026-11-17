. (Join-Path $PSScriptRoot 'Distribution.Common.ps1')
$DistributionProducts = @{
    web = @{ repository='NewDeriverius/MagicTheSortering'; workflow='release.yml'; prefix='web-packages' }
    companion = @{ repository='NewDeriverius/MagicTheSortering-Companion-App'; workflow='build-distribution.yml'; prefix='android-packages' }
}
function Read-DistributionApi([string]$Endpoint) {
    $json = & gh api $Endpoint
    if ($LASTEXITCODE -ne 0) { throw "GitHub API failed: $Endpoint" }
    return ($json -join [Environment]::NewLine) | ConvertFrom-Json
}
function Assert-ProductRun($Run, [string]$Product, $Plan, [switch]$Completed) {
    $spec=$DistributionProducts[$Product]
    if (!$spec -or $Run.head_repository.full_name -cne $spec.repository -or
        $Run.event -cne 'workflow_dispatch' -or $Run.path -cne ".github/workflows/$($spec.workflow)" -or
        $Run.head_branch -cne 'main' -or $Run.head_sha -cne $Plan.$Product.commit) {
        throw 'Only the pinned main product build workflow is authorized.'
    }
    if ($Completed -and ($Run.status -cne 'completed' -or $Run.conclusion -cne 'success')) {
        throw 'Product build has not completed successfully.'
    }
}
function Start-ProductBuild([string]$Product, $Plan, [string]$PlanCommit, [string]$ExistingRun) {
    $spec=$DistributionProducts[$Product]
    if (!$spec -or $PlanCommit -cnotmatch '^[a-f0-9]{40}$') { throw 'Invalid dispatch identity.' }
    if ($ExistingRun) {
        if ($ExistingRun -cnotmatch '^[1-9][0-9]*$') { throw 'Invalid recovery run ID.' }
        $run=Read-DistributionApi "repos/$($spec.repository)/actions/runs/$ExistingRun"
        Assert-ProductRun $run $Product $Plan -Completed
        return [string]$run.id
    }
    # Resolve main once; builders reject a later drift rather than compiling different code.
    $main=Read-DistributionApi "repos/$($spec.repository)/commits/main"
    if ($main.sha -cne $Plan.$Product.commit) { throw 'Product main changed; prepare a new immutable plan.' }
    $body=@{ref='main';return_run_details=$true;inputs=@{plan_commit=$PlanCommit}} | ConvertTo-Json -Compress
    $json=$body | & gh api --method POST "repos/$($spec.repository)/actions/workflows/$($spec.workflow)/dispatches" --input -
    if ($LASTEXITCODE -ne 0) { throw 'Product workflow dispatch failed.' }
    $response=($json -join [Environment]::NewLine) | ConvertFrom-Json
    $id=[string]$response.workflow_run_id
    if ($id -cnotmatch '^[1-9][0-9]*$') { throw 'Dispatch did not return an immutable workflow run ID.' }
    return $id
}
function Assert-ProductBuildRequest([string]$Product, $Plan, [string]$ExistingRun) {
    $spec=$DistributionProducts[$Product]
    if (!$spec) { throw 'Unknown product.' }
    if ($ExistingRun) {
        if ($ExistingRun -cnotmatch '^[1-9][0-9]*$') { throw 'Invalid recovery run ID.' }
        $run=Read-DistributionApi "repos/$($spec.repository)/actions/runs/$ExistingRun"
        Assert-ProductRun $run $Product $Plan -Completed
    } else {
        $main=Read-DistributionApi "repos/$($spec.repository)/commits/main"
        if ($main.sha -cne $Plan.$Product.commit) { throw 'Both products must be pinned to their integrated main revisions.' }
        $workflow=Read-DistributionApi "repos/$($spec.repository)/actions/workflows/$($spec.workflow)"
        if ($workflow.state -cne 'active') { throw 'Specialized product workflow is unavailable.' }
    }
    $link=Read-DistributionApi "repos/$($spec.repository)/contents/external/SharedUI?ref=$($Plan.$Product.commit)"
    if ($link.sha -cne $Plan.sharedUI.commit) { throw 'Product SharedUI gitlink differs from the immutable plan.' }
}
function Resolve-ProductArtifact([string]$Product, $Plan, [string]$RunId) {
    if ($RunId -cnotmatch '^[1-9][0-9]*$') { throw 'Invalid workflow run ID.' }
    $spec=$DistributionProducts[$Product]
    if (!$spec) { throw 'Unknown product.' }
    $run=Read-DistributionApi "repos/$($spec.repository)/actions/runs/$RunId"
    Assert-ProductRun $run $Product $Plan -Completed
    $result=Read-DistributionApi "repos/$($spec.repository)/actions/runs/$RunId/artifacts?per_page=100"
    $expected="$($spec.prefix)-$RunId-$($run.run_attempt)"
    $matches=@($result.artifacts | Where-Object name -CEQ $expected)
    if ($matches.Count -ne 1) { throw 'Missing or ambiguous product artifact from the successful attempt.' }
    $artifact=$matches[0]
    if ([string]$artifact.id -cnotmatch '^[1-9][0-9]*$' -or $artifact.expired -or $artifact.size_in_bytes -le 0 -or
        [DateTimeOffset]$artifact.expires_at -le [DateTimeOffset]::UtcNow -or
        [string]$artifact.workflow_run.id -cne $RunId -or
        $artifact.workflow_run.head_branch -cne 'main' -or
        $artifact.workflow_run.head_sha -cne $Plan.$Product.commit -or
        $artifact.digest -cnotmatch '^sha256:[a-f0-9]{64}$') { throw 'Invalid product artifact provenance/digest.' }
    return $artifact
}
function Wait-ProductBuild([string]$Product, $Plan, [string]$RunId) {
    if ($RunId -cnotmatch '^[1-9][0-9]*$' -or !$DistributionProducts.ContainsKey($Product)) { throw 'Invalid build request.' }
    $deadline=[DateTimeOffset]::UtcNow.AddMinutes(90)
    do {
        $run=Read-DistributionApi "repos/$($DistributionProducts[$Product].repository)/actions/runs/$RunId"
        Assert-ProductRun $run $Product $Plan
        if ($run.status -ceq 'completed') { Assert-ProductRun $run $Product $Plan -Completed; return }
        if ([DateTimeOffset]::UtcNow -ge $deadline) { throw 'Product build exceeded the bounded wait.' }
        # gh run watch requires Checks access unavailable to fine-grained PATs.
        # This bounded Actions-only wait uses just Actions:read, with no Codex polling.
        Start-Sleep -Seconds 60
    } while ($true)
}
function Expand-ProductArtifact([string]$ArchivePath, [string]$OutputPath, [string[]]$AllowedNames) {
    if (Test-Path -LiteralPath $OutputPath) { throw 'Use a new artifact directory.' }
    $archive=[IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        if ($archive.Entries.Count -ne $AllowedNames.Count) { throw 'Unexpected product artifact contents.' }
        $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $total=0L
        foreach ($entry in $archive.Entries) {
            $total+=$entry.Length
            if ($entry.FullName -cnotin $AllowedNames -or !$seen.Add($entry.FullName) -or
                $entry.Length -le 0 -or $total -gt 4GB) { throw 'Unsafe, duplicate or excessive artifact entry.' }
        }
        New-Item -ItemType Directory -Path $OutputPath | Out-Null
        foreach ($entry in $archive.Entries) {
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $OutputPath $entry.FullName), $false)
        }
    } finally { $archive.Dispose() }
}
function Receive-ProductArtifact([string]$Product, $Plan, [string]$PlanCommit, [string]$RunId, [string]$OutputPath) {
    $artifact=Resolve-ProductArtifact $Product $Plan $RunId
    $repo=$DistributionProducts[$Product].repository
    $zip=Join-Path $env:RUNNER_TEMP ("distribution-"+[Guid]::NewGuid().ToString('N')+'.zip')
    try {
        # Copy binary stdout directly: no shell interpolation or text re-encoding of ZIP bytes.
        $start=[Diagnostics.ProcessStartInfo]::new('gh')
        $start.UseShellExecute=$false; $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
        $start.ArgumentList.Add('api'); $start.ArgumentList.Add("repos/$repo/actions/artifacts/$($artifact.id)/zip")
        $process=[Diagnostics.Process]::Start($start)
        try {
            $errors=$process.StandardError.ReadToEndAsync()
            $file=[IO.File]::Create($zip)
            try { $process.StandardOutput.BaseStream.CopyTo($file) } finally { $file.Dispose() }
            $process.WaitForExit(); $null=$errors.GetAwaiter().GetResult()
            if ($process.ExitCode -ne 0) { throw 'Private artifact download failed.' }
        } finally { $process.Dispose() }
        if ('sha256:'+(Get-DistributionHash $zip) -cne $artifact.digest) { throw 'GitHub artifact archive digest mismatch.' }
        $names=if ($Product -ceq 'web') {
            @((Get-DistributionAssetNames $Plan) | Where-Object { ! $_.EndsWith('.apk') }) + @('web-provenance.json',"MagicTheSortering-$($Plan.web.version)-release.json", "MagicTheSortering-$($Plan.web.version)-SHA256SUMS.txt")
        } else { @("MagicTheSortering-Companion-$($Plan.companion.version).apk",'companion-provenance.json') }
        Expand-ProductArtifact $zip $OutputPath $names
        $provenance=Get-Content (Join-Path $OutputPath "$Product-provenance.json") -Raw | ConvertFrom-Json
        if ($provenance.planCommit -cne $PlanCommit -or [string]$provenance.workflowRunId -cne $RunId -or
            $provenance.commit -cne $Plan.$Product.commit -or $provenance.sharedUI -cne $Plan.sharedUI.commit) {
            throw 'Downloaded product provenance does not match this immutable plan/run.'
        }
    } finally { if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip } }
}
