class Companies::CustomerCarrierCredentialConfigurationsController < CompaniesController
  before_action :set_customer
  before_action :set_carrier

  def show
  end

  def update
    @credential.whitelist_and_assign_params(params.fetch(:credential))
    @credential.save!

    flash[:notice] = "Credentials have been saved"
    redirect_to params[:redirect_url] || companies_customer_carrier_path(@customer, @carrier)
  end

  private

  def set_current_nav
    @current_nav = "customers"
  end

  def set_customer
    @customer = current_company.customers.find(params[:customer_id])
  end

  def set_carrier
    @carrier = Carrier.where(company: current_company).find(params[:carrier_id])
    raise "Carrier does not support overriding credentials" unless @carrier.supports_override_credentials?
    @credential = @carrier.override_credentials_class.find_or_initialize_by(target: @carrier, owner: @customer)
  end
end
