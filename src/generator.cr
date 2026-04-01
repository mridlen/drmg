# src/generator.cr
require "./monster_template"

module Generator
  # Generates `count` randomized variants of `template` using `rng`.
  def self.generate(template : MonsterTemplate, count : Int32, rng : Random) : Array(MonsterVariant)
    variants = [] of MonsterVariant

    count.times do |i|
      # ---------- Roll stats within template ranges ----------
      health      = rng.rand(template.health_range)
      speed       = rng.rand(template.speed_range)
      pain_chance = rng.rand(template.pain_chance_range)

      # ---------- Roll attack parameters ----------
      bullet_count = rng.rand(template.attack.bullet_count_range)
      damage       = rng.rand(template.attack.damage_range)

      spread_min = template.attack.spread_range.begin
      spread_max = template.attack.spread_range.end
      spread     = (spread_min + rng.rand * (spread_max - spread_min)).round(2)

      # ---------- Select translation ----------
      translation = template.translations.sample(rng)

      # ---------- Resolve drop tier based on health vs base ----------
      drop_items = resolve_drops(template, health)

      # ---------- Roll optional flags ----------
      rolled_flags = [] of String

      # Roll each global flag independently
      OPTIONAL_FLAGS.each do |entry|
        rolled_flags << entry.flag if rng.rand < entry.chance
      end

      # Roll speed pair (mutually exclusive: fast, slow, or neither)
      # Probability windows: [0.0, 0.15) = fast, [0.15, 0.30) = slow, [0.30, 1.0) = neither
      speed_roll = rng.rand
      if speed_roll < SPEED_FLAGS[:fast].chance
        rolled_flags << SPEED_FLAGS[:fast].flag
      elsif speed_roll < SPEED_FLAGS[:fast].chance + SPEED_FLAGS[:slow].chance
        rolled_flags << SPEED_FLAGS[:slow].flag
      end

      # Roll per-monster extra flags (appended after global flags; no deduplication)
      template.extra_flags.each do |entry|
        rolled_flags << entry.flag if rng.rand < entry.chance
      end

      # ---------- Roll behavioral properties ----------
      mass               = template.mass_range.try { |r| rng.rand(r) }
      gravity            = template.gravity_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(2) }
      reaction_time      = template.reaction_time_range.try { |r| rng.rand(r) }
      pain_threshold     = template.pain_threshold_range.try { |r| rng.rand(r) }
      threshold          = template.threshold_range.try { |r| rng.rand(r) }
      min_missile_chance = template.min_missile_chance_range.try { |r| rng.rand(r) }
      max_target_range   = template.max_target_dist_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(1) }
      melee_range        = template.melee_dist_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(1) }
      damage_multiply    = template.damage_multiply_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(2) }

      # ---------- Roll scale (valid range 0.5-2.0) ----------
      # Radius and Height are derived proportionally from fixed_fields base values
      scale         = template.scale_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(2) }
      rolled_radius = scale.try { |s| (template.fixed_fields.radius * s).round.to_i }
      rolled_height = scale.try { |s| (template.fixed_fields.height * s).round.to_i }

      # ---------- Roll render style ----------
      # Weighted selection: sum weights, walk list until cumulative weight exceeds roll.
      # "Normal" is a valid style but writes nothing (render_style stays nil).
      render_style  = nil.as(String?)
      alpha         = nil.as(Float64?)
      stencil_color = nil.as(String?)

      if styles = template.render_styles
        total    = styles.sum(&.weight)
        roll     = rng.rand * total
        accum    = 0.0
        selected = styles.last  # fallback: only reachable if roll == total (fp edge case)
        styles.each do |entry|
          accum += entry.weight
          if roll < accum
            selected = entry
            break
          end
        end
        unless selected.style == "Normal"
          render_style  = selected.style
          alpha         = selected.alpha_range.try { |r| (r.begin + rng.rand * (r.end - r.begin)).round(2) }
          stencil_color = selected.stencil_colors.try(&.sample(rng))
        end
      end

      # ---------- Roll blood color (50% chance; nil = inherit actor default) ----------
      blood_color = nil.as(String?)
      if rng.rand < 0.5
        r_val = rng.rand(256)
        g_val = rng.rand(256)
        b_val = rng.rand(256)
        blood_color = "#{r_val} #{g_val} #{b_val}"
      end

      # ---------- Roll combo attack (melee + projectile) ----------
      combo_attack = template.combo_attack_params.try do |ca|
        proj_speed      = rng.rand(ca.projectile_speed_range)
        proj_fast_speed = ca.projectile_fast_speed_range.try { |r| rng.rand(r) }
        proj_damage     = rng.rand(ca.projectile_damage_range)
        melee_dmg       = rng.rand(ca.melee_damage_range)
        proj_name       = "#{ca.projectile_class}_#{i + 1}"
        ResolvedComboAttack.new(
          projectile_name:      proj_name,
          projectile_class:     ca.projectile_class,
          projectile_speed:     proj_speed,
          projectile_damage:    proj_damage,
          melee_damage:         melee_dmg,
          melee_sound:          ca.melee_sound,
          projectile_fast_speed: proj_fast_speed
        )
      end

      # ---------- Build variant name ----------
      name = "#{template.actor_name}_#{i + 1}"

      variants << MonsterVariant.new(
        name:               name,
        health:             health,
        speed:              speed,
        pain_chance:        pain_chance,
        attack:             ResolvedAttack.new(bullet_count, damage, spread),
        drop_items:         drop_items,
        translation:        translation,
        template:           template,
        flags:              rolled_flags,
        mass:               mass,
        gravity:            gravity,
        reaction_time:      reaction_time,
        pain_threshold:     pain_threshold,
        threshold:          threshold,
        min_missile_chance: min_missile_chance,
        max_target_range:   max_target_range,
        melee_range:        melee_range,
        damage_multiply:    damage_multiply,
        scale:              scale,
        radius:             rolled_radius,
        height:             rolled_height,
        render_style:       render_style,
        alpha:              alpha,
        stencil_color:      stencil_color,
        blood_color:        blood_color,
        combo_attack:       combo_attack
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
