class PickupsIndexView
  include ActiveModel::Model

  class << self
    def base_index_relation_for_customer(company:, customer:)
      Pickup
        .where(company: company, customer: customer)
        .where.not(state: [Pickup::States::CANCELLED, Pickup::States::PICKED_UP])
        .where(table[:pickup_date].gteq(Date.today))
    end

    def base_archived_relation_for_customer(company:, customer:)
      Pickup
        .where(company: company, customer: customer)
        .where(pickups_in_states([Pickup::States::CANCELLED, Pickup::States::PICKED_UP]).or(pickups_before_date(Date.today)))
    end

    def pickups_in_states(states)
      table[:state].in(states)
    end

    def pickups_before_date(date)
      table[:pickup_date].lt(date)
    end

    def table
      Pickup.arel_table
    end
  end

  ACTIVE_STATES = [Pickup::States::CREATED, Pickup::States::BOOKED, Pickup::States::PROBLEM]
  ARCHIVED_STATES = [Pickup::States::PICKED_UP, Pickup::States::CANCELLED]

  attr_accessor :sorting
  attr_accessor :state
  attr_accessor :page

  def initialize(params = {})
    @base_relation = params.delete(:base_relation) || Pickup.none
    @available_states = params.delete(:available_states)

    self.sorting = nil
    self.state = nil

    super(params)
  end

  def sorting=(value)
    @sorting = value.presence || CargofluxConstants::Sort::DATE_DESC
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
    if @available_states
      [["All states", ""]] + @available_states.map { |state| [ViewHelper::Pickups.state_name(state), state] }
    else
      []
    end
  end

  private

  def filter_by_state(relation)
    if state.present?
      relation.where(state: state)
    else
      relation.all
    end
  end

  def apply_sorting(relation)
    case sorting
    when CargofluxConstants::Sort::DATE_ASC
      relation.order(pickup_date: :asc, from_time: :asc, id: :asc)
    when CargofluxConstants::Sort::DATE_DESC
      relation.order(pickup_date: :desc, from_time: :desc, id: :desc)
    else
      relation.all
    end
  end
end
