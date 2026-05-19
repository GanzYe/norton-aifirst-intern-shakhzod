#!/usr/bin/env bash
# Fetches llama.cpp into the flutter_llama pub-cache package (required for Android builds).
set -euo pipefail

LLAMA_CPP_TAG="b5472"
LLAMA_CPP_REPO="https://github.com/ggml-org/llama.cpp.git"

PUB_CACHE="${PUB_CACHE:-${HOME}/.pub-cache}"
HOSTED="${PUB_CACHE}/hosted/pub.dev"

if [[ ! -d "${HOSTED}" ]]; then
  echo "Pub cache not found at ${HOSTED}. Run 'flutter pub get' first." >&2
  exit 1
fi

PLUGIN_DIR="$(find "${HOSTED}" -maxdepth 1 -type d -name 'flutter_llama-*' | sort -V | tail -n 1)"
if [[ -z "${PLUGIN_DIR}" ]]; then
  echo "flutter_llama not in pub cache. Run 'flutter pub get' first." >&2
  exit 1
fi

LLAMA_DIR="${PLUGIN_DIR}/llama.cpp"
echo "flutter_llama package: ${PLUGIN_DIR}"

apply_patches() {
  PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/patches/flutter_llama"
  cp "${PATCH_ROOT}/android_build.gradle" "${PLUGIN_DIR}/android/build.gradle"
  cp "${PATCH_ROOT}/CMakeLists.txt" "${PLUGIN_DIR}/android/src/main/cpp/CMakeLists.txt"
  echo "Applied Android build patches to flutter_llama."
}

if [[ -f "${LLAMA_DIR}/CMakeLists.txt" ]]; then
  echo "llama.cpp already present at ${LLAMA_DIR}"
  apply_patches
  exit 0
fi

echo "Cloning llama.cpp (tag ${LLAMA_CPP_TAG})..."
git clone --depth 1 --branch "${LLAMA_CPP_TAG}" "${LLAMA_CPP_REPO}" "${LLAMA_DIR}"
echo "Done. llama.cpp installed at ${LLAMA_DIR}"

apply_patches
