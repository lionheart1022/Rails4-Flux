class EconomicInvoiceRecord < ActiveRecord::Base
  self.table_name = "economic_invoices"

  belongs_to :parent, polymorphic: true, required: true
  belongs_to :seller, polymorphic: true
  belongs_to :buyer, polymorphic: true
  has_many :shipment_associations, class_name: "EconomicInvoiceShipment", foreign_key: "invoice_id", inverse_of: :invoice
  has_many :shipments, through: :shipment_associations
  has_many :lines, class_name: "EconomicInvoiceLine", foreign_key: "invoice_id", inverse_of: :invoice, dependent: :delete_all
  has_many :ordered_lines, -> { order(:id) }, class_name: "EconomicInvoiceLine", foreign_key: "invoice_id", inverse_of: :invoice

  scope :still_editable, -> { where(http_request_sent_at: nil) }
  scope :ready, -> { where(ready: true) }
  scope :enqueued, -> { where.not(job_enqueued_at: nil) }
  scope :not_sent, -> { where(http_request_sent_at: nil) }
  scope :succeeded, -> { where(http_request_succeeded: true) }

  class << self
    def bulk_update!(parent:, bulk_update_params: {})
      invoices_relation = self.still_editable.where(parent: parent)

      ActiveRecord::Base.transaction do
        (bulk_update_params[:invoices] || {}).each do |_, invoice_params|
          invoice_id = invoice_params.delete(:id)
          invoice_lines_params = invoice_params.delete(:invoice_lines) || {}

          invoice = invoices_relation.find(invoice_id)
          invoice.assign_attributes(invoice_params)
          invoice.save!

          invoice_lines_params.each do |_, invoice_line_params|
            invoice_line_id = invoice_line_params.delete(:id)

            invoice_line = invoice.lines.find(invoice_line_id)
            invoice_line.assign_attributes(invoice_line_params)
            invoice_line.save!
          end

          invoice.check_readiness!
        end
      end

      true
    end
  end

  def build_lines_from_shipment(shipment)
    seller_price = shipment.advanced_prices.find_by(seller: seller)

    return if seller_price.nil?

    carrier_product = find_carrier_product_for_seller_company_from_shipment(shipment)
    economic_product_mapping = EconomicProductMapping.find_by(owner: seller, item: carrier_product)
    shipment_includes_vat = ShipmentVatPolicy.new(shipment).include_vat?

    seller_price.advanced_price_line_items.each do |line_item|
      next if line_item.sales_price_amount.nil?

      economic_product_number =
        if economic_product_mapping
          if shipment_includes_vat
            economic_product_mapping.product_number_incl_vat.presence
          else
            economic_product_mapping.product_number_excl_vat.presence
          end
        end

      self.lines.build(
        includes_vat: shipment_includes_vat,
        payload: {
          "description" => build_invoice_line_description(shipment: shipment, line_item: line_item),
          "product" => { "productNumber" => economic_product_number },
          "unit" => { "unitNumber" => 1 },
          "quantity" => line_item.times,
          "unitNetPrice" => line_item.sales_price_amount.round(2).to_f,
        }
      )
    end
  end

  def build_simplified_lines_from_shipment(shipment)
    seller_price = shipment.advanced_prices.find_by(seller: seller)

    return if seller_price.nil?

    carrier_product = find_carrier_product_for_seller_company_from_shipment(shipment)
    economic_product_mapping = EconomicProductMapping.find_by(owner: seller, item: carrier_product)
    shipment_includes_vat = ShipmentVatPolicy.new(shipment).include_vat?

    economic_product_number =
      if economic_product_mapping
        if shipment_includes_vat
          economic_product_mapping.product_number_incl_vat.presence
        else
          economic_product_mapping.product_number_excl_vat.presence
        end
      end

    sales_price_amounts = seller_price.advanced_price_line_items.map do |line_item|
      line_item.sales_price_amount.present? ? line_item.sales_price_amount.round(2) : nil
    end

    return if sales_price_amounts.compact.count == 0

    total_sales_price_amount = sales_price_amounts.compact.sum

    self.lines.build(
      includes_vat: shipment_includes_vat,
      payload: {
        "description" => build_simplified_invoice_line_description(shipment: shipment),
        "product" => { "productNumber" => economic_product_number },
        "unit" => { "unitNumber" => 1 },
        "quantity" => 1,
        "unitNetPrice" => total_sales_price_amount.to_f,
      }
    )
  end

  def still_editable?
    http_request_sent_at.blank?
  end

  def no_longer_editable?
    !still_editable?
  end

  def looks_valid?
    ready?
  end

  def looks_invalid?
    !looks_valid?
  end

  def check_readiness!
    update!(ready: external_accounting_number.present? && lines.all?(&:product_number?))
  end

  private

  def find_carrier_product_for_seller_company_from_shipment(shipment)
    carrier_product = shipment.carrier_product

    while carrier_product
      return carrier_product if carrier_product.company == seller

      # Move on to next carrier product
      carrier_product = carrier_product.carrier_product
    end

    return nil
  end

  def build_invoice_line_description(shipment:, line_item:)
    part_id_and_product = "#{shipment.unique_shipment_id}, #{shipment.carrier_product.name}"
    part_description = line_item.description.present? ? "#{line_item.description}" : "/"
    part_sender = shipment.sender ? "#{shipment.sender.company_name} [#{shipment.sender.country_code.try(:upcase)}]" : "Sender N/A"
    part_recipient = shipment.recipient ? "#{shipment.recipient.company_name} [#{shipment.recipient.country_code.try(:upcase)}]" : "Recipient N/A"
    parts_package_data = shipment.package_dimensions.aggregate.map do |dimension|
      "#{dimension.amount} x L#{dimension.length.round(2)}cm W#{dimension.width.round(2)}cm H#{dimension.height.round(2)}cm [#{dimension.weight.round(2)}kg]"
    end

    "#{part_id_and_product}: #{part_description}; #{part_sender} - #{part_recipient}; #{shipment.reference}; #{shipment.shipping_date.to_s}; #{parts_package_data.join(', ')}"
  end

  def build_simplified_invoice_line_description(shipment:)
    part_id_and_product = "#{shipment.unique_shipment_id}, #{shipment.carrier_product.name}"
    part_sender = shipment.sender ? "#{shipment.sender.company_name} [#{shipment.sender.country_code.try(:upcase)}]" : "Sender N/A"
    part_recipient = shipment.recipient ? "#{shipment.recipient.company_name} [#{shipment.recipient.country_code.try(:upcase)}]" : "Recipient N/A"
    parts_package_data = shipment.package_dimensions.aggregate.map do |dimension|
      "#{dimension.amount} x L#{dimension.length.round(2)}cm W#{dimension.width.round(2)}cm H#{dimension.height.round(2)}cm [#{dimension.weight.round(2)}kg]"
    end

    "#{part_id_and_product}; #{part_sender} - #{part_recipient}; #{shipment.reference}; #{shipment.shipping_date.to_s}; #{parts_package_data.join(', ')}"
  end
end
