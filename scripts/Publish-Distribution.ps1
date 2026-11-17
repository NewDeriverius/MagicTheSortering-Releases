param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$PlanPath,
    [Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{40}$')][string]$PlanCommit,
    [switch]$Publish
)
. (Join-Path $PSScriptRoot 'Distribution.Common.ps1')
& (Join-Path $PSScriptRoot 'Test-Distribution.ps1') -Path $Path -PlanPath $PlanPath -PlanCommit $PlanCommit
if(-not $Publish){Write-Output 'Dry-run: no GitHub release/tag writes.';return}
$p=Read-DistributionPlan $PlanPath
$repository='NewDeriverius/MagicTheSortering-Releases'
$tag="v$($p.distributionVersion)"
function Invoke-Gh([string[]]$Arguments){
    $result=& gh @Arguments
    if($LASTEXITCODE -ne 0){throw "GitHub command failed: $($Arguments[0])"}
    return $result
}
function Get-ReleaseTagCommit {
    # A draft can name a tag that GitHub has not created yet. GraphQL returns
    # null for that ref without treating an authentication/network error as absence.
    $query='query($owner:String!,$name:String!,$ref:String!){repository(owner:$owner,name:$name){ref(qualifiedName:$ref){target{oid}}}}'
    $reference=Invoke-Gh @('api','graphql','-f',"query=$query",'-F','owner=NewDeriverius','-F','name=MagicTheSortering-Releases','-F',"ref=refs/tags/$tag",'--jq','.data.repository.ref.target.oid // empty')
    if(-not $reference){return $null}
    # Resolve annotated tags as well as lightweight refs to their commit.
    return Invoke-Gh @('api',"repos/$repository/commits/$tag",'--jq','.sha')
}
$visibility=Invoke-Gh @('repo','view',$repository,'--json','visibility','--jq','.visibility')
if($visibility -cne 'PUBLIC'){throw 'Distribution destination must be the fixed public repository.'}
$files=@(Get-ChildItem -LiteralPath $Path -File | Sort-Object Name)
# No --clobber: an existing published distribution is immutable.
$json=& gh release view $tag --repo $repository --json isDraft,assets,body,targetCommitish 2>$null
$exists=$LASTEXITCODE -eq 0
if(-not $exists){
    $arguments=@('release','create',$tag,'--repo',$repository,'--target',$PlanCommit,'--draft','--title',"Magic The Sortering $($p.distributionVersion)",'--notes-file',(Join-Path $Path 'RELEASE-NOTES.md'))
    if($p.distributionVersion.Contains('-')){$arguments+='--prerelease'}
    Invoke-Gh ($arguments+@($files|ForEach-Object FullName))|Out-Null
    $json=Invoke-Gh @('release','view',$tag,'--repo',$repository,'--json','isDraft,assets,body,targetCommitish')
}
$release=$json|ConvertFrom-Json
$target=Get-ReleaseTagCommit
if($release.isDraft -and $release.targetCommitish -cne $PlanCommit){throw 'Existing draft targets another or mutable plan revision.'}
if($target -and $target -cne $PlanCommit){throw 'Existing release tag points to another plan commit.'}
if(-not $release.isDraft -and -not $target){throw 'Published release tag is missing; manual investigation required.'}
$notes=[IO.File]::ReadAllText((Resolve-Path -LiteralPath (Join-Path $Path 'RELEASE-NOTES.md'))).TrimEnd()
if($release.body.TrimEnd() -cne $notes){throw 'Existing release notes differ; refusing replacement.'}
$names=@($files.Name)
if(@($release.assets | Where-Object {$_.name -cnotin $names}).Count){throw 'Existing release has unexpected assets.'}
$missing=@($files | Where-Object {$_.Name -cnotin @($release.assets | ForEach-Object name)})
if(-not $release.isDraft -and $missing.Count){throw 'Published distribution is incomplete; manual investigation required.'}
$temp=Join-Path ([IO.Path]::GetTempPath()) ('mts-release-verify-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp|Out-Null
try {
    foreach($asset in $release.assets){
        $local=Join-Path $Path $asset.name
        if((Get-Item -LiteralPath $local).Length -ne $asset.size){throw 'Existing asset size differs.'}
        Invoke-Gh @('release','download',$tag,'--repo',$repository,'--pattern',$asset.name,'--dir',$temp)|Out-Null
        if((Get-DistributionHash (Join-Path $temp $asset.name)) -cne (Get-DistributionHash $local)){throw 'Existing asset content differs; refusing overwrite.'}
    }
    foreach($file in $missing){
        Invoke-Gh @('release','upload',$tag,$file.FullName,'--repo',$repository)|Out-Null
        Invoke-Gh @('release','download',$tag,'--repo',$repository,'--pattern',$file.Name,'--dir',$temp)|Out-Null
        if((Get-DistributionHash (Join-Path $temp $file.Name)) -cne (Get-DistributionHash $file.FullName)){throw 'Uploaded asset checksum mismatch.'}
    }
    $final=(Invoke-Gh @('release','view',$tag,'--repo',$repository,'--json','assets'))|ConvertFrom-Json
    if(@($final.assets).Count -ne $files.Count){throw 'Remote release is incomplete.'}
    # Only after every asset has been downloaded and verified may the public tag
    # be created. Never move an existing ref; a conflicting target is a hard error.
    $target=Get-ReleaseTagCommit
    if(-not $target){
        Invoke-Gh @('api','--method','POST',"repos/$repository/git/refs",'-f',"ref=refs/tags/$tag",'-f',"sha=$PlanCommit")|Out-Null
        $target=Get-ReleaseTagCommit
    }
    if($target -cne $PlanCommit){throw 'Release tag differs from the verified plan.'}
    if($release.isDraft){
        Invoke-Gh @('release','edit',$tag,'--repo',$repository,'--draft=false')|Out-Null
    } else {Write-Output 'Identical distribution already published: no changes.'}
    if((Get-ReleaseTagCommit) -cne $PlanCommit){throw 'Published tag verification failed.'}
} finally {
    $resolved=[IO.Path]::GetFullPath($temp)
    $parent=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
    if(-not $resolved.StartsWith($parent,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($resolved) -notmatch '^mts-release-verify-[a-f0-9]{32}$'){throw 'Unsafe cleanup path.'}
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
