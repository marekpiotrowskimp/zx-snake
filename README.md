# zxSnake

Classic Snake game for ZX Spectrum 48K, written in Z80 assembly.

## Quick Start

Requirements: `python3` and the [pasmo](https://pasmo.speccy.org/) Z80 assembler in `PATH` (or `make PASMO=/path/to/pasmo`).

```sh
make
make run
```

The default build creates `build/zxsnake.tap`. Release files are available in `release/` as `.tap` and `.tzx`.

## Gameplay

- 8 hand-crafted levels.
- 3 lives.
- QAOP, WASD, or Kempston joystick controls.
- 4 fruit types with level-based scoring.
- New Game+ after level 8 with increased speed and fruit requirements.

## Controls

- `1` - QAOP: `Q` up, `A` down, `O` left, `P` right.
- `2` - WASD: `W` up, `S` down, `A` left, `D` right.
- `3` - Kempston joystick.

## Build Targets

- `make` / `make all` - build `build/zxsnake.tap` with loading screen.
- `make test` - build `build/test.tap` without loading screen.
- `make release` - build `.tap` and `.tzx` release artifacts.
- `make screen` - generate the loading screen.
- `make run` - open the game in FUSE when available.
- `make clean` - remove build artifacts.

## Project Layout

- `src/main.asm` - main game code and level data.
- `src/sprites.asm` - snake and fruit sprite data.
- `src/font.asm` - font data.
- `gfx/` - loading and menu screens.
- `tools/` - build and conversion utilities.
- `release/` - distributable files and promotional assets.

## Technical Notes

- Start address: `32768`.
- Board size: 16 x 11 tiles, 16 x 16 pixels each.
- Current release version: `1.0`.
- `ST_PAUSED` is defined in code but not exposed in the main gameplay loop.
