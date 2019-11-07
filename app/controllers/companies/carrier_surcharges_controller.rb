class Companies::CarrierSurchargesController < CompaniesController
  before_action :set_carrier

  def index
    @view_model = Companies::CarrierSurchargesView.new(current_company: current_company, carrier: @carrier)

    if @carrier.can_edit_surcharges?
      render :index
    else
      render :index_referenced
    end
  end

  def index_v2
    @view_model = Companies::CarrierSurchargesViewV2.new(current_company: current_company, carrier: @carrier)

    if @carrier.can_edit_surcharges?
      render
    else
      render :index_referenced
    end
  end

  def bulk_update
    @carrier.bulk_update_surcharges(bulk_update_params[:surcharges], current_user: current_user)

    redirect_to companies_carrier_surcharges_path(@carrier), notice: "Changes were saved"
  end

  def bulk_update_v2
    SurchargeOnCarrierBulkUpdate
      .new(carrier: @carrier, surcharges_attributes: bulk_update_v2_params[:surcharges], current_user: current_user)
      .perform!

    redirect_to(
      params[:redirect_url].presence || companies_carrier_surcharges_path(@carrier),
      notice: "Changes were saved"
    )
  end

  def new
    @surcharge = Surcharge.new
  end

  def create
    @surcharge = Surcharge.new(surcharge_params)

    @surcharge.transaction do
      if @surcharge.save
        surcharge_for_carrier = SurchargeOnCarrier.new(carrier: @carrier)
        surcharge_for_carrier.created_by = current_user
        surcharge_for_carrier.surcharge = @surcharge
        surcharge_for_carrier.save!
      end
    end

    if @surcharge.errors.empty?
      redirect_to companies_carrier_surcharges_path(@carrier), notice: "Surcharge has been added"
    else
      render :new
    end
  end

  private

  def set_carrier
    @carrier = ::Carrier.find_enabled_company_carriers(company_id: current_company.id).find(params[:carrier_id])
  end

  def bulk_update_params
    params.fetch(:bulk_update, {}).permit(
      :surcharges => [
        :id,
        :predefined_type,
        :enabled,
        :description,
        :charge_value,
        :calculation_method,
      ]
    )
  end

  def bulk_update_v2_params
    params.fetch(:bulk_update, {}).permit(
      :surcharges => [
        :id,
        :predefined_type,
        :enabled,
        :description,
        :charge_value,
        :calculation_method,
        :monthly => [
          :valid_from,
          :expires_on,
          :charge_value,
        ]
      ]
    )
  end

  def surcharge_params
    params.fetch(:surcharge, {}).permit(
      :description,
      :charge_value,
      :calculation_method,
    )
  end

  def set_current_nav
    @current_nav = "carrier_surcharges"
  end
end
