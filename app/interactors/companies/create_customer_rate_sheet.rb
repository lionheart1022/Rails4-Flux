class Companies::CreateCustomerRateSheet
  attr_accessor :current_company
  attr_accessor :current_user
  attr_accessor :customer
  attr_accessor :customer_carrier_product

  attr_reader :customer_recording
  attr_reader :rate_sheet

  def initialize(current_company:, current_user: nil, customer_id:, customer_carrier_product_id:)
    self.current_company = current_company
    self.current_user = current_user
    self.customer = self.current_company.customers.find(customer_id)
    self.customer_carrier_product = CustomerCarrierProduct.where(customer: self.customer).find(customer_carrier_product_id)

    @customer_recording = CustomerRecording.find_by!(company: self.current_company, recordable: self.customer)
  end

  def carrier_product
    customer_carrier_product.carrier_product
  end

  def base_price_document_upload
    PriceDocumentUpload.active.find_by(company: current_company, carrier_product: carrier_product)
  end

  def perform!
    unless carrier_product.carrier_product_price
      raise Error, "The selected carrier product has no associated price document"
    end

    unless carrier_product.has_valid_price_document?
      raise Error, "The selected carrier product does not have a valid price document"
    end

    unless customer_carrier_product.sales_price
      raise Error, "The selected carrier product and customer has no associated sales price"
    end

    unless base_price_document_upload
      raise Error, "You'll have to re-upload the price document for the selected carrier product before the rate sheet can be generated"
    end

    ActiveRecord::Base.transaction do
      latest_rate_sheet = RateSheet.all.order(id: :desc).find_by(
        company: current_company,
        customer_recording: customer_recording,
        carrier_product: carrier_product
      )

      new_rate_sheet = RateSheet.new(
        created_by: current_user,
        company: current_company,
        customer_recording: customer_recording,
        carrier_product: carrier_product,
        base_price_document_upload: base_price_document_upload,
      )
      new_rate_sheet.build_1_level_margin(customer_carrier_product: customer_carrier_product)

      @rate_sheet = nil

      if latest_rate_sheet
        @rate_sheet = latest_rate_sheet.no_change?(new_rate_sheet) ? latest_rate_sheet : new_rate_sheet
      else
        @rate_sheet = new_rate_sheet
      end

      if @rate_sheet.new_record?
        @rate_sheet.build_rate_snapshot
        @rate_sheet.save!
      end
    end

    true
  end

  class Error < StandardError
  end
end
