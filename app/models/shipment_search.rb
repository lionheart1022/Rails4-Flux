class ShipmentSearch
  include ActiveModel::Model

  attr_accessor :current_company, :current_customer
  attr_accessor :query
  attr_accessor :pagination, :page
  attr_accessor :mode
  attr_reader :shipments

  alias pagination? pagination

  validates! :current_company, presence: true

  def initialize(params = {})
    @shipments = Shipment.none

    super
  end

  def perform_search!
    @shipments =
      if pagination?
        find_shipments.page(page)
      else
        find_shipments
      end
  end

  def shipment
    shipments.first
  end

  def matches_no_shipments?
    query_specified? && shipments.count == 0
  end

  def matches_multiple_shipments?
    query_specified? && shipments.count > 1
  end

  def matches_single_shipment?
    query_specified? && shipments.count == 1
  end

  def query_specified?
    stripped_query.present?
  end

  def query_not_specified?
    !query_specified?
  end

  private

  def find_shipments
    validate

    if mode == "match_id"
      find_shipments_matching_id
    else
      find_shipments_matching_all
    end
  end

  def find_shipments_matching_all
    if query_not_specified?
      Shipment.none
    elsif current_customer.present?
      Shipment.find_customer_shipments_with_awb_or_unique_shipment_id(
        company_id: current_company.id,
        customer_id: current_customer.id,
        query: stripped_query,
      )
    else
      Shipment.find_company_shipments_with_awb_or_unique_shipment_id(
        company_id: current_company.id,
        query: stripped_query,
      )
    end
  end

  def find_shipments_matching_id
    if query_not_specified?
      Shipment.none
    elsif current_customer.present?
      Shipment
        .where(company_id: current_company.id, customer_id: current_customer.id, unique_shipment_id: stripped_query)
        .where.not(state: Shipment::States::REQUEST)
        .limit(1)
    else
      Shipment
        .find_company_shipments(company_id: current_company.id).where(unique_shipment_id: stripped_query)
        .limit(1)
    end
  end

  def stripped_query
    query ? query.gsub(/[#\s]/, "") : nil
  end
end
