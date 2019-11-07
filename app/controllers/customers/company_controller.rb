class Customers::CompanyController < CustomersController

  def terms_and_conditions
    company = current_company

    company = current_company
    company_assets = Asset.find_company_terms_and_condition_assets(company_id: company.id)

    @view_model = Customers::Company::TermsAndConditionsView.new(
      company:                 current_company,
      company_assets:          current_company.asset_company
    )
  end

  private

  def set_current_nav
    @current_nav = "terms_and_conditions"
  end

end
