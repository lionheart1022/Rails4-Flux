class Companies::Shipments::DestroyAsset < ApplicationInteractor

  def initialize(company_id: nil, shipment_id: nil, asset_id: nil)
    @company_id  = company_id
    @shipment_id = shipment_id
    @asset_id    = asset_id
    return self
  end

  def run

    shipment = Shipment.find(@shipment_id)
    raise PermissionError.new('You do not have permission for this action') if shipment.product_responsible.id != @company_id

    asset = Asset.find_shipment_asset(shipment_id: @shipment_id, asset_id: @asset_id)
    asset.destroy! if asset.present?

    return InteractorResult.new(asset: asset)
  rescue => e
    Rails.logger.error "DestroyAsset#Error #{e.inspect}"
    return InteractorResult.new(error: e)
  end

end
