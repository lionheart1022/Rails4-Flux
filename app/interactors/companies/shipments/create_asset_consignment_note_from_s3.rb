class Companies::Shipments::CreateAssetConsignmentNoteFromS3 < ApplicationInteractor

  def initialize(company_id: nil, shipment_id: nil, filepath: nil, filename: nil, filetype: nil)
    @company_id   = company_id
    @shipment_id  = shipment_id
    @filepath     = filepath
    @filename     = filename
    @filetype     = filetype
    return self
  end

  def run
    check_permissions

    Asset.transaction do
      shipment = Shipment.find(@shipment_id)
      raise PermissionError.new('You do not have permission for this action') if shipment.product_responsible.id != @company_id

      @asset = shipment.create_or_update_consignment_note_asset(filepath: @filepath, filename: @filename, filetype: @filetype)
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
