#!/bin/bash
# install.sh: build RecompIV from your own copy of GTA IV (PC 1.0.8.0) and
# put "RecompIV.app" in /Applications.
#
#   ./install.sh "/path/to/Grand Theft Auto IV"
#   ./install.sh --check ["/path/to/Grand Theft Auto IV"]   look, install nothing
#
# The game folder is remembered (tools/local.env); later runs, after a
# `git pull`, need no argument. Running it again rebuilds and reinstalls.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
usage: ./install.sh [--check] ["/path/to/Grand Theft Auto IV"]

  --check   check this Mac and the game folder, install and build nothing
  -h        this text

Builds the game from your own GTA IV (PC 1.0.8.0, the one with GTAIV.exe),
then puts RecompIV in /Applications. Nothing of the game is in this
repository: the build translates your own GTAIV.exe.
EOF
}

check=0
game=
for a in "$@"; do
  case $a in
    --check|--doctor) check=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option: $a (try --help)" ;;
    *) game=$a ;;
  esac
done

[ "$(uname -s)" = Darwin ] || die "RecompIV builds on macOS."
[ "$(uname -m)" = arm64 ] || die "RecompIV needs a Mac with Apple silicon."

[ -f tools/local.env ] && . tools/local.env
if [ -n "$game" ]; then GTAIV_GAME_DIR=$(cd "$game" && pwd); fi

if [ "$check" = 1 ]; then
  exec "$here/tools/doctor.sh" "${GTAIV_GAME_DIR:-}"
fi

[ -n "${GTAIV_GAME_DIR:-}" ] || die "give the game folder (the one with GTAIV.exe): ./install.sh \"/path/to/Grand Theft Auto IV\""

say "Checking this Mac and the game folder"
if ! "$here/tools/doctor.sh" "$GTAIV_GAME_DIR"; then
  die "something needed is missing (above). Fix it and run this again; --check repeats only the checks."
fi

[ -f "$GTAIV_GAME_DIR/GTAIV.exe" ] || die "no GTAIV.exe in $GTAIV_GAME_DIR"
printf 'GTAIV_GAME_DIR=%q\n' "$GTAIV_GAME_DIR" > tools/local.env
export GTAIV_GAME_DIR
export PATH="/opt/homebrew/bin:$PATH"

say "Build tools"
command -v brew >/dev/null 2>&1 || die "install Homebrew first: https://brew.sh"
brew install cmake ninja sdl3 ffmpeg llvm@22 glslang spirv-cross python

say "x86recomp"
tools/fetch_runtime.sh

say "Lifter and runtime (first build)"
cmake --preset release >/dev/null
cmake --build --preset release

say "The game's code, from your GTAIV.exe"
tools/lift.sh

say "The app's icon, from the game's own logo"
icon=out/icons/AppIcon.icns
if ! { python3 -m venv out/venv && out/venv/bin/pip -q install pillow &&
       out/venv/bin/python -I tools/make_ios_icon.py "$GTAIV_GAME_DIR" out/icons --mac; }; then
  echo "No icon could be made from the game's files: the app has the standard one."
fi

say "The game"
cmake --preset release >/dev/null
cmake --build --preset release

say "Installing to /Applications"
app="out/build/release/RecompIV.app"
[ -d "$app" ] || die "the build made no app: $app"
rm -rf "/Applications/RecompIV.app"
ditto "$app" "/Applications/RecompIV.app"
# (The build puts the icon in only when it links the game anew.)
if [ -f "$icon" ]; then
  mkdir -p "/Applications/RecompIV.app/Contents/Resources"
  cp -f "$icon" "/Applications/RecompIV.app/Contents/Resources/"
fi
codesign --force --sign - "/Applications/RecompIV.app" >/dev/null 2>&1 || true

say "Done"
cat <<EOF
Open "RecompIV" from Applications (or Launchpad), pick the game folder in
the launcher if asked, and press Play.

Game folder: $GTAIV_GAME_DIR
Saves and settings: ~/Library/Application Support/gtaiv
Log: ~/Library/Logs/gtaiv.log

If something looks wrong: ./install.sh --check, and README.md > If something goes wrong.
EOF
