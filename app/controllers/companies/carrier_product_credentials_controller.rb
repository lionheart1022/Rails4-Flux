class Companies::CarrierProductCredentialsController < CompaniesController
  before_action :set_carrier_product

  def show
    render_edit_page
  end

  def edit
    render_edit_page
  end

  def update
    credentials = (params[:product] ? params[:product].to_unsafe_hash : {}).symbolize_keys

    begin
      @carrier_product.set_credentials(credentials: credentials)
    rescue ActiveRecord::RecordInvalid, StandardError => e
      flash.now[:error] = e.message

      view_model = Companies::CarrierProducts::EditCredentialsView.new(
        carrier: @carrier_product.carrier,
        product: @carrier_product,
        credentials: credentials,
      )

      render_edit_page(view_model: view_model)
    else
      flash[:success] = "Updated credentials of product: #{@carrier_product.name}"
      redirect_to companies_carrier_path(@carrier_product.carrier)
    end
  end

  private

  def set_carrier_product
    @carrier_product = CarrierProduct.where(company: current_company).find(params[:carrier_product_id])

    raise "Carrier product is locked for editing" if @carrier_product.is_locked_for_configuring?
  end

  def render_edit_page(view_model: nil)
    @view_model = view_model || begin
      Companies::CarrierProducts::EditCredentialsView.new(
        carrier: @carrier_product.carrier,
        product: @carrier_product,
        credentials: @carrier_product.get_credentials,
      )
    end

    if @view_model.live_fields.nil?
      raise "Could not detect fields of carrier product credentials. Most likely this is caused by the carrier type `#{@carrier_product.carrier.type}` being unhandled."
    end

    render :edit
  end

  def set_current_nav
    @current_nav = "carriers"
  end
end
