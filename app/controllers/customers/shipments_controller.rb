class Customers::ShipmentsController < CustomersController
  include GetCarrierProductsAndPricesForShipment

  respond_to :js, only: [:s3_invoice_callback]

  before_action :find_carrier_products, only: [:new, :create, :get_carrier_products_and_prices_for_shipment]

  def index
    base_relation =
      Shipment
      .find_company_shipments(company_id: current_company.id)
      .find_customer_shipments(customer_id: current_customer.id)
      .find_shipments_not_in_states([Shipment::States::CANCELLED, Shipment::States::DELIVERED_AT_DESTINATION, Shipment::States::REQUEST])
      .includes(:customer, :sender, :recipient, :carrier_product, :asset_awb)

    @view_model = Customers::Shipments::ListView.new(base_relation: base_relation)
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
      Shipment::States::CANCELLED,
      Shipment::States::DELIVERED_AT_DESTINATION,
    ]

    base_relation =
      Shipment
      .find_company_shipments(company_id: current_company.id)
      .find_customer_shipments(customer_id: current_customer.id)
      .find_shipments_in_states(filterable_states)
      .includes(:customer, :sender, :recipient, :carrier_product, :asset_awb)

    @view_model = Customers::Shipments::ListView.new(base_relation: base_relation)
    @view_model.assign_attributes(list_view_filter_params)
    @view_model.pagination = true
    @view_model.page = params[:page]
    @view_model.filterable_states = filterable_states

    @view_model.perform_search!
  end

  def search
    @view_model = ShipmentSearch.new(query: params[:search].try(:[], :query))
    @view_model.current_company = current_company
    @view_model.current_customer = current_customer
    @view_model.pagination = true
    @view_model.page = params[:page]

    @view_model.perform_search!

    if @view_model.matches_single_shipment?
      redirect_to customers_shipment_path(@view_model.shipment)
    end
  end

  def show
    shipment    = Shipment
      .includes(:sender, :recipient, :asset_other)
      .find_shipments_not_requested
      .find_customer_shipment(customer_id: current_customer.id, company_id: current_company.id, shipment_id: params[:id])

    @view_model = shipment_view(shipment: shipment)
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

    pickup = Pickup.new_from_contact(current_customer.address)
    pickup.description = "Warehouse"

    @view_model = form_view_for_new_shipment(shipment: @shipment, pickup: pickup)
  end

  def create
    creator = ShipmentCreator.new(current_context: current_context, shipment_params: params[:shipment].to_unsafe_h)
    success = creator.perform

    if success
      redirect_to customers_shipments_path, success: "Successfully created shipment"
    else
      @view_model = form_view_for_new_shipment(shipment: creator.shipment, pickup: creator.shipment.pickup_relation)
    end
  end

  def edit
    shipment = Shipment.find_customer_shipment(company_id: current_company.id, customer_id: current_customer.id, shipment_id: params[:id])

    @view_model = form_view_for_existing_shipment(shipment: shipment)
  end

  def update
    shipment = Shipment.find_customer_shipment(company_id: current_company.id, customer_id: current_customer.id, shipment_id: params[:id])
    updater = ShipmentUpdater.new(current_context: current_context, shipment: shipment, shipment_params: params[:shipment].to_unsafe_h)
    success = updater.perform

    if success
      redirect_to customers_shipments_path, success: "Successfully updated shipment"
    else
      @view_model = form_view_for_existing_shipment(shipment: updater.shipment)
    end
  end

  def get_carrier_products_and_prices_for_shipment
    perform_get_carrier_products_and_prices_for_shipment!(
      company_id: current_company.id,
      customer_id: current_customer.id,
      chain: true,
      custom_products_only: false
    )
  rescue => e
    ExceptionMonitoring.report!(e)
  end

  def s3_invoice_callback
    interactor = Customers::Shipments::CreateAssetInvoiceFromS3.new(
      company_id:  current_company.id,
      customer_id: current_customer.id,
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
    interactor = Customers::Shipments::CancelShipment.new(company_id: current_company.id, customer_id: current_customer.id, shipment_id: params[:id])
    result     = interactor.run

    if result.try(:error)
      flash[:error] = "Failed to cancel shipment"
      redirect_to customers_shipment_path(params[:id])
    else
      flash[:success] = "Successfully canceled shipment"
      redirect_to customers_shipments_path
    end
  end

  protected

  def shipment_view(shipment: nil, show_search: nil)
    shipment_events = shipment.events.order(created_at: :desc).includes(:linked_object)
    set_current_nav(sel: "shipments_archived") if [Shipment::States::DELIVERED_AT_DESTINATION, Shipment::States::CANCELLED].include?(shipment.state)
    advanced_price = AdvancedPrice.find_buyer_shipment_price(shipment_id: shipment.id, buyer_id: current_customer.id, buyer_type: current_customer.class.to_s)
    shipment_note  = Note.find_customer_shipment_note(customer_id: current_customer.id, shipment_id: shipment.id)
    other_assets    = Asset.find_creator_or_not_private_assets(shipment_id: shipment.id, creator_id: current_customer.id, creator_type: Customer.to_s)
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

    @view_model = Shared::ShipmentView.new(
      shipment:                             shipment,
      advanced_price:                       advanced_price,
      shipment_events:                      shipment_events,
      shipment_errors:                      shipment.shipment_errors,
      shipment_warnings:                    shipment.shipment_warnings,
      show_search:                          show_search,
      other_assets:                         other_assets,
      cancel_url:                           cancel_shipment_customers_shipment_path(shipment),
      allow_autobook:                       false,
      allow_retry_awb_document:             false,
      allow_edit:                           false,
      allow_update_price:                   false,
      allow_inline_invoice_upload:          true,
      allow_inline_consignment_note_upload: false,
      allow_additional_files_upload:        true,
      allow_history_references:             false,
      show_price:                           true,
      show_price_calculation:               show_price_calculation,
      show_admin_price:                     false,
      show_route:                           show_route,
      show_customer_name:                   false,
      show_action:                          true,
      action_text:                          action_text,
      action_url:                           action_url,
      can_retry:                            can_retry,
      invoice_upload_callback_url:          s3_invoice_callback_customers_shipment_path(shipment),
      consignment_note_upload_callback_url: nil,
      search_url:                           search_customers_shipments_path,
      shipment_note:                        shipment_note,
      other_upload_callback_url:            s3_other_callback_customers_shipment_url(shipment),
    )

  end

  def find_carrier_products
    @carrier_products = CustomerCarrierProduct.find_enabled_customer_carrier_products(customer_id: current_customer.id).includes(:carrier_product_price).sort_by{ |c| c.name.downcase }
  end

  def form_view_for_new_shipment(shipment:, pickup:)
    ::Customers::Shipments::FormView.new(
      submit_text: "Create Shipment",
      price_endpoint: get_carrier_products_and_prices_for_shipment_customers_shipments_path,
      endpoint: customers_shipments_path,
      method: :post,
      shipment: shipment,
      pickup: pickup,
      dgr_fields: current_customer.allow_dangerous_goods?,
      sender_autocomplete_url: customers_autocomplete_contacts_path(format: "json"),
      recipient_autocomplete_url: customers_autocomplete_contacts_path(format: "json"),
      show_save_contact: true,
    )
  end

  def form_view_for_existing_shipment(shipment:)
    ::Customers::Shipments::FormView.new(
      submit_text: "Retry Booking",
      price_endpoint: get_carrier_products_and_prices_for_shipment_customers_shipments_path,
      endpoint: customers_shipment_path(shipment),
      method: :put,
      shipment: shipment,
      dgr_fields: current_customer.allow_dangerous_goods?,
      sender_autocomplete_url: customers_autocomplete_contacts_path(format: "json"),
      recipient_autocomplete_url: customers_autocomplete_contacts_path(format: "json"),
    )
  end

  def set_current_nav(sel: nil)
    if action_name == "search"
      @current_nav = "shipments_search"
    elsif sel && sel != ''
      @current_nav = sel
    elsif action_name == "archived"
      @current_nav = "shipments_archived"
    elsif action_name == "rfq" || params[:rfq].present?
      @current_nav = "shipments_rfq"
    else
      @current_nav = "shipments"
    end
  end

  def list_view_filter_params
    {
      shipping_start_date: params[:filter_range_start],
      shipping_end_date: params[:filter_range_end],
      state: params[:filter_state],
      carrier_id: params[:filter_carrier_id],
      grouping: params[:grouping],
      sorting: params[:sorting],
    }
  end
end
