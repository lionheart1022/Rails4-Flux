module AttachmentDestroyAction
  extend ActiveSupport::Concern

  def destroy
    @asset = current_context.destroy_asset(shipment_id: params[:shipment_id], asset_id: params[:id])

    respond_to do |format|
      format.js do
        if @asset
          render "admin/attachments/destroy"
        else
          render nothing: true, status: :bad_request
        end
      end
    end
  end
end
