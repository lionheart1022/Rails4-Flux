class Customers::Shipments::FormView
  attr_reader :main_view, :shipment, :editing, :carrier_products, :is_rfq, :shipment_types, :endpoint, :method, :submit_text, :price_endpoint, :customer_responsible, :show_customer_selection, :pickup, :drivers, :trucks, :sender_autocomplete_url, :recipient_autocomplete_url, :truck_and_driver_enabled

  def initialize(editing: nil, endpoint: nil, is_rfq: false, price_endpoint: nil, method: nil, shipment: nil, carrier_products: nil, submit_text: nil, customer_responsible: nil, show_customer_selection: nil, pickup: nil, trucks: nil, drivers: nil, dgr_fields: false, sender_autocomplete_url: nil, recipient_autocomplete_url: nil, show_save_contact: :auto, truck_and_driver_enabled: false)
    @customer_responsible = customer_responsible
    @editing              = editing
    @endpoint             = endpoint
    @method               = method
    @shipment             = shipment
    @carrier_products     = carrier_products
    @price_endpoint       = price_endpoint
    @shipment_types       = Shipment.shipment_types
    @submit_text          = submit_text
    @show_customer_selection = show_customer_selection
    @is_rfq               = is_rfq
    @pickup               = pickup
    @trucks               = trucks
    @drivers              = drivers
    @dgr_fields           = dgr_fields
    @sender_autocomplete_url = sender_autocomplete_url
    @recipient_autocomplete_url = recipient_autocomplete_url
    @show_save_contact = show_save_contact
    @truck_and_driver_enabled = truck_and_driver_enabled

    Rails.logger.info "Shipments_FormView_init carrier_products=#{@carrier_products.inspect}"

    state_general
  end

  def carrier_products
    Rails.logger.warn "Shipments_FormView_carrier_products_invocation carrier_products=#{@carrier_products.inspect}"

    @carrier_products
  end

  def show_product_selection?
    (@editing && customer_responsible) || !@editing
  end

  def truck_and_driver_mapping
    trucks.map { |truck| [truck.id, truck.suggested_driver_id] }.to_h
  end

  def update?
    method == :put
  end

  def show_save_contact?
    if @show_save_contact == :auto
      !@show_customer_selection && !@editing
    else
      @show_save_contact
    end
  end

  def dgr_fields?
    @dgr_fields
  end

  def incomplete_information_text
    @show_customer_selection ?
    'Select customer and enter destination address + package dimensions to see available carrier products' :
    'Enter destination address + package dimensions to see available carrier products'
  end

  def title
    "Shipment ##{shipment.unique_shipment_id}"
  end

  def dangerous_goods_predefined_options
    [
      ["Dry Ice UN1845", "dry_ice"],
      ["Ion PI966 Section I (LiBa with equipment)", "lithium_ion_UN3481_PI966"],
      ["Ion PI967 Section I (LiBa in equipment)", "lithium_ion_UN3481_PI967"],
      ["Metal PI969 Section I (LiBa with equipment)", "lithium_metal_UN3091_PI969"],
      ["Metal PI970 Section I (LiBa in equipment)", "lithium_metal_UN3091_PI970"],
      ["Other", "other"],
    ]
  end

  def dangerous_goods_description_options
    [
      "Biological Substance, category B",
      "Genetically Modified Organisms",
      "Partially regulated (excepted) Lithium Batteries",
    ]
  end

  def dangerous_goods_class_options
    [
      "9",
    ]
  end

  def un_packing_group_options
    [
      "I",
      "II",
      "III",
    ]
  end

  def packing_instruction_options
    [
      "965",
      "966",
      "967",
      "968",
      "969",
      "970",
    ]
  end

  private

  def state_general
    @main_view = "components/shared/shipments/new"
  end
end
