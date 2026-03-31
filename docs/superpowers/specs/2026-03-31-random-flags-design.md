# DRMG — Random Flags Feature: Design Spec

**Date:** 2026-03-31

---

## Overview

Each generated `MonsterVariant` will now randomly receive zero or more optional DECORATE flags, in addition to its existing randomized stats. Flags are rolled independently, each with its own probability. A global pool covers most monsters; each monster template can also define per-monster extra flags for one-off cases.

---

## Flag Pool

### Global Pool (`OPTIONAL_FLAGS`)

Defined as `Array(FlagEntry)` in `src/monster_template.cr`.

| Flag | Chance | Effect |
|---|---|---|
| `+AMBUSH` | 20% | Deaf until line of sight |
| `+LOOKALLAROUND` | 25% | No blind spots |
| `+QUICKTORETALIATE` | 20% | Immediately turns on new attackers |
| `+FRIGHTENED` | 15% | Runs away but still fights back |
| `+FRIGHTENING` | 5% | Other monsters flee from this variant |
| `+AVOIDMELEE` | 15% | Backs away from close combat |
| `+JUMPDOWN` | 20% | Willing to jump off ledges to chase |
| `+DONTTHRUST` | 10% | Not knocked back by explosions |
| `+DROPOFF` | 15% | Freely walks off ledges |
| `+AVOIDHAZARDS` | 20% | Actively avoids crushing ceilings |
| `+HARMFRIENDS` | 10% | Projectiles hurt allied monsters |
| `+SHADOW` | 10% | Partial invisibility, degrades enemy aim |
| `+NORADIUSDMG` | 15% | Immune to explosion splash damage |
| `+NOPAIN` | 8% | Never flinches |
| `+NOINFIGHTING` | 10% | Never turns on other monsters |
| `+FORCEINFIGHTING` | 8% | Always infights regardless of map setting |
| `+BRIGHT` | 10% | All frames render at full brightness |
| `-FLOORCLIP` | 8% | Hovers slightly above liquid floors |

### Speed Flag Pair (`SPEED_FLAGS`)

`+ALWAYSFAST` and `+NEVERFAST` are mutually exclusive and handled as a paired roll:

```
roll = rng.rand  # 0.0..1.0
if roll < 0.15        → +ALWAYSFAST
elsif roll < 0.30     → +NEVERFAST
else                  → neither
```

This is stored as a separate constant `SPEED_FLAGS` (a named tuple `{fast: FlagEntry, slow: FlagEntry}`) and rolled separately from `OPTIONAL_FLAGS`.

### Per-Monster Extra Flags

Each `MonsterTemplate` has an `extra_flags : Array(FlagEntry)` field. At generation time, extra flags are rolled the same way as global flags and merged into the result. Monster files default to `[] of FlagEntry`.

---

## Data Model Changes

### New: `FlagEntry` struct (in `src/monster_template.cr`)

```crystal
struct FlagEntry
  getter flag : String
  getter chance : Float64  # 0.0 = never, 1.0 = always

  def initialize(@flag, @chance)
  end
end
```

### New: `OPTIONAL_FLAGS` constant (in `src/monster_template.cr`)

```crystal
OPTIONAL_FLAGS = [
  FlagEntry.new("+AMBUSH",            0.20),
  FlagEntry.new("+LOOKALLAROUND",     0.25),
  # ... (full list per table above)
]
```

### New: `SPEED_FLAGS` constant (in `src/monster_template.cr`)

```crystal
SPEED_FLAGS = {
  fast: FlagEntry.new("+ALWAYSFAST", 0.15),
  slow: FlagEntry.new("+NEVERFAST",  0.15),
}
```

### Modified: `MonsterTemplate`

Add field:
```crystal
getter extra_flags : Array(FlagEntry)
```

All 19 monster files default to `extra_flags: [] of FlagEntry`. The `MonsterTemplate` `initialize` method signature gains `@extra_flags` as its last parameter.

### Modified: `MonsterVariant`

Add field:
```crystal
getter flags : Array(String)
```

---

## Generator Changes (`src/generator.cr`)

After rolling stats, roll flags:

```crystal
# Roll global optional flags
rolled_flags = OPTIONAL_FLAGS.select { |e| rng.rand < e.chance }.map(&.flag)

# Roll speed pair (mutually exclusive)
speed_roll = rng.rand
if speed_roll < SPEED_FLAGS[:fast].chance
  rolled_flags << SPEED_FLAGS[:fast].flag
elsif speed_roll < SPEED_FLAGS[:fast].chance + SPEED_FLAGS[:slow].chance
  rolled_flags << SPEED_FLAGS[:slow].flag
end

# Roll per-monster extra flags
template.extra_flags.each do |e|
  rolled_flags << e.flag if rng.rand < e.chance
end
```

Pass `flags: rolled_flags` into `MonsterVariant.new`.

---

## DecorateWriter Changes (`src/decorate_writer.cr`)

After the `PainChance` line, write each flag:

```
  +SHADOW
  +LOOKALLAROUND
  -FLOORCLIP
```

If `v.flags` is empty, nothing is written.

---

## DECORATE Output Example

```
ACTOR ZombieMan_3 : ZombieMan
{
  Health 347
  Speed 14
  PainChance 88
  +SHADOW
  +LOOKALLAROUND
  Translation "176:191=112:127"
  DropItem "Clip" 255
  States
  {
  Missile:
    POSS E 10 A_FaceTarget
    POSS F 8 A_CustomBulletAttack(22.5, 0.0, 3, 8, "BulletPuff")
    POSS E 8
    Goto See
  }
}
```

---

## Files Changed

| File | Change |
|---|---|
| `src/monster_template.cr` | Add `FlagEntry`, `OPTIONAL_FLAGS`, `SPEED_FLAGS`; add `extra_flags` to `MonsterTemplate`; add `flags` to `MonsterVariant` |
| `src/generator.cr` | Roll flags after stats; pass into `MonsterVariant` |
| `src/decorate_writer.cr` | Render flags after `PainChance` |
| `src/monsters/*.cr` (all 19) | Add `extra_flags: [] of FlagEntry` to each template |
| `spec/generator_spec.cr` | Add tests for flag rolling, speed pair exclusivity, extra_flags |
| `spec/decorate_writer_spec.cr` | Add tests for flag rendering |
| `spec/monster_template_spec.cr` | Update `FixedFields` and `MonsterTemplate` construction to include `extra_flags` |
