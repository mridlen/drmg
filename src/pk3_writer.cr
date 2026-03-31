# src/pk3_writer.cr
require "compress/zip"

module Pk3Writer
  # Writes `decorate_content` into a PK3 (ZIP) file at `output_path`.
  # The PK3 contains a single entry named "DECORATE".
  def self.write(decorate_content : String, output_path : String)
    File.open(output_path, "w") do |file|
      Compress::Zip::Writer.open(file) do |zip|
        zip.add("DECORATE", IO::Memory.new(decorate_content))
      end
    end
  end
end
