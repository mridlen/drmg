# src/monsters/cacodemon.cr
require "../monster_template"

# Cacodemon — vanilla health 400, floating fireball attack
CACODEMON = MonsterTemplate.new(
  id: "cacodemon",
  actor_name: "Cacodemon",
  base_health: 400,
  health_range: (200..1200),
  speed_range: (4..20),
  pain_chance_range: (50..255),
  attack: AttackParams.new(
    bullet_count_range: (1..3),
    damage_range: (5..20),
    spread_range: (5.6..22.5)
  ),
  drop_table: DropTable.new(
    low: [DropEntry.new("Cell", 255)],
    mid: [DropEntry.new("Cell", 255), DropEntry.new("CellPack", 128)],
    high: [DropEntry.new("Cell", 255), DropEntry.new("CellPack", 255)]
  ),
  translations: TRANSLATIONS,
  fixed_fields: FixedFields.new(
    radius: 31,
    height: 56,
    flags: ["+FLOAT", "+NOGRAVITY"],
    see_sound: "caco/sight",
    attack_sound: "caco/attack",
    pain_sound: "caco/pain",
    death_sound: "caco/death",
    active_sound: "caco/active",
    sprite_prefix: "HEAD"
  ),
  extra_flags: [] of FlagEntry
)
