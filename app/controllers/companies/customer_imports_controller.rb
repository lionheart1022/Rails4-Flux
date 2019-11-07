class Companies::CustomerImportsController < CompaniesController
  def new
  end

  def parse_in_background
    file = params[:customer_import].try(:[], :file)

    if file.blank?
      redirect_to url_for(action: "new")
      return
    end

    import = CustomerImport.new(company: current_company, created_by: current_user)
    import.attach_file(file)
    import.save!
    import.parse_in_background

    redirect_to url_for(action: "show", id: import.id)
  end

  def show
    @import = CustomerImport.where(company: current_company).find(params[:id])

    case
    when @import.failed?
      render :show_failed
    when @import.parsing?
      render :show_parsing_in_progress
    when @import.creating?
      render :show_creating_in_progress
    else
      render :show
    end
  end

  def progress
    @import = CustomerImport.where(company: current_company).find(params[:id])

    respond_to do |format|
      format.json do
        render json: { result: @import.stage_completed?(params[:stage]) }
      end
    end
  end

  def perform_in_background
    import = CustomerImport.where(company: current_company).find(params[:id])
    import.update!(params.fetch(:customer_import, {}).permit(:send_invitation_email))
    import.perform_in_background

    redirect_to url_for(action: "show", id: import.id)
  end

  private

  def set_current_nav
    @current_nav = "customers"
  end
end
