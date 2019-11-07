module OtherAssetsControllerMethods
  extend ActiveSupport::Concern

  included do
    before_action :set_shipment
  end

  def callback
    result = current_context.create_other_asset(@shipment, asset_attributes: asset_params)
    @asset = result.asset

    if result.success?
      respond_to do |format|
        format.json { render json: { partial_html: render_to_string(partial: "admin/attachments/other_asset", formats: [:html], locals: { asset: @asset, view_model: shipment_view_model }) } }
      end
    else
      respond_to do |format|
        format.json { render json: { error: true, message: result.message }, status: :bad_request }
      end
    end
  end

  private

  def set_shipment
    @shipment = current_context.find_shipment(params[:id])

    if @shipment.nil?
      render nothing: true, status: :not_found
    end
  end

  def asset_params
    {
      filepath: params[:filepath],
      filename: params[:filename],
      filetype: params[:filetype],
      description: params[:file_description],
      private: params[:file_is_private],
    }
  end

  # TODO: I don't quite like what we do here but we need `Shared::ShipmentView` to render the "other_asset" partial.
  # We could also use a new (mock) class for this purpose but I would rather handle this in a different way.
  # But for now it's sufficient.
  def shipment_view_model
    if current_context.is_customer?
      Shared::ShipmentView.new(
        shipment: @shipment,
        allow_inline_consignment_note_upload: false,
        allow_additional_files_upload: true,
      )
    else
      Shared::ShipmentView.new(
        shipment: @shipment,
        allow_inline_consignment_note_upload: true,
        allow_additional_files_upload: true,
      )
    end
  end
end
