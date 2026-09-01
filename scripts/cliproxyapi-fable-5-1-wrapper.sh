#!/bin/sh

set -eu

if [ -z "${HOME:-}" ]; then
  user_name="$(/usr/bin/id -un)"
  HOME="$(/usr/bin/dscl . -read "/Users/${user_name}" NFSHomeDirectory | /usr/bin/awk '{print $2}')"
  export HOME
fi

patched_binary="${XDG_STATE_HOME:-${HOME}/.local/state}/cliproxyapi-fable-5-1/cliproxyapi-7.2.145-fable5.1"
exec "${patched_binary}" "$@"
