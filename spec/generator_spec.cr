require "./spec_helper"
require "../src/monster_template"
require "../src/generator"

# Helper: minimal MonsterTemplate for testing
def test_template
  fixed = FixedFields.new(
    radius: 20, height: 56, flags: ["+FLOORCLIP"],
    see_sound: "grunt/sight", attack_sound: "grunt/attack",
    pain_sound: "grunt/pain", death_sound: "grunt/death",
    active_sound: "grunt/active", sprite_prefix: "POSS"
  )
  attack = AttackParams.new(
    bullet_count_range: (1..3),
    damage_range: (3..15),
    spread_range: (11.25..22.5)
  )
  drop_table = DropTable.new(
    low: [DropEntry.new(item: "Clip", weight: 255)],
    mid: [DropEntry.new(item: "Clip", weight: 255), DropEntry.new(item: "ClipBox", weight: 128)],
    high: [DropEntry.new(item: "Clip", weight: 255), DropEntry.new(item: "ClipBox", weight: 255)]
  )
  MonsterTemplate.new(
    id: "zombie_man",
    actor_name: "ZombieMan",
    base_health: 20,
    health_range: (10..500),
    speed_range: (4..20),
    pain_chance_range: (50..255),
    attack: attack,
    drop_table: drop_table,
    translations: TRANSLATIONS,
    fixed_fields: fixed
  )
end

describe Generator do
  it "generates the requested number of variants" do
    rng = Random.new(42)
    variants = Generator.generate(test_template, count: 3, rng: rng)
    variants.size.should eq 3
  end

  it "names variants sequentially" do
    rng = Random.new(42)
    variants = Generator.generate(test_template, count: 3, rng: rng)
    variants[0].name.should eq "ZombieMan_1"
    variants[1].name.should eq "ZombieMan_2"
    variants[2].name.should eq "ZombieMan_3"
  end

  it "keeps rolled stats within template ranges" do
    rng = Random.new(42)
    variants = Generator.generate(test_template, count: 10, rng: rng)
    variants.each do |v|
      v.health.should be >= 10
      v.health.should be <= 500
      v.speed.should be >= 4
      v.speed.should be <= 20
      v.pain_chance.should be >= 50
      v.pain_chance.should be <= 255
    end
  end

  it "selects a valid translation" do
    rng = Random.new(42)
    variants = Generator.generate(test_template, count: 5, rng: rng)
    variants.each do |v|
      TRANSLATIONS.should contain v.translation
    end
  end

  it "assigns low tier drops when health < 1.5x base" do
    fixed = FixedFields.new(
      radius: 20, height: 56, flags: [] of String,
      see_sound: "", attack_sound: "", pain_sound: "", death_sound: "", active_sound: "",
      sprite_prefix: ""
    )
    attack = AttackParams.new((1..1), (5..5), (11.25..11.25))
    drop_table = DropTable.new(
      low: [DropEntry.new("Clip", 255)],
      mid: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 128)],
      high: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 255)]
    )
    template = MonsterTemplate.new(
      id: "test", actor_name: "Test", base_health: 20,
      health_range: (10..10),
      speed_range: (8..8), pain_chance_range: (200..200),
      attack: attack, drop_table: drop_table,
      translations: ["176:191=112:127"], fixed_fields: fixed
    )
    rng = Random.new(1)
    variants = Generator.generate(template, count: 1, rng: rng)
    variants[0].drop_items.size.should eq 1
    variants[0].drop_items[0].item.should eq "Clip"
  end

  it "assigns mid tier drops when health is 1.5x-3x base" do
    fixed = FixedFields.new(
      radius: 20, height: 56, flags: [] of String,
      see_sound: "", attack_sound: "", pain_sound: "", death_sound: "", active_sound: "",
      sprite_prefix: ""
    )
    attack = AttackParams.new((1..1), (5..5), (11.25..11.25))
    drop_table = DropTable.new(
      low: [DropEntry.new("Clip", 255)],
      mid: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 128)],
      high: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 255)]
    )
    template = MonsterTemplate.new(
      id: "test", actor_name: "Test", base_health: 20,
      health_range: (40..40),
      speed_range: (8..8), pain_chance_range: (200..200),
      attack: attack, drop_table: drop_table,
      translations: ["176:191=112:127"], fixed_fields: fixed
    )
    rng = Random.new(1)
    variants = Generator.generate(template, count: 1, rng: rng)
    variants[0].drop_items.size.should eq 2
  end

  it "assigns high tier drops when health > 3x base" do
    fixed = FixedFields.new(
      radius: 20, height: 56, flags: [] of String,
      see_sound: "", attack_sound: "", pain_sound: "", death_sound: "", active_sound: "",
      sprite_prefix: ""
    )
    attack = AttackParams.new((1..1), (5..5), (11.25..11.25))
    drop_table = DropTable.new(
      low: [DropEntry.new("Clip", 255)],
      mid: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 128)],
      high: [DropEntry.new("Clip", 255), DropEntry.new("ClipBox", 255)]
    )
    template = MonsterTemplate.new(
      id: "test", actor_name: "Test", base_health: 20,
      health_range: (70..70),
      speed_range: (8..8), pain_chance_range: (200..200),
      attack: attack, drop_table: drop_table,
      translations: ["176:191=112:127"], fixed_fields: fixed
    )
    rng = Random.new(1)
    variants = Generator.generate(template, count: 1, rng: rng)
    variants[0].drop_items.size.should eq 2
    variants[0].drop_items[1].weight.should eq 255
  end

  it "produces identical output with the same seed" do
    rng1 = Random.new(999)
    rng2 = Random.new(999)
    v1 = Generator.generate(test_template, count: 3, rng: rng1)
    v2 = Generator.generate(test_template, count: 3, rng: rng2)
    v1.map(&.health).should eq v2.map(&.health)
    v1.map(&.speed).should eq v2.map(&.speed)
    v1.map(&.translation).should eq v2.map(&.translation)
  end
end
