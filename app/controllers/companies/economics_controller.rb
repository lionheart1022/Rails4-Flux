class Companies::EconomicsController < CompaniesController
  before_filter :check_agreement_grant_token, except: [:callback]

  # Redirect back from e-conomic after authorization
  def callback
    find_economic_setting.update_agreement_grant_token(token: params[:token])
    set_default_settings
    redirect_to edit_companies_economic_path
  end

  # Edit local e-conomic settings
  def edit
    @view_model = Companies::EconomicSettings::EditView.new(
      setting:       find_economic_setting,
      products:      fetch_products
    )
  end

  def update
    if params.has_key?(:product_number_ex_vat) && !params[:product_number_ex_vat].nil?
      find_economic_setting.update_attributes!(
        product_number_ex_vat: params[:product_number_ex_vat],
        product_name_ex_vat:   params[:product_name_ex_vat]
      )
    end

    if params.has_key?(:product_number_inc_vat) && !params[:product_number_inc_vat].nil?
      find_economic_setting.update_attributes!(
        product_number_inc_vat: params[:product_number_inc_vat],
        product_name_inc_vat:   params[:product_name_inc_vat]
      )
    end

    redirect_to edit_companies_economic_path
  end

  private

    def set_default_settings
      find_economic_setting.update_attributes!(
        product_number_ex_vat:  fetch_products.body["collection"].first["productNumber"],
        product_number_inc_vat: fetch_products.body["collection"].last["productNumber"],
        product_name_ex_vat:    fetch_products.body["collection"].first["name"],
        product_name_inc_vat:   fetch_products.body["collection"].last["name"]
      )
    end

    def find_economic_setting
      @economic_setting ||= EconomicSetting.find_or_create_by(company_id: current_company.id)
    end

    def fetch_products
      connection.get("/products")
    end

    def check_agreement_grant_token
      if find_economic_setting.agreement_grant_token.nil?
        redirect_to "https://secure.e-conomic.com/secure/api1/requestaccess.aspx?appId=#{ENV.fetch("ECONOMIC_APP_PUBLIC_TOKEN")}&redirectUrl=#{callback_companies_economic_url}"
      end
    end

    def connection
      @connection ||= Faraday.new(url: "https://restapi.e-conomic.com",
        headers: {
          "Content-Type"          => "application/json",
          "X-AppSecretToken"      => ENV.fetch("ECONOMIC_APP_SECRET_TOKEN"),
          "X-AgreementGrantToken" => find_economic_setting.agreement_grant_token
        }
      ) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.response :json
      end
    end

    def set_current_nav
      @current_nav = "economic"
    end

end
