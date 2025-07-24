#Requires -Version 5.1
<#
.SYNOPSIS
    Installs or updates the 'hello' command-line tool.
.DESCRIPTION
    This script downloads the latest release of 'hello' for the appropriate
    Windows architecture (amd64 or arm64), extracts the executable, and adds
    it to the user's PATH for easy access from the command line.
.NOTES
    Author: ZilloweZ
    Version: 1.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$githubRepo = "Zillowe/Hello"
$binName = "hello"
$installDir = "$env:USERPROFILE\.local\bin"
$commentLine = "# Hello PATH addition"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    exit 1
}

function Test-Command {
    param([string]$Command)
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        Write-Error "'$Command' command is required but not found. Please install it."
    }
}

Test-Command "curl"
Test-Command "Expand-Archive"

Write-Info "Fetching the latest release tag from GitHub API..."
try {
    $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/$githubRepo/releases/latest"
    $latestTag = $latestRelease.tag_name
}
catch {
    Write-Error "Could not fetch the latest release tag. Please check the repository path and network."
}

if (-not $latestTag) {
    Write-Error "Could not fetch the latest release tag. Please check the repository path and network."
}
Write-Info "Latest tag found: $latestTag"

$os = "windows"
$arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { "amd64" }
    "ARM64" { "arm64" }
    default { Write-Error "Unsupported Architecture: $env:PROCESSOR_ARCHITECTURE" }
}

$repoBaseUrl = "https://github.com/$githubRepo/releases/download/$latestTag"
$targetArchive = "hello-$os-$arch.zip"
$downloadUrl = "$repoBaseUrl/$targetArchive"
$installPath = Join-Path -Path $installDir -ChildPath "$binName.exe"

$tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString()))
$tempArchive = Join-Path -Path $tempDir -ChildPath $targetArchive

Write-Info "Installing/Updating Hello for $os ($arch)..."
Write-Info "Target: $installPath"

if (-not (Test-Path -Path $installDir)) {
    Write-Info "Creating installation directory: $installDir"
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

Write-Info "Downloading Hello from: $downloadUrl"
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempArchive -UseBasicParsing
    Write-Info "Download successful to $tempArchive"
}
catch {
    Remove-Item -Path $tempArchive -Force -ErrorAction SilentlyContinue
    Write-Error "Download failed. Please check the URL and your connection."
}

if (Test-Path -Path $installPath) {
    Write-Info "Removing existing binary at $installPath..."
    Remove-Item -Path $installPath -Force -ErrorAction SilentlyContinue
}

Write-Info "Extracting binary..."
try {
    Expand-Archive -Path $tempArchive -DestinationPath $tempDir -Force
    Write-Info "Extraction successful."
}
catch {
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Error "Extraction failed."
}

$extractedBinary = Join-Path -Path $tempDir -ChildPath "hello.exe"
if (-not (Test-Path -Path $extractedBinary)) {
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Error "Could not find 'hello.exe' in the extracted contents."
}

Write-Info "Moving binary to $installPath..."
Move-Item -Path $extractedBinary -Destination $installPath

Remove-Item -Path $tempDir -Recurse -Force

Write-Info "Checking if '$installDir' is in PATH..."
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$installDir*") {
    Write-Warn "'$installDir' is not found in your current user PATH."
    Write-Info "Adding it to your user PATH..."
    $newPath = "$userPath;$installDir"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Info "Successfully updated user PATH. Please restart your shell for the changes to take effect."
}
else {
    Write-Info "'$installDir' is already in your PATH."
}

Write-Host ""
Write-Info "Hello ($targetArchive) installed/updated successfully to: $installPath"
