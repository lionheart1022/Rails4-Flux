class Companies::CarrierProductRulesController < CompaniesController
  before_action :set_carrier_product

  def index
    carrier_product_rule = CarrierProductRule.where(carrier_product: @carrier_product).first

    if carrier_product_rule
      redirect_to url_for(action: "edit", id: carrier_product_rule)
    else
      redirect_to url_for(action: "new")
    end
  end

  def new
    @carrier_product_rule = CarrierProductRule.new(carrier_product: @carrier_product)
  end

  def create
    @carrier_product_rule = CarrierProductRule.new(carrier_product: @carrier_product)
    @carrier_product_rule.assign_attributes(carrier_product_rule_params)

    if @carrier_product_rule.save
      redirect_to companies_carrier_path(@carrier_product.carrier), notice: "Product rules have been saved"
    else
      render :new
    end
  end

  def edit
    @carrier_product_rule = CarrierProductRule.where(carrier_product: @carrier_product).find(params[:id])
  end

  def update
    @carrier_product_rule = CarrierProductRule.where(carrier_product: @carrier_product).find(params[:id])
    @carrier_product_rule.assign_attributes(carrier_product_rule_params)

    if @carrier_product_rule.save
      @carrier_product_rule.shipment_weight_interval.save!
      @carrier_product_rule.number_of_packages_interval.save!

      redirect_to companies_carrier_path(@carrier_product.carrier), notice: "Product rules have been saved"
    else
      render :edit
    end
  end

  def destroy
    carrier_product_rule = CarrierProductRule.where(carrier_product: @carrier_product).find(params[:id])
    carrier_product_rule.destroy

    redirect_to companies_carrier_path(@carrier_product.carrier), notice: "Product rule has been deleted"
  end

  private

  def set_carrier_product
    @carrier_product = CarrierProduct.find_company_carrier_product(company_id: current_company.id, carrier_product_id: params[:carrier_product_id])
  end

  def carrier_product_rule_params
    params.fetch(:carrier_product_rule, {}).permit(
      :shipment_weight_interval_enabled,
      :shipment_weight_interval_from,
      :shipment_weight_interval_from_inclusive,
      :shipment_weight_interval_to,
      :shipment_weight_interval_to_inclusive,
      :number_of_packages_interval_enabled,
      :number_of_packages_interval_from,
      :number_of_packages_interval_from_inclusive,
      :number_of_packages_interval_to,
      :number_of_packages_interval_to_inclusive,
      :recipient_match_enabled,
      :recipient_location_value,
    )
  end
end
