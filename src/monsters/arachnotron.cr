# src/monsters/arachnotron.cr
require "../monster_template"

# Arachnotron — vanilla health 500, plasma gun attack
ARACHNOTRON = MonsterTemplate.new(
  id: "arachnotron",
  actor_name: "Arachnotron",
  base_health: 500,
  health_range: (250..1500),
  speed_range: (4..30),
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
    radius: 64,
    height: 48,
    flags: [] of String,
    see_sound: "baby/sight",
    attack_sound: "baby/attack",
    pain_sound: "baby/pain",
    death_sound: "baby/death",
    active_sound: "baby/active",
    sprite_prefix: "BSPI"
  ),
  extra_flags: [] of FlagEntry
)
