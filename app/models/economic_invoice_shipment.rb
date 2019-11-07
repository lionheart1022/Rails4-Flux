class EconomicInvoiceShipment < ActiveRecord::Base
  belongs_to :invoice, class_name: "EconomicInvoiceRecord", required: true
  belongs_to :shipment, required: true
end
