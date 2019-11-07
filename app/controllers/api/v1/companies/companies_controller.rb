class API::V1::Companies::CompaniesController < API::V1::APIController
  before_filter :restrict_access
  before_action :set_token

  private

  def access_token_forces_ssl?
    token_record ? token_record.force_ssl? : super
  end

  def restrict_access
    render json: { message: 'Invalid/missing access token' }, status: 401 if !access_token_is_valid?
  end

  def access_token_is_valid?
    !token_record.nil?
  end

  def set_token
    @token = token_record
  end

  def token_record
    if defined?(@_token_record)
      @_token_record
    else
      token = String(request.headers["HTTP_ACCESS_TOKEN"].presence || params[:access_token]).strip
      @_token_record = token.present? ? Token.find_company_token_by_value(value: token) : nil
    end
  end
end
