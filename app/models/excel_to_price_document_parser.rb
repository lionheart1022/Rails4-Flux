class ExcelToPriceDocumentParser

  # Data
  COL_PRICES_TYPE               = 0
  COL_PRICES_NAME               = 1
  COL_PRICES_CALCULATION_METHOD = 2
  COL_PRICES_WEIGHT             = 4
  ROW_PRICES_ZONE_NAMES         = 2
  VERTICAL_SPLIT_INDICATOR      = 'end'

  ROW_PRICE_DATA_START      = 3
  COL_FIRST_ZONE_DATA_INDEX = 5

  # Price types
  CHARGE_TYPE_SHIPMENT      = 'shipment_charge'
  CHARGE_TYPE_SURCHARGE     = 'surcharge'
  CHARGE_TYPE_HEAVY_PACKAGE = 'heavy_package_charge'
  CHARGE_TYPE_LARGE_PACKAGE = 'large_package_charge'
  CHARGE_TYPE_IMPORT_CHARGE = 'import_charge'
  CHARGE_TYPE_DGR_CHARGE    = 'dgr_charge'

  # Calculation methods
  CALCULATION_METHOD_SINGLE       = 'price_single'
  CALCULATION_METHOD_WEIGHT_RANGE = 'price_weight_range'
  CALCULATION_METHOD_PERCENTAGE   = 'price_percentage'
  CALCULATION_METHOD_RANGE        = 'price_range'
  CALCULATION_METHOD_LOGIC        = 'price_logic'
  CALCULATION_METHOD_FIXED        = 'price_fixed'

  # Zones
  ROW_ZONE_DATA_START   = 1
  COL_ZONE_COUNTRY_CODE = 0
  COL_ZONE_COUNTRY_NAME = 1
  COL_ZONE_NAME         = 2
  COL_ZIP_CODES_START   = 3

  # Currency
  COL_CURRENCY = 0
  ROW_CURRENCY = 1
  CURRENCY     = 'currency'

  # Calculation basis
  COL_CALCULATION_BASIS = 1
  ROW_CALCULATION_BASIS = 1
  CALCULATION_BASIS_PACKAGE  = 'package'
  CALCULATION_BASIS_SHIPMENT = 'shipment'
  CALCULATION_BASIS_PALLET   = 'pallet'
  CALCULATION_BASIS_DISTANCE = 'distance'

  # Calculation precision
  BIG_DECIMAL_PRECISION = 10

  # Parse errors
  PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE = "Cannot complete price document"


  # Parses an excel document into a price document
  #
  # @param price_document_class [PriceDocumentV1]
  #
  # @return [PriceDocumentV1]
  def parse(price_document_class: nil, filename: nil)
    # @type [Array<PriceDocumentV1::ParseError>]
    parsing_errors = []

    @workbook = Creek::Book.new(filename, check_file_extension: false)
    Rails.logger.debug "Sheetnames: #{@workbook.sheets.map { |sheet| sheet.name }}"
    zones_worksheet = @workbook.sheets.select{ |sheet| sheet.name.downcase == 'zones' }.first
    Rails.logger.debug "ZoneSheet: #{zones_worksheet.name}"

    # Parse zones
    zones = parse_zones(price_document_class: price_document_class, existing_parsing_errors: parsing_errors, zones_worksheet: zones_worksheet)

    fatal_zone_parsing_errors = parsing_errors.select {|pe| pe.severity ==  PriceDocumentV1::ParseError::Severity::FATAL }
    if fatal_zone_parsing_errors.count > 0
      Rails.logger.debug("Fatal errors parsing zones")
      price_document = price_document_class.new(state: price_document_class::States::FAILED, zones: nil, zone_prices: nil, currency: nil, parsing_errors: parsing_errors)
      return price_document
    end

    # Parse prices
    prices_worksheets = @workbook.sheets
    currency, calculation_basis, zone_prices, zones = parse_prices_for_zones(price_document_class: price_document_class, existing_parsing_errors: parsing_errors, zones: zones, prices_worksheets: prices_worksheets)

    fatal_price_parsing_errors = parsing_errors.select {|pe| pe.severity ==  PriceDocumentV1::ParseError::Severity::FATAL }
    if fatal_price_parsing_errors.count > 0
      Rails.logger.debug("Fatal errors parsing prices")
      price_document = price_document_class.new(state: price_document_class::States::FAILED, zones: nil, zone_prices: nil, currency: nil, parsing_errors: parsing_errors)
      return price_document
    end

    warnings_price_parsing_errors = parsing_errors.select {|pe| pe.severity ==  PriceDocumentV1::ParseError::Severity::WARNING }
    if warnings_price_parsing_errors.count > 0
      Rails.logger.debug("Warning errors parsing prices")
      price_document = price_document_class.new(state: price_document_class::States::WARNINGS, zones: zones, zone_prices: zone_prices, currency: currency, calculation_basis: calculation_basis, parsing_errors: parsing_errors)
      return price_document
    end

    unless zones.blank? || zone_prices.blank?
      price_document = price_document_class.new(state: price_document_class::States::OK, zones: zones, zone_prices: zone_prices, currency: currency, calculation_basis: calculation_basis, parsing_errors: parsing_errors)
    else
      price_document = price_document_class.new(state: price_document_class::States::FAILED, zones: zones, zone_prices: zone_prices, currency: currency, calculation_basis: calculation_basis, parsing_errors: parsing_errors)
    end
    return price_document

  rescue => e
    Rails.logger.debug "Parsing Error: #{e.inspect}"
    e.backtrace.each { |line| Rails.logger.error line }
    parsing_errors << price_document_class::ParseError.new(description: 'An unknown error occured, unable to parse document', severity: price_document_class::ParseError::Severity::FATAL, consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
    price_document = price_document_class.new(state: price_document_class::States::FAILED, zones: nil, zone_prices: nil, currency: nil, parsing_errors: parsing_errors)

    return price_document
  end

  private

  # Parses the zones from an excel sheet
  #
  # @param price_document_class [PriceDocumentV1]
  # @param zones_worksheet [Creek::Sheet]
  #
  # @return [Array<PriceDocumentV1::Zone>]
  def parse_zones(price_document_class: nil, existing_parsing_errors: nil, zones_worksheet: nil)
    data = data_from_excel_sheet(zones_worksheet)

    zones = []
    row_index = ROW_ZONE_DATA_START

    # iterate through rows
    while (row_data = data[row_index])
      parse_zone_from_row(price_document_class: price_document_class, existing_zones: zones, existing_parsing_errors: existing_parsing_errors, current_row_index: row_index, row_data: row_data)
      row_index += 1
    end

    return zones
  end

  # @param price_document_class [PriceDocumentV1]
  # @param existing_zones [Array<PriceDocumentV1::Zone>]
  # @param row_data [Array]
  #
  # @return [PriceDocumentV1::Zone]
  def parse_zone_from_row(price_document_class: nil, existing_zones: nil, existing_parsing_errors: nil, current_row_index: nil, row_data: nil)
    name = row_data[COL_ZONE_NAME]
    if name.blank? # Don't add zones for which there is no name specified
      country_code = row_data[COL_ZONE_COUNTRY_CODE]
      unless country_code.nil?
        existing_parsing_errors << price_document_class::ParseError.new(description: "Zone name not specified for country code '#{country_code}'", severity: price_document_class::ParseError::Severity::WARNING, indices: [current_row_index, COL_ZONE_NAME], consequence: "Country code has been removed")
      end

      return nil
    end

    # find any existing zone or create new zone
    existing_zone = existing_zones.select { |zone| zone.name == name }.first
    zone = existing_zone ? existing_zone : price_document_class::Zone.new(name: name)

    # add zone country code
    country_code = row_data[COL_ZONE_COUNTRY_CODE].try(:downcase)
    if country_code.blank?
      existing_parsing_errors << price_document_class::ParseError.new(description: "Country code cannot be blank", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, COL_ZONE_COUNTRY_CODE], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)

      return nil
    end

    is_invalid_country_code = Country[country_code].nil?
    if is_invalid_country_code
      existing_parsing_errors << price_document_class::ParseError.new(description: "Country code '#{country_code}' does not resolve to a known country", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, COL_ZONE_COUNTRY_CODE], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)

      return nil
    end

    # check if zone already has been specified for zone
    country_already_specified_for_zone = zone.has_country_code?(country_code: country_code)
    if country_already_specified_for_zone
      existing_parsing_errors << price_document_class::ParseError.new(description: "Country code '#{country_code}' has already been specified for zone '#{zone.name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, COL_ZONE_COUNTRY_CODE], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)

      return nil
    end

    country = price_document_class::Zone::Country.new(country_code: country_code)

    # add any zip codes
    parsed_zip_codes = parse_zone_zip_codes_from_row(price_document_class: price_document_class, existing_zones: existing_zones, zone: zone, country: country, existing_parsing_errors: existing_parsing_errors, current_row_index: current_row_index, row_data: row_data)
    country.zip_codes += parsed_zip_codes

    zone.countries << country

    # add zone to zones array if it didn't already exist
    existing_zones << zone unless existing_zones.include?(zone)

    return zone
  end

  # @param price_document_class [PriceDocumentV1]
  # @param country_code [String]
  # @param row_data [Array]
  #
  # @return [Array<PriceDocumentV1::Zone::ZipCode, PriceDocumentV1::Zone::ZipCodeRange>]
  def parse_zone_zip_codes_from_row(price_document_class: nil, existing_zones: nil, zone: nil, country: nil, existing_parsing_errors: nil, current_row_index: nil, row_data: nil)
    column_index = COL_ZIP_CODES_START
    zip_codes    = []
    until row_data[column_index].blank?
      col_data     = row_data[column_index]
      current_cell = col_data.to_s
      Rails.logger.debug "CurrentCell: #{current_cell}"
      if current_cell.split('').include?('-')
        zip_ranges = current_cell.split('-').map{ |zipcode| zipcode.strip }

        # check that lower and upper bounds are present
        if zip_ranges.length != 2
          existing_parsing_errors << price_document_class::ParseError.new(description: "zip code range in expression '#{current_cell}' does not contain a lower and upper limit separated by a '-', e.g. '500-1000'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, COL_ZONE_COUNTRY_CODE], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
          return zip_codes
        end

        zip_low  = zip_ranges.first
        zip_high = zip_ranges.last

        # check that the lower bound is less than the upper bound
        if zip_high.to_i < zip_low.to_i
          existing_parsing_errors << price_document_class::ParseError.new(description: "upper bound of zip code range in expression '#{current_cell}' must be greater than the lower bound", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        end

        # check for overlap between zipcodes in current zone
        overlapping_zip_codes = zip_codes.select { |zip_code| zip_code.matches?(zip_code: zip_low) || zip_code.matches?(zip_code: zip_high) }
        unless overlapping_zip_codes.empty?
          existing_parsing_errors << price_document_class::ParseError.new(description: "Zip code '#{current_cell}' is overlapping with zip codes in '#{overlapping_zip_codes.join(', ')}' ", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        end

        # check for overlap between zipcodes of the same country, across zones
        zones_with_overlapping_zip_codes = existing_zones.select { |zone| zone.has_zip_code?(country_code: country.country_code, zip_code: zip_low) || zone.has_zip_code?(country_code: country.country_code, zip_code: zip_high) }
        unless zones_with_overlapping_zip_codes.empty?
          overlapping_zone_names = zones_with_overlapping_zip_codes.map { |zone| zone.name }
          existing_parsing_errors << price_document_class::ParseError.new(description: "Zip code '#{current_cell}' is overlapping with zip codes in zones '#{overlapping_zone_names.join(', ')}' ", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        end

        # ensure ranges low / high are numbers
        low_high_are_numbers = true
        if !is_numeric?(zip_low)
          existing_parsing_errors << price_document_class::ParseError.new(description: "Lower zip code in range '#{current_cell}' is not a number", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, COL_ZONE_COUNTRY_CODE], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
          low_high_are_numbers = false
        end

        if !is_numeric?(zip_high)
          existing_parsing_errors << price_document_class::ParseError.new(description: "Upper zip code in range '#{current_cell}' is not a number", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, COL_ZONE_COUNTRY_CODE], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
          low_high_are_numbers = false
        end
        return zip_codes unless low_high_are_numbers

        zip_codes << price_document_class::Zone::ZipCodeRange.new(zip_low: zip_low, zip_high: zip_high)
      else
        # check for overlap between zipcodes in current zone
        overlapping_zip_codes = zip_codes.select { |zip_code| zip_code.matches?(zip_code: current_cell) }
        unless overlapping_zip_codes.empty?
          existing_parsing_errors << price_document_class::ParseError.new(description: "Zip code '#{current_cell}' is overlapping with zip codes in '#{overlapping_zip_codes.join(', ')}' ", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        end

        # check for overlap between zipcodes of the same country, across zones
        zones_with_overlapping_zip_codes = existing_zones.select { |zone| zone.has_zip_code?(country_code: country.country_code, zip_code: current_cell) }
        unless zones_with_overlapping_zip_codes.empty?
          overlapping_zone_names = zones_with_overlapping_zip_codes.map { |zone| zone.name }
          existing_parsing_errors << price_document_class::ParseError.new(description: "Zip code '#{current_cell}' is overlapping with zip codes in zones '#{overlapping_zone_names.join(', ')}' ", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        end

        zip_codes << price_document_class::Zone::ZipCode.new(zip_code: current_cell)
      end
      column_index += 1
    end

    return zip_codes
  end

  # Parses the prices from an excel sheet
  #
  # @param price_document_class [PriceDocumentV1]
  # @param zones [Array<PriceDocumentV1::Zone>]
  # @param prices_worksheet [Creek::Sheet]
  def parse_prices_for_zones(price_document_class: nil, existing_parsing_errors: nil, zones: nil, prices_worksheets: nil)
    zone_prices       = []
    currency          = nil
    calculation_basis = nil

    prices_worksheets.each do |worksheet|
      parsed_weights = []
      data = data_from_excel_sheet(worksheet)

      # check if worksheet is a price document, not zone
      next unless data[0][0].try(:downcase) == CURRENCY

      # Currency
      currency = data[ROW_CURRENCY][COL_CURRENCY]

      # Validate currency
      unless Money::Currency.find(currency)
        existing_parsing_errors << price_document_class::ParseError.new(description: "Currency '#{currency}' does not resolve to a known currency", severity: price_document_class::ParseError::Severity::FATAL, indices: [ROW_CURRENCY, COL_CURRENCY], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        return nil, nil, zones
      end

      # Calculation basis
      allowed_calculation_bases = [CALCULATION_BASIS_PACKAGE, CALCULATION_BASIS_SHIPMENT, CALCULATION_BASIS_PALLET, CALCULATION_BASIS_DISTANCE]
      calculation_basis = data[ROW_CALCULATION_BASIS][COL_CALCULATION_BASIS].try(:downcase)

      unless allowed_calculation_bases.include?(calculation_basis)
        existing_parsing_errors << price_document_class::ParseError.new(description: "No calculation basis specified. Must be either 'package', 'shipment', 'pallet' or 'distance'", severity: price_document_class::ParseError::Severity::FATAL, indices: [ROW_CALCULATION_BASIS, COL_CALCULATION_BASIS], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        return nil, nil, zones
      end

      column_index = COL_FIRST_ZONE_DATA_INDEX

      # Check zones in price worksheet are specified in zones worksheet
      #  check_zones_from_prices_is_present_in_zone_sheet(price_document_class: price_document_class, existing_parsing_errors: existing_parsing_errors, zones: zones, data: data)

      # Check that no weights are overlapping or specified more than once
      check_weight_uniqueness(price_document_class: price_document_class, existing_parsing_errors: existing_parsing_errors, data: data)

      zone_name  = data[ROW_PRICES_ZONE_NAMES][column_index]

      # iterate through each zone and find price data for each
      until zone_name.blank?
        zone = zones.select { |zone| zone.name == zone_name }.first

        # check if zone is specified in zones worksheet
        if zone.blank?
          existing_parsing_errors << price_document_class::ParseError.new(description: "Zone '#{zone_name}' doesn't match any of the zones specified in the zones worksheet", severity: price_document_class::ParseError::Severity::FATAL, indices: [ROW_PRICES_ZONE_NAMES, column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
          return
        end

        row_index  = ROW_PRICE_DATA_START
        zone_price = price_document_class::ZonePrice.new(zone: zone)

        charge_type                = data[row_index][COL_PRICES_TYPE]
        current_calculation_method = data[row_index][COL_PRICES_CALCULATION_METHOD]

        until data[row_index].blank?
          row_data = data[row_index]
          Rails.logger.debug "row: #{row_index} col: #{column_index}"

          charge_type                = row_data[COL_PRICES_TYPE] unless row_data[COL_PRICES_TYPE].blank?
          name                       = row_data[COL_PRICES_NAME] unless row_data[COL_PRICES_NAME].blank?
          current_calculation_method = row_data[COL_PRICES_CALCULATION_METHOD] unless row_data[COL_PRICES_CALCULATION_METHOD].blank?

          if charge_type == CHARGE_TYPE_SHIPMENT
            row_index = parse_calculation_method(price_document_class: price_document_class, parsed_weights: parsed_weights, allowed_calculation_methods: [CALCULATION_METHOD_SINGLE, CALCULATION_METHOD_WEIGHT_RANGE, CALCULATION_METHOD_RANGE], existing_parsing_errors: existing_parsing_errors, current_charge_type: charge_type, current_charge_type_name: name, data: data, current_row_index: row_index, current_column_index: column_index, zone_price: zone_price, calculation_method: current_calculation_method)
          elsif charge_type == CHARGE_TYPE_SURCHARGE
            row_index = parse_calculation_method(price_document_class: price_document_class, allowed_calculation_methods: [CALCULATION_METHOD_PERCENTAGE, CALCULATION_METHOD_RANGE, CALCULATION_METHOD_FIXED], existing_parsing_errors: existing_parsing_errors, current_charge_type: charge_type, current_charge_type_name: name, data: data, current_row_index: row_index, current_column_index: column_index, zone_price: zone_price, calculation_method: current_calculation_method)
          elsif charge_type == CHARGE_TYPE_DGR_CHARGE
            row_index = parse_calculation_method(price_document_class: price_document_class, allowed_calculation_methods: [CALCULATION_METHOD_PERCENTAGE, CALCULATION_METHOD_RANGE, CALCULATION_METHOD_FIXED], existing_parsing_errors: existing_parsing_errors, current_charge_type: charge_type, current_charge_type_name: name, data: data, current_row_index: row_index, current_column_index: column_index, zone_price: zone_price, calculation_method: current_calculation_method)
          elsif [CHARGE_TYPE_IMPORT_CHARGE, CHARGE_TYPE_HEAVY_PACKAGE, CHARGE_TYPE_LARGE_PACKAGE].include?(charge_type)
            row_index = parse_calculation_method(price_document_class: price_document_class, allowed_calculation_methods: [CALCULATION_METHOD_LOGIC], existing_parsing_errors: existing_parsing_errors, current_charge_type: charge_type, current_charge_type_name: name, data: data, current_row_index: row_index, current_column_index: column_index, zone_price: zone_price, calculation_method: current_calculation_method)
          else
            existing_parsing_errors << price_document_class::ParseError.new(description: "Charge type '#{charge_type}' not recognized", severity: price_document_class::ParseError::Severity::FATAL, indices: [row_index, COL_PRICES_TYPE], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
            break
          end
          zone_prices << zone_price

          break if row_index.nil?
        end

        column_index += 1
        zone_name  = data[ROW_PRICES_ZONE_NAMES][column_index] # Not correct index

      end

    end

    zone_prices.uniq! # Each zoneprice is parsed twice for some reason, find out why
    return currency, calculation_basis, zone_prices, zones
  end

  # Parses the current calculation method from the data
  #
  # @return [Integer] new row index after parsing
  def parse_calculation_method(price_document_class: nil, parsed_weights: nil, allowed_calculation_methods: [], existing_parsing_errors: nil, current_charge_type: nil, current_charge_type_name: nil, data: nil, current_row_index: nil, current_column_index: nil, zone_price: nil, calculation_method: nil)
    unless allowed_calculation_methods.include?(calculation_method)
      existing_parsing_errors << price_document_class::ParseError.new(description: "Charge type '#{current_charge_type}' used calculation method '#{calculation_method}' only allows calculation methods [#{allowed_calculation_methods.join(", ")}]", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, current_column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      return nil
    end

    zone_name = zone_price.zone.name

    if calculation_method == CALCULATION_METHOD_SINGLE

      unless is_numeric?(data[current_row_index][COL_PRICES_WEIGHT])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No weight specified price single in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        weight = BigDecimal.new(data[current_row_index][COL_PRICES_WEIGHT], BIG_DECIMAL_PRECISION)
      end

      unless is_numeric?(data[current_row_index][current_column_index])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No price specified for weight #{weight} in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, current_column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        amount = BigDecimal.new(data[current_row_index][current_column_index], BIG_DECIMAL_PRECISION)
      end

      zone_price.charges << price_document_class::FlatWeightCharge.new(identifier: current_charge_type, name: current_charge_type_name, type: calculation_method, weight: weight, amount: amount)
      return current_row_index + 1
    elsif calculation_method == CALCULATION_METHOD_WEIGHT_RANGE

      structure = parse_calculation_method_structure(price_document_class: price_document_class, existing_parsing_errors: existing_parsing_errors, current_charge_type_name: current_charge_type_name, data: data, current_row_index: current_row_index, current_column_index: current_column_index, calculation_method: calculation_method)
      return unless structure

      # Check if lower weight bound is specified
      unless is_numeric?(data[current_row_index][COL_PRICES_WEIGHT])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No lower weight bound specified for weight range charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        weight_low = BigDecimal.new(data[current_row_index][COL_PRICES_WEIGHT], BIG_DECIMAL_PRECISION)
      end

      # Check if upper weight bound is specified
      unless is_numeric?(data[current_row_index + 1][COL_PRICES_WEIGHT])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No upper weight bound specified for weight range charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index + 1, current_column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        weight_high = BigDecimal.new(data[current_row_index + 1][COL_PRICES_WEIGHT], BIG_DECIMAL_PRECISION)
      end
      
      # Check lower price bound is specified
      unless is_numeric?(data[current_row_index][current_column_index])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No lower price bound specified for weight range charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, current_column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        price_low = BigDecimal.new(data[current_row_index][current_column_index], BIG_DECIMAL_PRECISION)
      end

      # Check if price per interval is specified
      unless is_numeric?(data[current_row_index + 2][current_column_index])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No price per interval specified for weight range charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index + 2, current_column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        price_per_interval = BigDecimal.new(data[current_row_index + 2][current_column_index], BIG_DECIMAL_PRECISION)
      end

      # Check if interval is specified
      unless is_numeric?(data[current_row_index + 2][COL_PRICES_WEIGHT])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No interval specified for weight range charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index + 3, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        interval = BigDecimal.new(data[current_row_index + 2][COL_PRICES_WEIGHT], BIG_DECIMAL_PRECISION)
      end

      zone_price.charges << price_document_class::WeightRangeCharge.new(identifier: current_charge_type, name: current_charge_type_name, type: calculation_method, weight_low: weight_low, weight_high: weight_high, price_low: price_low, interval: interval, price_per_interval: price_per_interval)
      return current_row_index + 3
    elsif calculation_method == CALCULATION_METHOD_PERCENTAGE

      # Check if percentage is specified
      unless is_numeric?(data[current_row_index][current_column_index])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No percentage specified for relative charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, current_column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        percentage = BigDecimal.new(data[current_row_index ][current_column_index], BIG_DECIMAL_PRECISION)
      end

      zone_price.charges << price_document_class::RelativeCharge.new(identifier: current_charge_type, name: current_charge_type_name, type: calculation_method, percentage: percentage)
      return current_row_index + 1
    elsif calculation_method == CALCULATION_METHOD_RANGE

      # Parse structure
      structure = parse_calculation_method_structure(price_document_class: price_document_class, existing_parsing_errors: existing_parsing_errors, current_charge_type_name: current_charge_type_name, data: data, current_row_index: current_row_index, current_column_index: current_column_index, calculation_method: calculation_method)
      return unless structure

      # Check if upper price bound is specified
      unless is_numeric?(data[current_row_index][current_column_index])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No lower price bound specified for range charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, current_column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        price_low = BigDecimal.new(data[current_row_index][current_column_index], BIG_DECIMAL_PRECISION)
      end
      
      # Check upper price bound is specified
      unless is_numeric?(data[current_row_index + 1][current_column_index])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No upper price bound specified for range charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index + 1, current_column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        price_high = BigDecimal.new(data[current_row_index + 1][current_column_index], BIG_DECIMAL_PRECISION)
      end

      # Check if price per interval is specified
      unless is_numeric?(data[current_row_index + 2][current_column_index])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No price per interval specified for range charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index + 2, current_column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        price_per_interval = BigDecimal.new(data[current_row_index + 2][current_column_index], BIG_DECIMAL_PRECISION)
      end

      # Check if interval is specified
      unless is_numeric?(data[current_row_index + 2][COL_PRICES_WEIGHT])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No interval specified for range charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index + 2, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        interval = BigDecimal.new(data[current_row_index + 2][COL_PRICES_WEIGHT], BIG_DECIMAL_PRECISION)
      end

      price_low          = BigDecimal.new(data[current_row_index][current_column_index], BIG_DECIMAL_PRECISION)
      price_high         = BigDecimal.new(data[current_row_index + 1][current_column_index], BIG_DECIMAL_PRECISION)
      price_per_interval = BigDecimal.new(data[current_row_index + 2][current_column_index], BIG_DECIMAL_PRECISION)
      interval           = BigDecimal.new(data[current_row_index + 2][COL_PRICES_WEIGHT], BIG_DECIMAL_PRECISION)

      zone_price.charges << price_document_class::RangeCharge.new(identifier: current_charge_type, name: current_charge_type_name, type: calculation_method, price_low: price_low, price_high: price_high, interval: interval, price_per_interval: price_per_interval)
      return current_row_index + 3
    elsif calculation_method == CALCULATION_METHOD_FIXED

      unless is_numeric?(data[current_row_index][current_column_index])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No amount specified for fixed charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, current_column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        amount = BigDecimal.new(data[current_row_index][current_column_index], BIG_DECIMAL_PRECISION)
      end

      zone_price.charges << price_document_class::FlatCharge.new(identifier: current_charge_type, name: current_charge_type_name, type: calculation_method, amount: amount)
      return current_row_index + 1
    elsif calculation_method == CALCULATION_METHOD_LOGIC

       # Check if theshold is specified
      unless is_numeric?(data[current_row_index][current_column_index])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No threshold specified for logic charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, current_column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        threshold = BigDecimal.new(data[current_row_index][current_column_index], BIG_DECIMAL_PRECISION)
      end

      # Check if amount is specified
      unless is_numeric?(data[current_row_index + 1][current_column_index])
        existing_parsing_errors << price_document_class::ParseError.new(description: "No amount specified for logic charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index + 1, current_column_index], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      else
        amount = BigDecimal.new(data[current_row_index + 1][current_column_index], BIG_DECIMAL_PRECISION)
      end

      if current_charge_type_name.blank?
        existing_parsing_errors << price_document_class::ParseError.new(description: "No name specified for logic charge in zone '#{zone_name}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, COL_PRICES_NAME], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      end

      if current_charge_type == CHARGE_TYPE_LARGE_PACKAGE && price_document_class.constants.include?(:LargePackageCharge)
        zone_price.charges << price_document_class::LargePackageCharge.new(identifier: current_charge_type, name: current_charge_type_name, type: calculation_method, threshold: threshold, amount: amount)
      elsif current_charge_type == CHARGE_TYPE_HEAVY_PACKAGE && price_document_class.constants.include?(:HeavyPackageCharge)
        zone_price.charges << price_document_class::HeavyPackageCharge.new(identifier: current_charge_type, name: current_charge_type_name, type: calculation_method, threshold: threshold, amount: amount)
      elsif current_charge_type == CHARGE_TYPE_IMPORT_CHARGE && price_document_class.constants.include?(:ImportCharge)
        zone_price.charges << price_document_class::ImportCharge.new(identifier: current_charge_type, name: current_charge_type_name, type: calculation_method, threshold: threshold, amount: amount)
      end
      return current_row_index + 2
    else
      return current_row_index + 1
    end
  end

  # Checks presence of all the calculation method's parameters, if any
  #
  # @return [Boolean]
  def parse_calculation_method_structure(price_document_class: nil, existing_parsing_errors: nil, current_charge_type_name: nil, data: nil, current_row_index: nil, current_column_index: nil, calculation_method: nil)

    if calculation_method == CALCULATION_METHOD_RANGE
      parameters = ['interval']
      
      name      = data[current_row_index + 2][COL_PRICES_NAME]
      method    = data[current_row_index + 2][COL_PRICES_CALCULATION_METHOD]
      parameter = data[current_row_index + 2][COL_PRICES_WEIGHT]

      # Throw error is missing parameter
      unless (name == current_charge_type_name || name.blank?) && (method == calculation_method || method.blank?) && is_numeric?(parameter)
        existing_parsing_errors << price_document_class::ParseError.new(description: "No '#{parameters[0]}' specified for range charge", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index + 2, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        return false
      end
      
      # Throw error if additional paramater is added accidentaly
      return true if data[current_row_index + 3].nil?
      
      calculation_method_is_blank = data[current_row_index + 3][COL_PRICES_CALCULATION_METHOD].blank?
      parameter_is_specified      = data[current_row_index + 3][COL_PRICES_WEIGHT].present?
      
      if calculation_method_is_blank && parameter_is_specified
        existing_parsing_errors << price_document_class::ParseError.new(description: "Unknown parameter for range charge", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index + 3, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        return false
      end

    elsif calculation_method == CALCULATION_METHOD_WEIGHT_RANGE
      parameters = ['min kg', 'max kg', 'interval']
      values     = {}

      (0..2).to_a.each do |i|
        name      = data[current_row_index + i][COL_PRICES_NAME]
        method    = data[current_row_index + i][COL_PRICES_CALCULATION_METHOD]
        parameter = data[current_row_index + i][COL_PRICES_WEIGHT]
        values[parameters[i]] = parameter

        # Throw error is missing parameter
        unless (name == current_charge_type_name || name.blank?) && (method == calculation_method || method.blank?) && is_numeric?(parameter)
          existing_parsing_errors << price_document_class::ParseError.new(description: "No '#{parameters[i]}' specified for weight range charge", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index + i, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
          return false
        end

      end

      # Check that weight low <= weight high
      unless values['min kg'].to_f <= values['max kg'].to_f
        existing_parsing_errors << price_document_class::ParseError.new(description: "'min kg' cannot be higher than 'max kg'", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
      end

      # Throw error if additional paramater is added accidentaly
      return true if data[current_row_index + 3].nil?
      
      calculation_method_is_blank = data[current_row_index + 3][COL_PRICES_CALCULATION_METHOD].blank?
      parameter_is_specified      = data[current_row_index + 3][COL_PRICES_WEIGHT].present?

      if calculation_method_is_blank && parameter_is_specified
        existing_parsing_errors << price_document_class::ParseError.new(description: "Unknown parameter for weight range charge", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index + 3, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        return false
      end

    end

    return true
  rescue => e
    Rails.logger.debug "Calculation method error: #{e}"
    existing_parsing_errors << price_document_class::ParseError.new(description: "An error occured trying to parse calculation method", severity: price_document_class::ParseError::Severity::FATAL, indices: [current_row_index, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
    return false
  end

  # Checks if any weights are overlapping or specified more than once
  def check_weight_uniqueness(price_document_class: nil, existing_parsing_errors: nil, data: nil)
    parsed_weights       = []
    parsed_weight_ranges = []
    row_index = ROW_PRICE_DATA_START

    current_method = nil
    return if data[row_index].blank?

    more_data                     = !data[row_index].blank?
    price_type_is_shipment_charge = data[row_index].try(:[], COL_PRICES_TYPE) == CHARGE_TYPE_SHIPMENT
    price_type_is_blank           = data[row_index].try(:[], COL_PRICES_TYPE).blank?

    while more_data && (price_type_is_shipment_charge || price_type_is_blank)
      row_method     = data[row_index][COL_PRICES_CALCULATION_METHOD]
      current_method = data[row_index][COL_PRICES_CALCULATION_METHOD] if current_method.nil? || !row_method.blank? && row_method != current_method

      if current_method == CALCULATION_METHOD_SINGLE
        weight = data[row_index][COL_PRICES_WEIGHT].to_f

        # check if weight is specified more than once
        duplicates = parsed_weights.include?(weight)

        overlapping_weight_range = nil
        # check if weight is overlapping with any weight ranges
        overlap    = parsed_weight_ranges.any? do |wr| 
          if weight >= wr.weight_low && weight <= wr.weight_high 
            overlapping_weight_range = wr
            true
          end
        end

        if duplicates
          existing_parsing_errors << price_document_class::ParseError.new(description: "Weight '#{weight}' is specified more than once", severity: price_document_class::ParseError::Severity::FATAL, indices: [row_index, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        elsif overlap
          existing_parsing_errors << price_document_class::ParseError.new(description: "Weight '#{weight}' is overlapping with weight range '#{overlapping_weight_range.weight_low} - #{overlapping_weight_range.weight_high}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [row_index, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        else
          parsed_weights << weight
        end

        row_index += 1
      elsif current_method == CALCULATION_METHOD_WEIGHT_RANGE
        Rails.logger.debug "Row #{row_index} data: #{data[row_index]}"
        Rails.logger.debug "Row #{row_index + 1} data: #{data[row_index + 1]}" 
        Rails.logger.debug "Row #{row_index + 2} data: #{data[row_index + 2]}"

        
        weight_low  = data[row_index][COL_PRICES_WEIGHT].to_f
        weight_high = data[row_index + 1][COL_PRICES_WEIGHT].to_f
        
        weight_range = PriceDocumentV1::WeightRangeCharge.new(weight_low: weight_low, weight_high: weight_high)

        # check if weight range is overlapping with other weight ranges
        overlapping_weight_range = nil
        weight_range_overlap  = parsed_weight_ranges.any? do |wr| 
          if weight_low >= wr.weight_low && weight_low <= wr.weight_high || weight_high >= wr.weight_low && weight_high <= wr.weight_high
            overlapping_weight_range = wr
            true
          end
        end

        overlapping_weight = nil
        # check if weight range is overlapping with other flat weight charges
        weight_single_overlap = parsed_weights.any? do |weight|
          if weight >= weight_low && weight <= weight_high
            overlapping_weight = weight
            true
          end
        end

        if weight_range_overlap
          existing_parsing_errors << price_document_class::ParseError.new(description: "Weight range '#{weight_low} - #{weight_high}' is overlapping with weight range '#{overlapping_weight_range.weight_low} - #{overlapping_weight_range.weight_high}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [row_index, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        elsif weight_single_overlap
          existing_parsing_errors << price_document_class::ParseError.new(description: "Weight range '#{weight_low} - #{weight_high}' is overlapping with weight '#{overlapping_weight}'", severity: price_document_class::ParseError::Severity::FATAL, indices: [row_index, COL_PRICES_WEIGHT], consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
        else
          parsed_weight_ranges << weight_range
        end
        row_index += 3
      else
        row_index += 1
      end
      more_data                     = !data[row_index].blank?
      price_type_is_shipment_charge = data[row_index].try(:[], COL_PRICES_TYPE) == CHARGE_TYPE_SHIPMENT
      price_type_is_blank           = data[row_index].try(:[], COL_PRICES_TYPE).blank?

    end

  end

  # # Check if all the zones in price worksheet are specified in zones worksheet
  # # 
  # # @return [Boolean]
  # def check_zones_from_prices_is_present_in_zone_sheet(price_document_class: nil, existing_parsing_errors: nil, zones: nil, data: nil)
  #   matches    = 0
  #   zone_names = zones.map{ |z| z.name }
  #   col_index = COL_FIRST_ZONE_DATA_INDEX

  #   until data[ROW_PRICE_DATA_START - 1][col_index].blank?
  #     zone_name = data[ROW_PRICE_DATA_START - 1][col_index]
  #     if zone_names.include?(zone_name)
  #       zone_names.delete(zone_name)
  #       matches += 1
  #     else
  #       existing_parsing_errors << price_document_class::ParseError.new(description: "Zone '#{zone_name}' doesn't match any of the zones specified in the zone worksheet", severity: price_document_class::ParseError::Severity::FATAL, consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
  #     end
  #     col_index += 1
  #   end
  #   unless zone_names.empty?
  #     existing_parsing_errors << price_document_class::ParseError.new(description: "Zones [#{zone_names.join(', ')}] arent specified in the prices worksheet", severity: price_document_class::ParseError::Severity::FATAL, consequence: PARSE_ERROR_CONSEQUENCE_CANNOT_COMPLETE)
  #     return false
  #   end
  #   true
  # end

  # Converts data from the excel sheet into an array of arrays with data
  #
  # @param [Creek::Sheet]
  #
  # @return [Array<Array>]
  def data_from_excel_sheet(excel_sheet)
    data            = []
    letter_range    = 'A'..'ZZ'
    prices_row_data = excel_sheet.rows.to_a

    prices_row_data.each_with_index.map do |row, row_idx|
      col_idx_range   = 0..(row.length-1)
      excel_col_names = col_idx_range.map { |col_idx| "#{letter_range.to_a[col_idx]}#{row_idx+1}" }

      data << excel_col_names.map { |col_name| row[col_name].to_s }
    end
    data.each do |row| Rails.logger.debug row end
    data
  end

  def is_numeric?(string)
    Float(string) != nil rescue false
  end
end