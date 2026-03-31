# src/monsters/shotgun_guy.cr
require "../monster_template"

# ShotgunGuy — vanilla health 30, shotgun attack
SHOTGUN_GUY = MonsterTemplate.new(
  id: "shotgun_guy",
  actor_name: "ShotgunGuy",
  base_health: 30,
  health_range: (15..300),
  speed_range: (4..20),
  pain_chance_range: (50..255),
  attack: AttackParams.new(
    bullet_count_range: (1..5),
    damage_range: (3..15),
    spread_range: (5.6..45.0)
  ),
  drop_table: DropTable.new(
    low: [DropEntry.new("Shotgun", 255)],
    mid: [DropEntry.new("Shotgun", 255), DropEntry.new("Shell", 128)],
    high: [DropEntry.new("Shotgun", 255), DropEntry.new("ShellBox", 255)]
  ),
  translations: TRANSLATIONS,
  fixed_fields: FixedFields.new(
    radius: 20,
    height: 56,
    flags: ["+FLOORCLIP"],
    see_sound: "shotguy/sight",
    attack_sound: "",
    pain_sound: "shotguy/pain",
    death_sound: "shotguy/death",
    active_sound: "shotguy/active",
    sprite_prefix: "SPOS"
  ),
  extra_flags: [] of FlagEntry
)
