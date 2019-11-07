class EconomicInvoiceLine < ActiveRecord::Base
  belongs_to :invoice, class_name: "EconomicInvoiceRecord", required: true, touch: true

  def description
    payload.try(:[], "description")
  end

  def product_number
    payload.try(:[], "product").try(:[], "productNumber")
  end

  def product_number=(value)
    self.payload ||= {}
    self.payload["product"] ||= {}
    self.payload["product"]["productNumber"] = value
  end

  def product_number?
    product_number.present?
  end

  def quantity
    payload.try(:[], "quantity")
  end

  def unit_price
    payload.try(:[], "unitNetPrice")
  end
end
