class Companies::ReportExcelExportsController < CompaniesController
  def create
    report = current_company.reports.find(params[:report_id])
    report.generate_excel_report_later!

    redirect_to companies_report_path(report)
  end
end
