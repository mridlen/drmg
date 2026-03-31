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

# ---------- CLI argument parsing ----------

OptionParser.parse do |parser|
  parser.banner = "Usage: drmg [options]"

  parser.on("--monsters MONSTERS", "Comma-separated monster:count pairs, or 'all'") do |val|
    monsters_arg = val
  end

  parser.on("--seed SEED", "Integer RNG seed for reproducible output") do |val|
    seed = val.to_i
  end

  parser.on("--output PATH", "Output PK3 file path (default: ./drmg_output.pk3)") do |val|
    output_path = val
  end

  parser.on("-h", "--help", "Show help") do
    puts parser
    exit 0
  end
end

# ---------- Parse monster selection ----------

selections = [] of {MonsterTemplate, Int32}

if monsters_arg == "all"
  ALL_MONSTERS.each_value do |template|
    selections << {template, 1}
  end
else
  monsters_arg.split(",").each do |entry|
    parts = entry.split(":")
    id = parts[0].strip
    count = parts.size > 1 ? parts[1].to_i : 1

    unless ALL_MONSTERS.has_key?(id)
      STDERR.puts "Unknown monster id: '#{id}'. Valid ids: #{ALL_MONSTERS.keys.join(", ")}"
      exit 1
    end

    selections << {ALL_MONSTERS[id], count}
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

decorate_text = DecorateWriter.render(all_variants)
Pk3Writer.write(decorate_text, output_path)

puts "Written to #{output_path}"
