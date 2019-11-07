class Companies::EconomicCarrierProductsController < CompaniesController
  before_action :set_economic_product_mapping, only: [:edit, :update, :cancel_edit]

  def index
    @carrier = Carrier.find_enabled_company_carriers(company_id: current_company.id).find(params[:carrier_id])
    @carrier_products = EconomicCarrierProductMapping.new(company: current_company, carrier: @carrier).carrier_products
  end

  def edit
    respond_to do |format|
      format.js { render :edit }
    end
  end

  def update
    @product_mapping.assign_attributes(product_mapping_params)
    @product_mapping.save!

    respond_to do |format|
      format.js { render :show }
    end
  end

  def cancel_edit
    respond_to do |format|
      format.js { render :show }
    end
  end

  private

  def product_mapping_params
    params.fetch(:economic_product_mapping, {}).permit(
      :product_number_incl_vat,
      :product_number_excl_vat,
    )
  end

  def set_economic_product_mapping
    @carrier_product = CarrierProduct.where(company_id: current_company.id, is_disabled: false).find(params[:id])
    @product_mapping = EconomicProductMapping.find_or_initialize_by(owner: current_company, item: @carrier_product)
  end

  def set_current_nav
    @current_nav = "economic_v2"
  end
end
