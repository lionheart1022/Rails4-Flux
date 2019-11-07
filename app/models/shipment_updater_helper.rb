class ShipmentUpdaterHelper
  include ShipmentPersistence

  attr_reader :shipment, :api_request

  def initialize(current_context:, shipment:, shipment_params:)
    @current_context = current_context
    @shipment = shipment
    @shipment_params = shipment_params

    # Derive properties from the given arguments
    @customer = fetch_customer
    @carrier_product = fetch_carrier_product
    @customer_carrier_product = CustomerCarrierProduct.where(customer: @customer).find_by!(carrier_product: @carrier_product)
  end

  def update_shipment
    @parsed_package_dimensions = build_package_dimensions
    assign_shipment_fields!
    @new_prices = calculate_shipment_prices

    ActiveRecord::Base.transaction do
      persist_shipment!
    end

    auto_book_shipment
    emit_shipment_event
    enqueue_prebook_job

    true
  rescue ActiveRecord::RecordInvalid => e
    ExceptionMonitoring.report(e)

    false
  rescue => e
    ExceptionMonitoring.report!(e)

    false
  end

  def update_shipment_via_api
    @parsed_package_dimensions = build_package_dimensions
    assign_shipment_fields!
    @new_prices = calculate_shipment_prices

    ActiveRecord::Base.transaction do
      persist_shipment!

      @api_request = APIRequest.create!(shipment: shipment, token: current_context.token_value, callback_url: shipment_params["callback_url"])
    end

    auto_book_shipment
    emit_shipment_event
    enqueue_prebook_job

    true
  end

  private

  attr_reader :current_context
  attr_reader :shipment_params
  attr_reader :carrier_product, :customer, :customer_carrier_product

  def fetch_customer
    shipment.customer
  end

  def fetch_carrier_product
    # Only the company selling directly to the customer is allowed to change the carrier product.
    if shipment.company_id == current_company.id && shipment_params["carrier_product_id"].present?
      CarrierProduct.where(company: current_company).find(shipment_params["carrier_product_id"])
    else
      shipment.carrier_product
    end
  end

  def persist_shipment!
    change_events = []
    change_events << { description: "Sender updated" } if shipment.sender.changed?
    change_events << { description: "Recipient updated" } if shipment.recipient.changed?
    change_events << { description: "Packages updated" } if shipment.package_dimensions_changed?
    change_events << { description: "Shipment updated" } if shipment.changed?

    # Cache this value as `shipment.save!` will clear the changes.
    was_carrier_product_changed = shipment.carrier_product_id_changed?

    shipment.sender.save!
    shipment.recipient.save!
    shipment.save!

    shipment_goods = build_shipment_goods
    shipment_goods.save!
    shipment.update!(goods: shipment_goods)

    if was_carrier_product_changed
      # Delete all existing prices if the product changed.
      # Actually this is done implicitly when doing `shipment.advanced_prices = [...]`
      # but that way the line items will still stay in the DB.
      AdvancedPrice.where(shipment: shipment).each do |existing_price|
        existing_price.advanced_price_line_items.delete_all(:delete_all)
        existing_price.destroy
      end

      shipment.advanced_prices = @new_prices

      change_events << { description: "Product updated" }
      change_events << { description: "Price updated" }
    else
      shipment_price_updater = ShipmentPriceUpdater.new(shipment: shipment, new_prices: @new_prices)
      change_events << { description: "Price updated" } if shipment_price_updater.did_prices_change?
      shipment_price_updater.perform_update!
    end

    change_events.each do |event_attributes|
      event = shipment.events.new(event_attributes)
      event.event_type ||= Shipment::Events::INFO
      event.assign_attributes(company_id: shipment.company_id, customer_id: shipment.customer_id)
      event.save!
    end

    shipment.events.create!(company_id: shipment.company_id, customer_id: shipment.customer_id, event_type: Shipment::Events::RETRY)

    unless auto_book_shipment?
      # It seems weird that we create a "Create" event when the shipment is not going to auto book - this has been kept like this to be backwards compatible.
      shipment.events.create!(company_id: shipment.company_id, customer_id: shipment.customer_id, event_type: Shipment::Events::CREATE)
    end
  end

  def assign_shipment_fields!
    shipment.assign_attributes(permitted_shipment_attributes)
    shipment.carrier_product_id = carrier_product.id

    if shipment.package_dimensions.equal_to?(@parsed_package_dimensions)
      # We don't assign the package dimensions if it did not change from last time.
    else
      shipment.package_dimensions = @parsed_package_dimensions
      shipment.number_of_packages = shipment.package_dimensions.number_of_packages
    end

    if shipment.carrier_product_id_changed? && shipment.carrier_product.type.blank?
      # If the carrier product is being changed and the newly assigned carrier product is a custom product,
      # then we should roll the state back to created.
      shipment.state = Shipment::States::CREATED
    end

    shipment.sender.assign_attributes(sender_attributes)
    shipment.sender.set_country_name_from_code = true

    shipment.recipient.assign_attributes(recipient_attributes)
    shipment.recipient.set_country_name_from_code = true

    if shipment_params["customs_amount"]
      shipment.customs_amount_from_user_input = shipment_params["customs_amount"]
    end
  end

  def emit_shipment_event
    if current_context.is_customer?
      if auto_book_shipment?
        EventManager.handle_event(event: Shipment::ContextEvents::RETRY_AND_AUTOBOOK, event_arguments: { shipment_id: shipment.id })
      else
        EventManager.handle_event(event: Shipment::Events::RETRY, event_arguments: { shipment_id: shipment.id })
      end
    else
      EventManager.handle_event(event: Shipment::ContextEvents::COMPANY_UPDATE, event_arguments: { shipment_id: shipment.id })
    end
  end
end
