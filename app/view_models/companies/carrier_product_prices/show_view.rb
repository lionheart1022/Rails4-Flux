class Companies::CarrierProductPrices::ShowView
  attr_reader :main_view, :carrier_product_price, :carrier_product, :parsing_errors
  
  def initialize(carrier_product_price: nil)
    @carrier_product_price = carrier_product_price
    @carrier_product       = carrier_product_price.carrier_product
    @parsing_errors        = carrier_product_price.price_document.parsing_errors.sort { |a, b| a.severity <=> b.severity }
    state_general
  end

  # @param indices [Array<Int>]
  def format_cell(indices: nil)
    cell = indices.map { |e| e + 1 }.join(',')
    cell = "(#{cell})"
  rescue
    ""
  end
  
  private
  
  def state_general
    @main_view = "components/companies/carrier_product_prices/show"
  end
end
