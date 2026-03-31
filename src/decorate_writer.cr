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
    # --- ACTOR header ---
    io << "ACTOR #{v.name} : #{v.template.actor_name}\n"
    io << "{\n"

    # --- Core stats ---
    io << "  Health #{v.health}\n"
    io << "  Speed #{v.speed}\n"
    io << "  PainChance #{v.pain_chance}\n"

    # --- Optional flags ---
    v.flags.each do |flag|
      io << "  #{flag}\n"
    end

    # --- Scale and proportional collision box ---
    io << "  Scale #{v.scale}\n"   if v.scale
    io << "  Radius #{v.radius}\n" if v.radius
    io << "  Height #{v.height}\n" if v.height

    # --- Behavioral properties ---
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
    if rs = v.render_style
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

    # --- Override Missile state to use A_CustomBulletAttack ---
    # A_CustomBulletAttack signature: (spread, vspread, numbullets, damage, pufftype)
    spread = v.attack.spread
    bullets = v.attack.bullet_count
    damage = v.attack.damage
    sprite = v.template.fixed_fields.sprite_prefix

    io << "  States\n"
    io << "  {\n"
    io << "  Missile:\n"
    io << "    #{sprite} E 10 A_FaceTarget\n"
    io << "    #{sprite} F 8 A_CustomBulletAttack(#{spread}, 0.0, #{bullets}, #{damage}, \"BulletPuff\")\n"
    io << "    #{sprite} E 8\n"
    io << "    Goto See\n"
    io << "  }\n"
    io << "}\n"
  end
end
