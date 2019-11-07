class Customers::ShipmentRequestsController < CustomersController
  include GetCarrierProductsAndPricesForShipment

  def index
    @view_model = ShipmentRequestsIndexView.new(
      base_relation: base_relation,
      page: params[:page],
      sorting: params[:sorting],
      state: params[:filter_active_or_in_state],
    )

    render "admin/shipment_requests/index"
  end

  def new
    existing_shipment_id = params[:existing_shipment_id]

    if existing_shipment_id.blank?
      @shipment = Shipment.new(number_of_packages: 1)
      @shipment.package_dimensions = PackageDimensions.new(dimensions: [PackageDimension.new])
      @shipment.build_recipient
      @shipment.sender = Sender.new_contact_from_existing_contact(existing_contact: current_customer.address)
    else
      @shipment = current_context.new_shipment_based_on_existing(id: existing_shipment_id)
    end

    @view_model = form_view_for_new_rfq(shipment: @shipment)
  end

  def create
    creator = ShipmentRequestCreator.new(current_context: current_context, shipment_params: params[:shipment].to_unsafe_h)
    success = creator.perform

    if success
      redirect_to customers_shipment_requests_path, success: "Successfully created RFQ"
    else
      @view_model = form_view_for_new_rfq(shipment: creator.shipment)
    end
  end

  def show
    shipment_request = base_relation.find(params[:id])
    @view_model = shipment_view(shipment: shipment_request.shipment)
  end

  def update
    shipment_request_id = params[:id]
    state = params[:shipment_request][:state]

    data = {
      state: state
    }

    interactor = Customers::ShipmentRequests::Update.new(
      company_id: current_company.id,
      customer_id: current_customer.id,
      shipment_request_id: shipment_request_id,
      data: data
    )

    result = interactor.run
    redirect_to customers_shipment_requests_path
  end

  def get_carrier_products_and_prices_for_shipment
    perform_get_carrier_products_and_prices_for_shipment!(
      company_id: current_company.id,
      customer_id: current_customer.id,
      chain: false,
      custom_products_only: true
    )
  rescue => e
    ExceptionMonitoring.report!(e)
  end

  def set_current_nav(sel: nil)
    @current_nav = "shipment_requests"
  end

  def shipment_view(shipment: nil, show_search: nil)
    events = shipment.shipment_request.events.order(created_at: :desc)
    set_current_nav(sel: "shipments_archived") if [Shipment::States::DELIVERED_AT_DESTINATION, Shipment::States::CANCELLED].include?(shipment.state)
    advanced_price = AdvancedPrice.find_buyer_shipment_price(shipment_id: shipment.id, buyer_id: current_customer.id, buyer_type: current_customer.class.to_s)
    show_price = shipment.shipment_request.proposed? || shipment.shipment_request.accepted?
    shipment_note  = Note.find_customer_shipment_note(customer_id: current_customer.id, shipment_id: shipment.id)
    other_assets = Asset.find_creator_or_not_private_assets(shipment_id: shipment.id, creator_id: current_customer.id, creator_type: Customer.to_s)
    show_price_calculation = shipment.customer.show_detailed_prices

    can_retry = shipment.customer_can_retry_booking?(customer_id: current_customer.id)

    show_route = shipment.carrier_product.distance_based_product? ? true : false

    if can_retry
      action_text = 'Edit'
      action_url  = edit_customers_shipment_path(shipment)
    else
      action_text = 'New shipment based on this'
      action_url  = new_customers_shipment_path(existing_shipment_id: shipment.id)
    end

    @view_model = Shared::ShipmentRequestView.new(
      shipment:                             shipment,
      advanced_price:                       advanced_price,
      current_customer_id:                  current_customer.id,
      shipment_url:                         customers_shipment_path(shipment.id),
      shipment_events:                      events,
      show_search:                          show_search,
      other_assets:                         other_assets,
      allow_inline_invoice_upload:          true,
      allow_inline_consignment_note_upload: false,
      allow_additional_files_upload:        true,
      show_price:                           show_price,
      show_price_calculation:               show_price_calculation,
      show_route:                           show_route,
      show_customer_name:                   false,
      show_action:                          true,
      action_text:                          action_text,
      action_url:                           action_url,
      can_retry:                            can_retry,
      shipment_note:                        shipment_note,
      search_url:                           search_customers_shipments_path,
      invoice_upload_callback_url:          s3_invoice_callback_customers_shipment_path(shipment),
      consignment_note_upload_callback_url: nil,
      other_upload_callback_url:            s3_other_callback_customers_shipment_url(shipment),
    )

  end

  def form_view_for_new_rfq(shipment:)
    Customers::Shipments::FormView.new(
      is_rfq: true,
      submit_text: "Create RFQ",
      price_endpoint: get_carrier_products_and_prices_for_shipment_customers_shipment_requests_path,
      endpoint: customers_shipment_requests_path,
      method: :post,
      shipment: shipment,
      dgr_fields: current_customer.allow_dangerous_goods?,
      sender_autocomplete_url: customers_autocomplete_contacts_path(format: "json"),
      recipient_autocomplete_url: customers_autocomplete_contacts_path(format: "json"),
      show_save_contact: true,
    )
  end

  def base_relation
    ShipmentRequest.joins(:shipment).where(shipments: { company_id: current_company.id, customer_id: current_customer.id })
  end
end
