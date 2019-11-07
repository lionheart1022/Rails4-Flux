class Companies::CreateToken
  attr_reader :current_context
  attr_accessor :owner_id, :owner_type
  attr_reader :token

  def initialize(current_context:, params:)
    raise ArgumentError, "`current_context` is required" if !current_context

    @current_context = current_context

    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def perform!
    if owner_type == "Company"
      perform_for_company!
    elsif owner_type == "Customer"
      perform_for_customer!
    else
      raise "Cannot create token for invalid owner [#{owner_type.inspect}, #{owner_id.inspect}]"
    end
  end

  private

  def perform_for_company!
    @token = nil
    company = Company.find(owner_id)
    raise "Company is only allowed to create a new token for itself" if current_company != company
    @token = generate_token
  end

  def perform_for_customer!
    @token = nil
    customer = Customer.where(company: current_company).find(owner_id)
    @token = generate_token
  end

  def generate_token
    token = AccessToken.find_or_initialize_by(owner_id: owner_id, owner_type: owner_type)
    token.value = AccessToken.generate_token

    Rails.logger.tagged(current_company.name) do
      if token.persisted?
        Rails.logger.info "Companies::CreateToken current_user='#{current_context.identifier}' owner_type=#{owner_type} owner_id=#{owner_id} old_token=#{token.value_was} new_token=#{token.value}"
      else
        Rails.logger.info "Companies::CreateToken current_user='#{current_context.identifier}' owner_type=#{owner_type} owner_id=#{owner_id} initial_token=#{token.value}"
      end
    end

    token.save!
    token
  end

  def current_company
    current_context.company
  end
end
