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
