#!/usr/bin/env pwsh

param()

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    $GITHUB_REPO = "Zillowe/Hello"
    $BIN_NAME = "hello"

    function Write-Info($Message) {
        Write-Host "[INFO] $Message" -ForegroundColor Cyan
    }
    function Write-Warn($Message) {
        Write-Host "[WARN] $Message" -ForegroundColor Yellow
    }
    function Write-Error($Message) {
        Write-Host "[ERROR] $Message" -ForegroundColor Red
        throw $Message
    }
}

process {
    Write-Info "Fetching the latest release tag from GitHub API for '$GITHUB_REPO'..."
    try {
        $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/$GITHUB_REPO/releases/latest"
        $LATEST_TAG = $latestRelease.tag_name
        if (-not $LATEST_TAG) {
            Write-Error "Could not determine latest release tag. The API response may have changed."
        }
        Write-Info "Latest tag found: $LATEST_TAG"
    }
    catch {
        Write-Error "Failed to fetch release data from GitHub. Please check the repository path '$GITHUB_REPO' and your network connection."
    }

    $os = "windows"
    $arch = switch ($env:PROCESSOR_ARCHITECTURE) {
        "AMD64" { "amd64" }
        "ARM64" { "arm64" }
        Default { Write-Error "Unsupported processor architecture: $env:PROCESSOR_ARCHITECTURE" }
    }

    $INSTALL_DIR = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Programs\hello'
    $INSTALL_PATH = Join-Path -Path $INSTALL_DIR -ChildPath "$BIN_NAME.exe"

    $REPO_BASE_URL = "https://github.com/$GITHUB_REPO/releases/download/$LATEST_TAG"
    $TARGET_ARCHIVE = "$BIN_NAME-$os-$arch.zip"
    $DOWNLOAD_URL = "$REPO_BASE_URL/$TARGET_ARCHIVE"
    $CHECKSUM_URL = "$REPO_BASE_URL/checksums.txt"

    $TEMP_DIR = Join-Path -Path $env:TEMP -ChildPath ([System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
    $TEMP_ARCHIVE = Join-Path -Path $TEMP_DIR -ChildPath $TARGET_ARCHIVE
    $TEMP_CHECKSUMS = Join-Path -Path $TEMP_DIR -ChildPath "checksums.txt"

    Write-Info "Installing/Updating Hello for $os ($arch)..."
    Write-Info "Target: $INSTALL_PATH"

    if (-not (Test-Path -Path $INSTALL_DIR)) {
        Write-Info "Creating installation directory: $INSTALL_DIR"
        New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
    }

    Write-Info "Downloading Hello from: $DOWNLOAD_URL"
    try {
        Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $TEMP_ARCHIVE
        Write-Info "Download successful to $TEMP_ARCHIVE"
    }
    catch {
        Remove-Item -Path $TEMP_DIR -Recurse -Force
        Write-Error "Download failed. Please check the URL and your connection."
    }

    Write-Info "Verifying checksum..."
    try {
        Invoke-WebRequest -Uri $CHECKSUM_URL -OutFile $TEMP_CHECKSUMS
    }
    catch {
        Remove-Item -Path $TEMP_DIR -Recurse -Force
        Write-Error "Failed to download checksums file: $CHECKSUM_URL"
    }

    $expectedHash = (Get-Content $TEMP_CHECKSUMS | Select-String -Pattern $TARGET_ARCHIVE).Line.Split(' ')[0]
    if (-not $expectedHash) {
        Remove-Item -Path $TEMP_DIR -Recurse -Force
        Write-Error "Could not find checksum for '$TARGET_ARCHIVE' in the checksums file."
    }

    $actualHash = (Get-FileHash -Path $TEMP_ARCHIVE -Algorithm SHA256).Hash.ToLower()

    if ($actualHash -ne $expectedHash) {
        Remove-Item -Path $TEMP_DIR -Recurse -Force
        Write-Error "Checksum mismatch! The downloaded file may be corrupt or tampered with."
    }
    Write-Info "Checksum verified successfully."

    if (Test-Path -Path $INSTALL_PATH) {
        Write-Info "Removing existing binary at $INSTALL_PATH..."
        Remove-Item -Path $INSTALL_PATH -Force
    }

    Write-Info "Extracting binary..."
    try {
        Expand-Archive -Path $TEMP_ARCHIVE -DestinationPath $TEMP_DIR
        Write-Info "Extraction successful."
    }
    catch {
        Remove-Item -Path $TEMP_DIR -Recurse -Force
        Write-Error "Extraction failed. The archive may be corrupt."
    }

    $EXTRACTED_BINARY = Join-Path -Path $TEMP_DIR -ChildPath "$BIN_NAME.exe"
    if (-not (Test-Path -Path $EXTRACTED_BINARY)) {
        Remove-Item -Path $TEMP_DIR -Recurse -Force
        Write-Error "Could not find '$BIN_NAME.exe' in the extracted contents."
    }

    Write-Info "Moving binary to $INSTALL_PATH..."
    Move-Item -Path $EXTRACTED_BINARY -Destination $INSTALL_PATH

    Write-Info "Checking if '$INSTALL_DIR' is in PATH..."
    $currentUserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if ($currentUserPath -notlike "*$INSTALL_DIR*") {
        Write-Warn "'$INSTALL_DIR' is not found in your user PATH."
        Write-Info "Adding it to your user PATH environment variable..."
        $newPath = "$INSTALL_DIR;$currentUserPath"
        [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Info "Successfully updated PATH. Please restart your PowerShell session for the changes to take effect."
    } else {
        Write-Info "'$INSTALL_DIR' is already in your PATH."
    }
    Write-Host ""
    Write-Info "Hello ($TARGET_ARCHIVE) installed/updated successfully to: $INSTALL_PATH"
    Write-Info "Run 'hello --version' in a new terminal to verify."
}

end {
    if (Test-Path -Path $TEMP_DIR) {
        Remove-Item -Path $TEMP_DIR -Recurse -Force
    }
    Write-Info "Installation complete."
}
