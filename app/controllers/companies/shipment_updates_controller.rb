class Companies::ShipmentUpdatesController < CompaniesController
  def index
    @carrier_feedback_files = current_company.carrier_feedback_files.includes(:configuration).order(id: :desc).page(params[:page])
  end

  def new
  end

  def show
    @carrier_feedback_file = current_company.carrier_feedback_files.find(params[:id])
    @package_updates =
      @carrier_feedback_file
      .package_updates
      .includes(:package_recording, :package => [:active_recording, { :shipment => :asset_awb }])
      .order(:id)
      .page(params[:page])
      .per(100)
  end

  private

  def set_current_nav
    @current_nav = "shipments_updates"
  end
end
