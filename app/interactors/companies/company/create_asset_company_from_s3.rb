class Companies::Company::CreateAssetCompanyFromS3 < ApplicationInteractor

  def initialize(company_id: nil, filepath: nil, filename: nil, filetype: nil, description: nil)
    @company_id = company_id
    @filepath   = filepath
    @filename   = filename
    @filetype   = filetype
    @description       = description
    return self
  end

  def run
    check_permissions

    Asset.transaction do
      company = Company.find(@company_id)
      @asset = company.create_asset_company(filepath: @filepath, filename: @filename, filetype: @filetype, description: @description)
    end

    return InteractorResult.new(
      asset: @asset
    )
  rescue PermissionError => e
    raise e
  rescue => e
    return InteractorResult.new(error: e)
  end

  private

  def check_permissions
    #raise PermissionError.new "You don't have access (TODO)"
  end

end
