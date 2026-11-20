#!/bin/bash
# test.sh: the port's own tests, with nothing but Apple's Command Line Tools.
#
#   tools/test.sh            the unit tests and the tools' Python tests
#   tools/test.sh --unit     the unit tests alone
#   tools/test.sh --python   the Python tests alone
#
# No game files, no SDL3, no FFmpeg and no CMake configure of the whole
# project: each test is compiled on its own against src/. That is what the
# CI runs (see .github/workflows/tests.yml) and what a contributor without
# a copy of the game can run.
#
# `cmake --preset release -DGTAIV_TESTS=ON && ctest` builds the same tests
# inside a full build, which needs the vendored runtime and its libraries.
set -uo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here"

cxx=${CXX:-xcrun --sdk macosx clang++}
read -r -a cxx <<< "$cxx"

# Temporary build folder (out/ is not committed).
build=out/tests
rm -rf "$build"
mkdir -p "$build"

status=0
failed=()
passed=0

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

# build_and_run name [sources...]
build_and_run() {
  local name=$1
  shift
  local exe=$build/$name
  # The save reader is fed damaged files: catch a read past their end.
  local san=
  [ "$name" = save_file ] && san="-fsanitize=address,undefined -fno-sanitize-recover=undefined"
  if ! "${cxx[@]}" -std=c++20 -g -O1 -Wall -Wextra -Wno-unused-parameter \
      -Isrc -Ivendor/x86recomp/src $san "$@" -o "$exe" 2> "$build/$name.build.log"; then
    printf '  \033[31mFAIL\033[0m %s (does not compile: %s)\n' "$name" "$build/$name.build.log"
    sed -n '1,20p' "$build/$name.build.log"
    status=1
    failed+=("$name")
    return
  fi
  if ! "$exe" > "$build/$name.log" 2>&1; then
    printf '  \033[31mFAIL\033[0m %s\n' "$name"
    sed -n '1,20p' "$build/$name.log"
    status=1
    failed+=("$name")
    return
  fi
  printf '  \033[32mok\033[0m   %s\n' "$name"
  passed=$((passed + 1))
}

# build_and_run_objc name source [frameworks...] (the launcher's options)
build_and_run_objc() {
  local name=$1 src=$2
  shift 2
  local exe=$build/$name
  if ! xcrun --sdk macosx clang++ -std=c++20 -g -O1 -fobjc-arc -Isrc "$src" "$@" -o "$exe" \
      2> "$build/$name.build.log"; then
    printf '  \033[31mFAIL\033[0m %s (does not compile)\n' "$name"
    sed -n '1,20p' "$build/$name.build.log"
    status=1
    failed+=("$name")
    return
  fi
  if ! "$exe" > "$build/$name.log" 2>&1; then
    printf '  \033[31mFAIL\033[0m %s\n' "$name"
    sed -n '1,20p' "$build/$name.log"
    status=1
    failed+=("$name")
    return
  fi
  printf '  \033[32mok\033[0m   %s\n' "$name"
  passed=$((passed + 1))
}

# Two tests read the runtime's headers (vendor/x86recomp, the commit pinned
# in X86RECOMP; `install.sh` or `tools/fetch_runtime.sh` fetches it).
# Without it they are reported as skipped, not failed: neither needs any of
# the runtime's libraries, only its headers.
have_runtime=0
[ -d vendor/x86recomp/src/runtime ] && have_runtime=1

unit_tests() {
  say "Unit tests (plain C++, no game files)"
  build_and_run game_args          tests/game_args_test.cpp src/game_args.cpp
  build_and_run first_menu         tests/first_menu_test.cpp
  build_and_run save_paths         tests/save_paths_test.cpp
  build_and_run save_file          tests/save_file_test.cpp
  build_and_run night_shadow_slots tests/night_shadow_slots_test.cpp
  build_and_run language           tests/language_test.cpp
  build_and_run water_surface      tests/water_surface_test.cpp
  build_and_run episode_files      tests/episode_files_test.cpp
  if [ $have_runtime = 1 ]; then
    build_and_run pad_feedback     tests/pad_feedback_test.cpp
    build_and_run spatial_audio    tests/spatial_audio_test.cpp
  else
    printf '  \033[33mskip\033[0m pad_feedback, spatial_audio (no vendor/x86recomp: tools/fetch_runtime.sh)\n'
  fi
  if [ "$(uname -s)" = Darwin ]; then
    build_and_run_objc launcher_options tests/launcher_options_test.mm -framework Foundation
  fi
}

python_tests() {
  say "Python tools' tests"
  if python3 -m unittest discover -s tests > "$build/python.log" 2>&1; then
    printf '  \033[32mok\033[0m   %s\n' "$(grep -oE 'Ran [0-9]+ tests' "$build/python.log" | tail -1)"
    passed=$((passed + 1))
  else
    printf '  \033[31mFAIL\033[0m python3 -m unittest discover -s tests\n'
    tail -20 "$build/python.log"
    status=1
    failed+=(python_tools)
  fi
}

what=${1:-all}
case $what in
  --unit|unit) unit_tests ;;
  --python|python) python_tests ;;
  all) unit_tests; python_tests ;;
  *) echo "usage: tools/test.sh [--unit|--python]" >&2; exit 2 ;;
esac

echo
if [ $status -ne 0 ]; then
  echo "FAILED: ${failed[*]} (logs in $build)"
  exit 1
fi
echo "All tests passed ($passed suites). Logs in $build."
