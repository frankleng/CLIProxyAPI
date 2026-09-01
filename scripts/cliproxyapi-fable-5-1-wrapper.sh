#!/bin/sh

set -eu

if [ -z "${HOME:-}" ]; then
  user_name="$(/usr/bin/id -un)"
  HOME="/Users/${user_name}"
  if [ ! -d "${HOME}" ]; then
    echo "Unable to resolve the macOS home directory for ${user_name}." >&2
    exit 1
  fi
  export HOME
fi

patched_binary="${XDG_STATE_HOME:-${HOME}/.local/state}/cliproxyapi-fable-5-1/cliproxyapi-7.2.145-fable5.1"
exec "${patched_binary}" "$@"
