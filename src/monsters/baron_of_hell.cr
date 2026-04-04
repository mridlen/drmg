# src/monsters/baron_of_hell.cr
require "../monster_template"

# BaronOfHell — vanilla health 1000, plasma ball and melee attack
BARON_OF_HELL = MonsterTemplate.new(
  id: "baron_of_hell",
  actor_name: "BaronOfHell",
  base_health: 1000,
  health_range: (500..3000),
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
    see_sound: "baron/sight",
    attack_sound: "baron/attack",
    pain_sound: "baron/pain",
    death_sound: "baron/death",
    active_sound: "baron/active",
    sprite_prefix: "BOSS"
  ),
  extra_flags: [] of FlagEntry,
  combo_attack_params: ComboAttackParams.new(
    projectile_class: "BaronBall",
    projectile_prefix: "BOH",
    projectile_speed_range: (8..25),
    projectile_damage_range: (4..16),
    melee_damage_range: (8..20),       # vanilla: 10 * random(1,8)
    melee_sound: "baron/melee",
    projectile_fast_speed_range: (16..50)
  ),
  multi_prong_params: MultiProngParams.new(
    three_prong_chance: 0.15,
    five_prong_chance: 0.05,
    angle_range: (10.0..25.0)
  )
)
