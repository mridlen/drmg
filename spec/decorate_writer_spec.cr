require "./spec_helper"
require "../src/monster_template"
require "../src/decorate_writer"

def test_variant(flags : Array(String) = [] of String)
  fixed = FixedFields.new(
    radius: 20, height: 56, flags: ["+FLOORCLIP"],
    see_sound: "grunt/sight", attack_sound: "grunt/attack",
    pain_sound: "grunt/pain", death_sound: "grunt/death",
    active_sound: "grunt/active", sprite_prefix: "POSS"
  )
  attack_params = AttackParams.new((1..3), (3..15), (11.25..22.5))
  drop_table = DropTable.new(
    low: [DropEntry.new("Clip", 255)],
    mid: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 128)],
    high: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 255)]
  )
  template = MonsterTemplate.new(
    id: "zombie_man", actor_name: "ZombieMan", base_health: 20,
    health_range: (10..500), speed_range: (4..20), pain_chance_range: (50..255),
    attack: attack_params, drop_table: drop_table,
    translations: TRANSLATIONS, fixed_fields: fixed,
    extra_flags: [] of FlagEntry
  )
  MonsterVariant.new(
    name: "ZombieMan_1",
    health: 347,
    speed: 14,
    pain_chance: 88,
    attack: ResolvedAttack.new(3, 8, 22.5),
    drop_items: [ResolvedDropItem.new("Clip", 255), ResolvedDropItem.new("ClipBox", 140)],
    translation: "176:191=112:127",
    template: template,
    flags: flags
  )
end

describe DecorateWriter do
  it "renders the ACTOR header with inheritance" do
    output = DecorateWriter.render([test_variant])
    output.should contain "ACTOR ZombieMan_1 : ZombieMan"
  end

  it "renders Health, Speed, PainChance" do
    output = DecorateWriter.render([test_variant])
    output.should contain "Health 347"
    output.should contain "Speed 14"
    output.should contain "PainChance 88"
  end

  it "renders Translation" do
    output = DecorateWriter.render([test_variant])
    output.should contain "Translation \"176:191=112:127\""
  end

  it "renders DropItem lines" do
    output = DecorateWriter.render([test_variant])
    output.should contain "DropItem \"Clip\" 255"
    output.should contain "DropItem \"ClipBox\" 140"
  end

  it "renders the Missile state block with A_CustomBulletAttack" do
    output = DecorateWriter.render([test_variant])
    output.should contain "A_CustomBulletAttack(22.5, 0.0, 3, 8, \"BulletPuff\")"
  end

  it "renders multiple variants separated by blank lines" do
    v1 = test_variant
    fixed = FixedFields.new(
      radius: 20, height: 56, flags: [] of String,
      see_sound: "", attack_sound: "", pain_sound: "", death_sound: "", active_sound: "",
      sprite_prefix: "POSS"
    )
    attack_params = AttackParams.new((1..1), (5..5), (11.25..11.25))
    drop_table = DropTable.new(
      low: [DropEntry.new("Clip", 255)],
      mid: [DropEntry.new("Clip", 255)],
      high: [DropEntry.new("Clip", 255)]
    )
    template2 = MonsterTemplate.new(
      id: "zombie_man", actor_name: "ZombieMan", base_health: 20,
      health_range: (10..500), speed_range: (4..20), pain_chance_range: (50..255),
      attack: attack_params, drop_table: drop_table,
      translations: ["176:191=112:127"], fixed_fields: fixed,
      extra_flags: [] of FlagEntry
    )
    v2 = MonsterVariant.new(
      name: "ZombieMan_2", health: 100, speed: 10, pain_chance: 150,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [ResolvedDropItem.new("Clip", 255)],
      translation: "176:191=112:127",
      template: template2,
      flags: [] of String
    )
    output = DecorateWriter.render([v1, v2])
    output.should contain "ACTOR ZombieMan_1 : ZombieMan"
    output.should contain "ACTOR ZombieMan_2 : ZombieMan"
  end

  it "renders flags after PainChance when present" do
    output = DecorateWriter.render([test_variant(["+SHADOW", "+LOOKALLAROUND"])])
    output.should contain "  +SHADOW\n"
    output.should contain "  +LOOKALLAROUND\n"
    # flags should appear after PainChance and before Translation
    pain_pos = output.index("PainChance").not_nil!
    shadow_pos = output.index("+SHADOW").not_nil!
    translation_pos = output.index("Translation").not_nil!
    shadow_pos.should be > pain_pos
    shadow_pos.should be < translation_pos
  end

  it "renders nothing extra when flags list is empty" do
    output = DecorateWriter.render([test_variant([] of String)])
    output.should_not contain "+SHADOW"
    output.should_not contain "+NOPAIN"
    output.should_not contain "+BRIGHT"
  end

  it "renders a minus flag correctly" do
    output = DecorateWriter.render([test_variant(["-FLOORCLIP"])])
    output.should contain "  -FLOORCLIP\n"
  end
end
