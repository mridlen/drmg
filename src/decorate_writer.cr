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
