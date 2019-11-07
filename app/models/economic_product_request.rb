class EconomicProductRequest < ActiveRecord::Base
  scope :in_progress, -> { where(fetched_at: nil) }

  belongs_to :access, class_name: "EconomicAccess", required: true

  def enqueue_job!
    EconomicProductRequestJob.perform_later(id)
  end

  def fetched?
    fetched_at.present?
  end

  def fetch!
    with_lock { fetch_without_lock! }
  end

  def fetch_without_lock!
    return if fetched?

    products = EconomicProduct.where(access: access)

    EconomicProduct.transaction do
      # Mark all existing products as unavailable to begin with.
      products.update_all(no_longer_available: true)

      list = PaginatedProductList.new(access.agreement_grant_token)

      begin
        json_response = list.get_next_page
        json_response["collection"].each do |product_params|
          product = products.find_or_initialize_by(number: product_params["productNumber"])
          product.assign_attributes(name: product_params["name"], all_params: product_params)
          product.save!

          # Mark as available (without side-effects)
          product.update_column(:no_longer_available, false)
        end
      end until list.no_next_page?

      touch :fetched_at
    end
  end

  private

  class PaginatedProductList
    def initialize(token, uri: URI("https://restapi.e-conomic.com/products?pageSize=50"))
      @token = token
      @uri = uri
    end

    def get_next_page
      req = Net::HTTP::Get.new(uri)
      req["X-AppSecretToken"] = ENV.fetch("ECONOMIC_APP_SECRET_TOKEN")
      req["X-AgreementGrantToken"] = token

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      res.value # Raises an HTTP error if the response is not 2xx (success)

      @json_response = JSON.parse(res.body)
      @uri = URI(next_page) if next_page?

      @json_response
    end

    def no_next_page?
      !next_page?
    end

    def next_page?
      next_page
    end

    private

    attr_reader :token, :uri

    def next_page
      if @json_response
        @json_response["pagination"]["nextPage"]
      end
    end
  end
end
