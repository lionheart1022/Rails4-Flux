class Companies::ReportExcelExportStatusesController < CompaniesController
  def show
    report = Report.where(company_id: current_company.id).find(params[:report_id])

    respond_to do |format|
      format.json { render json: { result: !report.in_progress? } }
    end
  end
end
