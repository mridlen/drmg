# src/monsters/imp.cr
require "../monster_template"

# Imp — vanilla health 60, claw/fireball attack
IMP = MonsterTemplate.new(
  id: "imp",
  actor_name: "DoomImp",
  base_health: 60,
  health_range: (30..180),
  speed_range: (4..20),
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
    height: 56,
    flags: ["+FLOORCLIP"],
    see_sound: "imp/sight",
    attack_sound: "imp/attack",
    pain_sound: "imp/pain",
    death_sound: "imp/death",
    active_sound: "imp/active",
    sprite_prefix: "TROO"
  ),
  extra_flags: [] of FlagEntry,
  combo_attack_params: ComboAttackParams.new(
    projectile_class: "DoomImpBall",
    projectile_speed_range: (5..20),
    projectile_damage_range: (1..8),
    melee_damage_range: (1..6),
    melee_sound: "imp/melee",
    projectile_fast_speed_range: (10..40)
  ),
  multi_prong_params: MultiProngParams.new(
    three_prong_chance: 0.15,
    five_prong_chance: 0.05,
    angle_range: (10.0..25.0)
  )
)
