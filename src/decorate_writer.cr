# src/decorate_writer.cr
require "./monster_template"

module DecorateWriter
  # Renders an array of MonsterVariant instances to a DECORATE lump string.
  def self.render(variants : Array(MonsterVariant)) : String
    String.build do |io|
      variants.each_with_index do |v, idx|
        io << "\n" if idx > 0
        render_variant(io, v)
      end
    end
  end

  private def self.render_variant(io : IO, v : MonsterVariant)
    # --- Spawned Lost Soul actor (pain attack only) ---
    if pa = v.pain_attack
      io << "ACTOR #{pa.skull_name} : LostSoul\n"
      io << "{\n"
      io << "  Health #{pa.skull_health}\n"
      io << "  Speed #{pa.skull_speed}\n"
      io << "  Damage #{pa.skull_damage}\n"
      io << "  States\n"
      io << "  {\n"
      io << "  Missile:\n"
      io << "    SKUL C #{pa.skull_face_tics} bright A_FaceTarget\n"
      io << "    SKUL D 4 bright A_SkullAttack(#{pa.skull_charge_speed})\n"
      io << "    SKUL CD 4 bright\n"
      io << "    goto Missile+2\n"
      io << "  }\n"
      io << "}\n\n"
    end

    # --- Custom RevenantTracer actor (revenant attack only) ---
    if ra = v.revenant_attack
      io << "ACTOR #{ra.tracer_name} : RevenantTracer\n"
      io << "{\n"
      io << "  Speed #{ra.tracer_speed}\n"
      io << "  Damage #{ra.tracer_damage}\n"
      io << "}\n\n"
    end

    # --- Projectile actor (combo, projectile burst, or fat attack) ---
    if ca = v.combo_attack
      io << "ACTOR #{ca.projectile_name} : #{ca.projectile_class}\n"
      io << "{\n"
      io << "  Speed #{ca.projectile_speed}\n"
      io << "  FastSpeed #{ca.projectile_fast_speed}\n" if ca.projectile_fast_speed
      io << "  Damage #{ca.projectile_damage}\n"
      io << "}\n\n"
    elsif pb = v.projectile_burst_attack
      io << "ACTOR #{pb.projectile_name} : #{pb.projectile_class}\n"
      io << "{\n"
      io << "  Speed #{pb.projectile_speed}\n"
      io << "  Damage #{pb.projectile_damage}\n"
      io << "}\n\n"
    elsif fa = v.fat_attack
      io << "ACTOR #{fa.projectile_name} : #{fa.projectile_class}\n"
      io << "{\n"
      io << "  Speed #{fa.projectile_speed}\n"
      io << "  Damage #{fa.projectile_damage}\n"
      io << "}\n\n"
    end

    # --- ACTOR header ---
    io << "ACTOR #{v.name} : #{v.template.actor_name}\n"
    io << "{\n"

    # --- Core stats ---
    io << "  Health #{v.health}\n"
    io << "  Speed #{v.speed}\n"
    io << "  PainChance #{v.pain_chance}\n"

    # --- Skull attack: actor-level Damage property ---
    io << "  Damage #{v.skull_attack.not_nil!.damage}\n" if v.skull_attack

    # --- Optional flags ---
    v.flags.each do |flag|
      io << "  #{flag}\n"
    end

    # --- Scale and proportional collision box ---
    io << "  Scale #{v.scale}\n"   if v.scale
    io << "  Radius #{v.radius}\n" if v.radius
    io << "  Height #{v.height}\n" if v.height

    # --- Behavioral properties ---
    # Note: `if v.field` guards are falsy for 0/0.0; acceptable because
    # generator ranges never produce zero for these properties.
    io << "  Mass #{v.mass}\n"                       if v.mass
    io << "  Gravity #{v.gravity}\n"                 if v.gravity
    io << "  ReactionTime #{v.reaction_time}\n"      if v.reaction_time
    io << "  PainThreshold #{v.pain_threshold}\n"    if v.pain_threshold
    io << "  Threshold #{v.threshold}\n"             if v.threshold
    io << "  MinMissileChance #{v.min_missile_chance}\n" if v.min_missile_chance
    io << "  MaxTargetRange #{v.max_target_range}\n" if v.max_target_range
    io << "  MeleeRange #{v.melee_range}\n"          if v.melee_range
    io << "  DamageMultiply #{v.damage_multiply}\n"  if v.damage_multiply

    # --- Render style (Normal writes nothing; Stencil also writes StencilColor) ---
    if (rs = v.render_style) && rs != "Normal"
      io << "  RenderStyle #{rs}\n"
      io << "  Alpha #{v.alpha}\n" if v.alpha
      if sc = v.stencil_color
        io << "  StencilColor \"#{sc}\"\n"
      end
    end

    # --- Blood color ---
    io << "  BloodColor \"#{v.blood_color}\"\n" if v.blood_color

    # --- Translation ---
    io << "  Translation \"#{v.translation}\"\n"

    # --- Drop items ---
    v.drop_items.each do |drop|
      io << "  DropItem \"#{drop.item}\" #{drop.weight}\n"
    end

    # --- Missile state ---
    sprite = v.template.fixed_fields.sprite_prefix

    io << "  States\n"
    io << "  {\n"

    if ma = v.melee_attack
      # Melee-only attack (e.g. Demon)
      # A_CustomMeleeAttack signature: (damage, meleesound, misssound, damagetype, bleed)
      io << "  Melee:\n"
      io << "    #{sprite} EF 8 A_FaceTarget\n"
      io << "    #{sprite} G 8 A_CustomMeleeAttack(#{ma.damage}, \"#{ma.melee_sound}\", \"#{ma.miss_sound}\")\n"
      io << "    Goto See\n"
    elsif ca = v.combo_attack
      # Combo attack: melee claw + projectile fireball
      # A_CustomComboAttack signature: (missiletype, damagemul, meleesound)
      # Multi-prong: extra projectiles via A_CustomMissile at spread angles
      io << "  Melee:\n"
      io << "  Missile:\n"
      io << "    #{sprite} EF 8 A_FaceTarget\n"
      if mp = v.multi_prong
        half = (mp.prong_count - 1) // 2
        # Fire side prongs first (zero-tic), then center combo attack last (with tics)
        (-half..half).to_a.each do |n|
          angle = (n * mp.spread_angle).round(1)
          if n == 0
            io << "    #{sprite} G 6 A_CustomComboAttack(\"#{ca.projectile_name}\", #{ca.melee_damage}, \"#{ca.melee_sound}\")\n"
          else
            io << "    #{sprite} G 0 A_CustomMissile(\"#{ca.projectile_name}\", 32, 0, #{angle})\n"
          end
        end
      else
        io << "    #{sprite} G 6 A_CustomComboAttack(\"#{ca.projectile_name}\", #{ca.melee_damage}, \"#{ca.melee_sound}\")\n"
      end
      io << "    Goto See\n"
    elsif ra = v.revenant_attack
      # Revenant attack — separate Melee and Missile states
      # Engine picks Melee when close, Missile when far
      io << "  Melee:\n"
      io << "    #{sprite} G 6 A_FaceTarget\n"
      io << "    #{sprite} H 6 A_CustomMeleeAttack(#{ra.melee_damage}, \"#{ra.melee_sound}\")\n"
      io << "    Goto See\n"
      io << "  Missile:\n"
      io << "    #{sprite} J 0 bright A_FaceTarget\n"
      io << "    #{sprite} J 10 bright A_FaceTarget\n"
      emit_custom_missile(io, sprite, "K", 10, false, ra.tracer_name, v.multi_prong)
      io << "    #{sprite} K 10 A_FaceTarget\n"
      io << "    Goto See\n"
    elsif pa = v.pain_attack
      # Pain Elemental attack — spawns custom Lost Soul variant(s)
      # A_DualPainAttack spawns two at ±45°; A_PainAttack spawns one
      attack_func = pa.dual ? "A_DualPainAttack" : "A_PainAttack"
      io << "  Missile:\n"
      io << "    #{sprite} DE 5 A_FaceTarget\n"
      io << "    #{sprite} F 5 bright A_FaceTarget\n"
      io << "    #{sprite} F 0 bright #{attack_func}(\"#{pa.skull_name}\")\n"
      io << "    Goto See\n"
    elsif sa = v.skull_attack
      # Skull charge attack (e.g. Lost Soul)
      # A_SkullAttack(speed) uses actor's Damage property for ram damage
      io << "  Missile:\n"
      io << "    #{sprite} C #{sa.face_tics} bright A_FaceTarget\n"
      io << "    #{sprite} D 4 bright A_SkullAttack(#{sa.charge_speed})\n"
      io << "    #{sprite} CD 4 bright\n"
      io << "    goto Missile+2\n"
    elsif cy = v.cyber_attack
      # Cyber (3-rocket volley) attack
      # A_CyberAttack fires a rocket; 3 volleys with A_FaceTarget re-aim between each
      io << "  Missile:\n"
      io << "    #{sprite} E 6 A_FaceTarget\n"
      io << "    #{sprite} F #{cy.fire_tics} A_CyberAttack\n"
      io << "    #{sprite} E #{cy.face_tics} A_FaceTarget\n"
      io << "    #{sprite} F #{cy.fire_tics} A_CyberAttack\n"
      io << "    #{sprite} E #{cy.face_tics} A_FaceTarget\n"
      io << "    #{sprite} F #{cy.fire_tics} A_CyberAttack\n"
      io << "    Goto See\n"
    elsif va = v.vile_attack
      # Archvile fire attack
      # A_VileAttack signature: (sound, initialdamage, blastdamage, blastradius, thrustfactor)
      io << "  Missile:\n"
      io << "    #{sprite} G 0 bright A_VileStart\n"
      io << "    #{sprite} G 10 bright A_FaceTarget\n"
      io << "    #{sprite} H 8 bright A_VileTarget\n"
      io << "    #{sprite} IJKLMN 8 bright A_FaceTarget\n"
      io << "    #{sprite} O 8 bright A_VileAttack(\"vile/stop\", #{va.initial_damage}, #{va.blast_damage}, #{va.blast_radius}, #{va.thrust_factor})\n"
      io << "    #{sprite} P 20 bright\n"
      io << "    Goto See\n"
    elsif fa = v.fat_attack
      # Fat (3-volley) attack (e.g. Mancubus)
      # A_FatAttack1/2/3 each accept a custom projectile spawntype
      io << "  Missile:\n"
      io << "    #{sprite} G 20 A_FatRaise\n"
      io << "    #{sprite} H 10 bright A_FatAttack1(\"#{fa.projectile_name}\")\n"
      io << "    #{sprite} IG 5 A_FaceTarget\n"
      io << "    #{sprite} H 10 bright A_FatAttack2(\"#{fa.projectile_name}\")\n"
      io << "    #{sprite} IG 5 A_FaceTarget\n"
      io << "    #{sprite} H 10 bright A_FatAttack3(\"#{fa.projectile_name}\")\n"
      io << "    #{sprite} IG 5 A_FaceTarget\n"
      io << "    Goto See\n"
    elsif pb = v.projectile_burst_attack
      # Projectile burst with refire loop (e.g. Arachnotron)
      # A_CustomMissile fires the custom projectile; refire loop continues while target is visible
      io << "  Missile:\n"
      io << "    #{sprite} #{pb.face_frame} #{pb.face_tics} bright A_FaceTarget\n"
      emit_custom_missile(io, sprite, pb.attack_frame, pb.attack_tics, true, pb.projectile_name, v.multi_prong)
      io << "    #{sprite} #{pb.cooldown_frame} #{pb.cooldown_tics} bright\n"
      io << "    #{sprite} #{pb.refire_frame} 1 bright #{pb.refire_function}\n"
      io << "    goto Missile+1\n"
    elsif ba = v.burst_attack
      # Burst hitscan attack with refire loop (e.g. ChaingunGuy, SpiderMastermind)
      # Alternates two attack frames; zero-length sound frame before each shot
      spread  = v.attack.spread
      bullets = v.attack.bullet_count
      damage  = v.attack.damage
      tics    = ba.attack_tics
      io << "  Missile:\n"
      io << "    #{sprite} #{ba.face_frame} #{ba.face_tics} A_FaceTarget\n"
      io << "    #{sprite} #{ba.attack_frame_1} 0 A_PlaySound(\"#{ba.attack_sound}\", CHAN_WEAPON)\n"
      io << "    #{sprite} #{ba.attack_frame_1} #{tics} bright A_CustomBulletAttack(#{spread}, 0.0, #{bullets}, #{damage}, \"BulletPuff\")\n"
      io << "    #{sprite} #{ba.attack_frame_2} 0 A_PlaySound(\"#{ba.attack_sound}\", CHAN_WEAPON)\n"
      io << "    #{sprite} #{ba.attack_frame_2} #{tics} bright A_CustomBulletAttack(#{spread}, 0.0, #{bullets}, #{damage}, \"BulletPuff\")\n"
      io << "    #{sprite} #{ba.refire_frame} 1 #{ba.refire_function}\n"
      io << "    goto Missile+1\n"
    else
      # Hitscan bullet attack
      # A_CustomBulletAttack signature: (spread, vspread, numbullets, damage, pufftype)
      spread  = v.attack.spread
      bullets = v.attack.bullet_count
      damage  = v.attack.damage
      io << "  Missile:\n"
      io << "    #{sprite} E 10 A_FaceTarget\n"
      io << "    #{sprite} F 8 A_CustomBulletAttack(#{spread}, 0.0, #{bullets}, #{damage}, \"BulletPuff\")\n"
      io << "    #{sprite} E 8\n"
      io << "    Goto See\n"
    end

    io << "  }\n"
    io << "}\n"
  end

  # --- Helper: emit A_CustomMissile with optional multi-prong spread ---
  # Single prong: one call with the original tics.
  # Multi-prong (3 or 5): zero-tic calls for all but the last, which gets the original tics.
  private def self.emit_custom_missile(io : IO, sprite : String, frame : String, tics : Int32, bright : Bool, projectile : String, multi_prong : ResolvedMultiProng?)
    br = bright ? " bright" : ""
    if mp = multi_prong
      # Calculate angles: evenly spaced around center
      # 3-prong: -angle, 0, +angle
      # 5-prong: -2*angle, -angle, 0, +angle, +2*angle
      half = (mp.prong_count - 1) // 2
      angles = (-half..half).to_a.map { |n| (n * mp.spread_angle).round(1) }
      angles.each_with_index do |angle, idx|
        last = (idx == angles.size - 1)
        t = last ? tics : 0
        io << "    #{sprite} #{frame} #{t}#{br} A_CustomMissile(\"#{projectile}\", 32, 0, #{angle})\n"
      end
    else
      io << "    #{sprite} #{frame} #{tics}#{br} A_CustomMissile(\"#{projectile}\")\n"
    end
  end
end
