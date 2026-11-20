# Known issues

Two things are mixed here on purpose: what is wrong with the **port** , and what is wrong with **RecompIV's tooling**, which
is what RecompIV actually changes.

## Fixed in RecompIV

These are defects in the inherited scripts and docs, found while building
RecompIV. Each is fixed here and each fix is checked by `tools/test.sh`,
`./install.sh --check` or CI.

| # | Bug | Why it hurt | Fix |
|---|---|---|---|
| 1 | The port's unit tests could only be built through a full CMake configure, which requires SDL3, FFmpeg, glslang, SPIRV-Cross and the vendored runtime (and `cmake --preset release` otherwise fails on `add_subdirectory(vendor/x86recomp)` before the tests are even reached) | A contributor without a game copy, or without the heavy toolchain, could not run a single test; the tests were effectively CI-less and nobody would notice a regression in `src/game_args.cpp`, `src/save_file.h` and the rest | `tools/test.sh` compiles each test on its own against `src/` with nothing but the Command Line Tools. 11 unit suites and the 30 Python tool tests, no game files. `tools/test.sh --unit` and `tools/test.sh --python` are the same two things run one at a time. (A CI workflow is not included: GitHub Actions did not provision a runner for the account it was published from, so a workflow file would only have shown a red cross. Run it by hand, or add `.github/workflows/tests.yml` running `tools/test.sh`.) |
| 2 | `install.sh` checked only that `GTAIV.exe` exists and its SHA-256 matches, then went straight into `brew install` and a 15-minute build | A folder missing `pc/` or `common/`, a missing episode file list, or a half-copied install was discovered minutes into the build, after the toolchain download, with a compiler error instead of a sentence | `tools/doctor.sh` and `install.sh --check` check the Mac, the free space, the build tools, `GTAIV.exe`, the `pc`/`common` folders, the episodes' `E1_List.txt`/`E2_List.txt`, and `commandline.txt`, and name what is missing. `install.sh` runs the same checks before it installs anything |
| 3 | The pinned x86recomp could only be fetched as part of `install.sh`, which then built the lifter and refused to go on without a game folder | Two unit tests (`pad_feedback`, `spatial_audio`) read the runtime's headers and could not be built at all in a fresh checkout, and there was no supported way to get just the runtime | `tools/fetch_runtime.sh` fetches the commit in `X86RECOMP` on its own (and `install.sh` now calls it), so the tests build with `tools/test.sh` and CI runs them |
| 4 | The README required **macOS 15 or newer**; `install.sh` accepted macOS 14 and `macos/Info.plist` sets `LSMinimumSystemVersion` to 14.0 | A player on macOS 14 was told by the README that the port does not run for them, when the scripts and the app both accept it | RecompIV's docs say macOS 14, matching the scripts and the app. (If 15 really is needed, the code is what is wrong; `tools/doctor.sh` only warns below 14.) |
| 5 | The README's Quick start told the reader to download a **Builder** app from the project's releases | RecompIV publishes no Builder, so the front page sent the first user to a 404 | Quick start is the Terminal installer, with `--check` first; the Builder section says RecompIV does not ship one |
| 6 | The project's names lived in 25 files (app bundle, bundle ids, iCloud container, iOS/tvOS profiles, entitlements, launchers, builder recipe) | A build with the inherited bundle id collides with it on disk, in `/Applications`, in `NSUserDefaults` and in iCloud Drive | Renamed throughout, keeping the *user-visible* paths (`~/Library/Application Support/gtaiv`, `~/Library/Logs/gtaiv.log`, `GTAIV_*` options) so saves, logs and anything written for the original still apply |

## Open in the port

These are the port's open reports at the time RecompIV was started, with what
RecompIV does about them. **None of them is fixed here**: they are
gameplay, renderer or hooking bugs in the lifted code and the runtime, and
fixing them needs a copy of the game, a Metal-capable Mac and a way to play
the scene that misbehaves. Guessing at them without being able to run the game
would be worse than leaving them documented.

| Upstream issue | What it is | Status here |
|---|---|---|
| [#76](https://github.com/Awis13/liberty-pro-max/issues/76) | Aim lock / auto aim behaves wrongly | Not changed. Needs the running game |
| [#75](https://github.com/Awis13/liberty-pro-max/issues/75) | A recomp of the Xbox 360 version, for PC | Out of scope: that is a different binary and a different project |
| [#74](https://github.com/Awis13/liberty-pro-max/issues/74) | A Windows version | Out of scope: the port is built on Metal and Apple frameworks |
| [#73](https://github.com/Awis13/liberty-pro-max/issues/73) | A PC version (same request as #74) | Out of scope |
| [#72](https://github.com/Awis13/liberty-pro-max/issues/72) | Record GFWL achievements locally, with an unlock toast | Not implemented. The port answers Live offline; achievements are not part of RecompIV |
| [#71](https://github.com/Awis13/liberty-pro-max/issues/71) | "Now playing": show the radio's song and artist in a vehicle | Not implemented |
| [#70](https://github.com/Awis13/liberty-pro-max/issues/70) | Corruption in the windshield during rain | Not changed. Renderer, needs the running game |
| [#64](https://github.com/Awis13/liberty-pro-max/issues/64) | Mirrors in the strip club are broken | Not changed. Needs the running game |
| [#62](https://github.com/Awis13/liberty-pro-max/issues/62) | DualSense support | Already in the port (Extras tab, off by default); the issue asks for more than the port does. Not extended here |
| [#60](https://github.com/Awis13/liberty-pro-max/issues/60) | Manual shader compilation in the iPhone and iPad launchers | Not implemented. iOS launcher work, needs a device |
| [#59](https://github.com/Awis13/liberty-pro-max/issues/59) | A native tvOS launcher | Not implemented. Needs an Apple TV |
| [#54](https://github.com/Awis13/liberty-pro-max/issues/54) | Comparable warm Metal benchmarks and sampled-depth results | Not done. Needs the game and the hardware the numbers are about |
| [#51](https://github.com/Awis13/liberty-pro-max/issues/51) | The episode chooser does not appear | Partly addressed upstream: the port now says when an episode's folder has no `E1_List.txt`/`E2_List.txt` (the usual cause) and `tools/doctor.sh` warns about it before the build. The chooser's own logic is unchanged |
| [#50](https://github.com/Awis13/liberty-pro-max/issues/50) | Night shadow bug (a lamp's shadow vanishing while its light still shines) | Already addressed upstream by `night_shadow_slots` (`GTAIV_NIGHT_SHADOW_STABLE`, on by default), with `tests/night_shadow_slots_test.cpp`. Left as it is |
| [#48](https://github.com/Awis13/liberty-pro-max/issues/48) | Launcher language selection on Mac, iPhone and iPad | Not implemented. The game's own language menu and the system language are what exist |
| [#34](https://github.com/Awis13/liberty-pro-max/issues/34) | TBoGT's pause menu plays IV's menu music | Not changed. Needs the running game |

## Not verified here

This project was prepared on a Mac without a copy of GTA IV, so **the game was
not built and not run for it**. What is verified is the plain C++ and the
tools:

- `tools/test.sh`: 11 unit suites (command line and `commandline.txt`
  handling, save classification with a damaged-file fuzz under
  AddressSanitizer and UndefinedBehaviorSanitizer, save paths, episode files,
  first-menu state, night shadow slots, language, water surface, pad feedback,
  spatial audio, launcher options) and the 30 Python tool tests. All pass.
- `./install.sh --check` on a Mac with no game: reports the missing game
  folder and the missing Homebrew tools, exit status 1, and nothing is
  installed.
- `bash -n` / `zsh -n` on every script RecompIV touches.

Not verified, and not claimed: that the lifted game compiles from a real
`GTAIV.exe`, that the app launches, that rendering, audio and the fixes work,
and that the iOS/tvOS builds still bundle after the rename. Those need a Mac
with the game, Homebrew's toolchain, and something to play on.

If a build of RecompIV fails, the two checks that tell you the most are
`./install.sh --check` (environment and game files) and `tools/test.sh`
(the port's own logic). Then the log: `~/Library/Logs/gtaiv.log`.
