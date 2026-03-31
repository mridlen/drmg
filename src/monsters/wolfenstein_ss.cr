# src/monsters/wolfenstein_ss.cr
require "../monster_template"

# WolfensteinSS — vanilla health 50, rifle attack
WOLFENSTEIN_SS = MonsterTemplate.new(
  id: "wolfenstein_ss",
  actor_name: "WolfensteinSS",
  base_health: 50,
  health_range: (25..500),
  speed_range: (4..20),
  pain_chance_range: (50..255),
  attack: AttackParams.new(
    bullet_count_range: (1..5),
    damage_range: (3..15),
    spread_range: (5.6..45.0)
  ),
  drop_table: DropTable.new(
    low: [DropEntry.new("Clip", 255)],
    mid: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 128)],
    high: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 255)]
  ),
  translations: TRANSLATIONS,
  fixed_fields: FixedFields.new(
    radius: 20,
    height: 56,
    flags: ["+FLOORCLIP"],
    see_sound: "wolfss/sight",
    attack_sound: "wolfss/attack",
    pain_sound: "wolfss/pain",
    death_sound: "wolfss/death",
    active_sound: "wolfss/active",
    sprite_prefix: "SSWV"
  ),
  extra_flags: [] of FlagEntry
)
