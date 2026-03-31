# DRMG — Actor Properties Feature: Design Spec

**Date:** 2026-03-31

---

## Overview

Expand the set of randomized properties on each `MonsterVariant` to cover behavioral numeric properties (mass, gravity, reaction time, etc.), scale (with proportional radius/height derivation), render style (with alpha and stencil color), and blood color. All new properties follow the existing nilable-range pattern: a nil range on the template means the property is not rolled and the parent actor's inherited value is used.

---

## New Template Fields (`MonsterTemplate`)

All new fields are nilable. A `nil` value means "don't roll this property for variants; let it inherit from the base actor."

### Behavioral Ranges

| Field | Type | DECORATE property |
|---|---|---|
| `mass_range` | `Range(Int32, Int32)?` | `Mass` |
| `gravity_range` | `Range(Float64, Float64)?` | `Gravity` |
| `reaction_time_range` | `Range(Int32, Int32)?` | `ReactionTime` |
| `pain_threshold_range` | `Range(Int32, Int32)?` | `PainThreshold` |
| `threshold_range` | `Range(Int32, Int32)?` | `Threshold` |
| `min_missile_chance_range` | `Range(Int32, Int32)?` | `MinMissileChance` |
| `max_target_dist_range` | `Range(Float64, Float64)?` | `MaxTargetRange` |
| `melee_dist_range` | `Range(Float64, Float64)?` | `MeleeRange` |
| `damage_multiply_range` | `Range(Float64, Float64)?` | `DamageMultiply` |

### Scale Range

```crystal
scale_range : Range(Float64, Float64)?
```

Valid values: `0.5..2.0`. Values outside this range should not be used in monster definitions. When a scale is rolled, `Radius` and `Height` are derived from the template's `fixed_fields` base values multiplied by the scale factor:

```
radius = (fixed_fields.radius * scale).round.to_i
height = (fixed_fields.height * scale).round.to_i
```

### Render Style Pool

```crystal
render_styles : Array(RenderStyleEntry)?
```

A weighted pool of render style options. One is selected per variant using weighted random selection. If nil, no render style properties are written.

New struct `RenderStyleEntry` (added to `src/monster_template.cr`):

```crystal
struct RenderStyleEntry
  getter style : String                             # "Normal", "Translucent", "Fuzzy", "Shadow", "Stencil"
  getter weight : Float64                           # relative weight for selection
  getter alpha_range : Range(Float64, Float64)?     # Translucent and Stencil only
  getter stencil_colors : Array(String)?            # Stencil only; hex strings e.g. "FF0000"

  def initialize(@style, @weight, @alpha_range = nil, @stencil_colors = nil)
  end
end
```

Valid styles: `"Normal"`, `"Translucent"`, `"Fuzzy"`, `"Shadow"`, `"Stencil"`.

- `"Normal"` — no alpha or stencil color written
- `"Translucent"` — requires `alpha_range`; writes `RenderStyle Translucent` + `Alpha N`
- `"Fuzzy"` — no alpha or stencil color written
- `"Shadow"` — no alpha or stencil color written
- `"Stencil"` — requires `alpha_range` and `stencil_colors`; writes `RenderStyle Stencil` + `Alpha N` + `StencilColor "RRGGBB"`

Example monster file usage:

```crystal
render_styles: [
  RenderStyleEntry.new("Normal",      0.60),
  RenderStyleEntry.new("Translucent", 0.20, alpha_range: (0.4..0.9)),
  RenderStyleEntry.new("Fuzzy",       0.10),
  RenderStyleEntry.new("Shadow",      0.08),
  RenderStyleEntry.new("Stencil",     0.07, alpha_range: (0.5..1.0), stencil_colors: ["FF0000", "00FF00", "0000FF"]),
]
```

### Blood Color

No template field. Every variant has a 50% chance of rolling a random blood color. The other 50% inherits the default blood color (nothing written to output).

---

## New Variant Fields (`MonsterVariant`)

All new fields are nilable. Nil = omit from DECORATE output.

| Field | Type | Notes |
|---|---|---|
| `mass` | `Int32?` | |
| `gravity` | `Float64?` | |
| `reaction_time` | `Int32?` | |
| `pain_threshold` | `Int32?` | |
| `threshold` | `Int32?` | |
| `min_missile_chance` | `Int32?` | |
| `max_target_range` | `Float64?` | Rolled from `max_target_dist_range` |
| `melee_range` | `Float64?` | Rolled from `melee_dist_range` |
| `damage_multiply` | `Float64?` | |
| `scale` | `Float64?` | |
| `radius` | `Int32?` | Present only when scale is rolled |
| `height` | `Int32?` | Present only when scale is rolled |
| `render_style` | `String?` | e.g. `"Translucent"` |
| `alpha` | `Float64?` | Present when render_style is Translucent or Stencil |
| `stencil_color` | `String?` | Present when render_style is Stencil |
| `blood_color` | `String?` | Format: `"RR GG BB"` decimal integers; nil = inherit default |

---

## Generator Changes (`src/generator.cr`)

After existing stat and flag rolling, add:

### Behavioral properties

For each nilable range on the template, roll if present:

```crystal
mass          = template.mass_range.try { |r| rng.rand(r) }
gravity       = template.gravity_range.try { |r| rng.rand(r.begin..r.end) }
reaction_time = template.reaction_time_range.try { |r| rng.rand(r) }
pain_threshold = template.pain_threshold_range.try { |r| rng.rand(r) }
threshold     = template.threshold_range.try { |r| rng.rand(r) }
min_missile_chance = template.min_missile_chance_range.try { |r| rng.rand(r) }
max_target_range   = template.max_target_dist_range.try { |r| rng.rand(r.begin..r.end) }
melee_range_val    = template.melee_dist_range.try { |r| rng.rand(r.begin..r.end) }
damage_multiply    = template.damage_multiply_range.try { |r| rng.rand(r.begin..r.end) }
```

### Scale, Radius, Height

```crystal
scale  = template.scale_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(2) }
radius = scale.try { |s| (template.fixed_fields.radius * s).round.to_i }
height = scale.try { |s| (template.fixed_fields.height * s).round.to_i }
```

### Render style

If `template.render_styles` is present and non-empty:

1. Sum all weights
2. Roll `roll = rng.rand * total_weight`
3. Walk the list accumulating weight until the cumulative weight exceeds `roll` — that entry is selected
4. If selected style has `alpha_range`, roll alpha from it
5. If selected style has `stencil_colors`, pick one via `stencil_colors.sample(rng)`
6. If selected style is `"Normal"`, set `render_style = nil` (nothing to write)

```crystal
render_style   : String?  = nil
alpha          : Float64? = nil
stencil_color  : String?  = nil

if styles = template.render_styles
  total = styles.sum(&.weight)
  roll  = rng.rand * total
  accum = 0.0
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
```

### Blood color

```crystal
blood_color =
  if rng.rand < 0.5
    r = rng.rand(256)
    g = rng.rand(256)
    b = rng.rand(256)
    "#{r} #{g} #{b}"
  end
```

---

## DecorateWriter Changes (`src/decorate_writer.cr`)

New properties are written after `PainChance` and flags, before `Translation`. Each is omitted if nil. Full proposed output order:

```
Health N
Speed N
PainChance N
+FLAG
Scale N
Radius N
Height N
Mass N
Gravity N
ReactionTime N
PainThreshold N
Threshold N
MinMissileChance N
MaxTargetRange N
MeleeRange N
DamageMultiply N
RenderStyle Name
Alpha N
StencilColor "RRGGBB"
BloodColor "RR GG BB"
Translation "..."
DropItem "..." N
States { ... }
```

`StencilColor` uses hex format (e.g. `"FF0000"`). `BloodColor` uses space-separated decimal integers (e.g. `"200 20 20"`), per GZDoom DECORATE syntax.

---

## Files Changed

| File | Change |
|---|---|
| `src/monster_template.cr` | Add `RenderStyleEntry` struct; add 11 nilable range fields + `render_styles` to `MonsterTemplate`; add 17 nilable fields to `MonsterVariant` |
| `src/generator.cr` | Roll behavioral props, scale, render style, blood color after flags |
| `src/decorate_writer.cr` | Write new properties in defined order, omitting nils |
| `src/monsters/*.cr` (all 19) | All new `MonsterTemplate` fields default to `nil`; no changes required unless monster author adds ranges |
| `spec/generator_spec.cr` | Add tests for each new rolling path |
| `spec/decorate_writer_spec.cr` | Add tests for new property rendering |
| `spec/monster_template_spec.cr` | Update `MonsterTemplate.new` construction if needed |
