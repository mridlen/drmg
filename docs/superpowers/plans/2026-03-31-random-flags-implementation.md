# Random Flags Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add randomly rolled optional DECORATE flags to each generated `MonsterVariant`, driven by a global pool of curated flags with per-flag probabilities, plus per-monster extra flag lists.

**Architecture:** `FlagEntry` struct and flag pool constants are added to `monster_template.cr`. `MonsterTemplate` gains `extra_flags`. `MonsterVariant` gains `flags`. The generator rolls the global pool + speed pair + extra flags after stats. The DECORATE writer renders them after `PainChance`. All 19 monster files gain `extra_flags: [] of FlagEntry`.

**Tech Stack:** Crystal 1.19.1, existing project at `c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg/`

---

## File Map

| File | Change |
|---|---|
| `src/monster_template.cr` | Add `FlagEntry` struct; add `OPTIONAL_FLAGS`, `SPEED_FLAGS` constants; add `extra_flags` to `MonsterTemplate`; add `flags` to `MonsterVariant` |
| `src/generator.cr` | Add flag rolling after stat rolling; pass `flags:` into `MonsterVariant.new` |
| `src/decorate_writer.cr` | Render flags after `PainChance` line |
| `src/monsters/*.cr` (all 19) | Add `extra_flags: [] of FlagEntry` to each `MonsterTemplate.new` call |
| `spec/monster_template_spec.cr` | Add `extra_flags:` to `MonsterTemplate.new` call |
| `spec/generator_spec.cr` | Add `extra_flags:` to all `MonsterTemplate.new` calls; add new flag rolling tests |
| `spec/decorate_writer_spec.cr` | Add `extra_flags:` to `MonsterTemplate.new` calls; add `flags:` to `MonsterVariant.new` calls; add flag rendering tests |

---

## Task 1: Add FlagEntry, constants, and new fields to monster_template.cr; update all callers

**Files:**
- Modify: `src/monster_template.cr`
- Modify: `src/generator.cr` (placeholder only — full logic in Task 2)
- Modify: `spec/monster_template_spec.cr`
- Modify: `spec/generator_spec.cr`
- Modify: `spec/decorate_writer_spec.cr`
- Modify: all 19 `src/monsters/*.cr`

- [ ] **Step 1: Run current specs to confirm baseline**

```bash
cd c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg
crystal spec
```

Expected: `17 examples, 0 failures`

- [ ] **Step 2: Add FlagEntry struct, OPTIONAL_FLAGS, SPEED_FLAGS, and update MonsterTemplate/MonsterVariant in `src/monster_template.cr`**

Replace the entire contents of `src/monster_template.cr` with:

```crystal
# src/monster_template.cr

# ---------- Fixed (non-randomized) actor properties ----------

struct FixedFields
  getter radius : Int32
  getter height : Int32
  getter flags : Array(String)
  getter see_sound : String
  getter attack_sound : String
  getter pain_sound : String
  getter death_sound : String
  getter active_sound : String
  getter sprite_prefix : String  # 4-char sprite name (e.g. "POSS", "SPOS", "TROO")

  def initialize(
    @radius, @height, @flags,
    @see_sound, @attack_sound, @pain_sound, @death_sound, @active_sound,
    @sprite_prefix
  )
  end
end

# ---------- Randomizable attack parameters ----------

struct AttackParams
  getter bullet_count_range : Range(Int32, Int32)
  getter damage_range : Range(Int32, Int32)
  getter spread_range : Range(Float64, Float64)

  def initialize(@bullet_count_range, @damage_range, @spread_range)
  end
end

# ---------- Drop table ----------

struct DropEntry
  getter item : String
  getter weight : Int32

  def initialize(@item, @weight)
  end
end

struct DropTable
  getter low : Array(DropEntry)
  getter mid : Array(DropEntry)
  getter high : Array(DropEntry)

  def initialize(@low, @mid, @high)
  end
end

# ---------- Optional flag entry ----------

struct FlagEntry
  getter flag : String
  getter chance : Float64  # 0.0 = never, 1.0 = always

  def initialize(@flag, @chance)
  end
end

# ---------- Monster template ----------

struct MonsterTemplate
  getter id : String
  getter actor_name : String
  getter base_health : Int32
  getter health_range : Range(Int32, Int32)
  getter speed_range : Range(Int32, Int32)
  getter pain_chance_range : Range(Int32, Int32)
  getter attack : AttackParams
  getter drop_table : DropTable
  getter translations : Array(String)
  getter fixed_fields : FixedFields
  getter extra_flags : Array(FlagEntry)

  def initialize(
    @id, @actor_name, @base_health,
    @health_range, @speed_range, @pain_chance_range,
    @attack, @drop_table, @translations, @fixed_fields,
    @extra_flags
  )
  end
end

# ---------- Resolved (rolled) values ----------

struct ResolvedAttack
  getter bullet_count : Int32
  getter damage : Int32
  getter spread : Float64

  def initialize(@bullet_count, @damage, @spread)
  end
end

struct ResolvedDropItem
  getter item : String
  getter weight : Int32

  def initialize(@item, @weight)
  end
end

struct MonsterVariant
  getter name : String
  getter health : Int32
  getter speed : Int32
  getter pain_chance : Int32
  getter attack : ResolvedAttack
  getter drop_items : Array(ResolvedDropItem)
  getter translation : String
  getter template : MonsterTemplate
  getter flags : Array(String)

  def initialize(
    @name, @health, @speed, @pain_chance,
    @attack, @drop_items, @translation, @template,
    @flags
  )
  end
end

# ---------- Shared translation presets ----------
# These use DECORATE translation syntax: "source_range=dest_range"
# Doom's red palette indices are 176-191. Other ranges map to different colors.

TRANSLATIONS = [
  "176:191=112:127",  # red -> green
  "176:191=200:215",  # red -> blue
  "176:191=96:111",   # red -> grey
  "176:191=160:175",  # red -> orange
  "176:191=224:239",  # red -> yellow
  "176:191=144:159",  # red -> brown
  "176:191=240:247",  # red -> teal
  "176:191=64:79",    # red -> dark brown
]

# ---------- Global optional flag pool ----------
# Each flag is rolled independently per variant using its chance value.

OPTIONAL_FLAGS = [
  FlagEntry.new("+AMBUSH",           0.20),  # deaf until line of sight
  FlagEntry.new("+LOOKALLAROUND",    0.25),  # no blind spots
  FlagEntry.new("+QUICKTORETALIATE", 0.20),  # immediately turns on new attackers
  FlagEntry.new("+FRIGHTENED",       0.15),  # runs away but still fights back
  FlagEntry.new("+FRIGHTENING",      0.05),  # other monsters flee from this variant
  FlagEntry.new("+AVOIDMELEE",       0.15),  # backs away from close combat
  FlagEntry.new("+JUMPDOWN",         0.20),  # willing to jump off ledges to chase
  FlagEntry.new("+DONTTHRUST",       0.10),  # not knocked back by explosions
  FlagEntry.new("+DROPOFF",          0.15),  # freely walks off ledges
  FlagEntry.new("+AVOIDHAZARDS",     0.20),  # actively avoids crushing ceilings
  FlagEntry.new("+HARMFRIENDS",      0.10),  # projectiles hurt allied monsters
  FlagEntry.new("+SHADOW",           0.10),  # partial invisibility
  FlagEntry.new("+NORADIUSDMG",      0.15),  # immune to explosion splash damage
  FlagEntry.new("+NOPAIN",           0.08),  # never flinches
  FlagEntry.new("+NOINFIGHTING",     0.10),  # never turns on other monsters
  FlagEntry.new("+FORCEINFIGHTING",  0.08),  # always infights regardless of map setting
  FlagEntry.new("+BRIGHT",           0.10),  # all frames render at full brightness
  FlagEntry.new("-FLOORCLIP",        0.08),  # hovers slightly above liquid floors
]

# ---------- Speed flag pair (mutually exclusive) ----------
# Roll once: fast (0.0-0.15), slow (0.15-0.30), neither (0.30-1.0)

SPEED_FLAGS = {
  fast: FlagEntry.new("+ALWAYSFAST", 0.15),
  slow: FlagEntry.new("+NEVERFAST",  0.15),
}
```

- [ ] **Step 3: Update `src/generator.cr` to pass `flags: [] of String` placeholder**

This keeps the project compiling until Task 2 adds full flag rolling. Replace the `MonsterVariant.new(...)` call in `src/generator.cr`:

```crystal
      variants << MonsterVariant.new(
        name: name,
        health: health,
        speed: speed,
        pain_chance: pain_chance,
        attack: ResolvedAttack.new(bullet_count, damage, spread),
        drop_items: drop_items,
        translation: translation,
        template: template,
        flags: [] of String
      )
```

- [ ] **Step 4: Update `spec/monster_template_spec.cr` — add `extra_flags:` to MonsterTemplate.new**

Replace the `MonsterTemplate.new(...)` call in the `"holds all required fields"` test:

```crystal
    template = MonsterTemplate.new(
      id: "zombie_man",
      actor_name: "ZombieMan",
      base_health: 20,
      health_range: (10..500),
      speed_range: (4..20),
      pain_chance_range: (50..255),
      attack: attack,
      drop_table: drop_table,
      translations: TRANSLATIONS,
      fixed_fields: fixed,
      extra_flags: [] of FlagEntry
    )
```

- [ ] **Step 5: Update `spec/generator_spec.cr` — add `extra_flags:` to all MonsterTemplate.new calls**

There are 4 `MonsterTemplate.new(...)` calls in generator_spec.cr. Add `extra_flags: [] of FlagEntry` as the last named argument to each. The `test_template` helper becomes:

```crystal
def test_template
  fixed = FixedFields.new(
    radius: 20, height: 56, flags: ["+FLOORCLIP"],
    see_sound: "grunt/sight", attack_sound: "grunt/attack",
    pain_sound: "grunt/pain", death_sound: "grunt/death",
    active_sound: "grunt/active", sprite_prefix: "POSS"
  )
  attack = AttackParams.new(
    bullet_count_range: (1..3),
    damage_range: (3..15),
    spread_range: (11.25..22.5)
  )
  drop_table = DropTable.new(
    low: [DropEntry.new(item: "Clip", weight: 255)],
    mid: [DropEntry.new(item: "Clip", weight: 255), DropEntry.new(item: "ClipBox", weight: 128)],
    high: [DropEntry.new(item: "Clip", weight: 255), DropEntry.new(item: "ClipBox", weight: 255)]
  )
  MonsterTemplate.new(
    id: "zombie_man",
    actor_name: "ZombieMan",
    base_health: 20,
    health_range: (10..500),
    speed_range: (4..20),
    pain_chance_range: (50..255),
    attack: attack,
    drop_table: drop_table,
    translations: TRANSLATIONS,
    fixed_fields: fixed,
    extra_flags: [] of FlagEntry
  )
end
```

The three stub `MonsterTemplate.new(...)` calls in the drop tier tests each become (example for the low-tier test):

```crystal
    template = MonsterTemplate.new(
      id: "test", actor_name: "Test", base_health: 20,
      health_range: (10..10),
      speed_range: (8..8), pain_chance_range: (200..200),
      attack: attack, drop_table: drop_table,
      translations: ["176:191=112:127"], fixed_fields: fixed,
      extra_flags: [] of FlagEntry
    )
```

Apply the same `extra_flags: [] of FlagEntry` addition to the mid-tier and high-tier stub templates.

- [ ] **Step 6: Update `spec/decorate_writer_spec.cr` — add `extra_flags:` and `flags:`**

In `test_variant`, update the `MonsterTemplate.new(...)` call:

```crystal
  template = MonsterTemplate.new(
    id: "zombie_man", actor_name: "ZombieMan", base_health: 20,
    health_range: (10..500), speed_range: (4..20), pain_chance_range: (50..255),
    attack: attack_params, drop_table: drop_table,
    translations: TRANSLATIONS, fixed_fields: fixed,
    extra_flags: [] of FlagEntry
  )
```

Update the `MonsterVariant.new(...)` call in `test_variant`:

```crystal
  MonsterVariant.new(
    name: "ZombieMan_1",
    health: 347,
    speed: 14,
    pain_chance: 88,
    attack: ResolvedAttack.new(3, 8, 22.5),
    drop_items: [ResolvedDropItem.new("Clip", 255), ResolvedDropItem.new("ClipBox", 140)],
    translation: "176:191=112:127",
    template: template,
    flags: [] of String
  )
```

In the `"renders multiple variants"` test, update `template2`'s `MonsterTemplate.new(...)`:

```crystal
    template2 = MonsterTemplate.new(
      id: "zombie_man", actor_name: "ZombieMan", base_health: 20,
      health_range: (10..500), speed_range: (4..20), pain_chance_range: (50..255),
      attack: attack_params, drop_table: drop_table,
      translations: ["176:191=112:127"], fixed_fields: fixed,
      extra_flags: [] of FlagEntry
    )
```

Update `v2`'s `MonsterVariant.new(...)`:

```crystal
    v2 = MonsterVariant.new(
      name: "ZombieMan_2", health: 100, speed: 10, pain_chance: 150,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [ResolvedDropItem.new("Clip", 255)],
      translation: "176:191=112:127",
      template: template2,
      flags: [] of String
    )
```

- [ ] **Step 7: Update all 19 monster files — add `extra_flags: [] of FlagEntry`**

For each file in `src/monsters/`, add `extra_flags: [] of FlagEntry` as the last argument to `MonsterTemplate.new(...)`. The closing `)` moves down one line.

Example — `src/monsters/zombie_man.cr` becomes:

```crystal
# src/monsters/zombie_man.cr
require "../monster_template"

# ZombieMan — vanilla health 20, pistol attack
ZOMBIE_MAN = MonsterTemplate.new(
  id: "zombie_man",
  actor_name: "ZombieMan",
  base_health: 20,
  health_range: (10..500),
  speed_range: (4..20),
  pain_chance_range: (50..255),
  attack: AttackParams.new(
    bullet_count_range: (1..3),
    damage_range: (3..15),
    spread_range: (5.6..22.5)
  ),
  drop_table: DropTable.new(
    low: [DropEntry.new("Clip", 255)],
    mid: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 128)],
    high: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 255)]
  ),
  translations: TRANSLATIONS,
  fixed_fields: FixedFields.new(
    radius: 20,
    height: 56,
    flags: ["+FLOORCLIP"],
    see_sound: "grunt/sight",
    attack_sound: "grunt/attack",
    pain_sound: "grunt/pain",
    death_sound: "grunt/death",
    active_sound: "grunt/active",
    sprite_prefix: "POSS"
  ),
  extra_flags: [] of FlagEntry
)
```

Apply this same change to all 18 remaining monster files. Only the last two lines of the `MonsterTemplate.new(...)` call change — remove the `)` after `sprite_prefix: "..."` and add:
```
  ),
  extra_flags: [] of FlagEntry
)
```

- [ ] **Step 8: Run full spec suite**

```bash
crystal spec
```

Expected: `17 examples, 0 failures`

- [ ] **Step 9: Commit**

```bash
git add src/monster_template.cr src/generator.cr spec/ src/monsters/
git commit -m "feat: add FlagEntry struct, OPTIONAL_FLAGS, SPEED_FLAGS; wire extra_flags and flags fields"
```

---

## Task 2: Implement flag rolling in Generator

**Files:**
- Modify: `src/generator.cr`
- Modify: `spec/generator_spec.cr`

- [ ] **Step 1: Write failing tests for flag rolling**

Add these tests to the end of `spec/generator_spec.cr` (inside the `describe Generator do` block, before its closing `end`):

```crystal
  it "rolls extra_flags with chance 1.0 always onto the variant" do
    fixed = FixedFields.new(
      radius: 20, height: 56, flags: [] of String,
      see_sound: "", attack_sound: "", pain_sound: "", death_sound: "", active_sound: "",
      sprite_prefix: ""
    )
    attack = AttackParams.new((1..1), (5..5), (11.25..11.25))
    drop_table = DropTable.new(
      low: [] of DropEntry, mid: [] of DropEntry, high: [] of DropEntry
    )
    template = MonsterTemplate.new(
      id: "test", actor_name: "Test", base_health: 20,
      health_range: (20..20), speed_range: (8..8), pain_chance_range: (200..200),
      attack: attack, drop_table: drop_table,
      translations: ["176:191=112:127"], fixed_fields: fixed,
      extra_flags: [FlagEntry.new("+SHADOW", 1.0)]
    )
    rng = Random.new(1)
    variants = Generator.generate(template, count: 5, rng: rng)
    variants.each do |v|
      v.flags.should contain "+SHADOW"
    end
  end

  it "never rolls extra_flags with chance 0.0" do
    fixed = FixedFields.new(
      radius: 20, height: 56, flags: [] of String,
      see_sound: "", attack_sound: "", pain_sound: "", death_sound: "", active_sound: "",
      sprite_prefix: ""
    )
    attack = AttackParams.new((1..1), (5..5), (11.25..11.25))
    drop_table = DropTable.new(
      low: [] of DropEntry, mid: [] of DropEntry, high: [] of DropEntry
    )
    template = MonsterTemplate.new(
      id: "test", actor_name: "Test", base_health: 20,
      health_range: (20..20), speed_range: (8..8), pain_chance_range: (200..200),
      attack: attack, drop_table: drop_table,
      translations: ["176:191=112:127"], fixed_fields: fixed,
      extra_flags: [FlagEntry.new("+SHADOW", 0.0)]
    )
    rng = Random.new(1)
    variants = Generator.generate(template, count: 10, rng: rng)
    variants.each do |v|
      v.flags.should_not contain "+SHADOW"
    end
  end

  it "never produces both +ALWAYSFAST and +NEVERFAST on the same variant" do
    rng = Random.new(42)
    variants = Generator.generate(test_template, count: 100, rng: rng)
    variants.each do |v|
      has_fast = v.flags.includes?("+ALWAYSFAST")
      has_slow = v.flags.includes?("+NEVERFAST")
      (has_fast && has_slow).should be_false
    end
  end

  it "flags are deterministic with the same seed" do
    rng1 = Random.new(777)
    rng2 = Random.new(777)
    v1 = Generator.generate(test_template, count: 5, rng: rng1)
    v2 = Generator.generate(test_template, count: 5, rng: rng2)
    v1.map(&.flags).should eq v2.map(&.flags)
  end
```

- [ ] **Step 2: Run to confirm the new tests fail**

```bash
crystal spec spec/generator_spec.cr
```

Expected: the 4 new tests fail because `v.flags` is always `[] of String` (placeholder).

- [ ] **Step 3: Implement flag rolling in `src/generator.cr`**

Replace the entire contents of `src/generator.cr` with:

```crystal
# src/generator.cr
require "./monster_template"

module Generator
  # Generates `count` randomized variants of `template` using `rng`.
  def self.generate(template : MonsterTemplate, count : Int32, rng : Random) : Array(MonsterVariant)
    variants = [] of MonsterVariant

    count.times do |i|
      # ---------- Roll stats within template ranges ----------
      health = rng.rand(template.health_range)
      speed = rng.rand(template.speed_range)
      pain_chance = rng.rand(template.pain_chance_range)

      # ---------- Roll attack parameters ----------
      bullet_count = rng.rand(template.attack.bullet_count_range)
      damage = rng.rand(template.attack.damage_range)

      spread_min = template.attack.spread_range.begin
      spread_max = template.attack.spread_range.end
      spread = spread_min + rng.rand * (spread_max - spread_min)
      spread = spread.round(2)

      # ---------- Select translation ----------
      translation = template.translations.sample(rng)

      # ---------- Resolve drop tier based on health vs base ----------
      drop_items = resolve_drops(template, health)

      # ---------- Roll optional flags ----------
      rolled_flags = [] of String

      # Roll each global flag independently
      OPTIONAL_FLAGS.each do |entry|
        rolled_flags << entry.flag if rng.rand < entry.chance
      end

      # Roll speed pair (mutually exclusive: fast, slow, or neither)
      speed_roll = rng.rand
      if speed_roll < SPEED_FLAGS[:fast].chance
        rolled_flags << SPEED_FLAGS[:fast].flag
      elsif speed_roll < SPEED_FLAGS[:fast].chance + SPEED_FLAGS[:slow].chance
        rolled_flags << SPEED_FLAGS[:slow].flag
      end

      # Roll per-monster extra flags
      template.extra_flags.each do |entry|
        rolled_flags << entry.flag if rng.rand < entry.chance
      end

      # ---------- Build variant name ----------
      name = "#{template.actor_name}_#{i + 1}"

      variants << MonsterVariant.new(
        name: name,
        health: health,
        speed: speed,
        pain_chance: pain_chance,
        attack: ResolvedAttack.new(bullet_count, damage, spread),
        drop_items: drop_items,
        translation: translation,
        template: template,
        flags: rolled_flags
      )
    end

    variants
  end

  # ---------- Drop tier resolution ----------

  private def self.resolve_drops(template : MonsterTemplate, health : Int32) : Array(ResolvedDropItem)
    tier =
      if health > template.base_health * 3
        template.drop_table.high
      elsif health > (template.base_health * 1.5).to_i
        template.drop_table.mid
      else
        template.drop_table.low
      end

    tier.map { |entry| ResolvedDropItem.new(item: entry.item, weight: entry.weight) }
  end
end
```

- [ ] **Step 4: Run full spec suite**

```bash
crystal spec
```

Expected: `21 examples, 0 failures` (17 existing + 4 new)

- [ ] **Step 5: Commit**

```bash
git add src/generator.cr spec/generator_spec.cr
git commit -m "feat: add flag rolling to Generator (global pool, speed pair, extra_flags)"
```

---

## Task 3: Render flags in DecorateWriter

**Files:**
- Modify: `src/decorate_writer.cr`
- Modify: `spec/decorate_writer_spec.cr`

- [ ] **Step 1: Write failing tests**

Add these tests to `spec/decorate_writer_spec.cr` inside the `describe DecorateWriter do` block, before its closing `end`. Also update `test_variant` to accept an optional flags argument:

First, replace the `test_variant` helper at the top of `spec/decorate_writer_spec.cr` with a version that accepts flags:

```crystal
def test_variant(flags : Array(String) = [] of String)
  fixed = FixedFields.new(
    radius: 20, height: 56, flags: ["+FLOORCLIP"],
    see_sound: "grunt/sight", attack_sound: "grunt/attack",
    pain_sound: "grunt/pain", death_sound: "grunt/death",
    active_sound: "grunt/active", sprite_prefix: "POSS"
  )
  attack_params = AttackParams.new((1..3), (3..15), (11.25..22.5))
  drop_table = DropTable.new(
    low: [DropEntry.new("Clip", 255)],
    mid: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 128)],
    high: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 255)]
  )
  template = MonsterTemplate.new(
    id: "zombie_man", actor_name: "ZombieMan", base_health: 20,
    health_range: (10..500), speed_range: (4..20), pain_chance_range: (50..255),
    attack: attack_params, drop_table: drop_table,
    translations: TRANSLATIONS, fixed_fields: fixed,
    extra_flags: [] of FlagEntry
  )
  MonsterVariant.new(
    name: "ZombieMan_1",
    health: 347,
    speed: 14,
    pain_chance: 88,
    attack: ResolvedAttack.new(3, 8, 22.5),
    drop_items: [ResolvedDropItem.new("Clip", 255), ResolvedDropItem.new("ClipBox", 140)],
    translation: "176:191=112:127",
    template: template,
    flags: flags
  )
end
```

Then add these new tests inside `describe DecorateWriter do`:

```crystal
  it "renders flags after PainChance when present" do
    output = DecorateWriter.render([test_variant(["+SHADOW", "+LOOKALLAROUND"])])
    output.should contain "  +SHADOW\n"
    output.should contain "  +LOOKALLAROUND\n"
    # flags should appear after PainChance
    pain_pos = output.index("PainChance").not_nil!
    shadow_pos = output.index("+SHADOW").not_nil!
    shadow_pos.should be > pain_pos
  end

  it "renders nothing extra when flags list is empty" do
    output = DecorateWriter.render([test_variant([] of String)])
    output.should_not contain "+SHADOW"
    output.should_not contain "+NOPAIN"
    output.should_not contain "+BRIGHT"
  end

  it "renders a minus flag correctly" do
    output = DecorateWriter.render([test_variant(["-FLOORCLIP"])])
    output.should contain "  -FLOORCLIP\n"
  end
```

- [ ] **Step 2: Run to confirm new tests fail**

```bash
crystal spec spec/decorate_writer_spec.cr
```

Expected: the 3 new tests fail (flags not rendered yet; the empty-flags test may pass trivially — the other two will fail).

- [ ] **Step 3: Implement flag rendering in `src/decorate_writer.cr`**

Replace the entire contents of `src/decorate_writer.cr` with:

```crystal
# src/decorate_writer.cr
require "./monster_template"

module DecorateWriter
  # Renders an array of MonsterVariant instances to a DECORATE lump string.
  def self.render(variants : Array(MonsterVariant)) : String
    String.build do |io|
      variants.each_with_index do |v, idx|
        io << "\n" if idx > 0
        render_variant(io, v)
      end
    end
  end

  private def self.render_variant(io : IO, v : MonsterVariant)
    # --- ACTOR header ---
    io << "ACTOR #{v.name} : #{v.template.actor_name}\n"
    io << "{\n"

    # --- Core stats ---
    io << "  Health #{v.health}\n"
    io << "  Speed #{v.speed}\n"
    io << "  PainChance #{v.pain_chance}\n"

    # --- Optional flags ---
    v.flags.each do |flag|
      io << "  #{flag}\n"
    end

    # --- Translation ---
    io << "  Translation \"#{v.translation}\"\n"

    # --- Drop items ---
    v.drop_items.each do |drop|
      io << "  DropItem \"#{drop.item}\" #{drop.weight}\n"
    end

    # --- Override Missile state to use A_CustomBulletAttack ---
    # A_CustomBulletAttack signature: (spread, vspread, numbullets, damage, pufftype)
    spread = v.attack.spread
    bullets = v.attack.bullet_count
    damage = v.attack.damage
    sprite = v.template.fixed_fields.sprite_prefix

    io << "  States\n"
    io << "  {\n"
    io << "  Missile:\n"
    io << "    #{sprite} E 10 A_FaceTarget\n"
    io << "    #{sprite} F 8 A_CustomBulletAttack(#{spread}, 0.0, #{bullets}, #{damage}, \"BulletPuff\")\n"
    io << "    #{sprite} E 8\n"
    io << "    Goto See\n"
    io << "  }\n"
    io << "}\n"
  end
end
```

- [ ] **Step 4: Run full spec suite**

```bash
crystal spec
```

Expected: `24 examples, 0 failures` (21 from previous tasks + 3 new)

- [ ] **Step 5: Run a smoke test to see flags in real output**

```bash
./drmg --monsters zombie_man:3 --seed 42 --output smoke_flags.pk3
crystal eval "
require \"compress/zip\"
Compress::Zip::File.open(\"smoke_flags.pk3\") do |zip|
  zip.entries.each do |e|
    puts zip.open(e.filename, &.gets_to_end)
  end
end
"
rm smoke_flags.pk3
```

Expected: 3 ZombieMan variant ACTOR blocks, some with flag lines between `PainChance` and `Translation`.

- [ ] **Step 6: Commit**

```bash
git add src/decorate_writer.cr spec/decorate_writer_spec.cr
git commit -m "feat: render optional flags in DecorateWriter output"
```

---

## Self-Review

**Spec coverage:**
- `FlagEntry` struct ✓ Task 1
- `OPTIONAL_FLAGS` constant (18 flags) ✓ Task 1
- `SPEED_FLAGS` constant ✓ Task 1
- `extra_flags` on `MonsterTemplate` ✓ Task 1
- `flags` on `MonsterVariant` ✓ Task 1
- All 19 monster files updated ✓ Task 1
- Generator rolls global pool ✓ Task 2
- Generator rolls speed pair (mutually exclusive) ✓ Task 2
- Generator rolls extra_flags ✓ Task 2
- DecorateWriter renders flags after PainChance ✓ Task 3
- Empty flags list renders nothing extra ✓ Task 3
- Minus flag (`-FLOORCLIP`) renders correctly ✓ Task 3

**Placeholder scan:** None found.

**Type consistency:**
- `FlagEntry` defined in Task 1, used in Tasks 1/2 ✓
- `OPTIONAL_FLAGS : Array(FlagEntry)` defined in Task 1, used in Task 2 ✓
- `SPEED_FLAGS : NamedTuple(fast: FlagEntry, slow: FlagEntry)` defined in Task 1, accessed as `SPEED_FLAGS[:fast]` / `SPEED_FLAGS[:slow]` in Task 2 ✓
- `MonsterVariant#flags : Array(String)` defined in Task 1, populated in Task 2, read in Task 3 ✓
