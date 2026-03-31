# Actor Properties Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add randomized behavioral properties (mass, gravity, reaction time, etc.), proportional scale with derived radius/height, weighted render style selection, and random blood color to each generated `MonsterVariant`.

**Architecture:** All new `MonsterTemplate` fields are nilable with `nil` defaults, so no monster files need updating. All new `MonsterVariant` fields are nilable with `nil` defaults, so existing spec construction calls need no changes. The generator rolls new values after existing flag rolling; the writer emits them after flags, before Translation.

**Tech Stack:** Crystal 1.19.1, existing project at `c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg/`

---

## File Map

| File | Change |
|---|---|
| `src/monster_template.cr` | Add `RenderStyleEntry` struct; add 11 nilable range fields to `MonsterTemplate`; add 17 nilable fields to `MonsterVariant` |
| `src/generator.cr` | Roll behavioral props, scale, render style, blood color after flag rolling; pass all new fields to `MonsterVariant.new` |
| `src/decorate_writer.cr` | Render new properties in defined order after flags, before Translation |
| `spec/generator_spec.cr` | Add tests for behavioral rolling, scale derivation, render style selection, blood color |
| `spec/decorate_writer_spec.cr` | Add `minimal_template` helper; add tests for each new rendered property |

`src/monsters/*.cr` (all 19) and `spec/monster_template_spec.cr` require **no changes** — all new fields default to `nil`.

---

## Task 1: Update data model in `src/monster_template.cr`

**Files:**
- Modify: `src/monster_template.cr`

- [ ] **Step 1: Run baseline specs**

```bash
cd c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg
crystal spec
```

Expected: `24 examples, 0 failures`

- [ ] **Step 2: Replace `src/monster_template.cr` entirely**

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

# ---------- Render style entry ----------
# Used in MonsterTemplate.render_styles for weighted random render style selection.

struct RenderStyleEntry
  getter style : String                           # "Normal", "Translucent", "Fuzzy", "Shadow", "Stencil"
  getter weight : Float64                         # relative weight; higher = more likely
  getter alpha_range : Range(Float64, Float64)?   # Translucent and Stencil only
  getter stencil_colors : Array(String)?          # Stencil only; hex strings e.g. "FF0000"

  def initialize(@style, @weight, @alpha_range = nil, @stencil_colors = nil)
  end
end

# ---------- Monster template ----------

struct MonsterTemplate
  # Core identity
  getter id : String
  getter actor_name : String
  getter base_health : Int32

  # Required randomizable ranges
  getter health_range : Range(Int32, Int32)
  getter speed_range : Range(Int32, Int32)
  getter pain_chance_range : Range(Int32, Int32)
  getter attack : AttackParams
  getter drop_table : DropTable
  getter translations : Array(String)
  getter fixed_fields : FixedFields
  getter extra_flags : Array(FlagEntry)

  # Optional behavioral ranges (nil = inherit from base actor)
  getter mass_range : Range(Int32, Int32)?
  getter gravity_range : Range(Float64, Float64)?
  getter reaction_time_range : Range(Int32, Int32)?
  getter pain_threshold_range : Range(Int32, Int32)?
  getter threshold_range : Range(Int32, Int32)?
  getter min_missile_chance_range : Range(Int32, Int32)?
  getter max_target_dist_range : Range(Float64, Float64)?
  getter melee_dist_range : Range(Float64, Float64)?
  getter damage_multiply_range : Range(Float64, Float64)?

  # Optional scale range (valid: 0.5..2.0); Radius/Height are derived from fixed_fields base values
  getter scale_range : Range(Float64, Float64)?

  # Optional render style pool; one entry selected per variant by weighted random
  getter render_styles : Array(RenderStyleEntry)?

  def initialize(
    @id, @actor_name, @base_health,
    @health_range, @speed_range, @pain_chance_range,
    @attack, @drop_table, @translations, @fixed_fields,
    @extra_flags,
    @mass_range = nil,
    @gravity_range = nil,
    @reaction_time_range = nil,
    @pain_threshold_range = nil,
    @threshold_range = nil,
    @min_missile_chance_range = nil,
    @max_target_dist_range = nil,
    @melee_dist_range = nil,
    @damage_multiply_range = nil,
    @scale_range = nil,
    @render_styles = nil
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
  # Core rolled stats
  getter name : String
  getter health : Int32
  getter speed : Int32
  getter pain_chance : Int32
  getter attack : ResolvedAttack
  getter drop_items : Array(ResolvedDropItem)
  getter translation : String
  getter template : MonsterTemplate
  getter flags : Array(String)

  # Optional rolled behavioral properties (nil = omit from DECORATE output)
  getter mass : Int32?
  getter gravity : Float64?
  getter reaction_time : Int32?
  getter pain_threshold : Int32?
  getter threshold : Int32?
  getter min_missile_chance : Int32?
  getter max_target_range : Float64?
  getter melee_range : Float64?
  getter damage_multiply : Float64?

  # Optional scale (0.5-2.0); radius/height are proportionally derived from template base values
  getter scale : Float64?
  getter radius : Int32?
  getter height : Int32?

  # Optional render properties
  getter render_style : String?   # nil when Normal or not rolled
  getter alpha : Float64?         # Translucent or Stencil only
  getter stencil_color : String?  # Stencil only; hex e.g. "FF0000"
  getter blood_color : String?    # "RR GG BB" decimal; nil = inherit default

  def initialize(
    @name, @health, @speed, @pain_chance,
    @attack, @drop_items, @translation, @template,
    @flags,
    @mass = nil,
    @gravity = nil,
    @reaction_time = nil,
    @pain_threshold = nil,
    @threshold = nil,
    @min_missile_chance = nil,
    @max_target_range = nil,
    @melee_range = nil,
    @damage_multiply = nil,
    @scale = nil,
    @radius = nil,
    @height = nil,
    @render_style = nil,
    @alpha = nil,
    @stencil_color = nil,
    @blood_color = nil
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

- [ ] **Step 3: Run specs to verify no regressions**

```bash
cd c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg
crystal spec
```

Expected: `24 examples, 0 failures` (all new fields default to nil; no existing call sites need updating)

- [ ] **Step 4: Commit**

```bash
cd c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg
git add src/monster_template.cr
git commit -m "feat: add RenderStyleEntry; add nilable behavioral/scale/render fields to MonsterTemplate and MonsterVariant"
```

---

## Task 2: Generator — roll behavioral properties and scale

**Files:**
- Modify: `src/generator.cr`
- Modify: `spec/generator_spec.cr`

- [ ] **Step 1: Write failing tests for behavioral rolling and scale**

Add these tests to `spec/generator_spec.cr` inside the `describe Generator do` block, before its closing `end`:

```crystal
  it "rolls mass within mass_range when set" do
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
      extra_flags: [] of FlagEntry,
      mass_range: (50..200)
    )
    rng = Random.new(1)
    variants = Generator.generate(template, count: 10, rng: rng)
    variants.each do |v|
      m = v.mass.not_nil!
      m.should be >= 50
      m.should be <= 200
    end
  end

  it "leaves mass nil when mass_range is not set" do
    rng = Random.new(1)
    variants = Generator.generate(test_template, count: 5, rng: rng)
    variants.each do |v|
      v.mass.should be_nil
    end
  end

  it "derives radius and height proportionally from scale" do
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
      extra_flags: [] of FlagEntry,
      scale_range: (2.0..2.0)
    )
    rng = Random.new(1)
    variants = Generator.generate(template, count: 1, rng: rng)
    v = variants[0]
    v.scale.should eq 2.0
    v.radius.should eq 40   # 20 * 2.0
    v.height.should eq 112  # 56 * 2.0
  end

  it "leaves scale, radius, height nil when scale_range is not set" do
    rng = Random.new(1)
    variants = Generator.generate(test_template, count: 3, rng: rng)
    variants.each do |v|
      v.scale.should be_nil
      v.radius.should be_nil
      v.height.should be_nil
    end
  end
```

- [ ] **Step 2: Run to confirm new tests fail**

```bash
cd c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg
crystal spec spec/generator_spec.cr
```

Expected: 4 new tests fail (mass, scale fields are always nil in current generator)

- [ ] **Step 3: Replace `src/generator.cr` entirely**

```crystal
# src/generator.cr
require "./monster_template"

module Generator
  # Generates `count` randomized variants of `template` using `rng`.
  def self.generate(template : MonsterTemplate, count : Int32, rng : Random) : Array(MonsterVariant)
    variants = [] of MonsterVariant

    count.times do |i|
      # ---------- Roll stats within template ranges ----------
      health      = rng.rand(template.health_range)
      speed       = rng.rand(template.speed_range)
      pain_chance = rng.rand(template.pain_chance_range)

      # ---------- Roll attack parameters ----------
      bullet_count = rng.rand(template.attack.bullet_count_range)
      damage       = rng.rand(template.attack.damage_range)

      spread_min = template.attack.spread_range.begin
      spread_max = template.attack.spread_range.end
      spread     = (spread_min + rng.rand * (spread_max - spread_min)).round(2)

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
      # Probability windows: [0.0, 0.15) = fast, [0.15, 0.30) = slow, [0.30, 1.0) = neither
      speed_roll = rng.rand
      if speed_roll < SPEED_FLAGS[:fast].chance
        rolled_flags << SPEED_FLAGS[:fast].flag
      elsif speed_roll < SPEED_FLAGS[:fast].chance + SPEED_FLAGS[:slow].chance
        rolled_flags << SPEED_FLAGS[:slow].flag
      end

      # Roll per-monster extra flags (appended after global flags; no deduplication)
      template.extra_flags.each do |entry|
        rolled_flags << entry.flag if rng.rand < entry.chance
      end

      # ---------- Roll behavioral properties ----------
      mass               = template.mass_range.try { |r| rng.rand(r) }
      gravity            = template.gravity_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(2) }
      reaction_time      = template.reaction_time_range.try { |r| rng.rand(r) }
      pain_threshold     = template.pain_threshold_range.try { |r| rng.rand(r) }
      threshold          = template.threshold_range.try { |r| rng.rand(r) }
      min_missile_chance = template.min_missile_chance_range.try { |r| rng.rand(r) }
      max_target_range   = template.max_target_dist_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(1) }
      melee_range        = template.melee_dist_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(1) }
      damage_multiply    = template.damage_multiply_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(2) }

      # ---------- Roll scale (valid range 0.5-2.0) ----------
      # Radius and Height are derived proportionally from fixed_fields base values
      scale         = template.scale_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(2) }
      rolled_radius = scale.try { |s| (template.fixed_fields.radius * s).round.to_i }
      rolled_height = scale.try { |s| (template.fixed_fields.height * s).round.to_i }

      # ---------- Build variant name ----------
      name = "#{template.actor_name}_#{i + 1}"

      variants << MonsterVariant.new(
        name:               name,
        health:             health,
        speed:              speed,
        pain_chance:        pain_chance,
        attack:             ResolvedAttack.new(bullet_count, damage, spread),
        drop_items:         drop_items,
        translation:        translation,
        template:           template,
        flags:              rolled_flags,
        mass:               mass,
        gravity:            gravity,
        reaction_time:      reaction_time,
        pain_threshold:     pain_threshold,
        threshold:          threshold,
        min_missile_chance: min_missile_chance,
        max_target_range:   max_target_range,
        melee_range:        melee_range,
        damage_multiply:    damage_multiply,
        scale:              scale,
        radius:             rolled_radius,
        height:             rolled_height
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
cd c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg
crystal spec
```

Expected: `28 examples, 0 failures` (24 existing + 4 new)

- [ ] **Step 5: Commit**

```bash
cd c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg
git add src/generator.cr spec/generator_spec.cr
git commit -m "feat: roll behavioral properties and scale in Generator"
```

---

## Task 3: Generator — roll render style and blood color

**Files:**
- Modify: `src/generator.cr`
- Modify: `spec/generator_spec.cr`

- [ ] **Step 1: Write failing tests for render style and blood color**

Add these tests to `spec/generator_spec.cr` inside the `describe Generator do` block, before its closing `end`:

```crystal
  it "always selects the sole render style when its weight is 1.0" do
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
      extra_flags: [] of FlagEntry,
      render_styles: [RenderStyleEntry.new("Translucent", 1.0, alpha_range: (0.5..0.5))]
    )
    rng = Random.new(1)
    variants = Generator.generate(template, count: 5, rng: rng)
    variants.each do |v|
      v.render_style.should eq "Translucent"
      v.alpha.should eq 0.5
    end
  end

  it "sets render_style nil when Normal is the only style" do
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
      extra_flags: [] of FlagEntry,
      render_styles: [RenderStyleEntry.new("Normal", 1.0)]
    )
    rng = Random.new(1)
    variants = Generator.generate(template, count: 5, rng: rng)
    variants.each do |v|
      v.render_style.should be_nil
      v.alpha.should be_nil
    end
  end

  it "leaves render_style nil when render_styles is not set" do
    rng = Random.new(1)
    variants = Generator.generate(test_template, count: 3, rng: rng)
    variants.each do |v|
      v.render_style.should be_nil
    end
  end

  it "blood_color is deterministic with the same seed" do
    rng1 = Random.new(555)
    rng2 = Random.new(555)
    v1 = Generator.generate(test_template, count: 10, rng: rng1)
    v2 = Generator.generate(test_template, count: 10, rng: rng2)
    v1.map(&.blood_color).should eq v2.map(&.blood_color)
  end

  it "blood_color when set is three space-separated integers 0-255" do
    rng = Random.new(1)
    variants = Generator.generate(test_template, count: 20, rng: rng)
    variants.each do |v|
      if bc = v.blood_color
        parts = bc.split(" ")
        parts.size.should eq 3
        parts.each do |p|
          val = p.to_i
          val.should be >= 0
          val.should be <= 255
        end
      end
    end
  end
```

- [ ] **Step 2: Run to confirm new tests fail**

```bash
cd c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg
crystal spec spec/generator_spec.cr
```

Expected: 5 new tests fail (render_style, blood_color not yet rolled)

- [ ] **Step 3: Replace `src/generator.cr` entirely**

```crystal
# src/generator.cr
require "./monster_template"

module Generator
  # Generates `count` randomized variants of `template` using `rng`.
  def self.generate(template : MonsterTemplate, count : Int32, rng : Random) : Array(MonsterVariant)
    variants = [] of MonsterVariant

    count.times do |i|
      # ---------- Roll stats within template ranges ----------
      health      = rng.rand(template.health_range)
      speed       = rng.rand(template.speed_range)
      pain_chance = rng.rand(template.pain_chance_range)

      # ---------- Roll attack parameters ----------
      bullet_count = rng.rand(template.attack.bullet_count_range)
      damage       = rng.rand(template.attack.damage_range)

      spread_min = template.attack.spread_range.begin
      spread_max = template.attack.spread_range.end
      spread     = (spread_min + rng.rand * (spread_max - spread_min)).round(2)

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
      # Probability windows: [0.0, 0.15) = fast, [0.15, 0.30) = slow, [0.30, 1.0) = neither
      speed_roll = rng.rand
      if speed_roll < SPEED_FLAGS[:fast].chance
        rolled_flags << SPEED_FLAGS[:fast].flag
      elsif speed_roll < SPEED_FLAGS[:fast].chance + SPEED_FLAGS[:slow].chance
        rolled_flags << SPEED_FLAGS[:slow].flag
      end

      # Roll per-monster extra flags (appended after global flags; no deduplication)
      template.extra_flags.each do |entry|
        rolled_flags << entry.flag if rng.rand < entry.chance
      end

      # ---------- Roll behavioral properties ----------
      mass               = template.mass_range.try { |r| rng.rand(r) }
      gravity            = template.gravity_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(2) }
      reaction_time      = template.reaction_time_range.try { |r| rng.rand(r) }
      pain_threshold     = template.pain_threshold_range.try { |r| rng.rand(r) }
      threshold          = template.threshold_range.try { |r| rng.rand(r) }
      min_missile_chance = template.min_missile_chance_range.try { |r| rng.rand(r) }
      max_target_range   = template.max_target_dist_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(1) }
      melee_range        = template.melee_dist_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(1) }
      damage_multiply    = template.damage_multiply_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(2) }

      # ---------- Roll scale (valid range 0.5-2.0) ----------
      # Radius and Height are derived proportionally from fixed_fields base values
      scale         = template.scale_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(2) }
      rolled_radius = scale.try { |s| (template.fixed_fields.radius * s).round.to_i }
      rolled_height = scale.try { |s| (template.fixed_fields.height * s).round.to_i }

      # ---------- Roll render style ----------
      # Weighted selection: sum weights, walk list until cumulative weight exceeds roll.
      # "Normal" is a valid style but writes nothing (render_style stays nil).
      render_style  = nil.as(String?)
      alpha         = nil.as(Float64?)
      stencil_color = nil.as(String?)

      if styles = template.render_styles
        total    = styles.sum(&.weight)
        roll     = rng.rand * total
        accum    = 0.0
        selected = styles.last
        styles.each do |entry|
          accum += entry.weight
          if roll < accum
            selected = entry
            break
          end
        end
        unless selected.style == "Normal"
          render_style  = selected.style
          alpha         = selected.alpha_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(2) }
          stencil_color = selected.stencil_colors.try(&.sample(rng))
        end
      end

      # ---------- Roll blood color (50% chance of random RGB) ----------
      blood_color = nil.as(String?)
      if rng.rand < 0.5
        r_val = rng.rand(256)
        g_val = rng.rand(256)
        b_val = rng.rand(256)
        blood_color = "#{r_val} #{g_val} #{b_val}"
      end

      # ---------- Build variant name ----------
      name = "#{template.actor_name}_#{i + 1}"

      variants << MonsterVariant.new(
        name:               name,
        health:             health,
        speed:              speed,
        pain_chance:        pain_chance,
        attack:             ResolvedAttack.new(bullet_count, damage, spread),
        drop_items:         drop_items,
        translation:        translation,
        template:           template,
        flags:              rolled_flags,
        mass:               mass,
        gravity:            gravity,
        reaction_time:      reaction_time,
        pain_threshold:     pain_threshold,
        threshold:          threshold,
        min_missile_chance: min_missile_chance,
        max_target_range:   max_target_range,
        melee_range:        melee_range,
        damage_multiply:    damage_multiply,
        scale:              scale,
        radius:             rolled_radius,
        height:             rolled_height,
        render_style:       render_style,
        alpha:              alpha,
        stencil_color:      stencil_color,
        blood_color:        blood_color
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
cd c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg
crystal spec
```

Expected: `33 examples, 0 failures` (28 existing + 5 new)

- [ ] **Step 5: Commit**

```bash
cd c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg
git add src/generator.cr spec/generator_spec.cr
git commit -m "feat: roll render style and blood color in Generator"
```

---

## Task 4: Render new properties in DecorateWriter

**Files:**
- Modify: `src/decorate_writer.cr`
- Modify: `spec/decorate_writer_spec.cr`

- [ ] **Step 1: Add `minimal_template` helper and failing tests to `spec/decorate_writer_spec.cr`**

Add this helper function near the top of the file (after the existing `test_variant` helper, before `describe DecorateWriter do`):

```crystal
# Builds a minimal MonsterTemplate suitable for writer-focused tests
def minimal_template
  fixed = FixedFields.new(
    radius: 20, height: 56, flags: [] of String,
    see_sound: "", attack_sound: "", pain_sound: "", death_sound: "", active_sound: "",
    sprite_prefix: "POSS"
  )
  MonsterTemplate.new(
    id: "test", actor_name: "Test", base_health: 20,
    health_range: (20..20), speed_range: (8..8), pain_chance_range: (200..200),
    attack: AttackParams.new((1..1), (5..5), (11.25..11.25)),
    drop_table: DropTable.new(low: [] of DropEntry, mid: [] of DropEntry, high: [] of DropEntry),
    translations: ["176:191=112:127"], fixed_fields: fixed,
    extra_flags: [] of FlagEntry
  )
end
```

Then add these tests inside the `describe DecorateWriter do` block, before its closing `end`:

```crystal
  it "renders Mass when present" do
    v = MonsterVariant.new(
      name: "Test_1", health: 20, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      mass: 150
    )
    output = DecorateWriter.render([v])
    output.should contain "  Mass 150\n"
  end

  it "does not render Mass when nil" do
    output = DecorateWriter.render([test_variant])
    output.should_not contain "Mass"
  end

  it "renders Scale, Radius, Height in order after flags and before Translation" do
    v = MonsterVariant.new(
      name: "Test_1", health: 20, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      scale: 1.5,
      radius: 30,
      height: 84
    )
    output = DecorateWriter.render([v])
    output.should contain "  Scale 1.5\n"
    output.should contain "  Radius 30\n"
    output.should contain "  Height 84\n"
    scale_pos       = output.index("Scale").not_nil!
    radius_pos      = output.index("Radius").not_nil!
    height_pos      = output.index("Height").not_nil!
    translation_pos = output.index("Translation").not_nil!
    scale_pos.should  be < radius_pos
    radius_pos.should be < height_pos
    height_pos.should be < translation_pos
  end

  it "renders RenderStyle and Alpha for Translucent" do
    v = MonsterVariant.new(
      name: "Test_1", health: 20, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      render_style: "Translucent",
      alpha: 0.7
    )
    output = DecorateWriter.render([v])
    output.should contain "  RenderStyle Translucent\n"
    output.should contain "  Alpha 0.7\n"
  end

  it "renders RenderStyle, Alpha, and StencilColor for Stencil" do
    v = MonsterVariant.new(
      name: "Test_1", health: 20, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      render_style: "Stencil",
      alpha: 0.8,
      stencil_color: "FF0000"
    )
    output = DecorateWriter.render([v])
    output.should contain "  RenderStyle Stencil\n"
    output.should contain "  Alpha 0.8\n"
    output.should contain "  StencilColor \"FF0000\"\n"
  end

  it "renders BloodColor when present" do
    v = MonsterVariant.new(
      name: "Test_1", health: 20, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      blood_color: "200 20 20"
    )
    output = DecorateWriter.render([v])
    output.should contain "  BloodColor \"200 20 20\"\n"
  end

  it "renders no extra properties when all new fields are nil" do
    output = DecorateWriter.render([test_variant])
    output.should_not contain "Mass"
    output.should_not contain "Gravity"
    output.should_not contain "Scale"
    output.should_not contain "RenderStyle"
    output.should_not contain "BloodColor"
  end

  it "renders new properties after flags and before Translation" do
    v = MonsterVariant.new(
      name: "Test_1", health: 20, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: ["+SHADOW"] of String,
      mass: 200,
      render_style: "Fuzzy",
      blood_color: "255 0 0"
    )
    output = DecorateWriter.render([v])
    shadow_pos      = output.index("+SHADOW").not_nil!
    mass_pos        = output.index("Mass").not_nil!
    render_pos      = output.index("RenderStyle").not_nil!
    blood_pos       = output.index("BloodColor").not_nil!
    translation_pos = output.index("Translation").not_nil!
    shadow_pos.should      be < mass_pos
    mass_pos.should        be < render_pos
    render_pos.should      be < blood_pos
    blood_pos.should       be < translation_pos
  end
```

- [ ] **Step 2: Run to confirm new tests fail**

```bash
cd c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg
crystal spec spec/decorate_writer_spec.cr
```

Expected: 7 new tests fail (new properties not rendered yet)

- [ ] **Step 3: Replace `src/decorate_writer.cr` entirely**

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

    # --- Scale and proportional collision box ---
    io << "  Scale #{v.scale}\n"   if v.scale
    io << "  Radius #{v.radius}\n" if v.radius
    io << "  Height #{v.height}\n" if v.height

    # --- Behavioral properties ---
    io << "  Mass #{v.mass}\n"                       if v.mass
    io << "  Gravity #{v.gravity}\n"                 if v.gravity
    io << "  ReactionTime #{v.reaction_time}\n"      if v.reaction_time
    io << "  PainThreshold #{v.pain_threshold}\n"    if v.pain_threshold
    io << "  Threshold #{v.threshold}\n"             if v.threshold
    io << "  MinMissileChance #{v.min_missile_chance}\n" if v.min_missile_chance
    io << "  MaxTargetRange #{v.max_target_range}\n" if v.max_target_range
    io << "  MeleeRange #{v.melee_range}\n"          if v.melee_range
    io << "  DamageMultiply #{v.damage_multiply}\n"  if v.damage_multiply

    # --- Render style (Normal writes nothing; Stencil also writes StencilColor) ---
    if rs = v.render_style
      io << "  RenderStyle #{rs}\n"
      io << "  Alpha #{v.alpha}\n" if v.alpha
      if sc = v.stencil_color
        io << "  StencilColor \"#{sc}\"\n"
      end
    end

    # --- Blood color ---
    io << "  BloodColor \"#{v.blood_color}\"\n" if v.blood_color

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
cd c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg
crystal spec
```

Expected: `40 examples, 0 failures` (33 existing + 7 new)

- [ ] **Step 5: Commit**

```bash
cd c:/Users/mridlen/Dropbox/Apps/Doom/DRMG/drmg
git add src/decorate_writer.cr spec/decorate_writer_spec.cr
git commit -m "feat: render behavioral properties, scale, render style, and blood color in DecorateWriter"
```

---

## Self-Review

**Spec coverage:**

| Spec requirement | Task |
|---|---|
| `RenderStyleEntry` struct with style, weight, alpha_range, stencil_colors | Task 1 |
| 11 nilable range fields on `MonsterTemplate` (including scale_range, render_styles) | Task 1 |
| 17 nilable fields on `MonsterVariant` | Task 1 |
| No changes required to any of 19 monster files | Task 1 (all defaults nil) |
| Roll 9 behavioral ranges; nil range → nil field | Task 2 |
| Scale rolled from range; radius/height = base × scale, rounded | Task 2 |
| Render style: weighted selection; Normal → nil render_style | Task 3 |
| Alpha rolled from alpha_range when style is Translucent or Stencil | Task 3 |
| StencilColor picked from stencil_colors array | Task 3 |
| Blood color: 50% chance random RGB 0-255, format "RR GG BB" | Task 3 |
| Output order: flags → Scale/Radius/Height → behavioral → RenderStyle/Alpha/StencilColor → BloodColor → Translation | Task 4 |
| Nil properties omit nothing from output | Task 4 |

**Placeholder scan:** None found.

**Type consistency:**
- `RenderStyleEntry` defined in Task 1, used in Task 3 generator and Task 1 MonsterTemplate ✓
- `template.max_target_dist_range` (template field) → `v.max_target_range` (variant field) → `MaxTargetRange` (DECORATE) — names consistent across all tasks ✓
- `template.melee_dist_range` (template field) → `v.melee_range` (variant field) → `MeleeRange` (DECORATE) ✓
- `rolled_radius` / `rolled_height` local variables in generator → passed as `radius:` / `height:` to MonsterVariant.new ✓
- `stencil_color` format: hex string e.g. `"FF0000"` → written as `StencilColor "FF0000"` ✓
- `blood_color` format: decimal string e.g. `"200 20 20"` → written as `BloodColor "200 20 20"` ✓
