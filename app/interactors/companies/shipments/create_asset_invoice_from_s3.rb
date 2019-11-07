class Companies::Shipments::CreateAssetInvoiceFromS3 < ApplicationInteractor

  def initialize(company_id: nil, shipment_id: nil, filepath: nil, filename: nil, filetype: nil)
    @company_id = company_id
    @shipment_id = shipment_id
    @filepath = filepath
    @filename = filename
    @filetype = filetype
    return self
  end

  def run
    check_permissions

    Asset.transaction do
      shipment = Shipment.find_company_shipment(company_id: @company_id, shipment_id: @shipment_id)

      raise PermissionError, "Could not find your shipment" if shipment.nil?

      @asset = shipment.create_or_update_invoice_asset(filepath: @filepath, filename: @filename, filetype: @filetype)
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
