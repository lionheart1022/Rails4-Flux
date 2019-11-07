class Companies::CarrierProductSurchargesController < CompaniesController
  before_action :set_carrier_product

  def index
  end

  def index_v2
    @view_model = Companies::CarrierProductSurchargesViewV2.new(current_company: current_company, carrier_product: @carrier_product)
  end

  def bulk_update
    @carrier_product.bulk_update_surcharges(bulk_update_params[:surcharges], current_user: current_user)

    redirect_to companies_carrier_surcharges_path(@carrier), notice: "Changes were saved"
  end

  def bulk_update_v2
    SurchargeOnProductBulkUpdate
      .new(carrier_product: @carrier_product, surcharges_attributes: bulk_update_v2_params[:surcharges], current_user: current_user)
      .perform!

    redirect_to(
      params[:redirect_url].presence || companies_carrier_surcharges_path(@carrier),
      notice: "Changes were saved"
    )
  end

  def destroy
    surcharge_on_product = SurchargeOnProduct.where(carrier_product: @carrier_product).find(params[:id])
    surcharge_on_product.destroy

    redirect_to v2_companies_carrier_surcharges_path(@carrier), notice: "Product-level override has been removed"
  end

  private

  def set_carrier_product
    @carrier_product = CarrierProduct.find_company_carrier_product(company_id: current_company.id, carrier_product_id: params[:carrier_product_id])
    @carrier = @carrier_product.carrier
  end

  def bulk_update_params
    params.fetch(:bulk_update, {}).permit(
      :surcharges => [
        :id,
        :parent_id,
        :enabled,
        :charge_value,
        :calculation_method,
      ]
    )
  end

  def bulk_update_v2_params
    params.fetch(:bulk_update, {}).permit(
      :surcharges => [
        :id,
        :parent_id,
        :enabled,
        :charge_value,
        :calculation_method,
        :monthly => [
          :valid_from,
          :expires_on,
          :charge_value,
        ]
      ]
    )
  end

  def set_current_nav
    @current_nav = "carrier_surcharges"
  end
end
