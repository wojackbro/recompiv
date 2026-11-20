# Known issues

RecompIV's bug list, in two parts: the tooling bugs that were found and fixed
here, and the bugs that are still open in the game and the renderer.

## Fixed in RecompIV

These are defects in the port's scripts and docs, found while building
RecompIV. Each is fixed here and each fix is checked by `tools/test.sh` or
`./install.sh --check`.

| # | Bug | Why it hurt | Fix |
|---|---|---|---|
| 1 | The unit tests could only be built through a full CMake configure, which requires SDL3, FFmpeg, glslang, SPIRV-Cross and the vendored runtime (and `cmake --preset release` otherwise fails on `add_subdirectory(vendor/x86recomp)` before the tests are even reached) | A contributor without a game copy, or without the heavy toolchain, could not run a single test; the tests were effectively CI-less and nobody would notice a regression in `src/game_args.cpp`, `src/save_file.h` and the rest | `tools/test.sh` compiles each test on its own against `src/` with nothing but the Command Line Tools. 11 unit suites and the 30 Python tool tests, no game files. `tools/test.sh --unit` and `tools/test.sh --python` are the same two things run one at a time. (No CI workflow is included: GitHub Actions did not provision a runner for the account RecompIV is published from, so a workflow file would only have shown a red cross. Run it by hand, or add `.github/workflows/tests.yml` running `tools/test.sh`.) |
| 2 | `install.sh` checked only that `GTAIV.exe` exists and its SHA-256 matches, then went straight into `brew install` and a 15-minute build | A folder missing `pc/` or `common/`, a missing episode file list, or a half-copied install was discovered minutes into the build, after the toolchain download, with a compiler error instead of a sentence | `tools/doctor.sh` and `install.sh --check` check the Mac, the free space, the build tools, `GTAIV.exe`, the `pc`/`common` folders, the episodes' `E1_List.txt`/`E2_List.txt`, and `commandline.txt`, and name what is missing. `install.sh` runs the same checks before it installs anything |
| 3 | The pinned x86recomp could only be fetched as part of `install.sh`, which then built the lifter and refused to go on without a game folder | Two unit tests (`pad_feedback`, `spatial_audio`) read the runtime's headers and could not be built at all in a fresh checkout, and there was no supported way to get just the runtime | `tools/fetch_runtime.sh` fetches the commit in `X86RECOMP` on its own (and `install.sh` now calls it), so `tools/test.sh` builds those two suites and can run them without a game |
| 4 | The docs required **macOS 15 or newer**; `install.sh` accepted macOS 14 and `macos/Info.plist` sets `LSMinimumSystemVersion` to 14.0 | A player on macOS 14 was told the port does not run for them, when the scripts and the app both accept it | RecompIV's docs say macOS 14, matching the scripts and the app. (If 15 really is needed, the code is what is wrong; `tools/doctor.sh` only warns below 14.) |
| 5 | The Quick start told the reader to download a **Builder** app from the releases page | RecompIV publishes no Builder, so the front page sent the first user to a 404 | Quick start is the Terminal installer, with `--check` first; the Builder section says RecompIV does not ship one |
| 6 | The names lived in 25 files (app bundle, bundle ids, iCloud container, iOS/tvOS profiles, entitlements, launchers, builder recipe) | A build with the old bundle id collides with another install on disk, in `/Applications`, in `NSUserDefaults` and in iCloud Drive | Renamed throughout to `RecompIV`, keeping the *user-visible* paths (`~/Library/Application Support/gtaiv`, `~/Library/Logs/gtaiv.log`, `GTAIV_*` options) so saves, logs and existing scripts keep working |

## Open in the game

Sixteen gameplay, renderer and hooking bugs, still unfixed in this build. Each
was reported against the port and each is reproducible in the code RecompIV
ships. **None of them is fixed here**: they need a copy of the game, a
Metal-capable Mac and a way to play the scene that misbehaves, and guessing at
them without being able to run the game would be worse than leaving them
documented.

| # | Bug | Status |
|---|---|---|
| B1 | Aim lock / auto aim behaves wrongly | Not changed. Needs the running game |
| B2 | A recomp of the Xbox 360 version, for PC | Out of scope: that is a different binary and a different project |
| B3 | A Windows version | Out of scope: the port is built on Metal and Apple frameworks |
| B4 | A PC version (the same request as B3) | Out of scope |
| B5 | GFWL achievements are not recorded locally, and there is no unlock toast | Not implemented. The port answers Live offline; achievements are not part of RecompIV |
| B6 | "Now playing": the radio's song and artist are not shown while driving | Not implemented |
| B7 | Corruption in the windshield during rain | Not changed. Renderer, needs the running game |
| B8 | Mirrors in the strip club are broken | Not changed. Needs the running game |
| B9 | DualSense support is thinner than expected | Already in the port (Extras tab, off by default); what is asked for is more than the port does. Not extended here |
| B10 | No manual shader compilation in the iPhone and iPad launchers | Not implemented. iOS launcher work, needs a device |
| B11 | No native tvOS launcher | Not implemented. Needs an Apple TV |
| B12 | No comparable warm Metal benchmarks or sampled-depth results | Not done. Needs the game and the hardware the numbers are about |
| B13 | The episode chooser does not appear | Mostly explained: the port says when an episode's folder has no `E1_List.txt`/`E2_List.txt` (the usual cause) and `tools/doctor.sh` warns about it before the build. The chooser's own logic is unchanged ([report](https://github.com/Awis13/liberty-pro-max/issues/51)) |
| B14 | A lamp's shadow vanishes while its light still shines at night | Addressed in the port by `night_shadow_slots` (`GTAIV_NIGHT_SHADOW_STABLE`, on by default), with `tests/night_shadow_slots_test.cpp`. Left as it is ([report](https://github.com/Awis13/liberty-pro-max/issues/50)) |
| B15 | No language selection in the Mac, iPhone or iPad launcher | Not implemented. The game's own language menu and the system language are what exist |
| B16 | TBoGT's pause menu plays IV's menu music | Not changed. Needs the running game |

The two links above are the only ones kept: those reports carry the
reproduction detail, so they are worth reading before anyone tries a fix.
Bugs in RecompIV's own tooling go to
[this repository's issues](https://github.com/wojakbro/recompiv/issues).

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
