# src/monsters/lost_soul.cr
require "../monster_template"

# LostSoul — vanilla health 100, flying skull charge attack
LOST_SOUL = MonsterTemplate.new(
  id: "lost_soul",
  actor_name: "LostSoul",
  base_health: 100,
  health_range: (50..1000),
  speed_range: (4..20),
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
    height: 24,
    flags: ["+FLOAT", "+NOGRAVITY"],
    see_sound: "skull/sight",
    attack_sound: "skull/melee",
    pain_sound: "skull/pain",
    death_sound: "skull/death",
    active_sound: "skull/active",
    sprite_prefix: "SKUL"
  ),
  extra_flags: [] of FlagEntry
)
