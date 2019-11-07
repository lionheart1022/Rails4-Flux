module CompanyDashboard
  class CustomerList
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
      results =
        case type
        when :all
          customers_as_results(all_customers) + company_customers_as_results(all_company_customers)
        when :search
          customers_as_results(search_customers) + company_customers_as_results(search_company_customers)
        else
          []
        end

      sort_and_limit_results(results)
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

    def all_customers
      Customer
        .find_company_customers(company_id: current_company.id)
        .limit(limit.presence)
    end

    def all_company_customers
      Company
        .find_all_companies_buying_from_company(company_id: current_company.id)
        .limit(limit.presence)
    end

    def search_customers
      Customer
        .autocomplete_search(company_id: current_company.id, customer_name: search_term)
        .limit(limit.presence)
    end

    def search_company_customers
      Company
        .find_all_companies_buying_from_company(company_id: current_company.id)
        .autocomplete_search(company_name: search_term)
        .limit(limit.presence)
    end

    def customers_as_results(customers)
      customers.map { |customer| Result.new(type: "Customer", id: customer.id, text: customer.name) }
    end

    def company_customers_as_results(companies)
      companies.map { |company| Result.new(type: "Company", id: company.id, text: company.name) }
    end

    def sort_and_limit_results(results)
      sorted_results = results.sort_by(&:text)
      limit.present? ? sorted_results.take(limit) : sorted_results
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
