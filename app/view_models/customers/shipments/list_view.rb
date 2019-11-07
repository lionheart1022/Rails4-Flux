class Customers::Shipments::ListView
  include ActiveModel::Model

  DATE_FORMAT = "%Y-%m-%d".freeze

  attr_internal_accessor :base_relation

  attr_accessor :start_date, :end_date
  attr_accessor :shipping_start_date, :shipping_end_date
  attr_accessor :grouping
  attr_accessor :sorting
  attr_accessor :state, :filterable_states
  attr_accessor :carrier_id
  attr_accessor :pagination, :page
  attr_reader :shipments

  alias pagination? pagination
  alias ungrouped_shipments shipments

  def initialize(attrs = {})
    self.base_relation = attrs.delete(:base_relation)

    if base_relation.nil?
      raise ArgumentError, "Missing required `base_relation` attribute"
    end

    # Defaults
    @shipments = Shipment.none
    self.filterable_states = []
    self.grouping = nil # Sets default constant
    self.sorting = nil # Sets default constant

    assign_attributes(attrs)
  end

  def assign_attributes(attrs)
    attrs.each do |key, value|
      self.public_send("#{key}=", value)
    end
  end

  def perform_search!
    @shipments = find_shipments
  end

  def grouped_shipments
    if is_grouped?
      apply_group(shipments)
    else
      raise "Grouping type doesn't allow grouping (#{grouping.inspect})"
    end
  end

  def grouping=(value)
    @grouping = value.presence || CargofluxConstants::Group::NONE
  end

  def sorting=(value)
    @sorting = value.presence || CargofluxConstants::Sort::DATE_DESC
  end

  def is_grouped?
    !is_ungrouped?
  end

  def is_ungrouped?
    grouping == CargofluxConstants::Group::NONE
  end

  def state_blank_option
    "All states"
  end

  def state_options
    filterable_states.map { |state| [ViewHelper::Shipments.state_name(state), state] }
  end

  def carrier_id_blank_option
    "All carriers"
  end

  def grouping_options
    [
      ["No grouping", CargofluxConstants::Group::NONE],
      ["Grouped by state", CargofluxConstants::Group::STATE]
    ]
  end

  def sorting_options
    [
      ["Newest first", CargofluxConstants::Sort::DATE_DESC],
      ["Oldest first", CargofluxConstants::Sort::DATE_ASC],
    ]
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
    if state.present?
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

  def apply_filters(relation)
    relation = apply_state_filter(relation)
    relation = apply_start_date_filter(relation)
    relation = apply_end_date_filter(relation)
    relation = apply_shipping_start_date_filter(relation)
    relation = apply_shipping_end_date_filter(relation)
    relation = apply_carrier_filter(relation)
    relation
  end

  def apply_sort(relation)
    case sorting
    when CargofluxConstants::Sort::DATE_ASC
      relation.order("shipments.shipping_date ASC, shipments.id ASC")
    when CargofluxConstants::Sort::DATE_DESC
      relation.order("shipments.shipping_date DESC, shipments.id DESC")
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

  def apply_group(relation)
    case grouping
    when CargofluxConstants::Group::STATE
      apply_group_by_state(relation)
    end
  end

  def apply_group_by_state(relation)
    grouped = relation.group_by(&:state)
    grouped.each_pair.map do |key, val|
      GroupSortFilter::DataGroup.new(name: ViewHelper::Shipments.state_name(key), data: val)
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
end
