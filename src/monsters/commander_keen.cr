# src/monsters/commander_keen.cr
require "../monster_template"

# CommanderKeen — vanilla health 100, immobile easter egg enemy
COMMANDER_KEEN = MonsterTemplate.new(
  id: "commander_keen",
  actor_name: "CommanderKeen",
  base_health: 100,
  health_range: (50..300),
  speed_range: (0..0),
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
    radius: 16,
    height: 72,
    flags: ["+FLOORCLIP"],
    see_sound: "keen/sight",
    attack_sound: "",
    pain_sound: "keen/pain",
    death_sound: "keen/death",
    active_sound: "keen/active",
    sprite_prefix: "KEEN"
  ),
  extra_flags: [] of FlagEntry
)
