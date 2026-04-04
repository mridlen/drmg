# src/monsters/spectre.cr
require "../monster_template"

# Spectre — vanilla health 150, melee attack (invisible variant of Demon)
SPECTRE = MonsterTemplate.new(
  id: "spectre",
  actor_name: "Spectre",
  base_health: 150,
  health_range: (75..450),
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
    radius: 30,
    height: 56,
    flags: ["+FLOORCLIP"],
    see_sound: "demon/sight",
    attack_sound: "demon/melee",
    pain_sound: "demon/pain",
    death_sound: "demon/death",
    active_sound: "demon/active",
    sprite_prefix: "SARG"
  ),
  extra_flags: [] of FlagEntry,
  melee_attack_params: MeleeAttackParams.new(
    damage_range: (4..40),     # vanilla: 4 * random(1,10) = 4-40
    melee_sound: "demon/melee"
  )
)
