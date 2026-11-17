param([Parameter(Mandatory)][string]$ApkPath,[Parameter(Mandatory)][string]$PlanPath,
      [Parameter(Mandatory)][string]$AndroidSdkDirectory)
. (Join-Path $PSScriptRoot 'Distribution.Common.ps1')
. (Join-Path $PSScriptRoot 'Android-Signing.ps1')
$p=Read-DistributionPlan $PlanPath
$tools=Join-Path $AndroidSdkDirectory 'build-tools/36.0.0'
$signature=(& (Join-Path $tools 'apksigner.bat') verify --verbose --print-certs $ApkPath 2>&1) -join [Environment]::NewLine
$certificate=Get-VerifiedApkSigningCertificate -Output $signature -ExitCode $LASTEXITCODE
if ($certificate -cne '320b0ac4f79d1e60811c27e7f56e4f9ee8308264ad173358d14c91a903744836') { throw 'Unexpected official APK signing certificate.' }
$badging=(& (Join-Path $tools 'aapt.exe') dump badging $ApkPath) -join [Environment]::NewLine
$identity="package: name='com.newderiverius.magicthe_sortering.companion' versionCode='$($p.companion.androidVersionCode)' versionName='$($p.companion.version)'"
if ($LASTEXITCODE -ne 0 -or !$badging.Contains($identity)) { throw 'APK package/version differs from the official product plan.' }
$provenance=Get-Content -LiteralPath (Join-Path (Split-Path $ApkPath -Parent) 'companion-provenance.json') -Raw | ConvertFrom-Json
if ($provenance.signingCertificateSha256 -cne $certificate -or $provenance.apkSha256 -cne (Get-DistributionHash $ApkPath)) {
    throw 'Verified APK certificate/hash differs from producer provenance.'
}
Write-Output "Official APK signature, package and version verified: $certificate"
