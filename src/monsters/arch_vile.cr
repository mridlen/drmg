# src/monsters/arch_vile.cr
require "../monster_template"

# ArchVile — vanilla health 700, fire attack and monster resurrection
ARCH_VILE = MonsterTemplate.new(
  id: "arch_vile",
  actor_name: "Archvile",
  base_health: 700,
  health_range: (350..2100),
  speed_range: (4..30),
  pain_chance_range: (10..255),
  attack: AttackParams.new(
    bullet_count_range: (1..3),
    damage_range: (5..20),
    spread_range: (5.6..22.5)
  ),
  drop_table: DropTable.new(
    low: [] of DropEntry,
    mid: [] of DropEntry,
    high: [] of DropEntry
  ),
  translations: TRANSLATIONS,
  fixed_fields: FixedFields.new(
    radius: 20,
    height: 56,
    flags: ["+FLOORCLIP"],
    see_sound: "vile/sight",
    attack_sound: "vile/start",
    pain_sound: "vile/pain",
    death_sound: "vile/death",
    active_sound: "vile/active",
    sprite_prefix: "VILE"
  ),
  extra_flags: [] of FlagEntry
)
