#!/usr/bin/env bash

set -euo pipefail

patch_version="7.2.145-fable5.1"
upstream_version="7.2.145"
base_commit="d9cea8904b14fbbebb77ef26e98ef08f6b48a724"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer supports macOS only." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required." >&2
  exit 1
fi

formula_prefix="$(brew --prefix cliproxyapi 2>/dev/null || true)"
if [[ -z "${formula_prefix}" ]]; then
  echo "Install CLIProxyAPI ${upstream_version} with Homebrew first." >&2
  exit 1
fi

target_binary="${formula_prefix}/bin/cliproxyapi"
state_root="${XDG_STATE_HOME:-${HOME}/.local/state}/cliproxyapi-fable-5-1"
backup_binary="${state_root}/cliproxyapi-${upstream_version}.upstream"

if [[ ! -x "${target_binary}" ]]; then
  echo "CLIProxyAPI binary not found at ${target_binary}." >&2
  exit 1
fi

restore_upstream() {
  if [[ ! -f "${backup_binary}" ]]; then
    echo "No upstream backup found at ${backup_binary}." >&2
    exit 1
  fi

  brew services stop cliproxyapi >/dev/null
  install -m 0755 "${backup_binary}" "${target_binary}"
  brew services start cliproxyapi >/dev/null
  echo "Restored CLIProxyAPI ${upstream_version} and restarted the service."
}

if [[ "${1:-}" == "--restore" ]]; then
  restore_upstream
  exit 0
fi

if [[ $# -ne 0 ]]; then
  echo "Usage: $0 [--restore]" >&2
  exit 1
fi

current_version="$(${target_binary} -h 2>&1 | head -n 1 || true)"
if [[ "${current_version}" != *"${upstream_version}"* ]]; then
  echo "Expected CLIProxyAPI ${upstream_version}; found: ${current_version}" >&2
  exit 1
fi

if ! command -v go >/dev/null 2>&1; then
  brew install go
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

if git -C "${repo_root}" rev-parse --git-dir >/dev/null 2>&1; then
  if ! git -C "${repo_root}" merge-base --is-ancestor "${base_commit}" HEAD; then
    echo "This checkout is not based on the pinned CLIProxyAPI 7.2.145 commit." >&2
    exit 1
  fi
fi

build_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${build_dir}"
}
trap cleanup EXIT

(
  cd "${repo_root}"
  go test ./internal/registry
  go build \
    -trimpath \
    -ldflags "-s -w -X main.Version=${patch_version} -X main.Commit=${base_commit}+fable5.1 -X main.BuildDate=2026-09-01" \
    -o "${build_dir}/cliproxyapi" \
    ./cmd/server
)

built_version="$(${build_dir}/cliproxyapi -h 2>&1 | head -n 1 || true)"
if [[ "${built_version}" != *"${patch_version}"* ]]; then
  echo "Patched build did not report the expected version: ${built_version}" >&2
  exit 1
fi

mkdir -p "${state_root}"
if [[ "${current_version}" != *"${patch_version}"* && ! -f "${backup_binary}" ]]; then
  cp -p "${target_binary}" "${backup_binary}"
fi

brew services stop cliproxyapi >/dev/null
if ! install -m 0755 "${build_dir}/cliproxyapi" "${target_binary}"; then
  brew services start cliproxyapi >/dev/null || true
  exit 1
fi

if ! brew services start cliproxyapi >/dev/null; then
  echo "Patched service failed to start; restoring upstream binary." >&2
  install -m 0755 "${backup_binary}" "${target_binary}"
  brew services start cliproxyapi >/dev/null
  exit 1
fi

echo "Installed ${patch_version} and restarted the Homebrew service."
echo "Restore with: ${script_dir}/install-fable-5-1-macos.sh --restore"
