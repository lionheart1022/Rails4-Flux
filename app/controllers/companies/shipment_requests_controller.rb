class Companies::ShipmentRequestsController < CompaniesController
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
      @shipment.build_sender
      @shipment.build_customer
    else
      @shipment = current_context.new_shipment_based_on_existing(id: existing_shipment_id)
    end

    @view_model = form_view_for_new_shipment_request(shipment: @shipment)
  end

  def create
    creator = ShipmentRequestCreator.new(current_context: current_context, shipment_params: params[:shipment].to_unsafe_h)
    success = creator.perform

    if success
      redirect_to companies_shipment_requests_path, success: "Successfully created RFQ"
    else
      @view_model = form_view_for_new_shipment_request(shipment: creator.shipment)
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

    interactor = Companies::ShipmentRequests::Update.new(
      company_id: current_company.id,
      shipment_request_id: shipment_request_id,
      data: data
    )

    result = interactor.run
    redirect_to companies_shipment_requests_path
  end

  def book
    shipment_request_id = params[:id]

    interactor = Companies::ShipmentRequests::Book.new(
      company_id: current_company.id,
      shipment_request_id: shipment_request_id
    )

    result = interactor.run
    redirect_to companies_shipment_requests_path
  end

  def set_current_nav
    @current_nav = "shipment_requests"
  end

  def shipment_view(shipment: nil, show_search: nil)
    events = shipment.shipment_request.events.order(created_at: :desc)
    advanced_price  = AdvancedPrice.find_seller_shipment_price(shipment_id: shipment.id, seller_id: current_company.id, seller_type: current_company.class.to_s)
    other_assets    = Asset.find_creator_or_not_private_assets(shipment_id: shipment.id, creator_id: current_company.id, creator_type: Company.to_s)
    shipment_note   = Note.find_company_shipment_note(company_id: current_company.id, shipment_id: shipment.id)

    allow_inline_invoice_upload = false
    allow_inline_consignment_note_upload = false
    allow_additional_files_upload = false

    show_route = false
    set_price_url = update_customer_price_companies_shipment_path(shipment)

    show_action = true
    allow_edit = true
    can_retry = shipment.customer_can_retry_booking?(customer_id: shipment.customer_id)
    if can_retry
      action_text = 'Edit'
      action_url  = edit_companies_shipment_path(shipment)
    else
      action_text = 'Propose'
      action_url  = new_companies_shipment_path(existing_shipment_id: shipment.id)
    end

    if (shipment.product_responsible == current_company)
      show_route    = true if shipment.carrier_product.distance_based_product?
      set_price_url = update_owner_price_companies_shipment_path(shipment)
      show_edit     = true if shipment.carrier_product.custom?

      allow_inline_invoice_upload = true
      allow_inline_consignment_note_upload = true
      allow_additional_files_upload = true
    end

    allow_update_price = shipment.shipment_request.can_propose?(company_id: current_company.id)

    return Shared::ShipmentRequestView.new(
      shipment:                             shipment,
      current_company_id:                   current_company.id,
      shipment_url:                         companies_shipment_path(shipment.id),
      advanced_price:                       advanced_price,
      shipment_events:                      events,
      other_assets:                         other_assets,
      show_customer_name:                   true,
      show_action:                          show_action,
      show_price:                           true,
      show_price_calculation:               true,
      allow_update_price:                   allow_update_price,
      allow_inline_invoice_upload:          allow_inline_invoice_upload,
      allow_inline_consignment_note_upload: allow_inline_consignment_note_upload,
      allow_additional_files_upload:        allow_additional_files_upload,
      show_route:                           show_route,
      form_parameters:                      [:companies, shipment],
      other_upload_callback_url:            s3_other_callback_companies_shipment_url(shipment),
      awb_upload_callback_url:              s3_awb_callback_companies_shipment_url(shipment),
      invoice_upload_callback_url:          s3_invoice_callback_companies_shipment_url(shipment),
      consignment_note_upload_callback_url: s3_consignment_note_callback_companies_shipment_url(shipment),
      action_text:                          action_text,
      show_admin_price:                     true,
      action_url:                           action_url,
      can_retry:                            can_retry,
      shipment_note:                        shipment_note,
    )
  end

  def form_view_for_new_shipment_request(shipment:, pickup: nil)
    price_endpoint =
      if params[:existing_shipment_id].present?
        shipment = current_context.find_shipment(params[:existing_shipment_id])
        if shipment.company == current_company
          companies_customer_scoped_shipment_request_prices_path(selected_customer_identifier: shipment.customer_id)
        else
          ""
        end
      else
        ""
      end

    ::Customers::Shipments::FormView.new(
      submit_text: "Create RFQ",
      is_rfq: true,
      price_endpoint: price_endpoint,
      endpoint: companies_shipment_requests_path,
      method: :post,
      shipment: shipment,
      pickup: pickup,
      show_customer_selection: true,
      dgr_fields: true,
      sender_autocomplete_url: companies_autocomplete_contacts_path(format: "json", per: "10"),
      recipient_autocomplete_url: companies_autocomplete_contacts_path(format: "json", per: "10"),
      show_save_contact: true,
    )
  end

  def base_relation
    ShipmentRequest.joins(:shipment).where(shipments: { company_id: current_company.id })
  end
end
