class Companies::CompanyAddressesController < CompaniesController
  def update
    address = current_company.address_for_edit
    address.assign_attributes(params.fetch(:company_info).permit(:phone_number, :email))
    current_company.address = address

    redirect_to companies_setting_path
  end
end
