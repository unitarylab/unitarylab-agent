#requires -Version 5.1

<#
.SYNOPSIS
  UnitaryLab CLI Windows Installation Script

.DESCRIPTION
  Downloads the UnitaryLab CLI Windows executable from GitHub Releases,
  validates SHA256 checksum, installs it into a user-level bin directory,
  and optionally adds the directory to the user's PATH.

.USAGE
  irm https://raw.githubusercontent.com/unitarylab/unitarylab-agent/main/install.ps1 | iex

.OPTIONAL
  $env:VERSION="0.1.5"; irm https://raw.githubusercontent.com/unitarylab/unitarylab-agent/main/install.ps1 | iex
  $env:VERSION="latest"; irm https://raw.githubusercontent.com/unitarylab/unitarylab-agent/main/install.ps1 | iex
  $env:INSTALL_DIR="$HOME\.unitarylab\bin"; irm https://raw.githubusercontent.com/unitarylab/unitarylab-agent/main/install.ps1 | iex

.DEFAULT INSTALL PATH
  User install:
    $env:LOCALAPPDATA\Programs\UnitaryLab\bin\unitarylab.exe

  Admin install:
    $env:ProgramFiles\UnitaryLab\bin\unitarylab.exe
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ------------------------------------------------------------------------------
# Basic configuration
# ------------------------------------------------------------------------------

$Repo = "unitarylab/unitarylab-agent"
$CliName = "unitarylab"
$ExeName = "unitarylab.exe"

$Version = $env:VERSION
if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = "latest"
}

# Current Windows release asset
$Platform = "windows"
$Arch = "x86_64"

$BinaryName = "unitarylab-windows-x86_64.exe"
$ChecksumName = "SHA256SUMS-windows-x86_64.txt"

# ------------------------------------------------------------------------------
# UI helpers
# ------------------------------------------------------------------------------

function Write-Info {
    param([string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "Warning: $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "Error: $Message" -ForegroundColor Red
}

function Fail {
    param([string]$Message)
    Write-Fail $Message
    exit 1
}

# ------------------------------------------------------------------------------
# Architecture validation
# ------------------------------------------------------------------------------

function Get-WindowsArchitecture {
    $arch = $env:PROCESSOR_ARCHITECTURE

    if ($arch -eq "AMD64") {
        return "x86_64"
    }

    if ($arch -eq "ARM64") {
        return "arm64"
    }

    return $arch
}

$DetectedArch = Get-WindowsArchitecture

if ($DetectedArch -ne "x86_64") {
    Fail "Unsupported Windows architecture: $DetectedArch. Current release only provides unitarylab-windows-x86_64.exe."
}

# ------------------------------------------------------------------------------
# Resolve release URLs
# ------------------------------------------------------------------------------

if ($Version -eq "latest") {
    $DownloadUrl = "https://github.com/$Repo/releases/latest/download/$BinaryName"
    $ChecksumUrl = "https://github.com/$Repo/releases/latest/download/$ChecksumName"
} else {
    if (-not $Version.StartsWith("v")) {
        $Version = "v$Version"
    }

    $DownloadUrl = "https://github.com/$Repo/releases/download/$Version/$BinaryName"
    $ChecksumUrl = "https://github.com/$Repo/releases/download/$Version/$ChecksumName"
}

# ------------------------------------------------------------------------------
# Resolve install directory
# ------------------------------------------------------------------------------

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$IsAdmin = Test-IsAdmin

if (-not [string]::IsNullOrWhiteSpace($env:INSTALL_DIR)) {
    $InstallDir = $env:INSTALL_DIR
} elseif (-not [string]::IsNullOrWhiteSpace($env:PREFIX)) {
    $InstallDir = Join-Path $env:PREFIX "bin"
} elseif ($IsAdmin) {
    $InstallDir = Join-Path $env:ProgramFiles "UnitaryLab\bin"
} else {
    $InstallDir = Join-Path $env:LOCALAPPDATA "Programs\UnitaryLab\bin"
}

$InstallPath = Join-Path $InstallDir $ExeName

# ------------------------------------------------------------------------------
# Temporary directory
# ------------------------------------------------------------------------------

$TempRoot = [System.IO.Path]::GetTempPath()
$TempDir = Join-Path $TempRoot ("unitarylab-install-" + [System.Guid]::NewGuid().ToString("N"))

New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

$TempBinary = Join-Path $TempDir $BinaryName
$TempChecksum = Join-Path $TempDir $ChecksumName

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------

function Cleanup {
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ------------------------------------------------------------------------------
# Download helper
# ------------------------------------------------------------------------------

function Download-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$Output
    )

    $headers = @{}

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
        $headers["Authorization"] = "token $env:GITHUB_TOKEN"
    }

    try {
        Invoke-WebRequest `
            -Uri $Url `
            -OutFile $Output `
            -UseBasicParsing `
            -Headers $headers
    } catch {
        throw "Failed to download: $Url`n$($_.Exception.Message)"
    }
}

# ------------------------------------------------------------------------------
# Checksum validation
# ------------------------------------------------------------------------------

function Get-ExpectedSha256 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ChecksumFile,

        [Parameter(Mandatory = $true)]
        [string]$TargetName
    )

    $lines = Get-Content $ChecksumFile

    foreach ($line in $lines) {
        if ($line -match [regex]::Escape($TargetName)) {
            $parts = $line.Trim() -split "\s+"
            if ($parts.Length -ge 1) {
                return $parts[0].ToLowerInvariant()
            }
        }
    }

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -gt 0) {
            $parts = $trimmed -split "\s+"
            if ($parts.Length -ge 1) {
                return $parts[0].ToLowerInvariant()
            }
        }
    }

    return $null
}

function Validate-Sha256 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$ChecksumFile,

        [Parameter(Mandatory = $true)]
        [string]$TargetName
    )

    $expected = Get-ExpectedSha256 -ChecksumFile $ChecksumFile -TargetName $TargetName

    if ([string]::IsNullOrWhiteSpace($expected)) {
        Fail "Could not parse checksum file: $ChecksumFile"
    }

    $actual = (Get-FileHash -Algorithm SHA256 -Path $FilePath).Hash.ToLowerInvariant()

    if ($actual -ne $expected) {
        Write-Fail "Checksum validation failed."
        Write-Host "Expected: $expected"
        Write-Host "Actual:   $actual"
        exit 1
    }

    Write-Success "Checksum validated"
}

# ------------------------------------------------------------------------------
# PATH handling
# ------------------------------------------------------------------------------

function Test-PathContains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if ([string]::IsNullOrWhiteSpace($currentPath)) {
        return $false
    }

    $parts = $currentPath -split ";"

    foreach ($part in $parts) {
        if ($part.TrimEnd("\") -ieq $Directory.TrimEnd("\")) {
            return $true
        }
    }

    return $false
}

function Add-ToUserPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if ([string]::IsNullOrWhiteSpace($currentPath)) {
        $newPath = $Directory
    } else {
        $newPath = "$currentPath;$Directory"
    }

    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")

    $env:Path = "$env:Path;$Directory"
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

try {
    Write-Info "Installing UnitaryLab CLI..."

    Write-Host "Platform: $Platform"
    Write-Host "Architecture: $Arch"
    Write-Host "Version: $Version"
    Write-Host "Binary: $BinaryName"
    Write-Host "Downloading from: $DownloadUrl"

    Write-Info "Downloading binary..."
    Download-File -Url $DownloadUrl -Output $TempBinary

    if (-not (Test-Path $TempBinary)) {
        Fail "Downloaded binary was not found."
    }

    if ((Get-Item $TempBinary).Length -eq 0) {
        Fail "Downloaded binary is empty."
    }

    Write-Info "Downloading checksum..."
    $ChecksumAvailable = $false

    try {
        Download-File -Url $ChecksumUrl -Output $TempChecksum

        if ((Test-Path $TempChecksum) -and ((Get-Item $TempChecksum).Length -gt 0)) {
            $ChecksumAvailable = $true
        }
    } catch {
        Write-Warn "Checksum file is not available. Skipping checksum validation."
    }

    if ($ChecksumAvailable) {
        Validate-Sha256 `
            -FilePath $TempBinary `
            -ChecksumFile $TempChecksum `
            -TargetName $BinaryName
    }

    Write-Info "Installing to: $InstallPath"

    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    if (Test-Path $InstallPath) {
        Write-Warn "Replacing existing binary at $InstallPath"
    }

    $TempInstallPath = Join-Path $InstallDir ".$CliName.tmp.$PID.exe"

    Copy-Item -Path $TempBinary -Destination $TempInstallPath -Force
    Move-Item -Path $TempInstallPath -Destination $InstallPath -Force

    if (-not (Test-Path $InstallPath)) {
        Fail "Installation failed. Binary not found at $InstallPath"
    }

    Write-Success "UnitaryLab CLI installed to $InstallPath"

    # Add install directory to user PATH if needed.
    if (Test-PathContains -Directory $InstallDir) {
        Write-Success "$InstallDir is already in your user PATH"
    } else {
        Write-Host ""
        Write-Warn "$InstallDir is not in your user PATH"

        $answer = Read-Host "Would you like to add it to your user PATH? [y/N]"

        if ($answer -match "^(y|Y|yes|YES)$") {
            Add-ToUserPath -Directory $InstallDir
            Write-Success "Added $InstallDir to your user PATH"
            Write-Host "Restart PowerShell or open a new terminal window to use it globally."
        } else {
            Write-Host "PATH was not modified."
            Write-Host ""
            Write-Host "For this session only, you can run:"
            Write-Host "  `$env:Path = `"$InstallDir;`$env:Path`""
        }
    }

    Write-Host ""
    Write-Success "Installation complete."
    Write-Host "Run:"
    Write-Host "  unitarylab --help"

} catch {
    Write-Fail $_.Exception.Message
    exit 1
} finally {
    Cleanup
}