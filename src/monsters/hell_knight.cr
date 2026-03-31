# src/monsters/hell_knight.cr
require "../monster_template"

# HellKnight — vanilla health 500, plasma ball attack
HELL_KNIGHT = MonsterTemplate.new(
  id: "hell_knight",
  actor_name: "HellKnight",
  base_health: 500,
  health_range: (250..5000),
  speed_range: (4..20),
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
    radius: 24,
    height: 64,
    flags: ["+FLOORCLIP"],
    see_sound: "knight/sight",
    attack_sound: "knight/attack",
    pain_sound: "knight/pain",
    death_sound: "knight/death",
    active_sound: "knight/active",
    sprite_prefix: "BOS2"
  )
)
