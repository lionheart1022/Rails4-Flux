class Companies::PackageUpdatesController < CompaniesController
  def apply
    carrier_feedback_file = current_company.carrier_feedback_files.find(params[:shipment_update_id])
    package_update = carrier_feedback_file.package_updates.find(params[:id])

    package_update.apply_change!

    redirect_to companies_shipment_update_path(carrier_feedback_file)
  end
end
