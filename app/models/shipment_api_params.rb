class ShipmentAPIParams
  STRIP_VALUES = ->(v) { v.is_a?(String) ? v.strip : v }

  def initialize(current_customer:, root_params:)
    @current_customer = current_customer

    @root_params = root_params
    @shipment_params = root_params[:shipment] || {}
    @dgr_params = @shipment_params[:dgr] || {}
    @sender_params = root_params[:sender] || {}
    @recipient_params = root_params[:recipient] || {}
    @pickup_params = root_params[:pickup] || {}
  end

  def shipment_data
    {
      product_code: shipment_params[:product_code].try(:downcase),
      package_dimensions: shipment_params[:package_dimensions],
      number_of_pallets: shipment_params[:number_of_pallets],
      shipping_date: shipment_params[:shipping_date],
      dutiable: shipment_params[:dutiable],
      customs_amount: shipment_params[:customs_amount],
      customs_currency: shipment_params[:customs_currency],
      customs_code: shipment_params[:customs_code],
      description: shipment_params[:description],
      reference: shipment_params[:reference],
      remarks: shipment_params[:remarks],
      delivery_instructions: shipment_params[:delivery_instructions],
      shipment_type: shipment_params[:shipment_type],
      parcelshop_id: shipment_params[:parcelshop_id],
      return_label: return_label_value,
      dangerous_goods: dgr_params[:enabled],
      dangerous_goods_predefined_option: dgr_params[:identifier],
    }.transform_values(&STRIP_VALUES)
  end

  def sender_data
    if default_sender? && current_customer.address
      current_customer.address.slice(
        :company_name,
        :attention,
        :address_line1,
        :address_line2,
        :address_line3,
        :zip_code,
        :city,
        :country_code,
        :state_code,
        :phone_number,
        :email,
      )
    else
      {
        company_name: sender_params[:company_name],
        attention: sender_params[:attention],
        address_line1: sender_params[:address_line1],
        address_line2: sender_params[:address_line2],
        address_line3: sender_params[:address_line3],
        zip_code: sender_params[:zip_code],
        city: sender_params[:city],
        country_code: sender_params[:country_code].try(:downcase),
        state_code: sender_params[:state_code].try(:downcase),
        phone_number: sender_params[:phone_number],
        email: sender_params[:email],
      }.transform_values(&STRIP_VALUES)
    end
  end

  def recipient_data
    {
      company_name: recipient_params[:company_name],
      attention: recipient_params[:attention],
      address_line1: recipient_params[:address_line1],
      address_line2: recipient_params[:address_line2],
      address_line3: recipient_params[:address_line3],
      zip_code: recipient_params[:zip_code],
      city: recipient_params[:city],
      country_code: recipient_params[:country_code].try(:downcase),
      state_code: recipient_params[:state_code].try(:downcase),
      phone_number: recipient_params[:phone_number],
      email: recipient_params[:email],
      residential: recipient_params[:residential],
    }.transform_values(&STRIP_VALUES)
  end

  def request_pickup?
    true_ish? pickup_params[:enabled]
  end

  def pickup_data
    return unless request_pickup?

    {
      pickup_date: shipment_params[:shipping_date],
      from_time: pickup_params[:from_time],
      to_time: pickup_params[:to_time],
      description: pickup_params[:description],
      contact_attributes: pickup_contact_data.reject { |_, v| v.blank? }.presence || default_pickup_contact_data,
    }.transform_values(&STRIP_VALUES)
  end

  def callback_url
    root_params[:callback_url]
  end

  private

  attr_reader :current_customer
  attr_reader :root_params
  attr_reader :shipment_params, :dgr_params
  attr_reader :sender_params
  attr_reader :recipient_params
  attr_reader :pickup_params

  def return_label_value
    # The API docs show the return_label parameter as belonging under shipment (but not in the example).
    # So, let's just support both.
    root_params[:return_label].presence || shipment_params[:return_label]
  end

  def pickup_contact_data
    {
      company_name: pickup_params[:company_name],
      attention: pickup_params[:attention],
      address_line1: pickup_params[:address_line1],
      address_line2: pickup_params[:address_line2],
      address_line3: pickup_params[:address_line3],
      zip_code: pickup_params[:zip_code],
      city: pickup_params[:city],
      country_code: pickup_params[:country_code].try(:downcase),
    }.transform_values(&STRIP_VALUES)
  end

  def default_pickup_contact_data
    sender_data.slice(
      :company_name,
      :attention,
      :address_line1,
      :address_line2,
      :address_line3,
      :zip_code,
      :city,
      :country_code,
    )
  end

  def default_sender?
    true_ish? root_params[:default_sender]
  end

  def true_ish?(value)
    ["1", "true"].include?(value.to_s)
  end
end
