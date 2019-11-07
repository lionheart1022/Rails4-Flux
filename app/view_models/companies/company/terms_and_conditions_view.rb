class Companies::Company::TermsAndConditionsView
  attr_reader :main_view, :company, :company_assets, :s3_company_callback_url, :can_manage_files

  def initialize(company: nil, company_assets: nil, s3_company_callback_url: nil, can_manage_files: nil)
    @company                 = company
    @company_assets          = company_assets
    @s3_company_callback_url = s3_company_callback_url
    @can_manage_files        = can_manage_files
    state_general
  end

  private

  def state_general
    @main_view = "companies/company/terms_and_conditions"
  end
end
