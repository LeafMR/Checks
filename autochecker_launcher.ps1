
# autochecker_launcher.ps1
param(
  [string]$BundleUrl = "https://example.com/path/to/Checks.zip",
  [string]$ExpectedSha256 = "",
  [switch]$Ephemeral,
  [switch]$ForceReinstall
)
$ErrorActionPreference = "Stop"
$app = "autochecker"
$cacheRoot = Join-Path $env:LOCALAPPDATA "$app\cache"
New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null

function Get-Sha256([string]$Path) {
  (Get-FileHash -Algorithm SHA256 -Path $Path).Hash.ToLower()
}

$tmp = New-TemporaryFile
try {
  Invoke-WebRequest -Uri $BundleUrl -OutFile $tmp -UseBasicParsing | Out-Null
  $etag = ($_.Headers.ETag) -replace '"',''
} catch {
  Write-Error "Failed to download bundle: $_"
  exit 1
}

$digest = Get-Sha256 $tmp
if ($ExpectedSha256 -and ($digest.ToLower() -ne $ExpectedSha256.ToLower())) {
  Write-Error "SHA256 mismatch. Got $digest expected $ExpectedSha256"
  exit 2
}

$version = if ($etag) { $etag } else { $digest.Substring(0,12) }
$installDir = Join-Path $cacheRoot $version

if ((Test-Path $installDir) -and (-not $ForceReinstall)) {
  # reuse cache
} else {
  if (Test-Path $installDir) { Remove-Item -Recurse -Force $installDir }
  New-Item -ItemType Directory -Force -Path $installDir | Out-Null
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory($tmp, $installDir)
}

$candidates = @("run.ps1","run.bat","run.cmd","main.exe")
$subdirs = @("","dist","build","out")
$entry = $null
foreach ($sub in $subdirs) {
  $base = if ($sub) { Join-Path $installDir $sub } else { $installDir }
  foreach ($c in $candidates) {
    $p = Join-Path $base $c
    if (Test-Path $p) { $entry = $p; break }
  }
  if ($entry) { break }
}

if (-not $entry) {
  Write-Error "[autochecker] No Windows entrypoint found. Update candidates."
  exit 3
}

if ($entry.ToLower().EndsWith(".ps1")) {
  & powershell -ExecutionPolicy Bypass -File $entry @args
  $rc = $LASTEXITCODE
} elseif ($entry.ToLower().EndsWith(".bat") -or $entry.ToLower().EndsWith(".cmd")) {
  & $entry @args
  $rc = $LASTEXITCODE
} else {
  & $entry @args
  $rc = $LASTEXITCODE
}

if ($Ephemeral) { Remove-Item -Recurse -Force $installDir }
exit $rc
