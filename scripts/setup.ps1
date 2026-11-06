#
# setup.ps1 - Install a portable TinyTeX into .tools\TinyTeX.
#
# The TinyTeX version is pinned, and the download is checked against a known
# SHA-256 checksum. Nothing outside the repository is changed.
# To uninstall, delete the .tools\ folder.
#
$ErrorActionPreference = 'Stop'

$TinyTeXVersion = '2026.11'
$ReleaseUrl     = "https://github.com/rstudio/tinytex-releases/releases/download/v$TinyTeXVersion"

# The checksum comes from the GitHub release page of the archive.
$ArchiveName   = "TinyTeX-windows-v$TinyTeXVersion.exe"
$ArchiveSha256 = '6135c353af96628d81da93d7f508bbd726f7f7105427b48b01622dbd32dc7533'

$RepoRoot    = Split-Path $PSScriptRoot -Parent
$ToolsDir    = Join-Path $RepoRoot '.tools'
$InstallDir  = Join-Path $ToolsDir 'TinyTeX'
$DownloadDir = Join-Path $ToolsDir 'download'
$ArchivePath = Join-Path $DownloadDir $ArchiveName


function Invoke-Download {
    Write-Host "Downloading $ArchiveName"
    curl.exe --fail --location --retry 3 --output $ArchivePath "$ReleaseUrl/$ArchiveName"
    if ($LASTEXITCODE -ne 0) {
        throw "download failed: $ArchiveName"
    }
}


function Assert-Checksum {
    # -ne on strings ignores case, so the upper-case hash from Get-FileHash matches.
    $actualSha256 = (Get-FileHash $ArchivePath -Algorithm SHA256).Hash
    if ($actualSha256 -ne $ArchiveSha256) {
        throw "checksum mismatch for $ArchiveName"
    }
}


# The archive is a self-extracting .exe. The -y flag unpacks a "TinyTeX"
# folder into the working directory without questions.
function Expand-TinyTeX {
    Write-Host "Extracting into $InstallDir"
    $extractor = Start-Process -FilePath $ArchivePath -ArgumentList '-y' `
        -WorkingDirectory $DownloadDir -Wait -PassThru -NoNewWindow
    if ($extractor.ExitCode -ne 0) {
        throw "extraction failed: $ArchiveName"
    }

    Move-Item (Join-Path $DownloadDir 'TinyTeX') $InstallDir
}


function Main {
    if (Test-Path $InstallDir) {
        Write-Host "TinyTeX is already installed in $InstallDir"
        return
    }

    Remove-Item $DownloadDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory $DownloadDir | Out-Null

    try {
        Invoke-Download
        Assert-Checksum
        Expand-TinyTeX
    }
    finally {
        Remove-Item $DownloadDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host 'Done. To build the resume, run: scripts\build.ps1'
}


Main
