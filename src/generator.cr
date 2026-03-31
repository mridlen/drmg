# src/generator.cr
require "./monster_template"

module Generator
  # Generates `count` randomized variants of `template` using `rng`.
  def self.generate(template : MonsterTemplate, count : Int32, rng : Random) : Array(MonsterVariant)
    variants = [] of MonsterVariant

    count.times do |i|
      # ---------- Roll stats within template ranges ----------
      health = rng.rand(template.health_range)
      speed = rng.rand(template.speed_range)
      pain_chance = rng.rand(template.pain_chance_range)

      # ---------- Roll attack parameters ----------
      bullet_count = rng.rand(template.attack.bullet_count_range)
      damage = rng.rand(template.attack.damage_range)

      spread_min = template.attack.spread_range.begin
      spread_max = template.attack.spread_range.end
      spread = spread_min + rng.rand * (spread_max - spread_min)
      spread = spread.round(2)

      # ---------- Select translation ----------
      translation = template.translations.sample(rng)

      # ---------- Resolve drop tier based on health vs base ----------
      drop_items = resolve_drops(template, health)

      # ---------- Build variant name ----------
      name = "#{template.actor_name}_#{i + 1}"

      variants << MonsterVariant.new(
        name: name,
        health: health,
        speed: speed,
        pain_chance: pain_chance,
        attack: ResolvedAttack.new(bullet_count, damage, spread),
        drop_items: drop_items,
        translation: translation,
        template: template,
        flags: [] of String
      )
    end

    variants
  end

  # ---------- Drop tier resolution ----------

  private def self.resolve_drops(template : MonsterTemplate, health : Int32) : Array(ResolvedDropItem)
    tier =
      if health > template.base_health * 3
        template.drop_table.high
      elsif health > (template.base_health * 1.5).to_i
        template.drop_table.mid
      else
        template.drop_table.low
      end

    tier.map { |entry| ResolvedDropItem.new(item: entry.item, weight: entry.weight) }
  end
end
