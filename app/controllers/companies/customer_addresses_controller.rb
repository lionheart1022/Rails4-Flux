class Companies::CustomerAddressesController < CompaniesController
  def show
    @customer = current_company.customers.find(params[:customer_id])
    @customer_address = @customer.address || Contact.new
  end

  def edit
    @customer = current_company.customers.find(params[:customer_id])
    @form_model = Companies::CustomerAddressEditForm.new(customer_record: @customer)
  end

  def update
    @customer = current_company.customers.find(params[:customer_id])
    @form_model = Companies::CustomerAddressEditForm.new(customer_record: @customer)
    @form_model.assign_attributes(address_params)

    if @form_model.save
      redirect_to url_for(action: "show")
    else
      render :edit
    end
  end

  private

  def address_params
    params.require(:customer).permit(
      :name,
      :email,
      :external_accounting_number,
      :attention,
      :address_line1,
      :address_line2,
      :address_line3,
      :zip_code,
      :city,
      :country_code,
      :state_code,
      :phone_number,
      :cvr_number,
      :note,
    )
  end

  def set_current_nav
    @current_nav = "customers"
  end
end
