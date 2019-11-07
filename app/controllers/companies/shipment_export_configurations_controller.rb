class Companies::ShipmentExportConfigurationsController < CompaniesController
  def show
  end

  def update
    ShipmentExportSetting.transaction do
      shipment_export_setting = current_company.shipment_export_setting_for_editing
      shipment_export_setting.assign_attributes(shipment_export_setting_params)
      shipment_export_setting.save!
    end

    redirect_to url_for(action: "show"), notice: "Changes have been saved"
  end

  private

  def shipment_export_setting_params
    params.fetch(:shipment_export_setting, {}).permit(
      :trigger_when_created,
      :trigger_when_cancelled,
      :booked,
      :in_transit,
      :delivered,
      :problem,
    )
  end

  def set_current_nav
    @current_nav = "shipment_export_settings"
  end
end
