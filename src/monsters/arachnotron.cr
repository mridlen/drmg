# src/monsters/arachnotron.cr
require "../monster_template"

# Arachnotron — vanilla health 500, plasma gun attack
ARACHNOTRON = MonsterTemplate.new(
  id: "arachnotron",
  actor_name: "Arachnotron",
  base_health: 500,
  health_range: (250..1500),
  speed_range: (4..30),
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
    radius: 64,
    height: 48,
    flags: [] of String,
    see_sound: "baby/sight",
    attack_sound: "baby/attack",
    pain_sound: "baby/pain",
    death_sound: "baby/death",
    active_sound: "baby/active",
    sprite_prefix: "BSPI"
  ),
  extra_flags: [] of FlagEntry,
  projectile_burst_attack_params: ProjectileBurstAttackParams.new(
    projectile_class: "ArachnotronPlasma",
    projectile_speed_range: (12..40),
    projectile_damage_range: (2..10),
    attack_tics_range: (2..6),             # vanilla: 4
    cooldown_tics_range: (2..6),           # vanilla: 4
    face_frame: "A",
    face_tics: 20,
    attack_frame: "G",
    cooldown_frame: "H",
    refire_frame: "H",
    refire_function: "A_SpidRefire"
  ),
  multi_prong_params: MultiProngParams.new(
    three_prong_chance: 0.20,            # 20% chance of 3-way spread
    five_prong_chance: 0.10,             # 10% chance of 5-way spread
    angle_range: (8.0..20.0)             # degrees between each prong
  )
)
