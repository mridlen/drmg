# src/monsters/chain_gun_guy.cr
require "../monster_template"

# ChaingunGuy — vanilla health 70, chaingun attack
CHAIN_GUN_GUY = MonsterTemplate.new(
  id: "chain_gun_guy",
  actor_name: "ChaingunGuy",
  base_health: 70,
  health_range: (35..210),
  speed_range: (4..20),
  pain_chance_range: (50..255),
  attack: AttackParams.new(
    bullet_count_range: (1..1),   # 1 bullet per shot; burst comes from refire loop
    damage_range: (3..15),
    spread_range: (5.6..45.0)
  ),
  drop_table: DropTable.new(
    low: [DropEntry.new("Chaingun", 255)],
    mid: [DropEntry.new("Chaingun", 255), DropEntry.new("ClipBox", 128)],
    high: [DropEntry.new("Chaingun", 255), DropEntry.new("ClipBox", 255)]
  ),
  translations: TRANSLATIONS,
  fixed_fields: FixedFields.new(
    radius: 20,
    height: 56,
    flags: ["+FLOORCLIP"],
    see_sound: "chainguy/sight",
    attack_sound: "chainguy/attack",
    pain_sound: "chainguy/pain",
    death_sound: "chainguy/death",
    active_sound: "chainguy/active",
    sprite_prefix: "CPOS"
  ),
  extra_flags: [] of FlagEntry,
  burst_attack_params: BurstAttackParams.new(
    attack_tics_range: (2..10),          # frame duration per shot; lower = faster firing
    attack_sound: "chainguy/attack"
  )
)
