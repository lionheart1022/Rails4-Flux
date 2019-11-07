class Shared::ShipmentView
  attr_reader :main_view, :shipment, :shipment_url, :shipment_events, :current_customer_id, :show_edit, :shipment_errors, :show_customer_name, :show_price, :show_action, :action_text, :action_url, :show_price_calculation, :current_company_id, :show_route, :set_price_url,
              :allow_autobook, :allow_retry_awb_document, :allow_retry_consignment_note, :allow_edit, :allow_update_price, :allow_inline_invoice_upload, :allow_inline_consignment_note_upload, :allow_history_references, :form_parameters, :other_assets,
              :invoice_upload_callback_url, :can_retry, :show_admin_price, :cancel_url, :other_upload_callback_url, :awb_upload_callback_url, :consignment_note_upload_callback_url, :shipment_warnings, :shipment_types, :advanced_price, :advanced_price_line_item, :show_search, :search_url, :allow_additional_files_upload, :shipment_note, :update_note_url, :trucks, :drivers, :select_truck_and_driver, :latest_delivery, :allow_truck_and_driver_editing

  attr_reader :truck_driver_editable

  def initialize(shipment: nil, shipment_url: nil, show_edit: nil, show_admin_price: nil, shipment_events: nil, current_customer_id: nil, shipment_errors: nil, show_customer_name: nil, show_price: nil, show_action: nil, action_text: nil, action_url: nil, allow_autobook: nil, allow_retry_awb_document: nil, allow_retry_consignment_note: nil, allow_edit: nil, allow_update_price: nil, allow_inline_invoice_upload: nil, allow_inline_consignment_note_upload: nil, allow_history_references: nil, form_parameters: nil, invoice_upload_callback_url: nil, other_upload_callback_url: nil, awb_upload_callback_url: nil, consignment_note_upload_callback_url: nil, shipment_warnings: nil, shipment_types: nil, advanced_price: nil, show_price_calculation: nil, current_company_id: nil, can_retry: nil, show_search: nil, search_url: nil, allow_additional_files_upload: nil,  shipment_note: nil, update_note_url: nil, show_route: nil, other_assets: nil, set_price_url: nil, cancel_url: nil, truck_driver_editable: false, trucks: nil, drivers: nil, select_truck_and_driver: false, latest_delivery: nil, allow_truck_and_driver_editing: false)
    @shipment                             = shipment
    @shipment_url                         = shipment_url
    @current_company_id                   = current_company_id
    @current_customer_id                  = current_customer_id
    @show_edit                            = show_edit
    @advanced_price                       = advanced_price
    @advanced_price_line_item             = AdvancedPriceLineItem.new
    @shipment_events                      = shipment_events
    @other_assets                         = other_assets
    @shipment_errors                      = shipment_errors
    @shipment_warnings                    = shipment_warnings
    @allow_autobook                       = allow_autobook
    @allow_retry_awb_document             = allow_retry_awb_document
    @allow_retry_consignment_note         = allow_retry_consignment_note
    @allow_edit                           = allow_edit
    @allow_update_price                   = allow_update_price
    @allow_inline_invoice_upload          = allow_inline_invoice_upload
    @allow_inline_consignment_note_upload = allow_inline_consignment_note_upload
    @allow_history_references             = allow_history_references
    @allow_additional_files_upload        = allow_additional_files_upload
    @form_parameters                      = form_parameters
    @other_upload_callback_url            = other_upload_callback_url
    @awb_upload_callback_url              = awb_upload_callback_url
    @invoice_upload_callback_url          = invoice_upload_callback_url
    @consignment_note_upload_callback_url = consignment_note_upload_callback_url
    @show_customer_name                   = show_customer_name
    @show_price                           = show_price
    @show_price_calculation               = show_price_calculation
    @show_action                          = show_action
    @show_search                          = show_search
    @show_route                           = show_route
    @search_url                           = search_url
    @action_url                           = action_url
    @action_text                          = action_text
    @show_admin_price                     = show_admin_price
    @can_retry                            = can_retry
    @shipment_types                       = shipment_types
    @shipment_note                        = shipment_note
    @update_note_url                      = update_note_url
    @cancel_url                           = cancel_url
    @set_price_url                        = set_price_url
    @truck_driver_editable                = truck_driver_editable
    @trucks                               = trucks
    @drivers                              = drivers
    @select_truck_and_driver              = select_truck_and_driver
    @latest_delivery                      = latest_delivery
    @allow_truck_and_driver_editing       = allow_truck_and_driver_editing
    state_general
  end

  def shipment_note
    @shipment_note || Note.new
  end

  def format_tracking_event_description(event)
    tracking  = event.linked_object
    return '' if tracking.description.blank?

    time      = tracking.expected_delivery_time
    date      = tracking.expected_delivery_date
    timestamp = time || date
    location  = format_event_location(tracking)

    case event.linked_object_type
    when TNTTracking.to_s
      description = "TNT: " + event.description.capitalize + location
    when UPSTracking.to_s
      description = "UPS: " + event.description.capitalize + location
    when DHLTracking.to_s
      description = "DHL: " + event.description
    when GLSTracking.to_s
      description = "GLS: " + event.description + location
    when FedExTracking.to_s
      description = "FedEx: " + event.description + location
    when "UnifaunTracking"
      description = "PostNord: " + event.description + location + "#{tracking.expected_delivery_date.inspect}"
    when "DAOTracking"
      description = "DAO: " + event.description
    end

    description = attach_timestamp(description, date, time) if timestamp.present?
    description
  end

  def format_event_location(tracking)
    has_dot     = tracking.description.end_with?('.')
    description = has_dot ? '' : '.'

    case tracking.type
      when TNTTracking.to_s
        description += " #{tracking.depot_name.try(:titleize)}"
      # when DHLTracking.to_s
      #   description += " #{tracking.event_country.titleize}, #{tracking.event_city.titleize}"
      when UPSTracking.to_s
        description += " #{tracking.event_country.try(:upcase)}"
        description += ", #{tracking.event_city.try(:titleize)}" if tracking.event_city.present?
      when GLSTracking.to_s
        description += " #{tracking.event_country.try(:titleize)}" if tracking.event_country.present?
        description += ", #{tracking.event_city.try(:titleize)}" if tracking.event_city.present?
        description += ", #{tracking.depot_name.try(:upcase)}" if tracking.depot_name.present?
      when FedExTracking.to_s
        description += " #{tracking.event_country.try(:upcase)}" if tracking.event_country.present?
        description += ", #{tracking.event_city.try(:titleize)}" if tracking.event_city.present?
      when "UnifaunTracking"
        description += " #{tracking.event_country.try(:upcase)}" if tracking.event_country.present?
        description += ", #{tracking.event_city.try(:titleize)}" if tracking.event_city.present?
    end

    description
  end

  def full_sender_address
    shipment.sender.as_flat_address_string
  end

  def full_recipient_address
    shipment.recipient.as_flat_address_string
  end

  def attach_timestamp(description, date, time)
    description = "#{description}." if !description.end_with?('.')
    time.present? ? attach_time(description, date, time) : attach_date(description, date)
  end

  def attach_time(description, date, time)
    "#{description} Estimated delivery at: #{date} #{time.strftime('%H:%M (UTC)')}"
  end

  def attach_date(description, date)
    "#{description} Estimated delivery on #{date}"
  end

  def show_add_note_button?
    @shipment.note.blank?
  end

  def format_whitespace(string)
    return '' if string.blank?
    string.gsub(/\n/, '<br/>').html_safe
  end

  def state_editable?
    allow_edit && shipment.product_responsible.try(:id) == current_company_id
  end

  def awb_upload_allowed?
    allow_edit && shipment.product_responsible.try(:id) == current_company_id
  end

  def show_edit?
    show_edit &&
    (advanced_price && advanced_price.advanced_price_line_items.all?{ |a| a.price_type.present? } || advanced_price.blank?)
  end

  def has_note?
    @shipment_note.try(:text).present?
  end

  def lock_cost_currency?
    advanced_price && advanced_price.cost_price_currency.present? && advanced_price.advanced_price_line_items.length > 0
  end

  def lock_sales_currency?
    advanced_price &&advanced_price.sales_price_currency.present? &&  advanced_price.advanced_price_line_items.length > 0
  end

  def hide_attachments?
    @other_assets.count === 0 && !self.allow_additional_files_upload
  end

  def show_header
    false
  end

  def times(number)
    "x #{number}"
  end

  def cancel_button_text
    'Cancel'
  end

  def cancel_confirmation_text
    'Cancelling shipment - Are you sure?'
  end

  def format_decimal(amount)
    amount.round(2)
  end

  def total_weight
    shipment.package_dimensions.total_weight
  end

  def total_volume_weight
    shipment.package_dimensions.total_aggregated_and_rounded_volume_weight(3)
  end

  def show_price_calculation?
    advanced_price.try(:advanced_price_line_items).present? && show_price_calculation
  end

  def show_manual_pricing?
  	allow_update_price
  end

  def applied_volume_label
    shipment.carrier_product.volume_weight? ? 'Volume Weight' : "Loadingmeter"
  end

  def applied_volume_metric
    shipment.carrier_product.volume_weight? ? '' : "ldm"
  end

  def default_cost_currency
    (advanced_price && advanced_price.cost_price_currency) || 'DKK'
  end

  def default_sales_currency
    (advanced_price && advanced_price.sales_price_currency) || 'DKK'
  end

  def price_with_currency
    advanced_price &&
    advanced_price.sales_price_currency &&
    advanced_price.advanced_price_line_items.length > 0 &&
    advanced_price.total_sales_price_amount.present? ? "#{advanced_price.sales_price_currency} #{advanced_price.total_sales_price_amount.round(2)}" : 'N/A'
  end

  def show_cost_price?
    shipment.company_responsible_for_product?(company_id: current_company_id)
  end

  def format_line_item(line_item)
    string = "#{line_item.description}"
    string += " x #{line_item.times}" if line_item.times > 1
    string
  rescue
    "#{line_item.description}" # compatability for older shipments
  end

  def sorted_prices
    advanced_price
      .advanced_price_line_items
      .order([:price_type, :created_at])
  end

  def format_line_item_parameters(parameters)
    hash = Hash.new
    parameters.each{ |k, v| hash[k] = v.to_f.round(2)}
    hash.to_s.gsub(':', '').gsub('{', '').gsub('}', '').gsub('=>', ': ') #.gsub(',', ' - ')
  end

  def volume_weight_unit(dimension)
    (shipment.package_dimensions.loading_meter? && dimension.volume_weight) ? 'ldm' : ''
  end

  def volume_weight_value(dimension)
    dimension.volume_weight && dimension.volume_weight.round(3)
  end

  def available_truck_drivers
    if truck_driver_editable
      company_truck_drivers = TruckDriver.where(company_id: current_company_id)
      enabled_truck_drivers = company_truck_drivers.enabled
      selected_and_disabled_truck_drivers = company_truck_drivers.disabled.joins(:shipments).where(shipments: { id: shipment.id })

      enabled_truck_drivers.to_a + selected_and_disabled_truck_drivers.to_a
    else
      TruckDriver.none
    end
  end

  def truck_and_driver_mapping
    trucks.map { |truck| [truck.id, truck.suggested_driver_id] }.to_h
  end

  private

  def state_general
    @main_view = "components/shared/shipment_view"
  end
end
