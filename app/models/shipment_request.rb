class ShipmentRequest < ActiveRecord::Base
  include GroupSortFilter

  module States
    CREATED  = 'created'
    PROPOSED = 'proposed'
    ACCEPTED = 'accepted'
    BOOKED   = 'booked'
    DECLINED = 'declined'
    CANCELED = 'canceled'
  end

  module Events
    CREATE  = 'events_shipment_requests_create'
    PROPOSE = 'events_shipment_requests_propose'
    ACCEPT  = 'events_shipment_requests_accept'
    BOOK    = 'events_shipment_requests_book'
    DECLINE = 'events_shipment_requests_decline'
    CANCEL  = 'events_shipment_requests_cancel'
  end

  module ContextEvents
    COMPANY_CANCEL = "context_events_shipment_requests_company_cancel"
    CUSTOMER_CANCEL = "context_events_shipment_requests_customer_cancel"
  end

  module EventDescriptions
    CREATE  = 'RFQ created by customer. Waiting for proposal.'
    PROPOSE = 'RFQ proposal made by company. Waiting for response.'
    ACCEPT  = 'RFQ proposal accepted by customer. Waiting for booking.'
    BOOK    = 'Shipment has been booked.'
    DECLINE = 'RFQ proposal declined by customer.'
    CANCEL  = 'RFQ canceled.'
  end

  belongs_to :shipment
  has_many :events, as: :reference

  class << self

    def build(shipment_id: nil, state: nil)
      self.new(shipment_id: shipment_id, state: state)
    end

    def create(shipment_id: nil, state: nil)
      request = build(shipment_id: shipment_id)
      request.save!
      request.create # dispatch created event

      request
    end

    def update(shipment_request_id: nil, data: nil)
      request = self.find(shipment_request_id)
      request.update_attributes!(data)

      request
    end

    def all_actionable_states
      company_actionable_states + customer_actionable_states
    end

    def company_actionable_states
      [States::CREATED, States::ACCEPTED, States::DECLINED]
    end

    def customer_actionable_states
      [States::PROPOSED]
    end

    # Finders
    #
    #

    def find_company_shipment_requests(company_id: nil)
      self
        .joins("LEFT JOIN shipments s on shipment_requests.shipment_id = s.id")
        .where("s.company_id = ?", company_id)
    end

    def find_customer_shipment_requests(company_id: nil, customer_id: nil)
      self
        .joins("LEFT JOIN shipments s on shipment_requests.shipment_id = s.id")
        .where("s.company_id = ? AND s.customer_id = ?", company_id, customer_id)
    end

    def find_company_shipment_request(company_id: nil, shipment_request_id: nil)
      self
        .find_company_shipment_requests(company_id: company_id)
        .where(id: shipment_request_id)
        .first
    end

    def find_customer_shipment_request(company_id: nil, customer_id: nil, shipment_request_id: nil)
      self
        .find_customer_shipment_requests(company_id: company_id, customer_id: customer_id)
        .where(id: shipment_request_id)
        .first
    end

    def find_company_pending_requests
      self
        .joins("LEFT JOIN shipments s on shipment_requests.shipment_id = s.id")
        .where("s.state = ? AND shipment_requests.state <> ?", Shipment::States::REQUEST, States::BOOKED)
    end

    def find_customer_pending_requests
      self
        .joins("LEFT JOIN shipments s on shipment_requests.shipment_id = s.id")
        .where("s.state = ? AND shipment_requests.state <> ?", Shipment::States::REQUEST, States::BOOKED)
    end

    def find_all_actionable_states
      self
        .joins("LEFT JOIN shipments s on shipment_requests.shipment_id = s.id")
        .where("s.state = ? AND shipment_requests.state IN (?)", Shipment::States::REQUEST, all_actionable_states)
    end

    def find_company_actionable_states
      self
        .joins("LEFT JOIN shipments s on shipment_requests.shipment_id = s.id")
        .where("s.state = ? AND shipment_requests.state IN (?)", Shipment::States::REQUEST, company_actionable_states)
    end

    def find_customer_actionable_states
      self
        .joins("LEFT JOIN shipments s on shipment_requests.shipment_id = s.id")
        .where("s.state = ? AND shipment_requests.state IN (?)", Shipment::States::REQUEST, customer_actionable_states)
    end

    def find_requests_in_state(state: nil)
      self.where(state: state)
    end

    # Getters
    #
    #

    def get_action_required_for_company_count(company_id: nil)
      self
        .find_company_shipment_requests(company_id: company_id)
        .find_company_actionable_states
        .count
    end

    def get_action_required_for_customer_count(company_id: nil, customer_id: nil)
      self
        .find_customer_shipment_requests(company_id: company_id, customer_id: customer_id)
        .find_customer_actionable_states
        .count
    end

  end

  # Instance
  #
  #

  def created?
    self.state == States::CREATED
  end

  def proposed?
    self.state == States::PROPOSED
  end

  def accepted?
    self.state == States::ACCEPTED
  end

  def declined?
    self.state == States::DECLINED
  end

  def booked?
    self.state == States::BOOKED
  end

  def canceled?
    self.state == States::CANCELED
  end

  def company_responsible?(company_id: nil)
    self.shipment.company_id == company_id
  end

  def customer_responsible?(customer_id: nil)
    self.shipment.customer_id == customer_id
  end

  def can_propose?(company_id: nil)
    is_responsible = self.company_responsible?(company_id: company_id)
    is_responsible && self.created? || self.declined?
  end

  def can_accept?(customer_id: nil)
    is_responsible = self.customer_responsible?(customer_id: customer_id)
    is_responsible && self.proposed?
  end

  def can_decline?(customer_id: nil)
    self.can_accept?(customer_id: customer_id)
  end

  def can_company_cancel?(company_id: nil)
    is_responsible = self.company_responsible?(company_id: company_id)
    is_responsible && self.declined? || self.proposed?
  end

  def can_customer_cancel?(customer_id: nil)
    is_responsible = self.customer_responsible?(customer_id: customer_id)
    is_responsible && !self.canceled? && !self.booked?
  end

  def can_book?(company_id: nil)
    is_responsible = self.company_responsible?(company_id: company_id)
    is_responsible && self.accepted?
  end

  def create
    self.update_state(state: States::CREATED, event: Events::CREATE, info: EventDescriptions::CREATE)
  end

  def propose
    self.update_state(state: States::PROPOSED, event: Events::PROPOSE, info: EventDescriptions::PROPOSE)
  end

  def accept
    self.update_state(state: States::ACCEPTED, event: Events::ACCEPT, info: EventDescriptions::ACCEPT)
  end

  def decline
    self.update_state(state: States::DECLINED, event: Events::DECLINE, info: EventDescriptions::DECLINE)
  end

  def book
    self.update_state(state: States::BOOKED, event: Events::BOOK, info: EventDescriptions::BOOK)
  end

  def cancel
    self.update_state(state: States::CANCELED, event: Events::CANCEL, info: EventDescriptions::CANCEL)
  end

  def update_state(state: nil, event: nil, info: nil)
    self.transaction do
      self.update_attributes(state:  state)

      event_data = {
        reference_id:   self.id,
        reference_type: self.class.to_s,
        event_type:     event,
        description:    info
      }
      self.events << Event.create_event(company_id: self.shipment.company_id, customer_id: self.shipment.customer_id, event_data: event_data)

      return self
    end
  end

  private

    def self.apply_group(group)
      case group.type
        when CargofluxConstants::Group::STATE
          grouped = self.all.group_by(&:state)
          return grouped.each_pair.map {|key, val| GroupSortFilter::DataGroup.new(name: key, reference: CarrierProductAutobookRequest::States, data: val) }
        when CargofluxConstants::Group::NONE
          return self.all
      end
    end

    def self.apply_sort(sort)
      case sort
        when CargofluxConstants::Sort::DATE_ASC
          self.order("created_at ASC, id ASC")
        when CargofluxConstants::Sort::DATE_DESC
          self.order("created_at DESC, id DESC")
        else
          self
      end
    end

    def self.apply_filters(filters: nil, current_company_id: nil)
      result = self

      Rails.logger.debug filters.inspect
      filters.each do |filter|
        case filter.filter
          when CargofluxConstants::Filter::ACTIVE_OR_IN_STATE
            if filter.filter_value == CargofluxConstants::Filter::ACTIVE
              result = result.find_all_actionable_states
            else
              result = result.find_requests_in_state(state: filter.filter_value)
            end
        end
      end

      return result
    end

end
