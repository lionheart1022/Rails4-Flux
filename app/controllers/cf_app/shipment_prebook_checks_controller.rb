module CFApp
  class ShipmentPrebookChecksController < BaseAppController
    def create
      @prebook_check = ShipmentPrebook.check!(params: params, current_context: current_context)

      case @prebook_check
      when ShipmentPrebook::SurchargeWarningResult
        render :surcharge_warning
      when ShipmentPrebook::OKResult
        render :ok
      when ShipmentPrebook::ErrorResult
        render json: {}, status: :internal_server_error
      end
    end
  end
end
