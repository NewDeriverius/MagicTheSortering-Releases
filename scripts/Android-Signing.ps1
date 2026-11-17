function Get-VerifiedApkSigningCertificate {
    param([string]$Output,[int]$ExitCode)
    if ($ExitCode -ne 0) { throw "apksigner verification failed ($ExitCode)." }
    if ($Output -notmatch '(?m)^Number of signers:\s*1\s*\r?$') { throw 'Expected exactly one APK signer.' }
    if ($Output -match 'CN=Android Debug') { throw 'A debug signing identity cannot be distributed.' }
    # Build Tools 36: Signer #1 certificate ...; 37: V3.0 Signer: certificate ...
    $pattern='(?m)^(?:Signer #1|V\d+(?:\.\d+)? Signer:) certificate SHA-256 digest: ([a-fA-F0-9]{64})\s*\r?$'
    $hashes=@([regex]::Matches($Output,$pattern) | ForEach-Object { $_.Groups[1].Value.ToLowerInvariant() } | Sort-Object -Unique)
    if ($hashes.Count -ne 1) { throw 'Expected one unambiguous signing certificate SHA-256 digest.' }
    return $hashes[0]
}
