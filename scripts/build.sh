#!/bin/sh
#
# build.sh - Build a resume PDF into out/ with the portable TinyTeX.
#
# Usage:
#   scripts/build.sh [file.tex]
#
# Without an argument, the script builds private/main.tex if that file
# exists, otherwise example/resume.tex.
#
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/out"


fail() {
    echo "error: $*" >&2
    exit 1
}


# Print the TinyTeX folder with the programs, for example
# .tools/TinyTeX/bin/x86_64-linux. Its name depends on the platform.
find_tinytex_bin() {
    for bin_dir in "${REPO_ROOT}"/.tools/TinyTeX/bin/*/; do
        if [ -x "${bin_dir}pdflatex" ]; then
            echo "${bin_dir%/}"
            return
        fi
    done

    fail "TinyTeX is not installed. Run scripts/setup.sh first."
}


# Print the file to build: the argument if there is one, else the default.
choose_source() {
    if [ $# -gt 0 ]; then
        echo "$1"
    elif [ -f "${REPO_ROOT}/private/main.tex" ]; then
        echo "${REPO_ROOT}/private/main.tex"
    else
        echo "${REPO_ROOT}/example/resume.tex"
    fi
}


main() {
    tinytex_bin="$(find_tinytex_bin)"
    source_file="$(choose_source "$@")"

    if [ ! -f "${source_file}" ]; then
        fail "file not found: ${source_file}"
    fi

    source_dir="$(cd "$(dirname "${source_file}")" && pwd)"
    source_name="$(basename "${source_file}")"

    # These changes apply only to this script and the programs it starts.
    # TEXINPUTS lets TeX find resume.sty at the repository root.
    # The trailing ":" keeps TeX's default search path.
    PATH="${tinytex_bin}:${PATH}"
    TEXINPUTS="${REPO_ROOT}:${TEXINPUTS:-}"
    export PATH TEXINPUTS

    # TeX resolves \input paths from the working directory.
    cd "${source_dir}"

    exec latexmk \
        -pdf \
        -synctex=1 \
        -interaction=nonstopmode \
        -halt-on-error \
        -outdir="${OUTPUT_DIR}" \
        "${source_name}"
}


main "$@"
