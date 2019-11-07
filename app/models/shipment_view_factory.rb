class ShipmentViewFactory
  class << self
    def view_for_search(shipment, current_company:)
      f = new(shipment, current_company: current_company)
      f.build_for_search!
      f.view
    end
  end

  attr_reader :shipment
  attr_reader :current_company
  attr_accessor :show_search
  attr_accessor :show_price
  attr_accessor :show_price_calculation
  attr_accessor :show_admin_price
  attr_accessor :allow_edit
  attr_accessor :show_action
  attr_accessor :show_customer_name

  def initialize(shipment, current_company:)
    self.shipment = shipment
    self.current_company = current_company
  end

  def build_for_search!
    self.show_search = true
    self.show_price = true
    self.show_price_calculation = true
    self.show_admin_price = true
    self.allow_edit = true
    self.show_action = true
    self.show_customer_name = true

    self
  end

  def view
    Shared::ShipmentView.new(
      shipment: shipment,
      set_price_url: set_price_url,
      current_company_id: current_company.id,
      advanced_price: advanced_price,
      shipment_events: shipment_events,
      other_assets: other_assets,
      shipment_errors: shipment.shipment_errors,
      show_customer_name: show_customer_name,
      show_action: show_action,
      cancel_url: url_helpers.cancel_shipment_companies_shipment_path(shipment),
      show_price: show_price,
      show_price_calculation: show_price_calculation,
      show_route: show_route,
      show_search: show_search,
      allow_autobook: allow_autobook,
      allow_retry_awb_document: allow_retry_awb_document,
      allow_retry_consignment_note: allow_retry_consignment_note,
      allow_edit: allow_edit,
      allow_update_price: true,
      allow_inline_invoice_upload: allow_inline_invoice_upload,
      allow_inline_consignment_note_upload: allow_inline_consignment_note_upload,
      allow_additional_files_upload: allow_additional_files_upload,
      allow_history_references: allow_history_references,
      form_parameters: [:companies, shipment],
      other_upload_callback_url: url_helpers.s3_other_callback_companies_shipment_url(shipment),
      awb_upload_callback_url: url_helpers.s3_awb_callback_companies_shipment_url(shipment),
      invoice_upload_callback_url: url_helpers.s3_invoice_callback_companies_shipment_url(shipment),
      consignment_note_upload_callback_url: url_helpers.s3_consignment_note_callback_companies_shipment_url(shipment),
      search_url: url_helpers.search_companies_shipments_path,
      shipment_note: shipment_note,
      show_admin_price: show_admin_price,
      show_edit: show_edit,
      action_text: action_text,
      action_url: action_url,
      can_retry: can_retry,
    )
  end

  def shipment_events
    if defined?(@shipment_events)
      @shipment_events
    else
      @shipment_events = shipment.events.order(created_at: :desc).includes(:linked_object)
    end
  end

  def advanced_price
    if defined?(@advanced_price)
      @advanced_price
    else
      @advanced_price = AdvancedPrice.find_seller_shipment_price(shipment_id: shipment.id, seller_id: current_company.id, seller_type: "Company")
    end
  end

  def other_assets
    if defined?(@other_assets)
      @other_assets
    else
      @other_assets = Asset.find_creator_or_not_private_assets(shipment_id: shipment.id, creator_id: current_company.id, creator_type: "Company")
    end
  end

  def shipment_note
    if defined?(@shipment_note)
      @shipment_note
    else
      @shipment_note = Note.find_company_shipment_note(company_id: current_company.id, shipment_id: shipment.id)
    end
  end

  def customer_carrier_product
    if defined?(@customer_carrier_product)
      @customer_carrier_product
    else
      @customer_carrier_product = CustomerCarrierProduct.find_customer_carrier_product(customer_id: shipment.customer_id, carrier_product_id: shipment.carrier_product_id)
    end
  end

  def allow_autobook
    if current_company_is_product_responsible?
      customer_carrier_product.enable_autobooking && shipment.state == Shipment::States::CREATED
    else
      false
    end
  end

  def allow_retry_awb_document
    if current_company_is_product_responsible?
      shipment.carrier_product.supports_shipment_retry_awb_document? && customer_carrier_product.enable_autobooking && shipment.state == Shipment::States::BOOKED_WAITING_AWB_DOCUMENT
    else
      false
    end
  end

  def allow_retry_consignment_note
    if current_company_is_product_responsible?
      customer_carrier_product.enable_autobooking && shipment.state == Shipment::States::BOOKED_WAITING_CONSIGNMENT_NOTE
    else
      false
    end
  end

  def allow_inline_invoice_upload
    current_company_is_product_responsible?
  end

  def allow_inline_consignment_note_upload
    current_company_is_product_responsible?
  end

  def allow_history_references
    current_company_is_product_responsible?
  end

  def allow_additional_files_upload
    current_company_is_product_responsible?
  end

  def show_edit
    if current_company_is_product_responsible?
      shipment.carrier_product.custom?
    else
      false
    end
  end

  def can_retry
    shipment.customer_can_retry_booking?(customer_id: shipment.customer_id)
  end

  def show_route
    if current_company_is_product_responsible?
      shipment.carrier_product.distance_based_product?
    else
      false
    end
  end

  def set_price_url
    if current_company_is_product_responsible?
      url_helpers.update_owner_price_companies_shipment_path(shipment)
    else
      url_helpers.update_customer_price_companies_shipment_path(shipment)
    end
  end

  def action_text
    if can_retry
      "Edit"
    else
      "New shipment based on this"
    end
  end

  def action_url
    if can_retry
      url_helpers.edit_companies_shipment_path(shipment)
    else
      url_helpers.new_companies_shipment_path(existing_shipment_id: shipment.id)
    end
  end

  private

  attr_writer :shipment
  attr_writer :current_company

  def current_company_is_product_responsible?
    shipment.product_responsible == current_company
  end

  def url_helpers
    @url_helpers ||= CurrentContextUrls.new(company: current_company)
  end
end
