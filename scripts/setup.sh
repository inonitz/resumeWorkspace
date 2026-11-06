#!/bin/sh
#
# setup.sh - Install a portable TinyTeX into .tools/TinyTeX.
#
# The TinyTeX version is pinned, and the download is checked against a known
# SHA-256 checksum. Nothing outside the repository is changed.
# To uninstall, delete the .tools/ folder.
#
set -eu

TINYTEX_VERSION="2026.11"
RELEASE_URL="https://github.com/rstudio/tinytex-releases/releases/download/v${TINYTEX_VERSION}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="${REPO_ROOT}/.tools"
INSTALL_DIR="${TOOLS_DIR}/TinyTeX"
DOWNLOAD_DIR="${TOOLS_DIR}/download"


fail() {
    echo "error: $*" >&2
    exit 1
}


# Set ARCHIVE_NAME and ARCHIVE_SHA256 for this operating system and CPU.
# The checksums come from the GitHub release page of each archive.
select_archive() {
    platform="$(uname -s)-$(uname -m)"

    case "${platform}" in
        Linux-x86_64)
            ARCHIVE_NAME="TinyTeX-linux-x86_64-v${TINYTEX_VERSION}.tar.xz"
            ARCHIVE_SHA256="50e68059058db770a28bcca44d5a323cb57fc10d470017c858404aafeaac9dd7"
            ;;
        Linux-aarch64 | Linux-arm64)
            ARCHIVE_NAME="TinyTeX-linux-arm64-v${TINYTEX_VERSION}.tar.xz"
            ARCHIVE_SHA256="a493b548ba82aafd715f297397de959bc8131c16a9be9e4b90fa6454e5d57fb1"
            ;;
        Darwin-*)
            ARCHIVE_NAME="TinyTeX-darwin-v${TINYTEX_VERSION}.tar.xz"
            ARCHIVE_SHA256="a54a3a16aca1717580b1cc0e4965791487c0650a450d1502dda457dd68e41962"
            ;;
        *)
            fail "unsupported platform: ${platform}"
            ;;
    esac
}


# Print the SHA-256 checksum of a file.
# Linux provides sha256sum; macOS provides shasum.
sha256_of() {
    if command -v sha256sum > /dev/null 2>&1; then
        sha256sum "$1" | cut -d ' ' -f 1
    else
        shasum -a 256 "$1" | cut -d ' ' -f 1
    fi
}


download_archive() {
    echo "Downloading ${ARCHIVE_NAME}"
    curl --fail --location --retry 3 \
        --output "${DOWNLOAD_DIR}/${ARCHIVE_NAME}" \
        "${RELEASE_URL}/${ARCHIVE_NAME}"
}


verify_archive() {
    actual_sha256="$(sha256_of "${DOWNLOAD_DIR}/${ARCHIVE_NAME}")"

    if [ "${actual_sha256}" != "${ARCHIVE_SHA256}" ]; then
        fail "checksum mismatch for ${ARCHIVE_NAME}"
    fi
}


# The top folder in the archive is ".TinyTeX" on Linux and "TinyTeX" on macOS.
extract_archive() {
    echo "Extracting into ${INSTALL_DIR}"
    tar -xf "${DOWNLOAD_DIR}/${ARCHIVE_NAME}" -C "${DOWNLOAD_DIR}"

    for top_folder in "${DOWNLOAD_DIR}/.TinyTeX" "${DOWNLOAD_DIR}/TinyTeX"; do
        if [ -d "${top_folder}" ]; then
            mv "${top_folder}" "${INSTALL_DIR}"
            return
        fi
    done

    fail "unexpected folder layout in ${ARCHIVE_NAME}"
}


main() {
    if [ -d "${INSTALL_DIR}" ]; then
        echo "TinyTeX is already installed in ${INSTALL_DIR}"
        exit 0
    fi

    select_archive

    rm -rf "${DOWNLOAD_DIR}"
    mkdir -p "${DOWNLOAD_DIR}"
    trap 'rm -rf "${DOWNLOAD_DIR}"' EXIT

    download_archive
    verify_archive
    extract_archive

    echo "Done. To build the resume, run: scripts/build.sh"
}


main "$@"
