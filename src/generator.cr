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

      # ---------- Roll multi-prong spread ----------
      multi_prong = template.multi_prong_params.try do |mp|
        angle_min = mp.angle_range.begin
        angle_max = mp.angle_range.end
        spread    = (angle_min + rng.rand * (angle_max - angle_min)).round(1)
        roll      = rng.rand
        count     = if roll < mp.three_prong_chance
                      3
                    elsif roll < mp.three_prong_chance + mp.five_prong_chance
                      5
                    else
                      1
                    end
        # Only store if actually multi-prong
        count > 1 ? ResolvedMultiProng.new(prong_count: count, spread_angle: spread) : nil
      end

      # ---------- Roll combo attack (melee + projectile) ----------
      combo_attack = template.combo_attack_params.try do |ca|
        proj_speed      = rng.rand(ca.projectile_speed_range)
        proj_fast_speed = ca.projectile_fast_speed_range.try { |r| rng.rand(r) }
        proj_damage     = rng.rand(ca.projectile_damage_range)
        melee_dmg       = rng.rand(ca.melee_damage_range)
        # e.g. "BaronBall_HK_1" with prefix, "DoomImpBall_1" without
        proj_name = if prefix = ca.projectile_prefix
          "#{ca.projectile_class}_#{prefix}_#{i + 1}"
        else
          "#{ca.projectile_class}_#{i + 1}"
        end
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

      # ---------- Roll melee-only attack ----------
      melee_attack = template.melee_attack_params.try do |ma|
        dmg = rng.rand(ma.damage_range)
        ResolvedMeleeAttack.new(
          damage:      dmg,
          melee_sound: ma.melee_sound,
          miss_sound:  ma.miss_sound
        )
      end

      # ---------- Roll burst (refire loop) hitscan attack ----------
      burst_attack = template.burst_attack_params.try do |ba|
        tics = rng.rand(ba.attack_tics_range)
        ResolvedBurstAttack.new(
          attack_tics:      tics,
          attack_sound:     ba.attack_sound,
          face_frame:       ba.face_frame,
          face_tics:        ba.face_tics,
          attack_frame_1:   ba.attack_frame_1,
          attack_frame_2:   ba.attack_frame_2,
          refire_frame:     ba.refire_frame,
          refire_function:  ba.refire_function
        )
      end

      # ---------- Roll projectile burst (refire loop) attack ----------
      projectile_burst_attack = template.projectile_burst_attack_params.try do |pb|
        proj_speed    = rng.rand(pb.projectile_speed_range)
        proj_damage   = rng.rand(pb.projectile_damage_range)
        attack_tics   = rng.rand(pb.attack_tics_range)
        cooldown_tics = rng.rand(pb.cooldown_tics_range)
        proj_name     = "#{pb.projectile_class}_#{i + 1}"
        ResolvedProjectileBurstAttack.new(
          projectile_name:   proj_name,
          projectile_class:  pb.projectile_class,
          projectile_speed:  proj_speed,
          projectile_damage: proj_damage,
          attack_tics:       attack_tics,
          cooldown_tics:     cooldown_tics,
          face_frame:        pb.face_frame,
          face_tics:         pb.face_tics,
          attack_frame:      pb.attack_frame,
          cooldown_frame:    pb.cooldown_frame,
          refire_frame:      pb.refire_frame,
          refire_function:   pb.refire_function
        )
      end

      # ---------- Roll skull (charge) attack ----------
      skull_attack = template.skull_attack_params.try do |sa|
        charge_speed = rng.rand(sa.charge_speed_range)
        dmg          = rng.rand(sa.damage_range)
        face_tics    = rng.rand(sa.face_tics_range)
        ResolvedSkullAttack.new(
          charge_speed: charge_speed,
          damage:       dmg,
          face_tics:    face_tics
        )
      end

      # ---------- Roll revenant (homing tracer + melee) attack ----------
      revenant_attack = template.revenant_attack_params.try do |ra|
        tracer_spd  = rng.rand(ra.tracer_speed_range)
        tracer_dmg  = rng.rand(ra.tracer_damage_range)
        melee_dmg   = rng.rand(ra.melee_damage_range)
        tracer_name = "RevenantTracer_#{i + 1}"
        ResolvedRevenantAttack.new(
          tracer_name:  tracer_name,
          tracer_speed: tracer_spd,
          tracer_damage: tracer_dmg,
          melee_damage: melee_dmg,
          melee_sound:  ra.melee_sound
        )
      end

      # ---------- Roll pain (Lost Soul spawner) attack ----------
      pain_attack = template.pain_attack_params.try do |pa|
        skull_hp     = rng.rand(pa.skull_health_range)
        skull_spd    = rng.rand(pa.skull_speed_range)
        skull_chrg   = rng.rand(pa.skull_charge_speed_range)
        skull_dmg    = rng.rand(pa.skull_damage_range)
        skull_face   = rng.rand(pa.skull_face_tics_range)
        skull_name   = "LostSoul_PE_#{i + 1}"
        is_dual      = rng.rand < pa.dual_chance
        ResolvedPainAttack.new(
          skull_name:         skull_name,
          skull_health:       skull_hp,
          skull_speed:        skull_spd,
          skull_charge_speed: skull_chrg,
          skull_damage:       skull_dmg,
          skull_face_tics:    skull_face,
          dual:               is_dual
        )
      end

      # ---------- Roll cyber (3-rocket volley) attack ----------
      cyber_attack = template.cyber_attack_params.try do |cy|
        fire_tics = rng.rand(cy.fire_tics_range)
        face_tics = rng.rand(cy.face_tics_range)
        ResolvedCyberAttack.new(
          fire_tics: fire_tics,
          face_tics: face_tics
        )
      end

      # ---------- Roll vile (archvile fire) attack ----------
      vile_attack = template.vile_attack_params.try do |va|
        initial_dmg = rng.rand(va.initial_damage_range)
        blast_dmg   = rng.rand(va.blast_damage_range)
        blast_rad   = rng.rand(va.blast_radius_range)
        thrust_min  = va.thrust_factor_range.begin
        thrust_max  = va.thrust_factor_range.end
        thrust      = (thrust_min + rng.rand * (thrust_max - thrust_min)).round(2)
        ResolvedVileAttack.new(
          initial_damage: initial_dmg,
          blast_damage:   blast_dmg,
          blast_radius:   blast_rad,
          thrust_factor:  thrust
        )
      end

      # ---------- Roll fat (3-volley) attack ----------
      fat_attack = template.fat_attack_params.try do |fa|
        proj_speed  = rng.rand(fa.projectile_speed_range)
        proj_damage = rng.rand(fa.projectile_damage_range)
        proj_name   = "#{fa.projectile_class}_#{i + 1}"
        ResolvedFatAttack.new(
          projectile_name:   proj_name,
          projectile_class:  fa.projectile_class,
          projectile_speed:  proj_speed,
          projectile_damage: proj_damage
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
        multi_prong:        multi_prong,
        combo_attack:       combo_attack,
        burst_attack:       burst_attack,
        projectile_burst_attack: projectile_burst_attack,
        fat_attack:         fat_attack,
        skull_attack:       skull_attack,
        revenant_attack:    revenant_attack,
        pain_attack:        pain_attack,
        cyber_attack:       cyber_attack,
        vile_attack:        vile_attack,
        melee_attack:       melee_attack
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

    items = tier.map { |entry| ResolvedDropItem.new(item: entry.item, weight: entry.weight) }

    # --- Health pickup scaling: tougher variants drop health to compensate ---
    if health > template.base_health * 3
      items << ResolvedDropItem.new(item: "Medikit", weight: 192)
    elsif health > template.base_health * 2
      items << ResolvedDropItem.new(item: "Stimpack", weight: 128)
    end

    items
  end
end
