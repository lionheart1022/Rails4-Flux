class ShipmentCreatorHelper
  include ShipmentPersistence

  attr_reader :shipment, :shipment_request, :api_request

  def initialize(current_context:, shipment_params:, carrier_product:, initial_shipment_state: Shipment::States::CREATED)
    @current_context = current_context
    @shipment_params = shipment_params
    @initial_shipment_state = initial_shipment_state

    # Derive properties from the given arguments
    @customer = fetch_customer
    @carrier_product = carrier_product
    @customer_carrier_product = CustomerCarrierProduct.where(customer: @customer).find_by!(carrier_product: @carrier_product)

    @shipment = nil
    @shipment_request = nil
    @api_request = nil
  end

  def create_shipment
    @shipment = new_shipment
    @shipment.advanced_prices = calculate_shipment_prices

    ActiveRecord::Base.transaction do
      persist_shipment!
    end

    # The following tasks are placed outside the transaction because they mainly perform async logic.
    auto_book_shipment
    emit_shipment_event
    emit_pickup_event
    enqueue_prebook_job

    true
  rescue ActiveRecord::RecordInvalid => e
    ExceptionMonitoring.report(e)

    # Re-build shipment and pickup relation so it's available when re-rendering the shipment form.
    @shipment = new_shipment
    @shipment.pickup_relation = new_pickup

    false
  rescue => e
    ExceptionMonitoring.report!(e)

    # Re-build shipment and pickup relation so it's available when re-rendering the shipment form.
    @shipment = new_shipment
    @shipment.pickup_relation = new_pickup

    false
  end

  def create_shipment_via_api
    @shipment = new_shipment
    @shipment.advanced_prices = calculate_shipment_prices

    ActiveRecord::Base.transaction do
      persist_shipment!

      @api_request = APIRequest.create!(shipment: shipment, token: current_context.token_value, callback_url: shipment_params["callback_url"])
    end

    # The following tasks are placed outside the transaction because they mainly perform async logic.
    auto_book_shipment
    emit_shipment_event
    emit_pickup_event
    enqueue_prebook_job

    true
  end

  def create_rfq
    @shipment = new_shipment
    @shipment.advanced_prices = calculate_shipment_prices

    ActiveRecord::Base.transaction do
      persist_shipment!

      @shipment_request = ShipmentRequest.create!(shipment: shipment, state: ShipmentRequest::States::CREATED)

      if current_context.is_customer?
        @shipment_request.events.create!(company_id: shipment.company_id, customer_id: shipment.customer_id, event_type: ShipmentRequest::Events::CREATE, description: ShipmentRequest::EventDescriptions::CREATE)
      else
        @shipment_request.events.create!(company_id: shipment.company_id, customer_id: shipment.customer_id, event_type: ShipmentRequest::Events::CREATE, description: "RFQ created by company. Waiting for proposal.")
      end
    end

    # The following tasks are placed outside the transaction because they mainly perform async logic.
    auto_book_shipment
    emit_shipment_event
    emit_pickup_event
    emit_shipment_request_event
    enqueue_prebook_job

    true
  rescue ActiveRecord::RecordInvalid => e
    ExceptionMonitoring.report(e)

    # Re-build shipment and pickup relation so it's available when re-rendering the shipment form.
    @shipment = new_shipment
    @shipment.pickup_relation = new_pickup

    false
  rescue => e
    ExceptionMonitoring.report!(e)

    # Re-build shipment and pickup relation so it's available when re-rendering the shipment form.
    @shipment = new_shipment
    @shipment.pickup_relation = new_pickup

    false
  end

  private

  attr_reader :current_context
  attr_reader :shipment_params
  attr_reader :initial_shipment_state
  attr_reader :carrier_product, :customer, :customer_carrier_product

  def fetch_customer
    if current_context.is_customer?
      current_context.customer
    else
      Customer.where(company: current_company).find(shipment_params["customer_id"])
    end
  end

  def persist_shipment!
    shipment.shipment_id = customer.update_next_shipment_id
    shipment.unique_shipment_id = "#{customer.id}-#{customer.customer_id}-#{shipment.shipment_id}"
    shipment.save!

    shipment.events.create!(company_id: shipment.company_id, customer_id: shipment.customer_id, event_type: Shipment::Events::CREATE)

    if save_sender_in_address_book?
      current_context.add_contact_to_address_book!(sender_attributes) do |contact|
        contact.set_country_name_from_code = true
      end
    end

    if save_recipient_in_address_book?
      current_context.add_contact_to_address_book!(recipient_attributes) do |contact|
        contact.set_country_name_from_code = true
      end
    end

    shipment_goods = build_shipment_goods
    shipment_goods.save!
    shipment.update!(goods: shipment_goods)

    if request_pickup_for_shipment?
      pickup = new_pickup
      pickup.pickup_id = customer.update_next_pickup_id
      pickup.unique_pickup_id = "#{customer.id}-#{customer.customer_id}-#{pickup.pickup_id}"
      pickup.save!

      pickup.events.create!(company_id: shipment.company_id, customer_id: shipment.customer_id, event_type: Pickup::Events::CREATE)

      shipment.update!(pickup_relation: pickup)
    end

    if select_truck_and_driver_for_shipment? && can_assign_truck_and_driver?
      truck = Truck.where(company: current_company).find(shipment_params["truck_id"])
      driver = TruckDriver.where(company: current_company).find_by(id: shipment_params["driver_id"])

      active_delivery = truck.find_or_create_active_delivery

      active_delivery.truck_driver = driver if driver

      shipment.deliveries << active_delivery
    end
  end

  def new_shipment
    shipment = Shipment.new(permitted_shipment_attributes)
    shipment.company = current_company
    shipment.customer = customer
    shipment.carrier_product_id = carrier_product.id
    shipment.state = initial_shipment_state

    shipment.sender = Sender.new(sender_attributes)
    shipment.sender.set_country_name_from_code = true

    shipment.recipient = Recipient.new(recipient_attributes)
    shipment.recipient.set_country_name_from_code = true

    shipment.package_dimensions = build_package_dimensions
    shipment.number_of_packages ||= shipment.package_dimensions.number_of_packages

    if shipment_params["customs_amount"].present?
      shipment.customs_amount_from_user_input = shipment_params["customs_amount"]
    end

    shipment
  end

  def new_pickup
    pickup = Pickup.new(permitted_pickup_attributes)
    pickup.company = current_company
    pickup.customer = customer
    pickup.state = Pickup::States::CREATED
    pickup.pickup_date = shipment.shipping_date
    pickup.auto = customer_carrier_product.allow_auto_pickup?

    pickup.build_contact(permitted_pickup_contact_attributes)
    pickup.contact.set_country_name_from_code = true

    pickup
  end

  def permitted_pickup_attributes
    if shipment_params["pickup_options"].present?
      shipment_params["pickup_options"].slice("from_time", "to_time", "description")
    else
      {}
    end
  end

  def permitted_pickup_contact_attributes
    if shipment_params["pickup_options"].try(:[], "contact_attributes").present?
      shipment_params["pickup_options"]["contact_attributes"].slice(*ShipmentForm.permitted_contact_fields)
    else
      {}
    end
  end

  def save_sender_in_address_book?
    true_ish? shipment_params["sender_attributes"]["save_sender_in_address_book"]
  end

  def save_recipient_in_address_book?
    true_ish? shipment_params["recipient_attributes"]["save_recipient_in_address_book"]
  end

  def request_pickup_for_shipment?
    true_ish? shipment_params["request_pickup"]
  end

  def select_truck_and_driver_for_shipment?
    true_ish?(shipment_params["select_truck_and_driver"]) && shipment_params["truck_id"].present?
  end

  def can_assign_truck_and_driver?
    !current_context.is_customer? && carrier_product.product_responsible == current_company
  end

  def emit_shipment_event
    if auto_book_shipment?
      EventManager.handle_event(event: Shipment::ContextEvents::CREATE_AND_AUTOBOOK, event_arguments: { shipment_id: shipment.id })
    else
      EventManager.handle_event(event: Shipment::Events::CREATE, event_arguments: { shipment_id: shipment.id })
    end
  end

  def emit_pickup_event
    if shipment.pickup_relation
      PickupNotificationManager.handle_event(shipment.pickup_relation, event: Pickup::Events::CREATE)
    end
  end

  def emit_shipment_request_event
    ShipmentRequestNotificationManager.handle_event(shipment_request, event: ShipmentRequest::Events::CREATE)
  end

  def true_ish?(value)
    ["1", "true"].include?(value.to_s)
  end
end
