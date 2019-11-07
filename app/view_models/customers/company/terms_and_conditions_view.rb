class Customers::Company::TermsAndConditionsView
  attr_reader :main_view, :company, :company_assets

  def initialize(company: nil, company_assets: nil)
    @company                 = company
    @company_assets          = company_assets
    state_general
  end

  private

  def state_general
    @main_view = "customers/company/terms_and_conditions"
  end
end
