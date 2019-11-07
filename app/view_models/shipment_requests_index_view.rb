class ShipmentRequestsIndexView
  include ActiveModel::Model

  attr_accessor :sorting
  attr_accessor :state
  attr_accessor :page

  def initialize(params = {})
    @base_relation = params.delete(:base_relation) || ShipmentRequest.none

    self.sorting = nil
    self.state = nil

    super(params)
  end

  def sorting=(value)
    @sorting = value.presence || CargofluxConstants::Sort::DATE_DESC
  end

  def state=(value)
    @state = value.presence || CargofluxConstants::Filter::ACTIVE
  end

  def output_relation
    relation = @base_relation.all

    relation = filter_by_state(relation)
    relation = apply_sorting(relation)

    relation.includes(shipment: [:customer, :recipient, :carrier_product])
  end

  def output_relation_with_pagination
    output_relation.page(page)
  end

  def sorting_options
    [
      ["Newest first", CargofluxConstants::Sort::DATE_DESC],
      ["Oldest first", CargofluxConstants::Sort::DATE_ASC],
    ]
  end

  def state_options
    [["In Progress", CargofluxConstants::Filter::ACTIVE]] + ACTUAL_STATES.map { |state| [ViewHelper::ShipmentRequests.state_name(state), state] }
  end

  private

  def filter_by_state(relation)
    case state
    when CargofluxConstants::Filter::ACTIVE
      relation
        .where(state: ShipmentRequest.all_actionable_states)
        .includes(:shipment)
        .where(shipments: { state: Shipment::States::REQUEST })
    else
      relation.where(state: state)
    end
  end

  def apply_sorting(relation)
    case sorting
    when CargofluxConstants::Sort::DATE_ASC
      relation.order(created_at: :asc, id: :asc)
    when CargofluxConstants::Sort::DATE_DESC
      relation.order(created_at: :desc, id: :desc)
    else
      relation.all
    end
  end

  ACTUAL_STATES = [
    ShipmentRequest::States::CREATED,
    ShipmentRequest::States::PROPOSED,
    ShipmentRequest::States::ACCEPTED,
    ShipmentRequest::States::DECLINED,
    ShipmentRequest::States::BOOKED,
    ShipmentRequest::States::CANCELED,
  ]
end
