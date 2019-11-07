class ShipmentFilter
  include ActiveModel::Model

  DATE_FORMAT = "%Y-%m-%d".freeze

  attr_internal_accessor :current_company
  attr_internal_accessor :current_customer
  attr_internal_accessor :base_relation

  # Fields

  # These fields consider shipments.created_at
  attr_accessor :start_date, :end_date

  # These fields consider shipments.shipping_date
  attr_accessor :shipping_start_date, :shipping_end_date

  attr_accessor :state
  attr_accessor :carrier_id
  attr_accessor :customer_id
  attr_accessor :report_inclusion
  attr_accessor :manifest_inclusion
  attr_accessor :deprecated_manifest_inclusion
  attr_accessor :pricing_status
  attr_accessor :customer_type
  attr_accessor :buyer_company_id

  # Sorting
  attr_accessor :sorting

  # Pagination
  attr_accessor :pagination, :page
  alias_method :pagination?, :pagination

  # Result
  attr_reader :shipments

  def initialize(attrs = {})
    unless self.current_company = attrs.delete(:current_company)
      raise ArgumentError, "Missing required `current_company` attribute"
    end

    self.current_customer = attrs.delete(:current_customer)

    unless self.base_relation = attrs.delete(:base_relation)
      raise ArgumentError, "Missing required `base_relation` attribute"
    end

    @shipments = Shipment.none

    assign_attributes(attrs)
  end

  def assign_attributes(attrs)
    attrs.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def perform!
    @shipments = find_shipments
  end

  private

  def find_shipments
    apply_pagination(
      apply_sort(
        apply_filters(
          base_relation
        )
      )
    )
  end

  def apply_start_date_filter(relation)
    if date = parsed_start_date
      relation.find_shipments_after_date(date: date)
    else
      relation
    end
  end

  def apply_end_date_filter(relation)
    if date = parsed_end_date
      relation.find_shipments_before_date(date: date)
    else
      relation
    end
  end

  def apply_shipping_start_date_filter(relation)
    if (date = parsed_shipping_start_date)
      relation.shipped_after(date)
    else
      relation
    end
  end

  def apply_shipping_end_date_filter(relation)
    if (date = parsed_shipping_end_date)
      relation.shipped_before(date)
    else
      relation
    end
  end

  def apply_state_filter(relation)
    if state == CargofluxConstants::Filter::NOT_CANCELED
      accepted_events = [
        Shipment::Events::BOOK,
        Shipment::Events::SHIP,
        Shipment::Events::DELIVERED_AT_DESTINATION,
      ]

      shipments_having_been_booked = Shipment.joins(:events).where(events: { event_type: accepted_events })
      relation.find_shipments_not_in_states([Shipment::States::CANCELLED]).where(id: shipments_having_been_booked.select(:id))
    elsif state.present?
      relation.find_shipments_in_state(state: state)
    else
      relation
    end
  end

  def apply_carrier_filter(relation)
    if carrier_id.present?
      relation.find_shipments_with_carrier(carrier_id: carrier_id)
    else
      relation
    end
  end

  def apply_customer_id_filter(relation)
    if customer_id.present?
      relation.find_customer_shipments(customer_id: customer_id)
    else
      relation
    end
  end

  def apply_report_inclusion_filter(relation)
    if report_inclusion == "not_in_report"
      shipments_included_in_reports = Shipment.joins(:reports).where(reports: { company_id: current_company.id })
      relation.where.not(id: shipments_included_in_reports.select(:id))
    else
      relation
    end
  end

  def apply_manifest_inclusion_filter(relation)
    if manifest_inclusion == "not_in_manifest"
      shipments_included_in_manifests = Shipment.joins(:eod_manifests).where(eod_manifests: { owner: current_company })
      relation.where.not(id: shipments_included_in_manifests.select(:id))
    else
      relation.all
    end
  end

  def apply_deprecated_manifest_inclusion_filter(relation)
    if deprecated_manifest_inclusion == "not_in_manifest"
      shipments_included_in_manifests = Shipment.joins(:end_of_day_manifests).where(end_of_day_manifests: { customer: current_customer })
      relation.where.not(id: shipments_included_in_manifests.select(:id))
    else
      relation.all
    end
  end

  def apply_pricing_status_filter(relation)
    case pricing_status
    when "priced"
      relation.where(id: priced_shipments_relation.select(:id))
    when "unpriced"
      relation.where.not(id: priced_shipments_relation.select(:id))
    else
      relation.all
    end
  end

  def apply_customer_type_filter(relation)
    if customer_type.present?
      relation.find_shipments_with_customer_type(company_id: current_company.id, customer_type: customer_type)
    else
      relation
    end
  end

  def apply_buyer_company_filter(relation)
    if buyer_company_id.present?
      relation.find_shipments_sold_to_company(company_id: current_company.id, customer_company_id: buyer_company_id)
    else
      relation
    end
  end

  def apply_filters(relation)
    relation = apply_start_date_filter(relation)
    relation = apply_end_date_filter(relation)
    relation = apply_shipping_start_date_filter(relation)
    relation = apply_shipping_end_date_filter(relation)
    relation = apply_state_filter(relation)
    relation = apply_carrier_filter(relation)
    relation = apply_customer_id_filter(relation)
    relation = apply_report_inclusion_filter(relation)
    relation = apply_manifest_inclusion_filter(relation)
    relation = apply_deprecated_manifest_inclusion_filter(relation)
    relation = apply_pricing_status_filter(relation)
    relation = apply_customer_type_filter(relation)
    relation = apply_buyer_company_filter(relation)
    relation
  end

  def apply_sort(relation)
    case sorting
    when CargofluxConstants::Sort::DATE_ASC
      relation.order(shipping_date: :asc, id: :asc)
    when CargofluxConstants::Sort::DATE_DESC
      relation.order(shipping_date: :desc, id: :desc)
    else
      relation
    end
  end

  def apply_pagination(relation)
    if pagination?
      relation.page(page)
    else
      relation
    end
  end

  def parsed_start_date
    if date = parse_date(start_date)
      date.beginning_of_day
    end
  end

  def parsed_end_date
    if date = parse_date(end_date)
      date.end_of_day
    end
  end

  def parsed_shipping_start_date
    parse_date(shipping_start_date)
  end

  def parsed_shipping_end_date
    parse_date(shipping_end_date)
  end

  def parse_date(value)
    if value.is_a?(String)
      begin
        Date.strptime(value, DATE_FORMAT)
      rescue ArgumentError
        nil
      end
    elsif value.respond_to?(:to_date)
      value
    end
  end

  def priced_shipments_relation
    Shipment
      .joins(:advanced_prices => :advanced_price_line_items)
      .where(advanced_prices: { seller: current_company })
      .where.not(advanced_price_line_items: { cost_price_amount: nil })
      .where.not(advanced_price_line_items: { sales_price_amount: nil })
  end
end
