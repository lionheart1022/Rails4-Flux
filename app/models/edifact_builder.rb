class EdifactBuilder
  COMPONENT_DATA_ELEMENT_SEPARATOR =  ":"
  DATA_ELEMENT_SEPARATOR =  "+"
  DECIMAL_MARK =  "."
  RELEASE_CHARACTER =  "?"
  SEGMENT_TERMINATOR =  "'"

  attr_reader :number_of_segments

  def initialize
    @raw_segments = []
    @number_of_segments = 0
  end

  def add(segment_identifier, segment_data)
    new_segment = Segment.new(segment_identifier, segment_data)
    @raw_segments << new_segment
    @number_of_segments += 1

    new_segment
  end

  def una_segment
    "UNA:+.? '"
  end

  def as_string(separate_segments_with_newline: false)
    doc_segments = []
    doc_segments << una_segment
    doc_segments.concat @raw_segments.map { |segment| format_segment(segment) }

    doc_segments.join(separate_segments_with_newline ? "\n" : "")
  end

  private

  def format_segment(segment)
    s = ""
    s << "#{segment.identifier}"

    if segment.data.present?
      cs =
        segment.data.map do |component|
          Array(component).map { |value| format_value(value) }.join(COMPONENT_DATA_ELEMENT_SEPARATOR)
        end

      s << DATA_ELEMENT_SEPARATOR + cs.join(DATA_ELEMENT_SEPARATOR)
    end

    s << SEGMENT_TERMINATOR

    s
  end

  def format_value(value)
    escape_pattern = %r{(\:|\+|\?|\')}

    encoded_value = String(value).encode("ISO-8859-1", invalid: :replace, undef: :replace)
    encoded_value.encode("UTF-8").gsub(escape_pattern, '?\1')
  end

  Segment = Struct.new(:identifier, :data)
end
