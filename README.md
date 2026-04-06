# DRMG - Doom Random Monster Generator

DRMG generates randomized DECORATE monster variants for [UZDoom](https://zdoom.org/), packaged as PK3 files. Each variant gets randomized stats (health, speed, pain chance), attack parameters, visual effects (translations, render styles, blood color), behavioral properties, and optional flags — creating unique encounters every time you play.

## Features

- **18 supported monsters** covering all enemies from Ultimate Doom and Doom 2
- **Faithful attack types** for every monster — hitscan bursts, projectile volleys, melee combos, charge attacks, homing tracers, archvile fire, pain elemental spawning, and more
- **Multi-prong projectile spreads** — monsters with projectile attacks have a chance to fire 3-way or 5-way volleys
- **Seeded RNG** for fully reproducible output
- **Spawner actors** (`--replaces`) that drop into any map and randomly select a variant at load time
- **Doom version filtering** — generate for Ultimate Doom or Doom 2 monster sets
- **Health economy balancing** — tougher variants automatically drop health pickups to compensate
- **Randomized visuals** — color translations, render styles (translucent, fuzzy, stencil), scaled sizes, and blood colors
- **Optional flags** — AMBUSH, QUICKTORETALIATE, MISSILEMORE, speed modifiers, and per-monster extras rolled independently

## Supported Monsters

| Ultimate Doom | Doom 2 Additions |
|---|---|
| Zombie Man | Chaingun Guy |
| Shotgun Guy | Hell Knight |
| Imp | Arachnotron |
| Demon | Mancubus |
| Spectre | Revenant |
| Lost Soul | Arch-Vile |
| Cacodemon | Pain Elemental |
| Baron of Hell | Wolfenstein SS |
| Spider Mastermind | |
| Cyberdemon | |

## Installation

### Pre-built binary

Download `drmg.exe` from the [Releases](https://github.com/mridlen/drmg/releases) page.

### Build from source

Requires [Crystal](https://crystal-lang.org/) 1.19+.

```bash
shards install
shards build --release
```

The binary will be at `bin/drmg`.

## Usage

```
drmg [options]
```

### Options

| Flag | Description | Default |
|---|---|---|
| `--monsters MONSTERS` | Monster selection — `all` or comma-separated `id:count` pairs | `all` |
| `--variants COUNT` | Number of variants per monster | `1` |
| `--seed SEED` | Integer RNG seed for reproducible output | random |
| `--output PATH` | Output PK3 file path | `./drmg_output.pk3` |
| `--replaces` | Generate spawner actors that replace original monsters | off |
| `--doom VERSION` | `1` for Ultimate Doom only, `2` for all monsters | `2` |
| `-h`, `--help` | Show detailed help | |

### Examples

```bash
# Generate 1 variant of every Doom 2 monster
drmg

# 5 variants per monster with a fixed seed
drmg --variants 5 --seed 42

# Only Imps and Demons, custom counts
drmg --monsters imp:3,demon:2

# Ultimate Doom monsters with spawner replacements
drmg --replaces --doom 1

# Full generation for a mod
drmg --monsters all --variants 10 --replaces --output mymod.pk3
```

### Loading in UZDoom

```bash
uzdoom -file drmg_output.pk3
```

Or drag and drop the PK3 onto `uzdoom.exe`.

When using `--replaces`, the spawner actors automatically replace the original monsters in any map. Without `--replaces`, the generated actors can be placed manually in a map editor (e.g., Ultimate Doom Builder).

## How It Works

1. **Templates** define each monster's base stats, valid ranges, attack type, drop tables, sprites, sounds, and flags
2. **Generator** rolls randomized values within those ranges using seeded RNG, including stats, attacks, visuals, and behavioral properties
3. **DecorateWriter** renders valid UZDoom DECORATE lump text for each variant, plus any custom projectile/tracer actors they need
4. **Pk3Writer** packages the DECORATE lump into a PK3 (ZIP) file ready for UZDoom

## Development

```bash
# Run tests
crystal spec

# Build debug
shards build

# Build release
shards build --release
```

## License

[MIT](LICENSE)

## Author

[Mark Ridlen](https://github.com/mridlen)
