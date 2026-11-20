#!/bin/bash
# fetch_runtime.sh: the x86recomp runtime this port is pinned to (X86RECOMP),
# in vendor/x86recomp. install.sh runs this itself; run it by hand to build
# or test without a full install (the runtime's headers are what the unit
# tests of pad_feedback and spatial_audio read).
#
#   tools/fetch_runtime.sh
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here"

[ -f X86RECOMP ] || { echo "no X86RECOMP file: run this from the repository" >&2; exit 1; }
read -r branch pin < X86RECOMP

if [ ! -d vendor/x86recomp/.git ]; then
  mkdir -p vendor
  git clone --branch "$branch" https://github.com/Awis13/x86recomp vendor/x86recomp
fi
git -C vendor/x86recomp fetch --quiet origin "$branch"
git -C vendor/x86recomp checkout --quiet "$pin"
echo "x86recomp $pin ($branch) in vendor/x86recomp"
