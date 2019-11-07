module AdminNavigation
  def self.for_company(company)
    CompanyNavigation.new(company)
  end

  def self.for_customer(customer:, company:)
    CustomerNavigation.new(customer: customer, company: company)
  end

  class BaseNavigation
    def shipment_request_action_required_count
      nil
    end

    def shipment_action_required_count
      nil
    end

    def pickup_action_required_count
      nil
    end

    def ferry_routes?
      false
    end

    def economic?
      false
    end
  end

  class CompanyNavigation < BaseNavigation
    attr_reader :company

    def initialize(company)
      @company = company
    end

    def shipment_request_action_required_count
      @_shipment_request_action_required_count ||= company.shipment_request_action_required_count
    end

    def shipment_action_required_count
      @_shipment_action_required_count ||= company.shipment_action_required_count
    end

    def pickup_action_required_count
      @_pickup_action_required_count ||= company.pickup_action_required_count
    end

    def ferry_routes?
      if defined?(@_ferry_routes)
        @_ferry_routes
      else
        @_ferry_routes = company.ferry_routes_available?
      end
    end

    def economic?
      if defined?(@_economic)
        @_economic
      else
        @_economic = company.can_use_economic?
      end
    end
  end

  class CustomerNavigation < BaseNavigation
    attr_reader :customer, :company

    def initialize(customer:, company:)
      @customer = customer
      @company = company
    end

    def shipment_request_action_required_count
      @_shipment_request_action_required_count ||= ShipmentRequest.get_action_required_for_customer_count(company_id: company.id, customer_id: customer.id)
    end
  end
end
