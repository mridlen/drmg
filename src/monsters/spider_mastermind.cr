# src/monsters/spider_mastermind.cr
require "../monster_template"

# SpiderMastermind — vanilla health 3000, super chaingun attack
SPIDER_MASTERMIND = MonsterTemplate.new(
  id: "spider_mastermind",
  actor_name: "SpiderMastermind",
  base_health: 3000,
  health_range: (1500..9000),
  speed_range: (4..30),
  pain_chance_range: (5..80),
  attack: AttackParams.new(
    bullet_count_range: (1..5),   # vanilla fires 3; burst loop uses rolled value
    damage_range: (3..15),
    spread_range: (5.6..45.0)
  ),
  drop_table: DropTable.new(
    low: [] of DropEntry,
    mid: [] of DropEntry,
    high: [] of DropEntry
  ),
  translations: TRANSLATIONS,
  fixed_fields: FixedFields.new(
    radius: 128,
    height: 100,
    flags: [] of String,
    see_sound: "spider/sight",
    attack_sound: "spider/attack",
    pain_sound: "spider/pain",
    death_sound: "spider/death",
    active_sound: "spider/active",
    sprite_prefix: "SPID"
  ),
  extra_flags: [] of FlagEntry,
  burst_attack_params: BurstAttackParams.new(
    attack_tics_range: (2..10),          # frame duration per shot; lower = faster firing
    attack_sound: "spider/attack",
    face_frame: "A",
    face_tics: 20,
    attack_frame_1: "G",
    attack_frame_2: "H",
    refire_frame: "H",
    refire_function: "A_SpidRefire"
  )
)
