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

# Builds a minimal MonsterTemplate suitable for writer-focused tests
def minimal_template
  fixed = FixedFields.new(
    radius: 20, height: 56, flags: [] of String,
    see_sound: "", attack_sound: "", pain_sound: "", death_sound: "", active_sound: "",
    sprite_prefix: "POSS"
  )
  MonsterTemplate.new(
    id: "test", actor_name: "Test", base_health: 20,
    health_range: (20..20), speed_range: (8..8), pain_chance_range: (200..200),
    attack: AttackParams.new((1..1), (5..5), (11.25..11.25)),
    drop_table: DropTable.new(low: [] of DropEntry, mid: [] of DropEntry, high: [] of DropEntry),
    translations: ["176:191=112:127"], fixed_fields: fixed,
    extra_flags: [] of FlagEntry
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

  it "renders Mass when present" do
    v = MonsterVariant.new(
      name: "Test_1", health: 20, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      mass: 150
    )
    output = DecorateWriter.render([v])
    output.should contain "  Mass 150\n"
  end

  it "does not render Mass when nil" do
    output = DecorateWriter.render([test_variant])
    output.should_not contain "Mass"
  end

  it "renders Scale, Radius, Height in order after flags and before Translation" do
    v = MonsterVariant.new(
      name: "Test_1", health: 20, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      scale: 1.5,
      radius: 30,
      height: 84
    )
    output = DecorateWriter.render([v])
    output.should contain "  Scale 1.5\n"
    output.should contain "  Radius 30\n"
    output.should contain "  Height 84\n"
    scale_pos       = output.index("Scale").not_nil!
    radius_pos      = output.index("Radius").not_nil!
    height_pos      = output.index("Height").not_nil!
    translation_pos = output.index("Translation").not_nil!
    scale_pos.should  be < radius_pos
    radius_pos.should be < height_pos
    height_pos.should be < translation_pos
  end

  it "renders RenderStyle and Alpha for Translucent" do
    v = MonsterVariant.new(
      name: "Test_1", health: 20, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      render_style: "Translucent",
      alpha: 0.7
    )
    output = DecorateWriter.render([v])
    output.should contain "  RenderStyle Translucent\n"
    output.should contain "  Alpha 0.7\n"
  end

  it "renders RenderStyle, Alpha, and StencilColor for Stencil" do
    v = MonsterVariant.new(
      name: "Test_1", health: 20, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      render_style: "Stencil",
      alpha: 0.8,
      stencil_color: "FF0000"
    )
    output = DecorateWriter.render([v])
    output.should contain "  RenderStyle Stencil\n"
    output.should contain "  Alpha 0.8\n"
    output.should contain "  StencilColor \"FF0000\"\n"
  end

  it "renders BloodColor when present" do
    v = MonsterVariant.new(
      name: "Test_1", health: 20, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      blood_color: "200 20 20"
    )
    output = DecorateWriter.render([v])
    output.should contain "  BloodColor \"200 20 20\"\n"
  end

  it "renders no extra properties when all new fields are nil" do
    output = DecorateWriter.render([test_variant])
    output.should_not contain "Mass"
    output.should_not contain "Gravity"
    output.should_not contain "Scale"
    output.should_not contain "RenderStyle"
    output.should_not contain "BloodColor"
  end

  it "renders new properties after flags and before Translation" do
    v = MonsterVariant.new(
      name: "Test_1", health: 20, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: ["+SHADOW"] of String,
      mass: 200,
      render_style: "Fuzzy",
      blood_color: "255 0 0"
    )
    output = DecorateWriter.render([v])
    shadow_pos      = output.index("+SHADOW").not_nil!
    mass_pos        = output.index("Mass").not_nil!
    render_pos      = output.index("RenderStyle").not_nil!
    blood_pos       = output.index("BloodColor").not_nil!
    translation_pos = output.index("Translation").not_nil!
    shadow_pos.should      be < mass_pos
    mass_pos.should        be < render_pos
    render_pos.should      be < blood_pos
    blood_pos.should       be < translation_pos
  end

  it "does not render RenderStyle when render_style is Normal" do
    v = MonsterVariant.new(
      name: "Test_1", health: 20, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      render_style: "Normal"
    )
    output = DecorateWriter.render([v])
    output.should_not contain "RenderStyle"
  end

  it "renders projectile actor and A_CustomComboAttack for combo attack" do
    ca = ResolvedComboAttack.new(
      projectile_name: "DoomImpBall_1",
      projectile_class: "DoomImpBall",
      projectile_speed: 12,
      projectile_damage: 5,
      melee_damage: 3,
      melee_sound: "imp/melee",
      projectile_fast_speed: 24
    )
    v = MonsterVariant.new(
      name: "DoomImp_1", health: 60, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      combo_attack: ca
    )
    output = DecorateWriter.render([v])
    # Projectile actor
    output.should contain "ACTOR DoomImpBall_1 : DoomImpBall\n"
    output.should contain "  Speed 12\n"
    output.should contain "  FastSpeed 24\n"
    output.should contain "  Damage 5\n"
    # Monster uses A_CustomComboAttack, not A_CustomBulletAttack
    output.should contain "A_CustomComboAttack(\"DoomImpBall_1\", 3, \"imp/melee\")"
    output.should_not contain "A_CustomBulletAttack"
    # Melee: label should be present
    output.should contain "Melee:\n"
  end

  it "renders A_CustomBulletAttack when combo_attack is nil" do
    output = DecorateWriter.render([test_variant])
    output.should contain "A_CustomBulletAttack"
    output.should_not contain "A_CustomComboAttack"
    output.should_not contain "Melee:"
  end

  it "omits FastSpeed from projectile actor when not set" do
    ca = ResolvedComboAttack.new(
      projectile_name: "DoomImpBall_1",
      projectile_class: "DoomImpBall",
      projectile_speed: 10,
      projectile_damage: 3,
      melee_damage: 2,
      melee_sound: "imp/melee"
    )
    v = MonsterVariant.new(
      name: "DoomImp_1", health: 60, speed: 8, pain_chance: 200,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      combo_attack: ca
    )
    output = DecorateWriter.render([v])
    output.should_not contain "FastSpeed"
    output.should contain "  Speed 10\n"
  end

  it "renders A_CustomMeleeAttack for melee-only attack" do
    ma = ResolvedMeleeAttack.new(
      damage: 25,
      melee_sound: "demon/melee"
    )
    v = MonsterVariant.new(
      name: "Demon_1", health: 150, speed: 10, pain_chance: 180,
      attack: ResolvedAttack.new(1, 5, 11.25),
      drop_items: [] of ResolvedDropItem,
      translation: "176:191=112:127",
      template: minimal_template,
      flags: [] of String,
      melee_attack: ma
    )
    output = DecorateWriter.render([v])
    output.should contain "A_CustomMeleeAttack(25, \"demon/melee\", \"\")"
    output.should contain "Melee:\n"
    output.should_not contain "Missile:"
    output.should_not contain "A_CustomBulletAttack"
    output.should_not contain "A_CustomComboAttack"
  end
end
