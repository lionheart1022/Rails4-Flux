class API::V1::APIController < ActionController::Base
  force_ssl if: :access_token_forces_ssl?

  private

  def access_token_forces_ssl?
    Rails.env.staging? || Rails.env.production?
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
end
