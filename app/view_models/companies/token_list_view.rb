class Companies::TokenListView
  attr_reader :current_company
  attr_accessor :pagination, :page

  def initialize(current_company:)
    @current_company = current_company
  end

  def show_company?
    if pagination
      page.to_i <= 1
    else
      true
    end
  end

  def company_name
    current_company.name
  end

  def company_token
    if defined?(@company_token)
      @company_token
    else
      @company_token = Token.find_company_token(company_id: current_company.id)
    end
  end

  alias_method :company_token?, :company_token

  def customers_relation
    if defined?(@customers_relation)
      @customers_relation
    else
      @customers_relation = Customer.find_company_customers(company_id: current_company.id).order(:customer_id)
      @customers_relation = @customers_relation.page(page) if pagination
      @customers_relation
    end
  end

  def customers
    customers_relation.map do |customer|
      customer_token = Token.find_company_customer_token(company_id: current_company.id, customer_id: customer.id)
      CustomerTokenItem.new(customer, customer_token)
    end
  end

  CustomerTokenItem = Struct.new(:customer, :token) do
    def id
      customer.id
    end

    def name
      customer.name
    end

    def token?
      token
    end

    def token_id
      token.id
    end
  end

  private_constant :CustomerTokenItem
end
