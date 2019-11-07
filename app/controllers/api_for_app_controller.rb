class APIForAppController < ActionController::Base
  before_action :authenticate!
  before_action :response_format_must_be_json!
  after_action :update_last_used_at_for_token_session

  class BaseError < StandardError; end
  class ExpiredTokenError < BaseError; end
  class InvalidTokenError < BaseError; end

  rescue_from ExpiredTokenError do
    render "api_for_app/expired_token", status: :unauthorized
  end

  rescue_from InvalidTokenError do
    render "api_for_app/needs_auth", status: :unauthorized
  end

  attr_reader :current_token_session
  helper_method :current_token_session
  helper_method :current_company

  private

  def current_company
    current_token_session.company
  end

  def authenticate!
    if token_session = authenticate_with_http_token { |t, o| TruckDriver.authenticate_with_token(t, o) }
      if token_session.active?
        @current_token_session = token_session
      else
        raise ExpiredTokenError
      end
    else
      raise InvalidTokenError
    end
  end

  def response_format_must_be_json!
    if params[:format].blank?
      render "api_for_app/blank_format", status: :unsupported_media_type
    elsif params[:format] != "json"
      render "api_for_app/not_json_format", status: :unsupported_media_type
    end
  end

  def update_last_used_at_for_token_session
    if current_token_session
      current_token_session.register_usage!
    end
  end
end
