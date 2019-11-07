class Shared::ShipmentRequestView < Shared::ShipmentView

  def initialize(shipment: nil, shipment_url: nil, show_edit: nil, show_admin_price: nil, current_customer_id: nil, shipment_events: nil, shipment_errors: nil, show_customer_name: nil, show_price: nil, show_action: nil, action_text: nil, action_url: nil, allow_autobook: nil, allow_retry_awb_document: nil, allow_retry_consignment_note: nil, allow_edit: nil, allow_update_price: nil, allow_inline_invoice_upload: nil, allow_inline_consignment_note_upload: nil, allow_history_references: nil, form_parameters: nil, invoice_upload_callback_url: nil, other_upload_callback_url: nil, awb_upload_callback_url: nil, consignment_note_upload_callback_url: nil, shipment_warnings: nil, shipment_types: nil, advanced_price: nil, show_price_calculation: nil, current_company_id: nil, can_retry: nil, show_search: nil, search_url: nil, allow_additional_files_upload: nil,  shipment_note: nil, update_note_url: nil, show_route: nil, other_assets: nil, set_price_url: nil, cancel_url: nil)
    super
    state_general
  end

  def show_propose?
    @shipment.shipment_request.can_propose?(company_id: current_company_id) && current_customer_id.blank?
  end

  def show_book?
    @shipment.shipment_request.can_book?(company_id: current_company_id) && current_customer_id.blank?
  end

  def show_accept?
    @shipment.shipment_request.can_accept?(customer_id: current_customer_id)
  end

  def show_decline?
    @shipment.shipment_request.can_decline?(customer_id: current_customer_id)
  end

  def show_company_cancel?
    @shipment.shipment_request.can_company_cancel?(company_id: current_company_id) && current_customer_id.blank?
  end

  def show_customer_cancel?
    @shipment.shipment_request.can_customer_cancel?(customer_id: current_customer_id)
  end

  def events
    @shipment_events
  end

  def show_shipment_link?
    !@shipment.requested?
  end

  private

  def state_general
    @main_view = "components/shared/shipment_request_view"
  end
end
