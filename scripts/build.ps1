#
# build.ps1 - Build a resume PDF into out\ with the portable TinyTeX.
#
# Usage:
#   scripts\build.ps1 [file.tex]
#
# Without an argument, the script builds private\main.tex if that file
# exists, otherwise example\resume.tex.
#
param(
    [string]$SourceFile
)
$ErrorActionPreference = 'Stop'

$RepoRoot   = Split-Path $PSScriptRoot -Parent
$OutputDir  = Join-Path $RepoRoot 'out'
$TinyTeXBin = Join-Path $RepoRoot '.tools\TinyTeX\bin\windows'


# Return the file to build: the argument if there is one, else the default.
function Select-Source {
    if ($SourceFile) {
        return $SourceFile
    }

    $privateResume = Join-Path $RepoRoot 'private\main.tex'
    if (Test-Path $privateResume) {
        return $privateResume
    }

    return Join-Path $RepoRoot 'example\resume.tex'
}


function Main {
    if (-not (Test-Path (Join-Path $TinyTeXBin 'pdflatex.exe'))) {
        throw 'TinyTeX is not installed. Run scripts\setup.ps1 first.'
    }

    $source = Select-Source
    if (-not (Test-Path $source)) {
        throw "file not found: $source"
    }
    $source = (Resolve-Path $source).Path

    # These changes apply only to this script and the programs it starts.
    # TEXINPUTS lets TeX find resume.sty at the repository root.
    # The trailing ";" keeps TeX's default search path.
    $env:PATH      = "$TinyTeXBin;$env:PATH"
    $env:TEXINPUTS = "$RepoRoot;$env:TEXINPUTS"

    # TeX resolves \input paths from the working directory.
    Push-Location (Split-Path $source -Parent)
    try {
        latexmk `
            -pdf `
            -synctex=1 `
            -interaction=nonstopmode `
            -halt-on-error `
            "-outdir=$OutputDir" `
            (Split-Path $source -Leaf)
        $latexmkExitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    exit $latexmkExitCode
}


Main
