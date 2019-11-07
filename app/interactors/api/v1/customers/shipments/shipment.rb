class API::V1::Customers::Shipments::Shipment < ApplicationInteractor

  def initialize(company_id: nil, customer_id: nil, scoped_customer_id: nil, shipment_data: nil, sender_data: nil, recipient_data: nil, pickup_data: nil, token: nil, callback_url: nil)
    @company_id         = company_id
    @customer_id        = customer_id
    @scoped_customer_id = scoped_customer_id
    @shipment_data      = shipment_data
    @sender_data        = sender_data
    @recipient_data     = recipient_data
    @pickup_data        = pickup_data
    @token              = token
    @callback_url       = callback_url
    return self
  end

  def check_defaults
    check_callback_url
    check_product_code
    check_access_to_product
    check_return_label
    check_package_dimensions
    check_shipping_date
    check_customs
    check_delivery_instructions
    check_contact
    check_dgr
    check_pickup
  end

  def check_callback_url
    raise APIRequestError.new(code: APIRequestError::Codes::CALLBACK_MISSING, message: APIRequestError::Messages::CALLBACK_MISSING) if @callback_url.blank?
  end

  def check_return_label
    return_label = @shipment_data[:return_label]
    return if !return_label

    carrier_product_id    = @shipment_data[:carrier_product_id]
    carrier_product       = CarrierProduct.find_company_carrier_product(company_id: @company_id, carrier_product_id: carrier_product_id)
    supports_return_label = carrier_product.supports_return_label?

    raise APIRequestError.new(code: APIRequestError::Codes::RETURN_LABEL_NOT_SUPPORTED, message: APIRequestError::Messages::RETURN_LABEL_NOT_SUPPORTED) if !supports_return_label
  end

  def check_product_code
    carrier_product = CarrierProduct.find_carrier_product_from_product_code(product_code: @shipment_data[:product_code]) if @shipment_data[:product_code].present?

    product_code_not_found = carrier_product.nil?
    raise APIRequestError.new(code: APIRequestError::Codes::INVALID_PRODUCT_CODE, message: APIRequestError::Messages::INVALID_PRODUCT_CODE) if product_code_not_found
  end

  def check_access_to_product
    @carrier_product = CarrierProduct.find_enabled_customer_carrier_product_from_product_code(customer_id: @customer_id, product_code: @shipment_data[:product_code])
    raise APIRequestError.new(code: APIRequestError::Codes::NO_ACCESS_TO_PRODUCT, message: APIRequestError::Messages::NO_ACCESS_TO_PRODUCT) if @carrier_product.blank?
    @shipment_data[:carrier_product_id] = @carrier_product.id
  end

  def check_package_dimensions
    @shipment_data[:package_dimensions] = parse_package_dimensions(dimensions_array: @shipment_data[:package_dimensions])
    raise APIRequestError.new(code: APIRequestError::Codes::INVALID_PACKAGE_DIMENSIONS, message: APIRequestError::Messages::INVALID_PACKAGE_DIMENSIONS) if @shipment_data[:package_dimensions].blank?

  rescue => e
    Rails.logger.debug "\n\nPD ERROR #{e.inspect}"
    raise APIRequestError.new(code: APIRequestError::Codes::INVALID_PACKAGE_DIMENSIONS, message: APIRequestError::Messages::INVALID_PACKAGE_DIMENSIONS)
  end

  def check_shipping_date
    @shipment_data[:shipping_date] = Date.parse(@shipment_data[:shipping_date])
  rescue => e
    Rails.logger.debug "\n\ #{e.inspect}\n\n"

    raise APIRequestError.new(code: APIRequestError::Codes::INVALID_SHIPPING_DATE, message: APIRequestError::Messages::INVALID_SHIPPING_DATE)
  end

  def check_customs
    return if !@shipment_data[:dutiable]

    customs_amount   = @shipment_data[:customs_amount]
    customs_currency = @shipment_data[:customs_currency]
    customs_code     = @shipment_data[:customs_code]

    all_customs_fields_specified = customs_amount.present? && customs_currency.present? && customs_code.present?
    raise APIRequestError.new(code: APIRequestError::Codes::INVALID_CUSTOMS_INFORMATION, message: APIRequestError::Messages::INVALID_CUSTOMS_INFORMATION) if !all_customs_fields_specified
  end

  def check_delivery_instructions
    return if !@shipment_data[:delivery_instructions]

    raise APIRequestError.new(code: APIRequestError::Codes::DELIVERY_INSTRUCTIONS_NOT_SUPPORTED, message: APIRequestError::Messages::DELIVERY_INSTRUCTIONS_NOT_SUPPORTED) if !@carrier_product.supports_delivery_instructions?
  end

  def check_contact
    required_fields = [:company_name, :attention, :address_line1, :country_code, :city, :zip_code]

    required_fields.each do |field|
      raise APIRequestError.new(message: "Invalid or missing Sender field: #{field}") if @sender_data[field].blank?
      raise APIRequestError.new(message: "Invalid or missing Recipient field: #{field}") if @recipient_data[field].blank?
    end

    unless Country.find_country_by_alpha2(@sender_data[:country_code])
      raise APIRequestError.new(message: "Invalid sender field: country code")
    end

    unless Country.find_country_by_alpha2(@recipient_data[:country_code])
      raise APIRequestError.new(message: "Invalid recipient field: country code")
    end
  end

  def check_dgr
    if !@shipment_data[:dangerous_goods] && @shipment_data[:dangerous_goods_predefined_option].blank?
      return
    end

    if !@shipment_data[:dangerous_goods] && @shipment_data[:dangerous_goods_predefined_option].present?
      raise APIRequestError.new(code: APIRequestError::Codes::DGR_NOT_ENABLED_OPTION_GIVEN, message: APIRequestError::Messages::DGR_NOT_ENABLED_OPTION_GIVEN)
    end

    customer = ::Customer.where(company_id: @company_id).find(@customer_id)

    if !@shipment_data[:dangerous_goods] && customer.allow_dangerous_goods?
      raise APIRequestError.new(code: APIRequestError::Codes::DGR_NOT_ALLOWED, message: APIRequestError::Messages::DGR_NOT_ALLOWED)
    end

    supported_predefined_options = %w(
      dry_ice
      lithium_ion_UN3481_PI966
      lithium_ion_UN3481_PI967
      lithium_metal_UN3091_PI969
      lithium_metal_UN3091_PI970
    )

    if @shipment_data[:dangerous_goods_predefined_option].present? && !supported_predefined_options.include?(@shipment_data[:dangerous_goods_predefined_option])
      raise APIRequestError.new(code: APIRequestError::Codes::DGR_INVALID_IDENTIFIER, message: APIRequestError::Messages::DGR_INVALID_IDENTIFIER)
    end
  end

  def check_pickup
    return if @pickup_data.blank?

    customer = ::Customer.where(company_id: @company_id).find(@customer_id)
    carrier_product = CarrierProduct.find_company_carrier_product(company_id: @company_id, carrier_product_id: @shipment_data[:carrier_product_id])
    customer_carrier_product  = CustomerCarrierProduct.find_customer_carrier_product(customer_id: @customer_id, carrier_product_id: carrier_product.id)

    unless customer_carrier_product.allow_auto_pickup?
      raise APIRequestError.new(code: APIRequestError::Codes::AUTO_PICKUP_NOT_AVAILABLE, message: APIRequestError::Messages::AUTO_PICKUP_NOT_AVAILABLE)
    end
  end

  def parse_package_dimensions(dimensions_array: nil)
    expanded_dimensions_array = []
    dimensions_array.map do |dimension|
      amount = dimension[:amount].to_i
      amount.times do |i|
        weight = dimension[:weight].gsub(',', '.').to_f
        expanded_dimensions_array << PackageDimension.new(length: dimension[:length].to_i, width: dimension[:width].to_i, height: dimension[:height].to_i, weight: weight)
      end
    end

    @shipment_data[:number_of_packages] = @shipment_data[:package_dimensions].sum{ |d| d[:amount] }
    return expanded_dimensions_array
  end

end
