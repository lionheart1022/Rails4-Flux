class Companies::Shipments::ListView
  include ActiveModel::Model

  DATE_FORMAT = "%Y-%m-%d".freeze

  attr_internal_accessor :current_company
  attr_internal_accessor :base_relation

  attr_accessor :customer_id
  attr_accessor :start_date, :end_date
  attr_accessor :shipping_start_date, :shipping_end_date
  attr_accessor :grouping
  attr_accessor :sorting
  attr_accessor :customer_type
  attr_accessor :state, :filterable_states
  attr_accessor :related_company_id
  attr_accessor :pagination, :page
  attr_accessor :carrier_id
  attr_reader :shipments

  alias pagination? pagination
  alias ungrouped_shipments shipments

  def initialize(attrs = {})
    self.current_company = attrs.delete(:current_company)
    self.base_relation = attrs.delete(:base_relation)

    if current_company.nil?
      raise ArgumentError, "Missing required `current_company` attribute"
    end

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

  def customer_id_blank_option
    "All direct customers"
  end

  def customer_id_options
    Customer.find_company_customers(company_id: current_company.id).map { |c| [c.name, c.id] }
  end

  def customer_type_blank_option
    "All customer types"
  end

  def customer_type_options
    [
      ["Direct customers", CargofluxConstants::CustomerTypes::DIRECT_CUSTOMERS],
      ["Company customers", CargofluxConstants::CustomerTypes::COMPANY_CUSTOMERS],
      ["Carrier product customers", CargofluxConstants::CustomerTypes::CARRIER_PRODUCT_CUSTOMERS],
    ]
  end

  def state_blank_option
    "All states"
  end

  def state_options
    filterable_states.map { |state| [ViewHelper::Shipments.state_name(state), state] }
  end

  def related_company_options
    company_relations = EntityRelation.find_relations(from_type: Company, from_id: current_company.id, to_type: Company, relation_type: EntityRelation::RelationTypes::ALL)
    company_relations
      .map { |er| er.to_reference }
      .map { |c| [c.name, c.id] }
  end

  def related_company_blank_option
    "All company / carrier product customers"
  end

  def carrier_id_blank_option
    "All carriers"
  end

  def grouping_options
    [
      ["No grouping", CargofluxConstants::Group::NONE],
      ["Grouped by customer", CargofluxConstants::Group::CUSTOMER],
      ["Grouped by customer type", CargofluxConstants::Group::CUSTOMER_TYPE],
      ["Grouped by company", CargofluxConstants::Group::COMPANY],
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

  def apply_customer_filter(relation)
    if customer_id.present?
      relation.find_customer_shipments(customer_id: customer_id)
    else
      relation
    end
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

  def apply_customer_type_filter(relation)
    if customer_type.present?
      relation.find_shipments_with_customer_type(company_id: current_company.id, customer_type: customer_type)
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

  def apply_related_company_filter(relation)
    if related_company_id.present?
      relation.find_shipments_sold_to_company(company_id: current_company.id, customer_company_id: related_company_id)
    else
      relation
    end
  end

  def apply_filters(relation)
    relation = apply_customer_filter(relation)
    relation = apply_start_date_filter(relation)
    relation = apply_end_date_filter(relation)
    relation = apply_shipping_start_date_filter(relation)
    relation = apply_shipping_end_date_filter(relation)
    relation = apply_customer_type_filter(relation)
    relation = apply_state_filter(relation)
    relation = apply_carrier_filter(relation)
    relation = apply_related_company_filter(relation)
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
    when CargofluxConstants::Group::CUSTOMER
      apply_group_by_customer(relation)
    when CargofluxConstants::Group::STATE
      apply_group_by_state(relation)
    when CargofluxConstants::Group::CUSTOMER_TYPE
      apply_group_by_customer_type(relation)
    when CargofluxConstants::Group::COMPANY
      apply_group_by_company(relation)
    end
  end

  def apply_group_by_customer(relation)
    grouped = relation.group_by(&:customer)
    grouped.each_pair.map do |key, val|
      GroupSortFilter::DataGroup.new(name: key.name, data: val)
    end
  end

  def apply_group_by_state(relation)
    grouped = relation.group_by(&:state)
    grouped.each_pair.map do |key, val|
      GroupSortFilter::DataGroup.new(name: ViewHelper::Shipments.state_name(key), data: val)
    end
  end

  def apply_group_by_customer_type(relation)
    # company id - used for finding carrier products
    company_id = current_company.id

    # company carrier products - i.e. direct customers book on these
    carrier_products = CarrierProduct.find_all_company_carrier_products(company_id: company_id)
    carrier_product_ids = carrier_products.map(&:id)
    shipments_direct_customers =
      if carrier_product_ids.size > 0
        relation.where("shipments.carrier_product_id in (#{carrier_product_ids.join(',')})")
      else
        relation.none
      end

    # company ids for direct company customers
    entity_relations = EntityRelation.find_relations(from_type: Company, from_id: company_id, to_type: Company, relation_type: EntityRelation::RelationTypes::DIRECT_COMPANY)
    company_ids = entity_relations.map(&:to_reference_id)
    shipments_direct_companies =
      if company_ids.size > 0
        relation.where("shipments.company_id in (#{company_ids.join(',')})")
      else
        relation.none
      end

    # carrier product shipments - it's the rest minus the two other groups
    shipments_carrier_product_customers = relation
    if carrier_product_ids.size > 0
      shipments_carrier_product_customers =
        shipments_carrier_product_customers
        .where("shipments.carrier_product_id not in (#{carrier_product_ids.join(',')})")
    end
    if company_ids.size > 0
      shipments_carrier_product_customers =
        shipments_carrier_product_customers
        .where("shipments.company_id not in (#{company_ids.join(',')})")
    end

    groups = []

    if shipments_direct_customers.size > 0
      groups << GroupSortFilter::DataGroup.new(name: "Direct customers", data: shipments_direct_customers)
    end

    if shipments_direct_companies.size > 0
      groups << GroupSortFilter::DataGroup.new(name: "Direct companies", data: shipments_direct_companies)
    end

    if shipments_carrier_product_customers.size > 0
      groups << GroupSortFilter::DataGroup.new(name: "Carrier product customers", data: shipments_carrier_product_customers)
    end

    groups
  end

  def apply_group_by_company(relation)
    grouped = relation.group_by(&:company)

    groups = grouped.each_pair.map do |key, val|
      GroupSortFilter::DataGroup.new(name: key.name, reference: key, data: val)
    end

    groups.sort_by(&:name)
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
