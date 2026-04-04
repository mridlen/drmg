# src/monsters/cacodemon.cr
require "../monster_template"

# Cacodemon — vanilla health 400, floating fireball attack
CACODEMON = MonsterTemplate.new(
  id: "cacodemon",
  actor_name: "Cacodemon",
  base_health: 400,
  health_range: (200..1200),
  speed_range: (4..20),
  pain_chance_range: (50..255),
  attack: AttackParams.new(
    bullet_count_range: (1..3),
    damage_range: (5..20),
    spread_range: (5.6..22.5)
  ),
  drop_table: DropTable.new(
    low: [DropEntry.new("Cell", 255)],
    mid: [DropEntry.new("Cell", 255), DropEntry.new("CellPack", 128)],
    high: [DropEntry.new("Cell", 255), DropEntry.new("CellPack", 255)]
  ),
  translations: TRANSLATIONS,
  fixed_fields: FixedFields.new(
    radius: 31,
    height: 56,
    flags: ["+FLOAT", "+NOGRAVITY"],
    see_sound: "caco/sight",
    attack_sound: "caco/attack",
    pain_sound: "caco/pain",
    death_sound: "caco/death",
    active_sound: "caco/active",
    sprite_prefix: "HEAD"
  ),
  extra_flags: [] of FlagEntry,
  combo_attack_params: ComboAttackParams.new(
    projectile_class: "CacodemonBall",
    projectile_speed_range: (5..20),
    projectile_damage_range: (2..10),
    melee_damage_range: (10..60),        # vanilla: 10 * random(1,6) = 10-60
    melee_sound: "caco/melee",
    projectile_fast_speed_range: (10..40)
  ),
  multi_prong_params: MultiProngParams.new(
    three_prong_chance: 0.15,
    five_prong_chance: 0.05,
    angle_range: (10.0..25.0)
  )
)
