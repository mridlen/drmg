# src/main.cr
require "option_parser"
require "./monster_template"
require "./generator"
require "./decorate_writer"
require "./pk3_writer"
require "./monster_registry"

# ---------- Defaults ----------

monsters_arg = "all"
seed : Int32? = nil
output_path = "./drmg_output.pk3"
default_variants = 1
replaces = false
doom_version = 2

# ---------- CLI argument parsing ----------

OptionParser.parse do |parser|
  parser.banner = <<-BANNER
  Doom Random Monster Generator (DRMG)
  Generates randomized DECORATE monster variants for GZDoom, packaged as a PK3 file.

  Usage: drmg [options]

  Examples:
    drmg                                      Generate 1 variant of every Doom 2 monster
    drmg --variants 5 --seed 42               Generate 5 variants per monster, reproducible
    drmg --monsters imp:3,demon:2             Generate 3 Imp and 2 Demon variants only
    drmg --replaces --doom 1                  Ultimate Doom monsters with spawner replacements
    drmg --monsters all --variants 10 --replaces --output mymod.pk3

  BANNER

  parser.separator "  Options:"
  parser.separator ""

  parser.on("--monsters MONSTERS", "Monster selection (default: all)\n" \
    "                                     Use 'all' for every monster, or specify a comma-separated\n" \
    "                                     list of monster_id:count pairs. The count overrides\n" \
    "                                     --variants for that monster. Omit :count to use the\n" \
    "                                     --variants default.\n" \
    "                                     Valid IDs: zombie_man, shotgun_guy, chain_gun_guy, imp,\n" \
    "                                     demon, spectre, lost_soul, cacodemon, pain_elemental,\n" \
    "                                     hell_knight, baron_of_hell, arachnotron, mancubus,\n" \
    "                                     revenant, arch_vile, spider_mastermind, cyberdemon,\n" \
    "                                     wolfenstein_ss") do |val|
    monsters_arg = val
  end

  parser.on("--seed SEED", "Integer RNG seed for reproducible output.\n" \
    "                                     Same seed + same options = identical PK3 every time.\n" \
    "                                     Omit for a random seed.") do |val|
    parsed = val.to_i?(strict: true)
    if parsed.nil?
      STDERR.puts "Invalid --seed value: '#{val}'. Must be an integer."
      exit 1
    end
    seed = parsed
  end

  parser.on("--variants COUNT", "Number of variants per monster (default: 1).\n" \
    "                                     Each variant gets randomized stats, attacks, colors,\n" \
    "                                     and flags. Can be overridden per-monster via --monsters.") do |val|
    parsed = val.to_i?(strict: true)
    if parsed.nil? || parsed < 1
      STDERR.puts "Invalid --variants value: '#{val}'. Must be a positive integer."
      exit 1
    end
    default_variants = parsed
  end

  parser.on("--output PATH", "Output PK3 file path (default: ./drmg_output.pk3).\n" \
    "                                     The PK3 is a ZIP containing the DECORATE lump.\n" \
    "                                     Load it in GZDoom with: gzdoom -file <path>") do |val|
    output_path = val
  end

  parser.on("--replaces", "Generate spawner actors that replace original monsters.\n" \
    "                                     Each spawner randomly picks one of the generated\n" \
    "                                     variants at map load. Without this flag, variants\n" \
    "                                     must be placed manually in a map editor.") do
    replaces = true
  end

  parser.on("--doom VERSION", "Doom version: 1 or 2 (default: 2).\n" \
    "                                     1 = Ultimate Doom monsters only (excludes Doom 2\n" \
    "                                     additions like Mancubus, Revenant, Arch-Vile, etc.).\n" \
    "                                     2 = All monsters including Doom 2.") do |val|
    parsed = val.to_i?(strict: true)
    unless parsed == 1 || parsed == 2
      STDERR.puts "Invalid --doom value: '#{val}'. Must be 1 or 2."
      exit 1
    end
    doom_version = parsed
  end

  parser.separator ""
  parser.on("-h", "--help", "Show this help message") do
    puts parser
    exit 0
  end
end

# ---------- Parse monster selection ----------

selections = [] of {MonsterTemplate, Int32}

# --- Filter monsters by Doom version ---
available_monsters = if doom_version == 1
                       ALL_MONSTERS.reject { |id, _| DOOM2_ONLY.includes?(id) }
                     else
                       ALL_MONSTERS
                     end

if monsters_arg == "all"
  available_monsters.each_value do |template|
    selections << {template, default_variants}
  end
else
  monsters_arg.split(",").each do |entry|
    parts = entry.split(":")
    id = parts[0].strip
    count = parts.size > 1 ? parts[1].to_i : default_variants

    unless available_monsters.has_key?(id)
      STDERR.puts "Unknown monster id: '#{id}'. Valid ids: #{available_monsters.keys.join(", ")}"
      exit 1
    end

    selections << {available_monsters[id], count}
  end
end

# ---------- Generate variants ----------

rng = (s = seed) ? Random.new(s) : Random.new

all_variants = [] of MonsterVariant

selections.each do |(template, count)|
  variants = Generator.generate(template, count: count, rng: rng)
  all_variants.concat(variants)
end

puts "Generated #{all_variants.size} variant(s):"
all_variants.each { |v| puts "  #{v.name} (HP: #{v.health}, Speed: #{v.speed})" }

# ---------- Write output ----------

decorate_text = DecorateWriter.render(all_variants, replaces: replaces)
Pk3Writer.write(decorate_text, output_path)

puts "Written to #{output_path}"
