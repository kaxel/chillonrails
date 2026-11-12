# Reads the pixel size and type of a JPEG, PNG, GIF, or WebP file from its
# header, without an image library. Used for link-preview tags
# (og:image:width/height/type), which help iMessage, Facebook, and others
# lay out the card before downloading the image.
module ImageDimensions
  Info = Struct.new(:type, :width, :height)

  module_function

  # Returns an Info, or nil when the file is missing or not a supported image.
  def read(path)
    File.open(path, "rb") { |file| from_io(file) }
  rescue SystemCallError, IOError
    nil
  end

  def from_io(io)
    head = io.read(30).to_s.b
    if head.start_with?("\x89PNG\r\n\x1A\n".b)
      Info.new("image/png", *head[16, 8].unpack("NN"))
    elsif head.start_with?("GIF87a", "GIF89a")
      Info.new("image/gif", *head[6, 4].unpack("vv"))
    elsif head.start_with?("\xFF\xD8".b)
      jpeg(io)
    elsif head.start_with?("RIFF") && head[8, 4] == "WEBP"
      webp(head)
    end
  end

  # Walk the JPEG segments to the first start-of-frame marker, which holds the size.
  def jpeg(io)
    io.seek(2)
    loop do
      marker = io.read(2)&.unpack("CC")
      return nil unless marker && marker[0] == 0xFF

      length = io.read(2)&.unpack1("n")
      return nil unless length

      if (0xC0..0xCF).cover?(marker[1]) && [ 0xC4, 0xC8, 0xCC ].exclude?(marker[1])
        height, width = io.read(5).unpack("xnn")
        return Info.new("image/jpeg", width, height)
      end
      io.seek(length - 2, IO::SEEK_CUR)
    end
  end

  def webp(head)
    case head[12, 4]
    when "VP8 " # lossy
      width, height = head[26, 4].unpack("vv")
      Info.new("image/webp", width & 0x3FFF, height & 0x3FFF)
    when "VP8L" # lossless
      bits = head[21, 4].unpack1("V")
      Info.new("image/webp", (bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1)
    when "VP8X" # extended
      w = head[24, 3].unpack("CCC")
      h = head[27, 3].unpack("CCC")
      Info.new("image/webp", (w[0] | w[1] << 8 | w[2] << 16) + 1, (h[0] | h[1] << 8 | h[2] << 16) + 1)
    end
  end
end
