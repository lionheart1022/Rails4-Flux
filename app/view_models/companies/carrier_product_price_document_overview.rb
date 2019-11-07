class Companies::CarrierProductPriceDocumentOverview
  attr_reader :current_company

  def initialize(current_company:, carrier_products:)
    @current_company = current_company
    @carrier_products = carrier_products
  end

  def carrier_product_rows
    carrier_products.map do |carrier_product|
      Row.new(parent: self, carrier_product: carrier_product)
    end
  end

  private

  attr_reader :carrier_products

  class Row < SimpleDelegator
    def initialize(parent:, carrier_product:)
      @parent = parent
      super(carrier_product)
    end

    def active_price_document_upload
      if defined?(@_active_price_document_upload)
        @_active_price_document_upload
      else
        @_active_price_document_upload =
          PriceDocumentUpload
          .active
          .where(company: @parent.current_company)
          .where(carrier_product: __getobj__)
          .first
      end
    end

    def show_remove_btn?
      active_price_document_upload || carrier_product_price
    end
  end

  private_constant :Row
end
