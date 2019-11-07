class GLSFeedbackFile < CarrierFeedbackFile
  def header_label
    "GLS"
  end

  def utf8_string_io(force_reload = false)
    return @_utf8_io if defined?(@_utf8_io) && !force_reload

    utf8_contents = file_contents.dup
    utf8_contents.force_encoding("ISO-8859-1")
    utf8_contents.encode!("UTF-8")

    @_utf8_io = StringIO.new(utf8_contents)
  end

  def parse_file_and_persist_updates!
    parser = GLSDailyUpdatesFileParser.new(utf8_string_io)
    parser.parse

    parser.rows.each do |row|
      unique_identifier = row["Pakkenr"][0..-2] # The last digit is ignored, it is a check digit.

      matching_packages =
        GLSPackage
        .where(unique_identifier: unique_identifier)
        .order(id: :desc)
        .select { |package| package.shipment.carrier_product.get_credentials[:customer_id] == row["Kundenr"] }

      package_recording = nil
      package = matching_packages.first

      if package
        check_digit = row["Pakkenr"][-1]
        calculated_check_digit = calculate_check_digit(unique_identifier)

        if String(check_digit) == String(calculated_check_digit)
          Rails.logger.info "GLS.CheckDigit OK package=#{unique_identifier}"
        else
          Rails.logger.error "GLS.CheckDigit Error package=#{unique_identifier} (expected: #{check_digit}, calculated: #{calculated_check_digit})"
        end

        package_recording = PackageRecording.create!(
          package: package,
          weight_value: BigDecimal(row["Vægt"]),
          weight_unit: "kg",
          fee_data: {
            "SmallParcel" => row["SmallParcel"],
            "NotSystemConformal" => row["IkkeSystemKonform"],
            "OverSize" => row["OverSize"],
          }
        )
      end

      PackageUpdate.create!(
        feedback_file: self,
        package_recording: package_recording,
        package: package,
        metadata: row,
      )
    end
  end

  # The method can be found at: https://www.gs1.org/services/how-calculate-check-digit-manually
  def calculate_check_digit(identifier)
    if identifier
      sum = 0

      identifier.chars.reverse.each_with_index do |c, i|
        multiplier = (i % 2) == 0 ? 3 : 1 # Alternate between 3 and 1 (starting with 3 for the least significant digit)
        sum += Integer(c)*multiplier
      end

      # Subtract the sum from nearest equal or higher multiple of ten
      sum.fdiv(10).ceil*10 - sum
    end
  end
end
