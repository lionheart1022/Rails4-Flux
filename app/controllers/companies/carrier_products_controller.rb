class Companies::CarrierProductsController < CompaniesController
  before_action :set_carrier, only: [:new, :create]
  before_action :set_carrier_product, only: [:edit, :update]

  def new
    form = CarrierProductForm.new_product_for_carrier(@carrier)

    @view_model = Companies::CarrierProductNewView.new
    @view_model.form_object = form
    @view_model.carrier = @carrier
  end

  def create
    form = CarrierProductForm.new_product_for_carrier(@carrier)
    form.assign_params(carrier_product_params)

    interactor = ::Companies::CreateCarrierProduct.new(form: form, carrier: @carrier, current_company: current_company)
    interactor.perform!

    if interactor.success?
      flash[:success] = "Successfully created carrier product"
      redirect_to companies_carrier_path(@carrier)
    else
      @view_model = Companies::CarrierProductNewView.new
      @view_model.form_object = form
      @view_model.carrier = @carrier

      render :new
    end
  end

  def edit
    form = CarrierProductForm.edit_product(@carrier_product)

    @view_model = Companies::CarrierProductEditView.new
    @view_model.form_object = form
    @view_model.carrier_product = @carrier_product
  end

  def update
    form = CarrierProductForm.edit_product(@carrier_product)
    form.assign_params(carrier_product_params)

    interactor = ::Companies::UpdateCarrierProduct.new(form: form, carrier_product: @carrier_product, current_company: current_company)
    interactor.perform!

    if interactor.success?
      flash[:success] = "Successfully updated carrier product"
      redirect_to companies_carrier_path(@carrier_product.carrier)
    else
      @view_model = Companies::CarrierProductEditView.new
      @view_model.form_object = form
      @view_model.carrier_product = @carrier_product

      render :edit
    end
  end

  def disable
    carrier_product = CarrierProduct.where(company: current_company).find(params[:id])

    raise "Carrier product is locked for editing" if carrier_product.is_locked_for_editing?

    carrier_product.update!(is_disabled: true)

    flash[:success] = "Disabled product: #{carrier_product.name}"
    redirect_to companies_carrier_path(carrier_product.carrier)
  end

  private

  def carrier_product_params
    params.fetch(:carrier_product, {}).permit(
      :name,
      :track_trace_method,
      :transit_time,
      :basis,
      :volume_weight_type,
      :custom_volume_weight_enabled,
      :volume_weight_factor,
      :custom_label,
      :custom_label_variant,
      :truck_driver,
      :import,
    )
  end

  def set_carrier
    @carrier = Carrier.find_company_carrier(company_id: current_company.id, carrier_id: params[:carrier_id])
  end

  def set_carrier_product
    @carrier_product = CarrierProduct.find_company_carrier_product(company_id: current_company.id, carrier_product_id: params[:id])
  end

  def set_current_nav
    @current_nav = "carriers"
  end
end
