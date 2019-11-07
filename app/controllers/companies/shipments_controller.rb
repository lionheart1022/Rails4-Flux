class Companies::ShipmentsController < CompaniesController
  include GetCarrierProductsAndPricesForShipment

  respond_to :js, only: [:s3_awb_callback, :s3_invoice_callback]

  def index
    base_relation =
      Shipment
      .find_company_shipments(company_id: current_company.id)
      .find_shipments_not_in_states([Shipment::States::DELIVERED_AT_DESTINATION, Shipment::States::CANCELLED, Shipment::States::REQUEST])
      .includes(:customer, :sender, :recipient, :carrier_product, :asset_awb, :company)

    @view_model = Companies::Shipments::ListView.new(current_company: current_company, base_relation: base_relation)
    @view_model.assign_attributes(list_view_filter_params)
    @view_model.pagination = true
    @view_model.page = params[:page]
    @view_model.filterable_states = [
      Shipment::States::CREATED,
      Shipment::States::BOOKED,
      Shipment::States::IN_TRANSIT,
      Shipment::States::PROBLEM,
      Shipment::States::BOOKING_FAILED,
    ]

    @view_model.perform_search!
  end

  def archived
    filterable_states = [
      Shipment::States::DELIVERED_AT_DESTINATION,
      Shipment::States::CANCELLED,
    ]

    base_relation =
      Shipment
      .find_company_shipments(company_id: current_company.id)
      .find_shipments_in_states(filterable_states)
      .includes(:customer, :sender, :recipient, :carrier_product, :asset_awb, :company)

    @view_model = Companies::Shipments::ListView.new(current_company: current_company, base_relation: base_relation)
    @view_model.assign_attributes(list_view_filter_params)
    @view_model.pagination = true
    @view_model.page = params[:page]
    @view_model.filterable_states = filterable_states

    @view_model.perform_search!
  end

  def new
    pickup = nil

    existing_shipment_id = params[:existing_shipment_id]
    if existing_shipment_id.blank?
      @shipment = Shipment.new(number_of_packages: 1)
      @shipment.package_dimensions = PackageDimensions.new(dimensions: [PackageDimension.new])
      @shipment.build_recipient
      @shipment.build_sender
      @shipment.build_customer
    else
      @shipment = current_context.new_shipment_based_on_existing(id: existing_shipment_id)
      pickup = Pickup.new_from_contact(@shipment.customer.address) if @shipment.customer.try(:address) && @shipment.customer_responsible == current_company
    end

    pickup ||= Pickup.new
    pickup.build_contact unless pickup.contact
    pickup.description = "Warehouse"

    @view_model = form_view_for_new_shipment(shipment: @shipment, pickup: pickup)
  end

  def create
    creator = ShipmentCreator.new(current_context: current_context, shipment_params: params[:shipment].to_unsafe_h)
    success = creator.perform

    if success
      redirect_to companies_shipments_path, success: "Successfully created shipment"
    else
      @view_model = form_view_for_new_shipment(shipment: creator.shipment, pickup: creator.shipment.pickup_relation)
    end
  end

  def show
    shipment = Shipment
      .includes(:sender, :recipient, :asset_other)
      .find_shipments_not_requested
      .find_company_shipment(company_id: current_company.id, shipment_id: params[:id])

    @view_model = shipment_view(shipment: shipment)
  end

  def edit
    shipment = Shipment.find_company_shipment(company_id: current_company.id, shipment_id: params[:id])

    @view_model = form_view_for_existing_shipment(shipment: shipment)
  end

  def update
    shipment = Shipment.find_company_shipment(company_id: current_company.id, shipment_id: params[:id])
    updater = ShipmentUpdater.new(current_context: current_context, shipment: shipment, shipment_params: params[:shipment].to_unsafe_h)
    success = updater.perform

    if success
      redirect_to companies_shipment_path(params[:id]), success: "Successfully updated shipment"
    else
      @view_model = form_view_for_existing_shipment(shipment: updater.shipment)
    end
  end

  def get_carrier_products_and_prices_for_shipment
    customer_id = params[:customer_id]
    customer = Customer.find_customer(customer_id: customer_id)

    perform_get_carrier_products_and_prices_for_shipment!(
      company_id: customer.company_id,
      customer_id: params[:customer_id].to_i,
      chain: true,
      custom_products_only: false
    )
  rescue => e
    ExceptionMonitoring.report!(e)
    render json: { error: e.message }
  end

  def autobook
    shipment_id = params[:id]

    interactor = Companies::Shipments::Autobook.new(
      company_id:  current_company.id,
      shipment_id: shipment_id,
    )

    result = interactor.run

    redirect_to :back
  end

  def retry_awb_document
    shipment_id = params[:id]

    interactor = Companies::Shipments::RetryAwbDocument.new(
      company_id:  current_company.id,
      shipment_id: shipment_id,
    )

    result = interactor.run

    redirect_to :back
  end

  def retry_consignment_note
    shipment_id = params[:id]

    interactor = Companies::Shipments::RetryConsignmentNote.new(
      company_id:  current_company.id,
      shipment_id: shipment_id,
    )

    result = interactor.run

    redirect_to :back
  end

  def s3_awb_callback
    interactor = Companies::Shipments::CreateAssetAwbFromS3.new(
      company_id:  current_company.id,
      shipment_id: params[:id],
      filepath:    params[:filepath],
      filename:    params[:filename],
      filetype:    params[:filetype]
    )

    result = interactor.run

    if result.try(:error)
      @error_message = result.error.message
      ExceptionMonitoring.report_message(@error_message)
    else
      @asset = result.asset
    end
  end

  def s3_invoice_callback
    interactor = Companies::Shipments::CreateAssetInvoiceFromS3.new(
      company_id:  current_company.id,
      shipment_id: params[:id],
      filepath:    params[:filepath],
      filename:    params[:filename],
      filetype:    params[:filetype]
    )

    result = interactor.run

    if result.try(:error)
      @error_message = result.error.message
      ExceptionMonitoring.report_message(@error_message)
    else
      @asset = result.asset
    end
  end

  def s3_consignment_note_callback
    interactor = Companies::Shipments::CreateAssetConsignmentNoteFromS3.new(
      company_id:  current_company.id,
      shipment_id: params[:id],
      filepath:    params[:filepath],
      filename:    params[:filename],
      filetype:    params[:filetype]
    )

    result = interactor.run

    if result.try(:error)
      @error_message = result.error.message
      ExceptionMonitoring.report_message(@error_message)
    else
      @asset = result.asset
    end
  end

  def cancel_shipment
    shipment   = Shipment.find_company_shipment(company_id: current_company.id, shipment_id: params[:id])
    interactor = ::Customers::Shipments::CancelShipment.new(company_id: current_company.id, customer_id: shipment.customer_id, shipment_id: shipment.id)
    result     = interactor.run

    if result.try(:error)
      flash[:error] = "Failed to cancel shipment"
      redirect_to companies_shipment_path(params[:id])
    else
      flash[:success] = "Successfully canceled shipment"
      redirect_to companies_shipments_path
    end
  end

  private

  def shipment_view(shipment: nil, show_search: nil)
    shipment_events = shipment.events.order(created_at: :desc).includes(:linked_object)
    set_current_nav(sel: "shipments_archived") if [Shipment::States::DELIVERED_AT_DESTINATION, Shipment::States::CANCELLED].include?(shipment.state)

    advanced_price  = AdvancedPrice.find_seller_shipment_price(shipment_id: shipment.id, seller_id: current_company.id, seller_type: current_company.class.to_s)
    other_assets    = Asset.find_creator_or_not_private_assets(shipment_id: shipment.id, creator_id: current_company.id, creator_type: Company.to_s)

    shipment_note   = Note.find_company_shipment_note(company_id: current_company.id, shipment_id: shipment.id)

    allow_edit                    = false
    allow_autobook                = false
    allow_retry_awb_document      = false
    allow_retry_consignment_note  = false

    allow_inline_invoice_upload          = true
    allow_inline_consignment_note_upload = false
    allow_history_references             = false
    allow_additional_files_upload        = false
    show_edit                            = false

    show_route = false
    set_price_url = update_customer_price_companies_shipment_path(shipment)

    show_action = true
    allow_edit = true
    can_retry = shipment.customer_can_retry_booking?(customer_id: shipment.customer_id)
    if can_retry
      action_text = 'Edit'
      action_url  = edit_companies_shipment_path(shipment)
    else
      action_text = 'New shipment based on this'
      action_url  = new_companies_shipment_path(existing_shipment_id: shipment.id)
    end

    if (shipment.product_responsible == current_company)
      show_route = true if shipment.carrier_product.distance_based_product?
      set_price_url = update_owner_price_companies_shipment_path(shipment)

      customer_carrier_product = CustomerCarrierProduct.find_customer_carrier_product(customer_id: shipment.customer_id, carrier_product_id: shipment.carrier_product_id)
      # determine if autobooking is possible
      allow_autobook = customer_carrier_product.enable_autobooking && shipment.state == Shipment::States::CREATED
      # determine if retry awb document is possible
      allow_retry_awb_document = shipment.carrier_product.supports_shipment_retry_awb_document? && customer_carrier_product.enable_autobooking && shipment.state == Shipment::States::BOOKED_WAITING_AWB_DOCUMENT
      # determine if retry consignment note is possible
      allow_retry_consignment_note = customer_carrier_product.enable_autobooking && shipment.state == Shipment::States::BOOKED_WAITING_CONSIGNMENT_NOTE

      allow_inline_consignment_note_upload = true
      allow_history_references             = true
      allow_additional_files_upload        = true
      show_edit                            = true if shipment.carrier_product.custom?
    end

    return Shared::ShipmentView.new(
      shipment:                             shipment,
      set_price_url:                        set_price_url,
      current_company_id:                   current_company.id,
      advanced_price:                       advanced_price,
      shipment_events:                      shipment_events,
      other_assets:                         other_assets,
      shipment_errors:                      shipment.shipment_errors,
      shipment_warnings:                    shipment.shipment_warnings,
      show_customer_name:                   true,
      show_action:                          show_action,
      cancel_url:                           cancel_shipment_companies_shipment_path(shipment),
      show_price:                           true,
      show_price_calculation:               true,
      show_route:                           show_route,
      show_search:                          show_search,
      allow_autobook:                       allow_autobook,
      allow_retry_awb_document:             allow_retry_awb_document,
      allow_retry_consignment_note:         allow_retry_consignment_note,
      allow_edit:                           allow_edit,
      allow_update_price:                   true,
      allow_inline_invoice_upload:          allow_inline_invoice_upload,
      allow_inline_consignment_note_upload: allow_inline_consignment_note_upload,
      allow_additional_files_upload:        allow_additional_files_upload,
      allow_history_references:             allow_history_references,
      form_parameters:                      [:companies, shipment],
      other_upload_callback_url:            s3_other_callback_companies_shipment_url(shipment),
      awb_upload_callback_url:              s3_awb_callback_companies_shipment_url(shipment),
      invoice_upload_callback_url:          s3_invoice_callback_companies_shipment_url(shipment),
      consignment_note_upload_callback_url: s3_consignment_note_callback_companies_shipment_url(shipment),
      search_url:                           search_companies_shipments_path,
      shipment_note:                        shipment_note,
      show_admin_price:                     true,
      show_edit:                            show_edit,
      action_text:                          action_text,
      action_url:                           action_url,
      can_retry:                            can_retry,
      truck_driver_editable:                current_context.company_feature_flag_enabled?("truck-driver-db") && shipment.carrier_product.truck_driver_enabled?,
      trucks:                               Truck.where(company: current_company),
      drivers:                              TruckDriver.where(company: current_company),
      select_truck_and_driver:              shipment.deliveries.last.nil? ? true : shipment.deliveries.last.done?,
      latest_delivery:                      shipment.deliveries.last,
      allow_truck_and_driver_editing:       current_context.company_feature_flag_enabled?("truck-fleet") && shipment.carrier_product.product_responsible == current_company,
    )
  end

  def form_view_for_new_shipment(shipment:, pickup:)
    ::Customers::Shipments::FormView.new(
      submit_text: "Create Shipment",
      price_endpoint: get_carrier_products_and_prices_for_shipment_companies_shipments_path,
      endpoint: companies_shipments_path,
      method: :post,
      shipment: shipment,
      pickup: pickup,
      trucks: Truck.where(company: current_company),
      drivers: TruckDriver.where(company: current_company),
      show_customer_selection: true,
      dgr_fields: true,
      sender_autocomplete_url: companies_autocomplete_contacts_path(format: "json", per: "10"),
      recipient_autocomplete_url: companies_autocomplete_contacts_path(format: "json", per: "10"),
      show_save_contact: true,
      truck_and_driver_enabled: current_context.company_feature_flag_enabled?("truck-fleet")
    )
  end

  def form_view_for_existing_shipment(shipment:)
    ::Customers::Shipments::FormView.new(
      editing: true,
      customer_responsible: current_company.id == shipment.company_id,
      shipment: shipment,
      endpoint: companies_shipment_path,
      price_endpoint: get_carrier_products_and_prices_for_shipment_companies_shipments_path,
      method: :put,
      dgr_fields: true,
      sender_autocomplete_url: companies_autocomplete_contacts_path(format: "json", per: "10"),
      recipient_autocomplete_url: companies_autocomplete_contacts_path(format: "json", per: "10"),
    )
  end

  def set_current_nav(sel: nil)
    if action_name == "search"
      @current_nav = "shipments_search"
    elsif sel && sel != ''
      @current_nav = sel
    elsif action_name == "archived"
      @current_nav = "shipments_archived"
    else
      @current_nav = "shipments"
    end
  end

  def list_view_filter_params
    {
      customer_id: params[:filter_customer_id],
      shipping_start_date: params[:filter_range_start],
      shipping_end_date: params[:filter_range_end],
      customer_type: params[:filter_customer_type],
      state: params[:filter_state],
      carrier_id: params[:filter_carrier_id],
      related_company_id: params[:filter_company_id],
      grouping: params[:grouping],
      sorting: params[:sorting],
    }
  end
end
