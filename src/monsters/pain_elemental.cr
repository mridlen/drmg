# src/monsters/pain_elemental.cr
require "../monster_template"

# PainElemental — vanilla health 400, spawns Lost Souls
PAIN_ELEMENTAL = MonsterTemplate.new(
  id: "pain_elemental",
  actor_name: "PainElemental",
  base_health: 400,
  health_range: (200..4000),
  speed_range: (4..20),
  pain_chance_range: (50..255),
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
    radius: 31,
    height: 56,
    flags: ["+FLOAT", "+NOGRAVITY"],
    see_sound: "pain/sight",
    attack_sound: "pain/attack",
    pain_sound: "pain/pain",
    death_sound: "pain/death",
    active_sound: "pain/active",
    sprite_prefix: "PAIN"
  ),
  extra_flags: [] of FlagEntry
)
