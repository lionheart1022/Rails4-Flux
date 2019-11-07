class Companies::EconomicProductRequestsController < CompaniesController
  def create
    economic_access = EconomicAccess.active.find_by!(owner: current_company)
    product_request = economic_access.product_requests.create!
    product_request.enqueue_job!

    respond_to do |format|
      format.js
    end
  end

  def fetch_status
    economic_access = EconomicAccess.active.find_by!(owner: current_company)

    respond_to do |format|
      format.json { render json: { done: economic_access.in_progress_product_requests.empty? } }
    end
  end

  private

  def set_current_nav
    @current_nav = "economic_v2"
  end
end
