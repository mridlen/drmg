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

  def initialize(
    @id, @actor_name, @base_health,
    @health_range, @speed_range, @pain_chance_range,
    @attack, @drop_table, @translations, @fixed_fields
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

  def initialize(
    @name, @health, @speed, @pain_chance,
    @attack, @drop_items, @translation, @template
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
