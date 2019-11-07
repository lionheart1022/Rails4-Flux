class Customers::AddressesController < CustomersController
  before_action :set_address

  def show
    render_edit_page
  end

  def edit
    render_edit_page
  end

  def update
    @address.set_country_name_from_code = true
    @address.assign_attributes(address_params)

    if @address.save
      redirect_to url_for(action: "show"), notice: "Successfully updated address"
    else
      render_edit_page
    end
  end

  private

  def set_current_nav
    @current_nav = "company_address"
  end

  def set_address
    @address = Customer.find_address(company_id: current_company.id, customer_id: current_customer.id) || Contact.new
  end

  def address_params
    params.fetch(:contact, {}).permit(
      :company_name,
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
      :email,
    )
  end

  def render_edit_page
    render :edit
  end
end
