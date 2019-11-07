class Companies::EconomicAccessesController < CompaniesController
  def create
    request_access_uri = EconomicConnect.request_access_uri(redirect_url: callback_companies_v2_economic_access_url)

    redirect_to(request_access_uri.to_s)
  end

  def callback
    validation = EconomicConnect::CallbackValidation.new(params[:token])

    begin
      validation.perform!
    rescue EconomicConnect::CallbackValidation::BaseError => e
      ExceptionMonitoring.report!(e, context: { user_email: current_user.email, token: params[:token] })
      render text: e.human_friendly_reason
    else
      economic_access = current_context.set_economic_agreement_grant_token!(params[:token], self_response: validation.self_response)

      # Fetch products in the background
      economic_product_request = economic_access.product_requests.create!
      economic_product_request.enqueue_job!

      redirect_to companies_v2_economic_carriers_path, notice: "Connected with e-conomic successfully"
    end
  end
end
