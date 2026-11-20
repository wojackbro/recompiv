#!/bin/bash
# doctor.sh: is this Mac ready to build RecompIV, and is the game folder the
# one the port supports? Nothing is installed and nothing is built: it only
# looks, so it is safe to run any time.
#
#   tools/doctor.sh                       checks this Mac, and the game folder
#                                         install.sh remembered (tools/local.env)
#   tools/doctor.sh "/path/to/Grand Theft Auto IV"
#   ./install.sh --check [game folder]    the same, from the installer
#
# Exit status: 0 everything needed is there, 1 something needed is missing.
# Warnings (nice to have, or something to know before a 15-minute build) do
# not fail it.
set -uo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here"

[ -f tools/local.env ] && . tools/local.env
game=${1:-${GTAIV_GAME_DIR:-}}

fails=0
warns=0
ok()   { printf '  \033[32mok\033[0m    %s\n' "$*"; }
warn() { printf '  \033[33mwarn\033[0m  %s\n' "$*"; warns=$((warns + 1)); }
fail() { printf '  \033[31mfail\033[0m  %s\n' "$*"; fails=$((fails + 1)); }
section() { printf '\n\033[1m%s\033[0m\n' "$*"; }

section "This Mac"
if [ "$(uname -s)" = Darwin ]; then ok "macOS $(sw_vers -productVersion)"; else fail "macOS is needed (this is $(uname -s))"; fi
if [ "$(uname -m)" = arm64 ]; then ok "Apple silicon"; else fail "an Apple silicon Mac is needed (this is $(uname -m))"; fi
major=$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)
if [ "${major:-0}" -ge 14 ] 2>/dev/null; then ok "macOS 14 or newer"; else warn "macOS 14 or newer is recommended"; fi

if xcode-select -p >/dev/null 2>&1; then
  ok "Xcode Command Line Tools ($(xcode-select -p))"
else
  fail "no Xcode Command Line Tools: xcode-select --install"
fi

free_kb=$(df -k "$here" 2>/dev/null | awk 'NR == 2 {print $4}')
if [ -n "${free_kb:-}" ]; then
  free_gb=$((free_kb / 1024 / 1024))
  if [ "$free_kb" -ge 8388608 ]; then ok "$free_gb GB free for the build"; else warn "$free_gb GB free: the build needs about 8 GB"; fi
fi

section "Build tools"
if command -v brew >/dev/null 2>&1; then ok "Homebrew"; else warn "no Homebrew (https://brew.sh); ./install.sh needs it"; fi
for t in cmake ninja python3; do
  if command -v "$t" >/dev/null 2>&1; then ok "$t"; else warn "no $t: ./install.sh installs it with Homebrew"; fi
done
[ -d /opt/homebrew/opt/llvm@22 ] && ok "llvm@22" || warn "no llvm@22: ./install.sh installs it with Homebrew"
for t in glslangValidator spirv-cross; do
  command -v "$t" >/dev/null 2>&1 && ok "$t" || warn "no $t: ./install.sh installs it with Homebrew"
done
if [ -d vendor/x86recomp/src/runtime ]; then ok "runtime in vendor/x86recomp"; else warn "no vendor/x86recomp: ./install.sh fetches it (tools/fetch_runtime.sh)"; fi

section "The game"
if [ -z "$game" ]; then
  fail "no game folder given: tools/doctor.sh \"/path/to/Grand Theft Auto IV\""
else
  if [ -f "$game/GTAIV.exe" ] && [ ! -d "$game/GTAIV.exe" ]; then
    ok "GTAIV.exe"
    want=3d90e7c516fa450ca002e5031e62c0f66b404590f33e6cc9793b0da4fffbfd0f
    have=$(shasum -a 256 "$game/GTAIV.exe" | cut -d' ' -f1)
    if [ "$have" = "$want" ]; then
      ok "GTAIV.exe is version 1.0.8.0, as Rockstar signed it"
    else
      fail "GTAIV.exe is not 1.0.8.0 (SHA-256 $have)"
      printf '        The port lifts this exact file. The Steam 1.0.8.0 is the one supported;\n'
      printf '        the Complete Edition (1.2.0.x) and patched or cracked exes are not.\n'
      printf '        See README.md > What you need for the DepotDownloader command.\n'
    fi
  else
    fail "no GTAIV.exe in $game"
  fi
  for d in pc common; do
    if [ -d "$game/$d" ]; then ok "the game's $d folder"; else fail "no $d folder in $game: is this the game's folder?"; fi
  done
  # The episodes are optional, but a folder the game will not take is worth
  # knowing about before the build (README > The episodes).
  if [ -d "$game/TLAD" ] && [ ! -f "$game/TLAD/E1_List.txt" ]; then
    warn "TLAD has no E1_List.txt: the game will not show The Lost and Damned (use the Complete Edition's folder)"
  fi
  if [ -d "$game/TBoGT" ] && [ ! -f "$game/TBoGT/E2_List.txt" ]; then
    warn "TBoGT has no E2_List.txt: the game will not show The Ballad of Gay Tony (use the Complete Edition's folder)"
  fi
  if [ -f "$game/TLAD/E1_List.txt" ]; then ok "The Lost and Damned's file list"; fi
  if [ -f "$game/TBoGT/E2_List.txt" ]; then ok "The Ballad of Gay Tony's file list"; fi
  if [ -f "$game/commandline.txt" ]; then
    ok "commandline.txt (its own values win over the launcher's defaults)"
  fi
fi

section "Tests"
if [ -x tools/test.sh ]; then ok "tools/test.sh (no game files needed)"; else warn "tools/test.sh is not executable"; fi

echo
if [ "$fails" -ne 0 ]; then
  printf '\033[31m%s to fix\033[0m' "$fails"
  [ "$warns" -ne 0 ] && printf ', %s warning%s' "$warns" "$([ "$warns" = 1 ] || echo s)"
  echo
  exit 1
fi
if [ "$warns" -ne 0 ]; then
  printf '\033[33m%s warning%s\033[0m: building may still work\n' "$warns" "$([ "$warns" = 1 ] || echo s)"
else
  printf '\033[32mAll good\033[0m: ./install.sh "%s"\n' "${game:-/path/to/Grand Theft Auto IV}"
fi
exit 0
