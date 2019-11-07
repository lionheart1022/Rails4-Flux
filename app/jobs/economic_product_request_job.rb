class EconomicProductRequestJob < ActiveJob::Base
  queue_as :booking

  def perform(product_request_id)
    product_request = EconomicProductRequest.find(product_request_id)
    product_request.fetch!
  end
end
