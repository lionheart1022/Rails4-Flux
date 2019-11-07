class CustomerImportExcelParser
  attr_reader :file
  attr_reader :company
  attr_reader :result

  def initialize(file:, company:)
    @file = file
    @company = company
  end

  def perform!
    workbook = Creek::Book.new(file.path)
    sheet = workbook.sheets[0]

    # First row in the file is the header row
    header_row = sheet.rows.first

    # The others are the actual rows with values
    rows = sheet.rows.drop(1)

    mapped_rows = rows.map do |row|
      CustomerImportRow.build_from_spreadsheet(row: row, header_row: header_row)
    end

    mapped_rows.reject!(&:blank_row?)
    mapped_rows.each(&:validate)

    @result = mapped_rows
  end

  def valid_row_count
    result.count { |row| row.errors.empty? } if result
  end

  def invalid_row_count
    result.count { |row| row.errors.any? } if result
  end

  def total_row_count
    result.count if result
  end
end
