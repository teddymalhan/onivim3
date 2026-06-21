#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <destination-runtime-directory>" >&2
  exit 64
fi

NEOVIM_VERSION="${ONIVIM_NEOVIM_VERSION:-v0.12.3}"
ARM64_ARCHIVE="nvim-macos-arm64.tar.gz"
X86_64_ARCHIVE="nvim-macos-x86_64.tar.gz"
ARM64_SHA256="532da1d00e465a660fa01c3d4991333d09c52107dce7df937368545daca0a14e"
X86_64_SHA256="4b40e318eb7073321fa5fc06d7f60c3c0de1d7ea50ffbaa8b04286f5484d294f"
BASE_URL="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}"
DESTINATION="$1"
CACHE_ROOT="${ONIVIM_NEOVIM_CACHE_DIR:-${PROJECT_TEMP_DIR:-${TMPDIR:-/tmp}}/OnivimNeovimRuntime}"
VERSION_CACHE="${CACHE_ROOT}/${NEOVIM_VERSION}"
UNIVERSAL_CACHE="${VERSION_CACHE}/universal/Neovim"
WORK_ROOT="${VERSION_CACHE}/work"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required tool not found: $1" >&2
    exit 69
  fi
}

require_tool python3
require_tool shasum
require_tool lipo

sha256() {
  shasum -a 256 "$1" | awk '{ print $1 }'
}

download_archive() {
  local archive_name="$1"
  local expected_sha="$2"
  local output_path="${VERSION_CACHE}/${archive_name}"
  local actual_sha=""

  mkdir -p "${VERSION_CACHE}"
  if [[ -f "${output_path}" ]]; then
    actual_sha="$(sha256 "${output_path}")"
    if [[ "${actual_sha}" == "${expected_sha}" ]]; then
      return 0
    fi
    rm -f "${output_path}"
  fi

  python3 - "${BASE_URL}/${archive_name}" "${output_path}" <<'PY'
from pathlib import Path
from urllib.request import Request, urlopen
import sys

url = sys.argv[1]
output = Path(sys.argv[2])
temporary = output.with_suffix(output.suffix + ".tmp")
request = Request(url, headers={"User-Agent": "Onivim3-build"})
with urlopen(request, timeout=120) as response, temporary.open("wb") as file:
    while True:
        chunk = response.read(1024 * 1024)
        if not chunk:
            break
        file.write(chunk)
temporary.replace(output)
PY

  actual_sha="$(sha256 "${output_path}")"
  if [[ "${actual_sha}" != "${expected_sha}" ]]; then
    echo "Checksum mismatch for ${archive_name}: expected ${expected_sha}, got ${actual_sha}" >&2
    rm -f "${output_path}"
    exit 65
  fi
}

extract_archive() {
  local archive_name="$1"
  local destination="$2"

  rm -rf "${destination}"
  mkdir -p "${destination}"
  python3 - "${VERSION_CACHE}/${archive_name}" "${destination}" <<'PY'
from pathlib import Path
import sys
import tarfile

archive = Path(sys.argv[1])
destination = Path(sys.argv[2]).resolve()
with tarfile.open(archive, "r:gz") as tar:
    for member in tar.getmembers():
        target = (destination / member.name).resolve()
        if not str(target).startswith(str(destination) + "/") and target != destination:
            raise SystemExit(f"Refusing to extract path outside destination: {member.name}")
    tar.extractall(destination)
PY
}

build_universal_runtime() {
  local arm_root="${WORK_ROOT}/arm64/nvim-macos-arm64"
  local x86_root="${WORK_ROOT}/x86_64/nvim-macos-x86_64"
  local macho_list="${WORK_ROOT}/macho-files.txt"

  rm -rf "${WORK_ROOT}"
  mkdir -p "${WORK_ROOT}"
  extract_archive "${ARM64_ARCHIVE}" "${WORK_ROOT}/arm64"
  extract_archive "${X86_64_ARCHIVE}" "${WORK_ROOT}/x86_64"

  rm -rf "${UNIVERSAL_CACHE}"
  mkdir -p "$(dirname "${UNIVERSAL_CACHE}")"
  cp -R "${arm_root}" "${UNIVERSAL_CACHE}"

  python3 - "${arm_root}" "${x86_root}" > "${macho_list}" <<'PY'
from pathlib import Path
import subprocess
import sys

arm_root = Path(sys.argv[1])
x86_root = Path(sys.argv[2])
for arm_file in sorted(path for path in arm_root.rglob("*") if path.is_file()):
    relative = arm_file.relative_to(arm_root)
    x86_file = x86_root / relative
    if not x86_file.is_file():
        continue
    description = subprocess.check_output(["/usr/bin/file", str(arm_file)], text=True)
    if "Mach-O" in description:
        print(relative)
PY

  while IFS= read -r relative_path; do
    [[ -n "${relative_path}" ]] || continue
    lipo -create \
      "${arm_root}/${relative_path}" \
      "${x86_root}/${relative_path}" \
      -output "${UNIVERSAL_CACHE}/${relative_path}"
  done < "${macho_list}"

  printf '%s\n' "${NEOVIM_VERSION}" > "${UNIVERSAL_CACHE}/ONIVIM_NEOVIM_VERSION"
  rm -rf "${WORK_ROOT}"
}

if [[ ! -x "${UNIVERSAL_CACHE}/bin/nvim" || ! -f "${UNIVERSAL_CACHE}/ONIVIM_NEOVIM_VERSION" ]]; then
  download_archive "${ARM64_ARCHIVE}" "${ARM64_SHA256}"
  download_archive "${X86_64_ARCHIVE}" "${X86_64_SHA256}"
  build_universal_runtime
fi

rm -rf "${DESTINATION}"
mkdir -p "$(dirname "${DESTINATION}")"
cp -R "${UNIVERSAL_CACHE}" "${DESTINATION}"
chmod +x "${DESTINATION}/bin/nvim"

"${DESTINATION}/bin/nvim" --version >/dev/null
