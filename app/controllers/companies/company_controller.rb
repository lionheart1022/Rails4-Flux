class Companies::CompanyController < CompaniesController
  def terms_and_conditions
    company = current_company
    company_assets = Asset.find_company_terms_and_condition_assets(company_id: company.id)

    @view_model = Companies::Company::TermsAndConditionsView.new(
      company:                 current_company,
      company_assets:          current_company.asset_company,
      s3_company_callback_url: companies_terms_and_conditions_s3_company_callback_path,
      can_manage_files:        true
    )
  end

  def s3_company_callback
    interactor = Companies::Company::CreateAssetCompanyFromS3.new(
      company_id:  current_company.id,
      description: params[:file_description],
      filepath:    params[:filepath],
      filename:    params[:filename],
      filetype:    params[:filetype]
    )

    result = interactor.run

    if result.try(:error)
      error = result.error.message
      Rails.logger.error error

      render json: {
         error: error
      }, status: 500
    else
      asset      = result.asset

      render json: {
        asset: asset,
        filepath: params[:url],
        # delete_url: delete_url
      }, status: 200
    end
  end

  def delete_terms_and_condition
    company = current_company
    asset_id = params[:id]

    asset = Asset.find_company_terms_and_condition_asset(company_id: company.id, asset_id: asset_id)
    Rails.logger.debug asset
    asset.destroy!

    redirect_to companies_terms_and_conditions_path
  end

  private

  def set_current_nav
    @current_nav =
      case params[:action]
      when "settings"
        "company_settings"
      when "terms_and_conditions"
        "terms_and_conditions"
      end
  end
end
