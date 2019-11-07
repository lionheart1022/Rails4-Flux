class ShipmentPriceCatalog
  class << self
    def new_from_api(current_company:, current_customer:, params: {})
      xparams = params.merge(company: current_company, customer: current_customer)

      c = new(CatalogParamsFromAPI.new(xparams))
      c.require_product_code = true
      c
    end
  end

  attr_accessor :catalog_params
  attr_accessor :require_product_code
  attr_reader :result

  def initialize(catalog_params)
    self.catalog_params = catalog_params
  end

  def perform!
    @result = nil

    if catalog_params.invalid?
      return false
    end

    unless catalog_params.respond_to?(:interactor_params)
      raise "`catalog_params` must implement a `#interactor_params` method"
    end

    interactor = Shared::Shipments::GetPrices.new(catalog_params.interactor_params)
    interactor_result = interactor.run

    if e = interactor_result.try(:error)
      ExceptionMonitoring.report_exception!(e)
    else
      @result = []

      interactor_result.carrier_products_and_prices.each do |r|
        carrier_product = CarrierProduct.find(r[:carrier_product_id])
        sales_price = r[:price]

        next if require_product_code && carrier_product.product_code.blank?

        @result << ResultItem.new(
          carrier_product.name,
          carrier_product.product_code,
          carrier_product.transit_time,
          sales_price.try(:total_sales_price_amount),
          sales_price.try(:sales_price_currency),
        )
      end
    end
  end

  def success?
    result
  end

  class CatalogParamsFromAPI
    include ActiveModel::Model

    attr_accessor :company
    attr_accessor :customer
    attr_accessor :shipment_type
    attr_accessor :dangerous_goods
    attr_accessor :chain
    attr_accessor :custom_products_only
    attr_accessor :default_sender
    attr_accessor :sender
    attr_accessor :recipient
    attr_accessor :package_dimensions

    alias_method :default_sender?, :default_sender

    validates! :company, :customer, presence: true
    validates :shipment_type, presence: true
    validates :recipient, presence: true
    validates :package_dimensions, presence: true
    validates :sender, presence: true, unless: :default_sender?
    validate :customer_must_have_address, if: :default_sender?

    def initialize(params = {})
      # Defaults
      self.shipment_type = "Export"
      self.chain = true
      self.custom_products_only = false
      self.dangerous_goods = false

      super(params)
    end

    def interactor_params
      raise "catalog params are not valid" if invalid?

      {
        company_id: company.id,
        customer_id: customer.id,
        sender_params: sender_or_default_sender_params,
        recipient_params: recipient_params,
        package_dimensions: package_dimensions_as_html_form_params,
        shipment_type: shipment_type,
        dangerous_goods: dangerous_goods,
        chain: chain,
        custom_products_only: custom_products_only,
      }
    end

    private

    def sender_or_default_sender_params
      if default_sender
        customer.address.slice(
          :address_line1,
          :address_line2,
          :address_line3,
          :zip_code,
          :city,
          :country_code,
          :state_code,
        )
      else
        sender_params
      end
    end

    def sender_params
      sender ? normalize_address_params(sender) : nil
    end

    def recipient_params
      normalize_address_params(recipient)
    end

    def package_dimensions_as_html_form_params
      pairs =
        Array(package_dimensions).each_with_index.map do |dim, index|
          [
            index.to_s,
            {
              amount: dim["amount"].to_s,
              length: dim["length"].to_s,
              width: dim["width"].to_s,
              height: dim["height"].to_s,
              weight: dim["weight"].to_s,
            }
          ]
        end

      Hash[pairs]
    end

    def customer_must_have_address
      if customer.address.nil?
        errors.add(:default_sender, "customer has no default address")
      end
    end

    def normalize_address_params(address)
      address.dup.tap do |a|
        a[:country_code] = a[:country_code].downcase if a[:country_code]
        a[:state_code] = a[:state_code].downcase if a[:state_code]
      end
    end
  end

  private_constant :CatalogParamsFromAPI

  ResultItem = Struct.new(
    :carrier_product_name,
    :carrier_product_code,
    :carrier_product_transit_time,
    :price_amount,
    :price_currency,
  )

  private_constant :ResultItem
end
