class Companies::DraftReportsController < CompaniesController
  def new
    @draft_report = current_company.draft_reports.where(id: params[:existing]).first if params[:existing].present?
    @draft_report ||= DraftReport.new_from_params(current_company, params: draft_report_params)
  end

  def create
    @draft_report = DraftReport.new_from_params(current_company, params: draft_report_params)
    @draft_report.created_by = current_user
    @draft_report.save!
    @draft_report.generate_shipment_collection_in_background!

    redirect_to wait_companies_draft_report_path(@draft_report)
  end

  def show
    @draft_report = current_company.draft_reports.find(params[:id])
    @shipment_collection_items =
      @draft_report
      .shipment_collection_items
      .includes(:shipment => [:carrier_product, :customer, :recipient, :asset_awb])
      .order(:id)
      .page(params[:page])
      .per(50)

    if @draft_report.generated_report
      redirect_to companies_report_path(@draft_report.generated_report)
    end
  end

  def wait
    @draft_report = current_company.draft_reports.find(params[:id])

    if @draft_report.report_in_progress?
      render :wait_report
    else
      render :wait_collection
    end
  end

  def in_progress
    @draft_report = current_company.draft_reports.find(params[:id])

    respond_to do |format|
      format.json do
        render json: { result: !@draft_report.in_progress? }
      end
    end
  end

  def toggle_shipment
    @draft_report = current_company.draft_reports.find(params[:id])
    @draft_report.toggle_shipment!(id: params[:shipment_id], selected: params[:selected])

    respond_to do |format|
      format.html { redirect_to companies_draft_report_path(@draft_report) }
      format.js
    end
  end

  def toggle_all_shipments
    @draft_report = current_company.draft_reports.find(params[:id])
    @draft_report.toggle_all_shipment!(selected: params[:selected])

    respond_to do |format|
      format.html { redirect_to companies_draft_report_path(@draft_report) }
      format.js
    end
  end

  def complete
    @draft_report = current_company.draft_reports.find(params[:id])
    @draft_report.generate_report_in_background!

    redirect_to wait_companies_draft_report_path(@draft_report)
  end

  private

  def draft_report_params
    params.fetch(:draft_report, {}).permit(
      :shipment_filter => [
        :customer_recording_id,
        :carrier_id,
        :start_date,
        :end_date,
        :pricing_status,
        :report_inclusion,
        :shipment_state,
      ],
      :configuration => [
        :with_detailed_pricing,
        :ferry_booking_data,
        :truck_driver_data,
      ],
    )
  end

  def set_current_nav
    @current_nav = "customers_reports"
  end
end
