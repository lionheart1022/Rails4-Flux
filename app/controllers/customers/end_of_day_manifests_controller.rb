class Customers::EndOfDayManifestsController < CustomersController
  def index
    @end_of_day_manifests = current_customer.end_of_day_manifests.order(created_at: :desc).page(params[:page])
  end

  def new
    @end_of_day_manifest = EndOfDayManifest.new(customer: current_customer)
    @end_of_day_manifest.shipment_filter_form = EndOfDayManifest::ShipmentFilterForm.new(shipment_filter_params)
  end

  def create
    end_of_day_manifest = current_customer.create_end_of_day_manifest!(eod_manifest_params)

    redirect_to action: "show", id: end_of_day_manifest.id
  end

  def show
    @end_of_day_manifest = current_customer.end_of_day_manifests.find(params[:id])
    @shipments = @end_of_day_manifest.shipments.includes(:carrier_product, :recipient).order(shipping_date: :asc).page(params[:page]).per(100)
  end

  def print
    @end_of_day_manifest = current_customer.end_of_day_manifests.find(params[:id])
    @shipments = @end_of_day_manifest.shipments.includes(:carrier_product, :recipient).order(shipping_date: :asc)

    render layout: "print"
  end

  private

  def set_current_nav
    @current_nav = "eod_manifests"
  end

  def shipment_filter_params
    all_params = {
      carrier_id: params[:filter_carrier_id],
      manifest_inclusion: params[:filter_not_in_manifest],
      shipment_state: params[:filter_has_been_booked_or_in_state],
    }

    all_params.reject { |_, value| value.nil? }
  end

  def eod_manifest_params
    params.fetch(:manifest, {}).permit(:raw_shipment_ids => [])
  end
end
