class Companies::CompanyLogosController < CompaniesController
  def callback
    current_company.create_or_update_logo_asset(
      filepath: params[:filepath],
      filename: params[:filename],
      filetype: params[:filetype],
    )

    respond_to do |format|
      format.js
    end
  end

  def destroy
    current_company.update!(asset_logo: nil)
  end
end
