class Companies::ShipmentUpdates::GLSFeedbackFilesController < CompaniesController
  def new
  end

  def create
    if params[:file].blank?
      flash.now[:error] = "File is missing"
      render :new

      return
    end

    feedback_file = GLSFeedbackFile.create! do |f|
      io = params[:file]

      f.company = current_company
      f.file_uploaded_by = current_user
      f.attach_file(io)
      io.rewind
      f.assign_file_contents(io)
    end

    feedback_file.parse!
    feedback_file.package_updates.each(&:apply_change!)

    redirect_to companies_shipment_update_path(feedback_file)
  end

  private

  def set_current_nav
    @current_nav = "shipments_updates"
  end
end
