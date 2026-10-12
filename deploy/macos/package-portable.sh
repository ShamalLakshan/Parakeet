#!/usr/bin/env bash
set -euo pipefail

# Parakeet macOS Portable Packager
# Packages Parakeet.app with macdeployqt into a portable standalone ZIP

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

BUILD_DIR="${1:-${REPO_ROOT}/build}"
OUTPUT_DIR="${2:-${REPO_ROOT}/dist}"

echo "=== Parakeet macOS Portable Packager ==="
echo "Repo Root: ${REPO_ROOT}"
echo "Build Dir: ${BUILD_DIR}"
echo "Output Dir: ${OUTPUT_DIR}"

APP_BUNDLE=""
if [ -d "${BUILD_DIR}/app/Parakeet.app" ]; then
    APP_BUNDLE="${BUILD_DIR}/app/Parakeet.app"
elif [ -d "${BUILD_DIR}/Parakeet.app" ]; then
    APP_BUNDLE="${BUILD_DIR}/Parakeet.app"
fi

if [ -z "${APP_BUNDLE}" ]; then
    echo "Error: Parakeet.app bundle not found in ${BUILD_DIR}. Please build the project first."
    exit 1
fi

mkdir -p "${OUTPUT_DIR}"

# 1. Run macdeployqt
echo "--> Running macdeployqt..."
macdeployqt "${APP_BUNDLE}" -qmldir="${REPO_ROOT}/adapters/ui_qt/qml"

# 2. Bundle themes into Contents/Resources
RESOURCES_DIR="${APP_BUNDLE}/Contents/Resources"
mkdir -p "${RESOURCES_DIR}/themes"
cp "${REPO_ROOT}/themes/"*.json "${RESOURCES_DIR}/themes/"

# 3. Create portable indicator inside MacOS directory if portable data desired
touch "${APP_BUNDLE}/Contents/MacOS/portable.dat"

# 4. Create ZIP archive
ZIP_NAME="Parakeet-macos-universal-portable.zip"
echo "--> Compressing to ${OUTPUT_DIR}/${ZIP_NAME}..."
(
    cd "$(dirname "${APP_BUNDLE}")"
    zip -r -q -y "${OUTPUT_DIR}/${ZIP_NAME}" "$(basename "${APP_BUNDLE}")"
)

echo "=== macOS Portable ZIP created successfully! ==="
echo "File: ${OUTPUT_DIR}/${ZIP_NAME}"
