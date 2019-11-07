module CustomerRecordings
  class CarrierProductCustomer < ::CustomerRecording
    alias_attribute :carrier_product_customer, :recordable

    validates :recordable_type, inclusion: { in: %w(Company) }

    before_validation :set_customer_name_from_carrier_product_customer

    def shipment_filter_params
      {
        current_company: company,
        base_relation: Shipment.find_company_shipments(company_id: company_id),
        buyer_company_id: recordable_id,
      }
    end

    private

    def set_customer_name_from_carrier_product_customer
      if carrier_product_customer
        self.customer_name = carrier_product_customer.name
        self.normalized_customer_name = normalize_string_value(customer_name)
      end
    end
  end
end
