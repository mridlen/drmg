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

# ---------- Combo (melee + projectile) attack parameters ----------

struct ComboAttackParams
  getter projectile_class : String                        # base class e.g. "DoomImpBall"
  getter projectile_prefix : String?                      # short tag e.g. "HK" → "BaronBall_HK_1"; nil = no prefix
  getter projectile_speed_range : Range(Int32, Int32)
  getter projectile_fast_speed_range : Range(Int32, Int32)?  # optional FastSpeed
  getter projectile_damage_range : Range(Int32, Int32)
  getter melee_damage_range : Range(Int32, Int32)         # multiplier for random(1,8)
  getter melee_sound : String

  def initialize(
    @projectile_class, @projectile_speed_range, @projectile_damage_range,
    @melee_damage_range, @melee_sound, @projectile_prefix = nil, @projectile_fast_speed_range = nil
  )
  end
end

# ---------- Burst (refire loop) hitscan attack parameters ----------

struct BurstAttackParams
  getter attack_tics_range : Range(Int32, Int32)  # frame duration per attack frame
  getter attack_sound : String                     # sound played before each shot
  getter face_frame : String                       # sprite frame for A_FaceTarget (e.g. "E" or "A")
  getter face_tics : Int32                         # tics for face target frame
  getter attack_frame_1 : String                   # first attack sprite frame (e.g. "F" or "G")
  getter attack_frame_2 : String                   # second attack sprite frame (e.g. "E" or "H")
  getter refire_frame : String                     # sprite frame for refire check
  getter refire_function : String                  # e.g. "A_CPosRefire" or "A_SpidRefire"

  def initialize(
    @attack_tics_range, @attack_sound,
    @face_frame = "E", @face_tics = 10,
    @attack_frame_1 = "F", @attack_frame_2 = "E",
    @refire_frame = "F", @refire_function = "A_CPosRefire"
  )
  end
end

# ---------- Projectile burst (refire loop) attack parameters ----------

struct ProjectileBurstAttackParams
  getter projectile_class : String                    # base class e.g. "ArachnotronPlasma"
  getter projectile_speed_range : Range(Int32, Int32)
  getter projectile_damage_range : Range(Int32, Int32)
  getter attack_tics_range : Range(Int32, Int32)      # frame duration for attack frame
  getter cooldown_tics_range : Range(Int32, Int32)    # frame duration for cooldown frame
  getter face_frame : String                          # sprite frame for A_FaceTarget
  getter face_tics : Int32                            # tics for face target frame
  getter attack_frame : String                        # sprite frame for A_CustomMissile
  getter cooldown_frame : String                      # sprite frame for cooldown
  getter refire_frame : String                        # sprite frame for refire check
  getter refire_function : String                     # e.g. "A_SpidRefire"

  def initialize(
    @projectile_class, @projectile_speed_range, @projectile_damage_range,
    @attack_tics_range, @cooldown_tics_range,
    @face_frame, @face_tics,
    @attack_frame, @cooldown_frame,
    @refire_frame, @refire_function
  )
  end
end

# ---------- Fat (3-volley) attack parameters ----------

struct FatAttackParams
  getter projectile_class : String                    # base class e.g. "FatShot"
  getter projectile_speed_range : Range(Int32, Int32)
  getter projectile_damage_range : Range(Int32, Int32)

  def initialize(@projectile_class, @projectile_speed_range, @projectile_damage_range)
  end
end

# ---------- Vile (archvile fire) attack parameters ----------

struct VileAttackParams
  getter initial_damage_range : Range(Int32, Int32)         # direct hit damage
  getter blast_damage_range : Range(Int32, Int32)           # explosion damage at tracer
  getter blast_radius_range : Range(Int32, Int32)           # explosion radius (higher = more infighting)
  getter thrust_factor_range : Range(Float64, Float64)      # vertical launch force on target

  def initialize(@initial_damage_range, @blast_damage_range, @blast_radius_range, @thrust_factor_range)
  end
end

# ---------- Cyber (3-rocket volley) attack parameters ----------

struct CyberAttackParams
  getter fire_tics_range : Range(Int32, Int32)   # tics on A_CyberAttack frames; vanilla: 12
  getter face_tics_range : Range(Int32, Int32)   # tics on A_FaceTarget re-aim frames; vanilla: 12

  def initialize(@fire_tics_range, @face_tics_range)
  end
end

# ---------- Skull (charge) attack parameters ----------

struct SkullAttackParams
  getter charge_speed_range : Range(Int32, Int32)  # A_SkullAttack speed; vanilla: 20
  getter damage_range : Range(Int32, Int32)        # actor Damage property; vanilla: 3 → 3*random(1,8)
  getter face_tics_range : Range(Int32, Int32)     # windup tics before charge; vanilla: 10

  def initialize(@charge_speed_range, @damage_range, @face_tics_range)
  end
end

# ---------- Revenant (homing tracer + melee) attack parameters ----------

struct RevenantAttackParams
  getter tracer_speed_range : Range(Int32, Int32)       # projectile speed; vanilla: 10
  getter tracer_damage_range : Range(Int32, Int32)      # projectile damage; vanilla: 10
  getter melee_damage_range : Range(Int32, Int32)       # melee punch damage; vanilla: random(1,10)*6 = 6-60
  getter melee_sound : String

  def initialize(@tracer_speed_range, @tracer_damage_range, @melee_damage_range, @melee_sound)
  end
end

# ---------- Pain (Lost Soul spawner) attack parameters ----------

struct PainAttackParams
  # Stats for the spawned Lost Soul variant
  getter skull_health_range : Range(Int32, Int32)         # spawned soul health
  getter skull_speed_range : Range(Int32, Int32)           # spawned soul movement speed
  getter skull_charge_speed_range : Range(Int32, Int32)    # A_SkullAttack speed
  getter skull_damage_range : Range(Int32, Int32)          # actor Damage property
  getter skull_face_tics_range : Range(Int32, Int32)       # windup tics before charge
  getter dual_chance : Float64                             # chance of A_DualPainAttack (0.0-1.0)

  def initialize(
    @skull_health_range, @skull_speed_range,
    @skull_charge_speed_range, @skull_damage_range, @skull_face_tics_range,
    @dual_chance = 0.0
  )
  end
end

# ---------- Multi-prong (spread) missile parameters ----------

struct MultiProngParams
  getter three_prong_chance : Float64                    # chance of 3-way spread
  getter five_prong_chance : Float64                     # chance of 5-way spread (rolled if 3-prong fails)
  getter angle_range : Range(Float64, Float64)           # spread angle between each prong

  def initialize(@three_prong_chance, @five_prong_chance, @angle_range)
  end
end

# ---------- Melee-only attack parameters ----------

struct MeleeAttackParams
  getter damage_range : Range(Int32, Int32)  # rolled per variant as A_CustomMeleeAttack damage
  getter melee_sound : String
  getter miss_sound : String

  def initialize(@damage_range, @melee_sound, @miss_sound = "")
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

  # Optional combo attack (melee + projectile); nil = use hitscan AttackParams instead
  getter combo_attack_params : ComboAttackParams?

  # Optional burst (refire loop) hitscan attack; nil = use single-shot hitscan
  getter burst_attack_params : BurstAttackParams?

  # Optional projectile burst (refire loop); nil = not a projectile-burst attacker
  getter projectile_burst_attack_params : ProjectileBurstAttackParams?

  # Optional fat (3-volley) attack; nil = not a Mancubus-style attacker
  getter fat_attack_params : FatAttackParams?

  # Optional skull (charge) attack; nil = not a Lost Soul-style charger
  getter skull_attack_params : SkullAttackParams?

  # Optional revenant (homing tracer + melee) attack; nil = not a Revenant-style attacker
  getter revenant_attack_params : RevenantAttackParams?

  # Optional pain (Lost Soul spawner) attack; nil = not a Pain Elemental-style spawner
  getter pain_attack_params : PainAttackParams?

  # Optional cyber (3-rocket volley) attack; nil = not a Cyberdemon-style attacker
  getter cyber_attack_params : CyberAttackParams?

  # Optional vile (archvile fire) attack; nil = not an archvile-style attacker
  getter vile_attack_params : VileAttackParams?

  # Optional melee-only attack; nil = not a melee-only monster
  getter melee_attack_params : MeleeAttackParams?

  # Optional multi-prong spread for A_CustomMissile attacks; nil = always single shot
  getter multi_prong_params : MultiProngParams?

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
    @combo_attack_params = nil,
    @burst_attack_params = nil,
    @projectile_burst_attack_params = nil,
    @fat_attack_params = nil,
    @skull_attack_params = nil,
    @revenant_attack_params = nil,
    @pain_attack_params = nil,
    @cyber_attack_params = nil,
    @vile_attack_params = nil,
    @melee_attack_params = nil,
    @multi_prong_params = nil,
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

struct ResolvedComboAttack
  getter projectile_name : String       # e.g. "DoomImpBall_1"
  getter projectile_class : String      # base class e.g. "DoomImpBall" (for ACTOR inheritance)
  getter projectile_speed : Int32
  getter projectile_fast_speed : Int32? # optional FastSpeed
  getter projectile_damage : Int32
  getter melee_damage : Int32           # multiplier for random(1,8) in A_CustomComboAttack
  getter melee_sound : String

  def initialize(
    @projectile_name, @projectile_class, @projectile_speed,
    @projectile_damage, @melee_damage, @melee_sound,
    @projectile_fast_speed = nil
  )
  end
end

struct ResolvedBurstAttack
  getter attack_tics : Int32
  getter attack_sound : String
  getter face_frame : String
  getter face_tics : Int32
  getter attack_frame_1 : String
  getter attack_frame_2 : String
  getter refire_frame : String
  getter refire_function : String

  def initialize(
    @attack_tics, @attack_sound,
    @face_frame, @face_tics,
    @attack_frame_1, @attack_frame_2,
    @refire_frame, @refire_function
  )
  end
end

struct ResolvedProjectileBurstAttack
  getter projectile_name : String     # e.g. "ArachnotronPlasma_1"
  getter projectile_class : String    # base class e.g. "ArachnotronPlasma"
  getter projectile_speed : Int32
  getter projectile_damage : Int32
  getter attack_tics : Int32
  getter cooldown_tics : Int32
  getter face_frame : String
  getter face_tics : Int32
  getter attack_frame : String
  getter cooldown_frame : String
  getter refire_frame : String
  getter refire_function : String

  def initialize(
    @projectile_name, @projectile_class, @projectile_speed, @projectile_damage,
    @attack_tics, @cooldown_tics,
    @face_frame, @face_tics,
    @attack_frame, @cooldown_frame,
    @refire_frame, @refire_function
  )
  end
end

struct ResolvedFatAttack
  getter projectile_name : String    # e.g. "FatShot_1"
  getter projectile_class : String   # base class e.g. "FatShot"
  getter projectile_speed : Int32
  getter projectile_damage : Int32

  def initialize(@projectile_name, @projectile_class, @projectile_speed, @projectile_damage)
  end
end

struct ResolvedMultiProng
  getter prong_count : Int32      # 1 (normal), 3, or 5
  getter spread_angle : Float64   # angle between each prong

  def initialize(@prong_count, @spread_angle)
  end
end

struct ResolvedRevenantAttack
  getter tracer_name : String         # e.g. "RevenantTracer_1"
  getter tracer_speed : Int32
  getter tracer_damage : Int32
  getter melee_damage : Int32
  getter melee_sound : String

  def initialize(@tracer_name, @tracer_speed, @tracer_damage, @melee_damage, @melee_sound)
  end
end

struct ResolvedPainAttack
  getter skull_name : String          # e.g. "LostSoul_PE_1"
  getter skull_health : Int32
  getter skull_speed : Int32
  getter skull_charge_speed : Int32
  getter skull_damage : Int32
  getter skull_face_tics : Int32
  getter dual : Bool                    # true = A_DualPainAttack (spawns two at ±45°)

  def initialize(
    @skull_name, @skull_health, @skull_speed,
    @skull_charge_speed, @skull_damage, @skull_face_tics,
    @dual = false
  )
  end
end

struct ResolvedSkullAttack
  getter charge_speed : Int32
  getter damage : Int32
  getter face_tics : Int32

  def initialize(@charge_speed, @damage, @face_tics)
  end
end

struct ResolvedCyberAttack
  getter fire_tics : Int32
  getter face_tics : Int32

  def initialize(@fire_tics, @face_tics)
  end
end

struct ResolvedVileAttack
  getter initial_damage : Int32
  getter blast_damage : Int32
  getter blast_radius : Int32
  getter thrust_factor : Float64

  def initialize(@initial_damage, @blast_damage, @blast_radius, @thrust_factor)
  end
end

struct ResolvedMeleeAttack
  getter damage : Int32
  getter melee_sound : String
  getter miss_sound : String

  def initialize(@damage, @melee_sound, @miss_sound = "")
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
  getter render_style : String?   # nil = omit from DECORATE output (Normal is the base default)
  getter alpha : Float64?         # Translucent or Stencil only
  getter stencil_color : String?  # Stencil only; hex e.g. "FF0000"
  getter blood_color : String?    # "RR GG BB" decimal; nil = inherit default

  # Optional multi-prong spread for A_CustomMissile; nil = single shot
  getter multi_prong : ResolvedMultiProng?

  # Optional combo attack (melee + projectile); nil = use hitscan ResolvedAttack
  getter combo_attack : ResolvedComboAttack?

  # Optional burst (refire loop) hitscan attack; nil = use single-shot hitscan
  getter burst_attack : ResolvedBurstAttack?

  # Optional projectile burst (refire loop); nil = not a projectile-burst attacker
  getter projectile_burst_attack : ResolvedProjectileBurstAttack?

  # Optional fat (3-volley) attack; nil = not a Mancubus-style attacker
  getter fat_attack : ResolvedFatAttack?

  # Optional skull (charge) attack; nil = not a Lost Soul-style charger
  getter skull_attack : ResolvedSkullAttack?

  # Optional revenant (homing tracer + melee) attack; nil = not a Revenant-style attacker
  getter revenant_attack : ResolvedRevenantAttack?

  # Optional pain (Lost Soul spawner) attack; nil = not a Pain Elemental-style spawner
  getter pain_attack : ResolvedPainAttack?

  # Optional cyber (3-rocket volley) attack; nil = not a Cyberdemon-style attacker
  getter cyber_attack : ResolvedCyberAttack?

  # Optional vile (archvile fire) attack; nil = not an archvile-style attacker
  getter vile_attack : ResolvedVileAttack?

  # Optional melee-only attack; nil = not a melee-only monster
  getter melee_attack : ResolvedMeleeAttack?

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
    @blood_color = nil,
    @multi_prong = nil,
    @combo_attack = nil,
    @burst_attack = nil,
    @projectile_burst_attack = nil,
    @fat_attack = nil,
    @skull_attack = nil,
    @revenant_attack = nil,
    @pain_attack = nil,
    @cyber_attack = nil,
    @vile_attack = nil,
    @melee_attack = nil
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
