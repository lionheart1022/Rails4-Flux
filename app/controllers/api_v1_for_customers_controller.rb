class APIV1ForCustomersController < ActionController::Base
  force_ssl if: :access_token_forces_ssl?

  before_filter :restrict_access
  before_action :set_token

  private

  def access_token_forces_ssl?
    if token_record
      token_record.force_ssl?
    else
      Rails.env.staging? || Rails.env.production?
    end
  end

  def restrict_access
    render json: { message: 'Invalid/missing access token' }, status: 401 if invalid_access_token?
  end

  def set_token
    @token = token_record
  end

  def token_record
    if defined?(@_token_record)
      @_token_record
    else
      token = String(request.headers["HTTP_ACCESS_TOKEN"].presence || params[:access_token]).strip
      @_token_record = token.present? ? Token.find_customer_token_by_value(value: token) : nil
    end
  end

  def current_context
    @current_context ||= CurrentContext.token_setup(
      token: token_record,
      is_customer: current_customer.present?,
      company: current_company,
      customer: current_customer,
    )
  end

  def current_customer
    return if @token.blank?

    @token.owner if @token.is_customer?
  end

  def current_company
    return if @token.blank?

    return @token.owner.company if @token.is_customer?
    return @token.owner if @token.is_company?
  end

  def invalid_access_token?
    token_record.nil?
  end
end
