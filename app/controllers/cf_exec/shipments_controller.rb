module CFExec
  class ShipmentsController < ExecController
    def index
      filter_object = Filter.new(params.fetch(:filter, {}).permit(:status, :company_id))
      filter_object.page = params[:page]

      @view_model = OpenStruct.new
      @view_model.shipments = filter_object.shipments
      @view_model.filter_object = filter_object

      respond_to do |format|
        format.html
      end
    end

    private

    def active_nav
      case params[:action]
      when "index"
        [:shipments, :index]
      end
    end

    class Filter
      include ActiveModel::Model

      CURRENT_EXCLUDE_STATES = [Shipment::States::DELIVERED_AT_DESTINATION, Shipment::States::CANCELLED, Shipment::States::REQUEST]
      ARCHIVED_INCLUDE_STATES = [Shipment::States::DELIVERED_AT_DESTINATION, Shipment::States::CANCELLED]

      attr_accessor :status
      attr_accessor :company_id
      attr_accessor :page

      def initialize(params = {})
        self.status = "current"

        super(params)
      end

      def shipments
        @shipments ||= filter_shipments
      end

      private

      def filter_shipments
        relation =
          Shipment
          .all
          .order(shipping_date: :desc, id: :desc)
          .includes(:customer, :sender, :recipient, :carrier_product, :asset_awb, :company)
          .page(page)

        relation =
          if status == "current"
            relation.find_shipments_not_in_states(CURRENT_EXCLUDE_STATES)
          elsif status == "archived"
            relation.find_shipments_in_states(ARCHIVED_INCLUDE_STATES)
          else
            relation.none
          end

        relation =
          if company_id.present?
            relation.where(company_id: company_id)
          else
            relation.all
          end

        relation
      end
    end
  end
end
