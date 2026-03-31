# src/monsters/cyberdemon.cr
require "../monster_template"

# Cyberdemon — vanilla health 4000, rocket launcher attack
CYBERDEMON = MonsterTemplate.new(
  id: "cyberdemon",
  actor_name: "Cyberdemon",
  base_health: 4000,
  health_range: (2000..40000),
  speed_range: (4..30),
  pain_chance_range: (5..80),
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
    radius: 40,
    height: 110,
    flags: [] of String,
    see_sound: "cyber/sight",
    attack_sound: "cyber/hoof",
    pain_sound: "cyber/pain",
    death_sound: "cyber/death",
    active_sound: "cyber/active",
    sprite_prefix: "CYBR"
  )
)
