param(
    [Parameter(Mandatory, Position = 0)][string]$Name,
    [Parameter(Mandatory, Position = 1)][string]$Executable,
    [Parameter(Position = 2, ValueFromRemainingArguments)][string[]]$CommandArguments
)

$ErrorActionPreference = 'Stop'
# Native failures are handled explicitly after capturing their complete output.
$PSNativeCommandUseErrorActionPreference = $false
$directory = Join-Path $env:BUILD_DIR 'diagnostics'
New-Item -ItemType Directory -Force $directory | Out-Null
$timer = [Diagnostics.Stopwatch]::StartNew()
& $Executable @CommandArguments 2>&1 | Tee-Object -FilePath (Join-Path $directory "$Name.log") | Out-Host
$code = $LASTEXITCODE
$timer.Stop()
$line = "| $Name | $code | $([math]::Round($timer.Elapsed.TotalSeconds, 1)) |"
if ($env:GITHUB_STEP_SUMMARY) { Add-Content $env:GITHUB_STEP_SUMMARY $line }
if ($code -ne 0) { throw "Stage '$Name' failed with exit code $code. See diagnostics/$Name.log." }
