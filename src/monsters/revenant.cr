# src/monsters/revenant.cr
require "../monster_template"

# Revenant — vanilla health 300, homing rockets and melee attack
REVENANT = MonsterTemplate.new(
  id: "revenant",
  actor_name: "Revenant",
  base_health: 300,
  health_range: (150..900),
  speed_range: (4..30),
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
    radius: 20,
    height: 64,
    flags: ["+FLOORCLIP"],
    see_sound: "skeleton/sight",
    attack_sound: "skeleton/attack",
    pain_sound: "skeleton/pain",
    death_sound: "skeleton/death",
    active_sound: "skeleton/active",
    sprite_prefix: "SKEL"
  ),
  extra_flags: [] of FlagEntry
)
