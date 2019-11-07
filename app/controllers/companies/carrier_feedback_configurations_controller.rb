class Companies::CarrierFeedbackConfigurationsController < CompaniesController
  def index
    @carrier_feedback_configurations = CarrierFeedbackConfiguration.all.where(company: current_company).order(:id)
  end

  private

  def set_current_nav
    @current_nav = "shipments_updates"
  end
end
