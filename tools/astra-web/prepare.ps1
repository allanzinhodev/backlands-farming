param([string]$SourceDirectory = "")
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $SourceDirectory) { $SourceDirectory = Join-Path $repository '_study/AstraClient' }
$revision = '80c59ec7aab584b970b8a9d98cd8282e3b5fe136'
if (-not (Test-Path -LiteralPath (Join-Path $SourceDirectory '.git'))) {
    & git clone --no-checkout https://github.com/Mateuzkl/AstraClient $SourceDirectory
    if ($LASTEXITCODE -ne 0) { throw 'Could not clone AstraClient.' }
    & git -C $SourceDirectory checkout $revision
    if ($LASTEXITCODE -ne 0) { throw 'Could not select the pinned AstraClient revision.' }
}
$current = (& git -C $SourceDirectory rev-parse HEAD).Trim()
if ($current -ne $revision) { throw "Expected AstraClient $revision; found $current. Use a separate study checkout." }
$patchFile = Join-Path $PSScriptRoot 'patches/backlands-16px.patch'
$previousErrorPreference = $ErrorActionPreference
try {
    # A clean checkout is expected to fail this probe. PowerShell 5.1 otherwise
    # promotes redirected native stderr into a terminating NativeCommandError.
    $ErrorActionPreference = 'Continue'
    & git -C $SourceDirectory apply --reverse --check $patchFile 2>$null
    $patchAlreadyApplied = $LASTEXITCODE -eq 0
} finally { $ErrorActionPreference = $previousErrorPreference }
if (-not $patchAlreadyApplied) {
    & git -C $SourceDirectory apply --check $patchFile
    if ($LASTEXITCODE -ne 0) { throw 'The Backlands patch conflicts with local changes; nothing was overwritten.' }
    & git -C $SourceDirectory apply $patchFile
    if ($LASTEXITCODE -ne 0) { throw 'Could not apply the Backlands patch.' }
}
Write-Host "AstraClient prepared at $SourceDirectory (16px, protocol 860)."
