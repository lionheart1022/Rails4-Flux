class UPSLabelConsolidation
  attr_reader :base64_encoded_gif_labels

  def initialize(base64_encoded_gif_labels)
    @base64_encoded_gif_labels = base64_encoded_gif_labels
  end

  def perform!
    identifier = SecureRandom.hex(3)

    tmp_label_files = base64_encoded_gif_labels.each_with_index.map do |base64_encoded_gif_label, index|
      tmp_label_file = Tempfile.new(["ups-label-#{identifier}-#{index}", ".png"], Rails.root.join("tmp"))
      tmp_label_file.binmode

      image = MiniMagick::Image.read(Base64.decode64(base64_encoded_gif_label), "gif")

      image.combine_options do |b|
        b.rotate "90" # Rotate 90-degrees clockwise
        b.crop "800x1210+0+0" # Crop ~200px whitespace from the bottom of the label
      end

      image.format("png") # Prawn does not support GIF, so we convert it here.
      image.write(tmp_label_file.path)

      tmp_label_file.rewind

      tmp_label_file
    end

    new_page = false
    @pdf = Prawn::Document.new(page_size: "A4", margin: 20, page_layout: :portrait) # Margin is ~0.7cm

    tmp_label_files.each do |label_file|
      @pdf.start_new_page if new_page
      @pdf.image label_file, width: 250, position: :left # Width is ~8.8cm
      new_page = true
    end
  end

  def write!(path)
    if @pdf
      @pdf.render_file(path)
    else
      raise "`#perform!` before `#write!`"
    end
  end
end
