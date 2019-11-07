class GLSDailyUpdatesFileParser
  class << self
    def from_path(path, fmode: "r:ISO-8859-1")
      file = File.new(path, fmode)
      new(file)
    end
  end

  HEADER_INDEX = 0
  HEADER_SEPARATOR_INDEX = 1

  attr_reader :file
  attr_reader :headers, :rows

  def initialize(file)
    @file = file
    @headers = []
    @rows = []
  end

  def parse
    line_index = -1

    until file.eof? do
      line = file.readline
      line_index += 1

      line_parts = line.split(";").map(&:strip)

      case line_index
      when HEADER_INDEX
        @headers = line_parts
      when HEADER_SEPARATOR_INDEX
        # noop
      else
        row = Hash[@headers.zip(line_parts)]
        @rows << row

        Rails.logger.tagged("GLSDailyUpdatesFileParser") do
          Rails.logger.debug(sprintf "%3d: %s", line_index, row.inspect)
        end
      end
    end
  end
end
