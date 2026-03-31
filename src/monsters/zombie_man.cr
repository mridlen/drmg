# src/monsters/zombie_man.cr
require "../monster_template"

# ZombieMan — vanilla health 20, pistol attack
ZOMBIE_MAN = MonsterTemplate.new(
  id: "zombie_man",
  actor_name: "ZombieMan",
  base_health: 20,
  health_range: (10..500),
  speed_range: (4..20),
  pain_chance_range: (50..255),
  attack: AttackParams.new(
    bullet_count_range: (1..3),
    damage_range: (3..15),
    spread_range: (5.6..22.5)
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
    see_sound: "grunt/sight",
    attack_sound: "grunt/attack",
    pain_sound: "grunt/pain",
    death_sound: "grunt/death",
    active_sound: "grunt/active",
    sprite_prefix: "POSS"
  ),
  extra_flags: [] of FlagEntry
)
