require "./spec_helper"
require "../src/monster_template"
require "../src/monsters/zombie_man"

describe MonsterTemplate do
  it "holds all required fields" do
    fixed = FixedFields.new(
      radius: 20,
      height: 56,
      flags: ["+FLOORCLIP"],
      see_sound: "grunt/sight",
      attack_sound: "grunt/attack",
      pain_sound: "grunt/pain",
      death_sound: "grunt/death",
      active_sound: "grunt/active",
      sprite_prefix: "POSS"
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
    template = MonsterTemplate.new(
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
    template.id.should eq "zombie_man"
    template.actor_name.should eq "ZombieMan"
    template.base_health.should eq 20
    template.translations.size.should be > 0
  end
end

describe TRANSLATIONS do
  it "contains at least 5 entries" do
    TRANSLATIONS.size.should be >= 5
  end
end

describe "ZOMBIE_MAN template" do
  it "has correct id and actor name" do
    ZOMBIE_MAN.id.should eq "zombie_man"
    ZOMBIE_MAN.actor_name.should eq "ZombieMan"
    ZOMBIE_MAN.base_health.should eq 20
    ZOMBIE_MAN.fixed_fields.sprite_prefix.should eq "POSS"
  end
end
