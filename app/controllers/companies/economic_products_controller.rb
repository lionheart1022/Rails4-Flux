class Companies::EconomicProductsController < CompaniesController
  def select_element
    economic_access = EconomicAccess.active.find_by!(owner: current_company)
    @products = economic_access.products.order(:number, :name)

    respond_to do |format|
      format.json { render json: { html: render_to_string("_select_element", layout: false, formats: [:html]) } }
    end
  end

  private

  def set_current_nav
    @current_nav = "economic_v2"
  end
end
