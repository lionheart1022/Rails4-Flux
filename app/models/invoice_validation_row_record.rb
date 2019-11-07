class InvoiceValidationRowRecord < ActiveRecord::Base
  belongs_to :invoice_validation, required: true

  def shipment_id
    column_letters = invoice_validation.shipment_id_column.gsub(/[^a-zA-Z]/, '')
    shipment_id = field_data.select { |k, _| k.include? column_letters }.values.first
    shipment_id ? shipment_id : ""
  end

  def cost
    column_letters = invoice_validation.cost_column.gsub(/[^a-zA-Z]/, '')
    cost = field_data.select { |k, _| k.include? column_letters }.values.first
    cost ? cost : ""
  end
end
