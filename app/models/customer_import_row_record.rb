class CustomerImportRowRecord < ActiveRecord::Base
  self.table_name = "customer_import_rows"

  scope :valid_for_creating_customer, -> { where({}) }

  belongs_to :customer_import, required: true

  def as_plain_row
    CustomerImportRow.new(field_data)
  end
end
