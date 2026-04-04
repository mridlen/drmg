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
  extra_flags: [] of FlagEntry,
  revenant_attack_params: RevenantAttackParams.new(
    tracer_speed_range: (5..20),         # vanilla: 10; faster = harder to dodge
    tracer_damage_range: (5..20),        # vanilla: 10
    melee_damage_range: (6..60),         # vanilla: random(1,10)*6 = 6-60
    melee_sound: "skeleton/melee"
  ),
  multi_prong_params: MultiProngParams.new(
    three_prong_chance: 0.15,            # 15% chance of 3-way homing spread
    five_prong_chance: 0.05,             # 5% chance of 5-way homing spread
    angle_range: (10.0..25.0)            # degrees between each prong
  )
)
