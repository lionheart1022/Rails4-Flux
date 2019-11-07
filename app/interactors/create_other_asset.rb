class CreateOtherAsset
  attr_reader :context
  attr_reader :shipment
  attr_reader :asset
  attr_accessor :asset_attributes
  attr_reader :result

  def initialize(params = {})
    @context = params.delete(:context)
    @shipment = params.delete(:shipment)
  end

  def perform!
    unless context.allow_creating_other_asset?(shipment)
      return PermissionErrorResult.new("You do not have permission for this action")
    end

    @asset = nil

    Asset.transaction do
      filepath = asset_attributes.delete(:filepath)
      filename = asset_attributes.delete(:filename)
      filetype = asset_attributes.delete(:filetype)

      @asset = AssetOther.new(asset_attributes)

      asset.assetable = shipment
      asset.creator = context.other_asset_creator
      asset.save!

      shipment.s3_copy_file_between_buckets(asset: asset, filepath: filepath, filename: filename)

      shipment.events.create!({
        company_id: shipment.company_id,
        customer_id: shipment.customer_id,
        event_type: Shipment::Events::ASSET_OTHER_UPLOADED,
        description: asset.attachment_file_name,
      })
    end

    SuccessResult.new(asset)
  end

  class SuccessResult
    def initialize(asset)
      @asset = asset
    end

    def message
      nil
    end

    def asset
      @asset
    end

    def success?
      true
    end
  end

  class PermissionErrorResult
    def initialize(message)
      @message = message
    end

    def message
      @message
    end

    def asset
      nil
    end

    def success?
      false
    end
  end

  private_constant :SuccessResult, :PermissionErrorResult
end
