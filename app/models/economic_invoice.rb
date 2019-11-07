class EconomicInvoice

  attr_reader :sender_company, :recipient_company_or_customer, :currency, :shipments

  def initialize(sender_company: nil, recipient_company_or_customer: nil, currency: nil)
    @sender_company = sender_company
    @recipient_company_or_customer = recipient_company_or_customer
    @currency = currency
    @shipments = []
    @freight_product_with_vat_total = BigDecimal.new("0.0")
    @freight_product_without_vat_total = BigDecimal.new("0.0")
  end

  def add_shipment(shipment)
    @shipments << shipment
  end

  def create_economic_draft_invoice
    calculate_totals
    post_invoice_to_economic
  end

  private

    def calculate_totals

      # shipments.each do |shipment|
      #   Rails.logger.info("*** [VAT] shipment #{shipment.unique_shipment_id}: #{include_vat?(shipment)}")
      #
      #   if shipment.unique_shipment_id == "3-1-784"
      #     carrier_product = shipment.carrier_product
      #     Rails.logger.info("*** [VAT] sender.address.in_eu?: #{sender.address.in_eu?} - #{sender.address.inspect}")
      #     Rails.logger.info("*** [VAT] recipient.address.in_eu?: #{recipient.address.in_eu?} - #{recipient.address.inspect}")
      #     Rails.logger.info("*** [VAT] sender.address.is_denmark?: #{sender.address.is_denmark?}")
      #     Rails.logger.info("*** [VAT] recipient.address.is_denmark?: #{recipient.address.is_denmark?}")
      #     Rails.logger.info("*** [VAT] POST 1: #{carrier_product.is_a?(PacsoftPostDkPrivatpakkerNordenMedOmdelingCarrierProduct)}")
      #     Rails.logger.info("*** [VAT] POST 2: #{carrier_product.is_a?(PacsoftPostDkPrivatpakkerNordenCarrierProduct)}")
      #   end
      #
      # end
      #
      # raise "stop"

      shipments.each do |shipment|
        advanced_price = shipment.advanced_prices.select{ |ap| ap.seller_id == sender_company.id}.first
        sales_price_amount = advanced_price.try(:total_sales_price_amount) || BigDecimal.new("0.0")

        if include_vat?(shipment)
          @freight_product_with_vat_total += sales_price_amount.round(2)
        else
          @freight_product_without_vat_total += sales_price_amount.round(2)
        end
      end

      Rails.logger.info("*** [EconomicInvoice] Totals:")
      Rails.logger.info("*** [EconomicInvoice] freight_product_with_vat_total: #{@freight_product_with_vat_total}")
      Rails.logger.info("*** [EconomicInvoice] freight_product_without_vat_total: #{@freight_product_without_vat_total}")
    end

    def post_invoice_to_economic

      # Rails.logger.debug ENV.inspect
      # Rails.logger.debug Rails.env
      # Rails.logger.info("*** [SHP] REQUEST BODY: #{build_request_body}")

      response = connection.post('/invoices/drafts') do |req|
        req.body = build_request_body
      end

      unless response.status == 201
        raise "*** [EconomicInvoice] Failed to create e-conomic invoice. Request body: #{build_request_body}, response: #{response.inspect}"
      end
    end

    def find_economic_setting
      @economic_setting ||= EconomicSetting.find_for_company(company_id: sender_company.id)
    end

    def include_vat?(shipment)
      ShipmentVatPolicy.new(shipment).include_vat?
    end

    def find_external_accounting_number
      accounting_number = 0

      if recipient_company_or_customer.is_a?(Customer)
        accounting_number = recipient_company_or_customer.external_accounting_number.to_i
      elsif recipient_company_or_customer.is_a?(Company)
        accounting_number = EntityRelation.find_carrier_product_customer_entity_relation(from_reference_id: sender_company.id, to_reference_id: recipient_company_or_customer.id).external_accounting_number.to_i
      end

      raise "*** [EconomicInvoice] Failed to find external accounting number for: #{recipient_company_or_customer.inspect}" if accounting_number < 1

      return accounting_number
    end

    def external_accounting_number
      @external_accounting_number ||= find_external_accounting_number
    end

    def build_request_body
      economic_invoice_template.merge({
        "lines" => [
          {
            "description" => find_economic_setting.product_name_inc_vat,
            "product" => {
              "productNumber" => find_economic_setting.product_number_inc_vat.to_s
            },
            "unit" => {
              "unitNumber" => 1
            },
            "quantity" => 1.0,
            "unitNetPrice" => @freight_product_with_vat_total.truncate(2).to_f
          },
          {
            "description" => find_economic_setting.product_name_ex_vat,
            "product" => {
              "productNumber" => find_economic_setting.product_number_ex_vat.to_s
            },
            "unit" => {
              "unitNumber" => 1
            },
            "quantity" => 1.0,
            "unitNetPrice" => @freight_product_without_vat_total.truncate(2).to_f
          }
        ]
      }).to_json
    end

    def economic_invoice_template
      response = connection.get "/customers/#{external_accounting_number}/templates/invoice"
      JSON.parse(response.body)
    end

    def connection
      @connection ||= Faraday.new(
        url: "https://restapi.e-conomic.com",
        headers: economic_headers
      )
    end

    def economic_headers
      {
        "Content-Type" => "application/json",
        "X-AppSecretToken" => ENV.fetch("ECONOMIC_APP_SECRET_TOKEN"),
        "X-AgreementGrantToken" => find_economic_setting.agreement_grant_token
      }
    end
end
