class Companies::UnbilledShipmentsController < CompaniesController
  def index
    filter_form = FilterForm.new(filter_params)
    filter_form.current_company = current_company

    @view_model = ListViewModel.new(filter_form: filter_form)
  end

  private

  def filter_params
    {
      start_date: params[:filter_range_start],
      end_date: params[:filter_range_end],
      page: params[:page],
    }
  end

  def set_current_nav
    @current_nav = "company_unbilled_shipments"
  end

  class ListViewModel
    attr_accessor :filter_form

    def initialize(filter_form:)
      self.filter_form = filter_form
    end

    def shipments
      filter_form.shipments
    end
  end

  class FilterForm
    include ActiveModel::Model

    attr_accessor :current_company
    attr_accessor :start_date, :end_date
    attr_accessor :page

    def shipments
      shipment_filter_params = {
        current_company: current_company,
        base_relation: filter_base_relation,
        start_date: start_date,
        end_date: end_date,
        pricing_status: "unpriced",
        pagination: true,
        page: page,
        sorting: CargofluxConstants::Sort::DATE_DESC,
      }

      shipment_filter = ShipmentFilter.new(shipment_filter_params)
      shipment_filter.perform!

      @shipments ||= shipment_filter.shipments
    end

    private

    def filter_base_relation
      Shipment
        .includes(:customer, :sender, :recipient, :carrier_product, :asset_awb, :company)
        .find_company_shipments(company_id: current_company.id)
        .where(state: [Shipment::States::BOOKED, Shipment::States::IN_TRANSIT, Shipment::States::DELIVERED_AT_DESTINATION, Shipment::States::PROBLEM])
    end
  end
end
