class Companies::EndOfDayManifestsController < CompaniesController
  def index
    @end_of_day_manifests = current_company.eod_manifests.order(:owner_scoped_id => :desc).page(params[:page])
  end

  def new
    @view_model = NewEODManifestViewModel.new(current_company: current_company, shipment_filter_params: shipment_filter_params)
  end

  def create
    end_of_day_manifest = current_company.create_eod_manifest!(eod_manifest_params) do |manifest|
      manifest.created_by = current_user
    end

    redirect_to action: "show", id: end_of_day_manifest.id
  end

  def show
    @end_of_day_manifest = current_company.eod_manifests.find(params[:id])
    @shipments =
      @end_of_day_manifest.shipments
      .includes(:carrier_product, :recipient)
      .order(shipping_date: :asc)
      .page(params[:page])
      .per(100)
  end

  def print
    @end_of_day_manifest = current_company.eod_manifests.find(params[:id])
    @shipments =
      @end_of_day_manifest.shipments
      .includes(:carrier_product, :recipient)
      .order(shipping_date: :asc)

    render layout: "print"
  end

  private

  def shipment_filter_params
    all_params = {
      carrier_id: params[:filter_carrier_id],
      manifest_inclusion: params[:filter_not_in_manifest],
      shipment_state: params[:filter_has_been_booked_or_in_state],
    }

    all_params.reject { |_, value| value.nil? }
  end

  def eod_manifest_params
    manifest_shipment_ids = Array(params[:manifest].try(:[], :shipment_ids))

    whitelisted_shipment_ids =
      Shipment
      .find_company_shipments(company_id: current_company.id)
      .where(id: Array(manifest_shipment_ids).reject(&:blank?))
      .pluck(:id)

    { bulk_insert_shipment_ids: whitelisted_shipment_ids }
  end

  def set_current_nav
    @current_nav = "eod_manifests"
  end

  class NewEODManifestViewModel
    attr_reader :current_company
    attr_reader :shipment_filter_form

    def initialize(current_company:, shipment_filter_params:)
      @current_company = current_company
      @shipment_filter_form = NewEODManifestShipmentFilterForm.new(shipment_filter_params)
    end

    def shipments
      @shipments ||= begin
        filter = shipment_filter
        filter.perform!

        filter
          .shipments
          .includes(:carrier_product, :customer, :recipient, :asset_awb)
          .order(shipping_date: :desc, id: :desc)
      end
    end

    def shipment_filter
      filter = ShipmentFilter.new(
        current_company: current_company,
        base_relation: Shipment.find_company_shipments(company_id: current_company.id),
      )

      filter.carrier_id = shipment_filter_form.carrier_id
      filter.state = shipment_filter_form.shipment_state
      filter.manifest_inclusion = shipment_filter_form.manifest_inclusion

      filter
    end
  end

  class NewEODManifestShipmentFilterForm
    include ActiveModel::Model

    attr_accessor :carrier_id
    attr_accessor :manifest_inclusion
    attr_accessor :shipment_state

    def initialize(params = {})
      self.manifest_inclusion = "not_in_manifest"
      self.shipment_state = CargofluxConstants::Filter::NOT_CANCELED

      super(params)
    end

    def manifest_inclusion_options
      [
        ["Shipments not in a manifest", "not_in_manifest"],
        ["All shipments", nil],
      ]
    end

    def state_options
      [
        ["Shipments booked and not cancelled", CargofluxConstants::Filter::NOT_CANCELED],
        ["Created", Shipment::States::CREATED],
        ["Booked", Shipment::States::BOOKED],
        ["In transit", Shipment::States::IN_TRANSIT],
        ["Problem", Shipment::States::PROBLEM],
        ["All states", nil],
      ]
    end
  end
end
