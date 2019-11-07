module CompanyDashboard
  class CarrierList
    attr_accessor :current_company
    attr_accessor :limit
    attr_accessor :type
    attr_accessor :search_term

    def initialize(params = {})
      # Defaults
      self.limit = 5
      self.type = :all

      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def results
      case type
      when :all
        carriers_as_results(all_carriers)
      when :search
        carriers_as_results(search_carriers)
      else
        []
      end
    end

    def to_builder
      Jbuilder.new do |json|
        json.array! results do |result|
          json.key "#{result.type}##{result.id}"
          json.type result.type
          json.id result.id
          json.text result.text
        end
      end
    end

    private

    def all_carriers
      Carrier
        .find_company_carriers(company_id: current_company.id)
        .limit(limit.presence)
    end

    def search_carriers
      Carrier
        .autocomplete_search(company_id: current_company.id, carrier_name: search_term)
        .limit(limit.presence)
    end

    def carriers_as_results(carriers)
      carriers.map { |carrier| Result.new(type: "Carrier", id: carrier.id, text: carrier.name) }
    end

    class Result
      attr_accessor :type, :id, :text

      def initialize(params = {})
        params.each do |attr, value|
          self.public_send("#{attr}=", value)
        end
      end
    end

    private_constant :Result
  end
end
