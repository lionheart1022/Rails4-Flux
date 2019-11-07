class AutobookRequestFilter
  include ActiveModel::Model

  class << self
    def for_company(company, params: {})
      base_relation = CarrierProductAutobookRequest.find_company_requests(company_id: company.id)
      xparams = params.merge(company: company, type: :active, base_relation: base_relation)
      new(xparams)
    end
  end

  attr_reader :base_relation
  attr_reader :company

  attr_accessor :customer_id
  attr_accessor :state
  attr_accessor :grouping
  attr_accessor :sorting

  attr_accessor :type
  attr_accessor :page, :pagination

  attr_reader :requests

  alias pagination? pagination
  alias ungrouped_requests requests

  def initialize(params = {})
    @base_relation = params.delete(:base_relation)
    @company = params.delete(:company)

    if base_relation.nil?
      raise ArgumentError, "`base_relation` is required"
    end

    if company.nil?
      raise ArgumentError, "`company` is required"
    end

    # Set defaults
    self.grouping = nil
    self.sorting = nil
    @requests = CarrierProductAutobookRequest.none

    super
  end

  def perform!
    @requests = find_requests
  end

  def grouped_requests
    if is_grouped?
      apply_group(requests)
    else
      raise "Grouping type doesn't allow grouping (#{grouping.inspect})"
    end
  end

  def is_grouped?
    !is_ungrouped?
  end

  def is_ungrouped?
    grouping == CargofluxConstants::Group::NONE
  end

  def state=(value)
    @state = (filterable_states & Array(value.presence)).first
  end

  def grouping=(value)
    @grouping = value.presence || CargofluxConstants::Group::NONE
  end

  def sorting=(value)
    @sorting = value.presence || CargofluxConstants::Sort::DATE_DESC
  end

  def grouping_options
    [
      ["No grouping", CargofluxConstants::Group::NONE],
      ["Grouped by customer", CargofluxConstants::Group::CUSTOMER],
      ["Grouped by state", CargofluxConstants::Group::STATE],
    ]
  end

  def sorting_options
    [
      ["Newest first", CargofluxConstants::Sort::DATE_DESC],
      ["Oldest first", CargofluxConstants::Sort::DATE_ASC],
    ]
  end

  def state_options
    filterable_states.map { |state| [ViewHelper::CarrierProductAutobookRequests.state_name(state), state] }
  end

  def filterable_states
    [
      CarrierProductAutobookRequest::States::CREATED,
      CarrierProductAutobookRequest::States::WAITING,
      CarrierProductAutobookRequest::States::IN_PROGRESS,
      CarrierProductAutobookRequest::States::ERROR,
      CarrierProductAutobookRequest::States::COMPLETED,
    ]
  end

  def state_blank_option
    "All states"
  end

  def selected_customer_name
    selected_customer_relation.pluck(:name).first
  end

  private

  def find_requests
    apply_pagination(
      apply_sort(
        apply_filters(
          base_relation
        )
      )
    )
  end

  def apply_filters(relation)
    relation = apply_customer_filter(relation)
    relation = apply_state_filter(relation)
    relation
  end

  def apply_customer_filter(relation)
    if customer_id.present?
      relation.find_customer_requests(customer_id: customer_id)
    else
      relation
    end
  end

  def apply_state_filter(relation)
    if state.present?
      relation.find_requests_in_state(state: state)
    else
      relation
    end
  end

  def apply_sort(relation)
    case sorting
    when CargofluxConstants::Sort::DATE_ASC
      relation.order("carrier_product_autobook_requests.created_at ASC, carrier_product_autobook_requests.id ASC")
    when CargofluxConstants::Sort::DATE_DESC
      relation.order("carrier_product_autobook_requests.created_at DESC, carrier_product_autobook_requests.id DESC")
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
      GroupSortFilter::DataGroup.new(name: ViewHelper::CarrierProductAutobookRequests.state_name(key), data: val)
    end
  end

  def selected_customer_relation
    if customer_id.present?
      Customer.find_company_customers(company_id: company.id).where(id: customer_id)
    else
      Customer.none
    end
  end
end
