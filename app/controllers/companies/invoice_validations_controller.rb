class Companies::InvoiceValidationsController < CompaniesController
  def create
    file_io = params["file"]
    if file_io.blank?
      flash[:error] = "Please select a file"
      redirect_to new_companies_invoice_validation_path
    else
      @invoice_validation = InvoiceValidation.create(company: current_company)
      @invoice_validation.attach_file(file_io)
      PreprocessInvoiceValidationJob.perform_later(@invoice_validation.id)
      redirect_to companies_invoice_validation_path(@invoice_validation)
    end
  end

  def show
    @invoice_validation = InvoiceValidation.where(company: current_company).find(params[:id])
    case @invoice_validation.status
    when *InvoiceValidation::LOADING_STATES
      render :poll_and_redirect
    when InvoiceValidation::States::PREPROCESSED_FILE
      render :edit
    when InvoiceValidation::States::PROCESSED_FILE, InvoiceValidation::States::EXPORTED_EXCEL_ERRORS
      render :show
    when InvoiceValidation::States::FAILED
      render :error_page, locals: { message: "There was an error. Please check your file again." }
    when InvoiceValidation::States::ERROR_HEADER
      render :error_page, locals: { message: "File's first line is empty." }
    when InvoiceValidation::States::EMPTY_FILE
      render :error_page, locals: { message: "File is empty." }
    else
      render :error_page, locals: { message: "Something went wrong." }
    end
  end

  def update
    @invoice_validation = InvoiceValidation.where(company: current_company).find(params[:id])
    @invoice_validation.update_attributes(invoice_validation_params)

    if @invoice_validation.preprocessed_file?
      ProcessInvoiceValidationJob.perform_later(@invoice_validation.id)
    else
      @invoice_validation.update!(status: InvoiceValidation::States::FAILED)
    end

    redirect_to companies_invoice_validation_path(@invoice_validation)
  end

  def export_excel_file
    @invoice_validation = InvoiceValidation.where(company: current_company).find(params[:id])
    ExportExcelErrorsFileJob.perform_later(@invoice_validation.id)
    redirect_to companies_invoice_validation_path(@invoice_validation)
  end

  def in_progress
    @invoice_validation = InvoiceValidation.where(company: current_company).find(params[:id])
    respond_to do |format|
      format.json do
        render json: { result: !@invoice_validation.in_a_loading_status? }
      end
    end
  end

  private

  def invoice_validation_params
    params.require(:invoice_validation).permit(:name, :shipment_id_column, :cost_column)
  end

  def set_current_nav
    @current_nav = "invoice_validation"
  end
end
