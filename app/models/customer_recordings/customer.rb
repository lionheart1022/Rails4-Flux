module CustomerRecordings
  class Customer < ::CustomerRecording
    alias_attribute :customer, :recordable

    validates :recordable_type, inclusion: { in: %w(Customer) }

    before_validation :set_customer_name_from_customer
    before_create :set_company_scoped_id_from_customer

    def shipment_filter_params
      {
        current_company: company,
        base_relation: Shipment.find_company_shipments(company_id: company_id),
        customer_id: recordable_id,
      }
    end

    private

    def set_customer_name_from_customer
      if customer
        self.customer_name = customer.name
        self.normalized_customer_name = normalize_string_value(customer_name)
      end
    end

    def set_company_scoped_id_from_customer
      if customer
        self.company_scoped_id ||= customer.customer_id
      end
    end
  end
end
