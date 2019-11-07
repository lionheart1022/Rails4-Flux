module InvoicingMethods
  class Base < ActiveRecord::Base
    self.table_name = "invoicing_methods"

    belongs_to :company, required: true

    def can_destroy_via_ui?
      false
    end
  end
end
