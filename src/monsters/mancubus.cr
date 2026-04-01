# src/monsters/mancubus.cr
require "../monster_template"

# Mancubus — vanilla health 600, dual flamethrower attack
MANCUBUS = MonsterTemplate.new(
  id: "mancubus",
  actor_name: "Fatso",
  base_health: 600,
  health_range: (300..1800),
  speed_range: (4..20),
  pain_chance_range: (50..255),
  attack: AttackParams.new(
    bullet_count_range: (1..3),
    damage_range: (5..20),
    spread_range: (5.6..22.5)
  ),
  drop_table: DropTable.new(
    low: [DropEntry.new("RocketAmmo", 255)],
    mid: [DropEntry.new("RocketAmmo", 255), DropEntry.new("RocketBox", 128)],
    high: [DropEntry.new("RocketAmmo", 255), DropEntry.new("RocketBox", 255)]
  ),
  translations: TRANSLATIONS,
  fixed_fields: FixedFields.new(
    radius: 48,
    height: 64,
    flags: ["+FLOORCLIP"],
    see_sound: "fatso/sight",
    attack_sound: "fatso/attack",
    pain_sound: "fatso/pain",
    death_sound: "fatso/death",
    active_sound: "fatso/active",
    sprite_prefix: "FATT"
  ),
  extra_flags: [] of FlagEntry
)
