# src/monsters/hell_knight.cr
require "../monster_template"

# HellKnight — vanilla health 500, plasma ball attack
HELL_KNIGHT = MonsterTemplate.new(
  id: "hell_knight",
  actor_name: "HellKnight",
  base_health: 500,
  health_range: (250..1500),
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
  ),
  extra_flags: [] of FlagEntry,
  combo_attack_params: ComboAttackParams.new(
    projectile_class: "BaronBall",
    projectile_prefix: "HK",
    projectile_speed_range: (8..25),
    projectile_damage_range: (3..12),
    melee_damage_range: (5..15),       # vanilla: 10 * random(1,8)
    melee_sound: "baron/melee",
    projectile_fast_speed_range: (16..50)
  ),
  multi_prong_params: MultiProngParams.new(
    three_prong_chance: 0.15,
    five_prong_chance: 0.05,
    angle_range: (10.0..25.0)
  )
)
