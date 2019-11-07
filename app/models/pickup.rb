class Pickup < ActiveRecord::Base
  module States
    CREATED                   = 'created'
    BOOKED                    = 'booked'
    PICKED_UP                 = 'picked_up'
    PROBLEM                   = 'problem'
    CANCELLED                 = 'cancelled'
  end

  module Events
    CREATE                    = 'events_pickups_create'
    BOOK                      = 'events_pickups_book'
    PICKUP                    = 'events_pickups_pickup'
    REPORT_PROBLEM            = 'events_pickups_report_problem'
    CANCEL                    = 'events_pickups_cancel'
    COMMENT                   = 'events_pickups_comment'
  end

  include GroupSortFilter

  belongs_to :customer
  belongs_to :company
  has_one :contact, class_name: 'Contact', as: :reference
  has_many :events, as: :reference
  has_one :shipment

  validates :from_time, presence: true
  validates :to_time, presence: true

  accepts_nested_attributes_for :contact

  # PUBLIC API

  scope :for_company, -> (company_id) { where(:company_id => company_id) }
  scope :for_customer, -> (customer_id) { where(:customer_id => customer_id) }
  scope :sorted_by_date_asc, -> { order("pickup_date ASC") }
  scope :sorted_by_date_desc, -> { order("pickup_date DESC") }
  scope :sorted_by_time, -> { order("from_time ASC, to_time ASC") }
  scope :auto, -> { where(auto: true) }
  scope :outdated, ->(cutoff_date) { where(arel_table[:pickup_date].lt(cutoff_date)) }

  delegate :name, to: :customer, prefix: true

  class << self

    def create_pickup(customer_id: nil, company_id: nil, scoped_customer_id: nil, pickup_data: nil, contact_data: nil, id_generator: nil)
      pickup = nil
      Pickup.transaction do
        pickup_id = id_generator.update_next_pickup_id
        pickup = self.new({
          pickup_id:          pickup_id,
          unique_pickup_id:   "#{customer_id}-#{scoped_customer_id}-#{pickup_id}",
          customer_id:        customer_id,
          company_id:         company_id,
          state:              Pickup::States::CREATED,
          pickup_date:        pickup_data[:pickup_date],
          from_time:          pickup_data[:from_time],
          to_time:            pickup_data[:to_time],
          description:        pickup_data[:description],
          auto:               pickup_data[:auto],
        })

        pickup.contact = Contact.create_contact(reference: pickup, contact_data: contact_data)
        pickup.save!

        # log change
        event_data = {
          reference_id:   pickup.id,
          reference_type: pickup.class.to_s,
          event_type:     Pickup::Events::CREATE,
        }
        pickup.events << Event.create_event(company_id: company_id, customer_id: customer_id, event_data: event_data)
      end

      return pickup
    rescue => e
      raise ModelError.new(e.message, pickup)
    end

    # Find methods

    def find_all_for_customer_id(customer_id:nil)
      self.where(customer_id:customer_id)
    end

    def find_customer_pickup(customer_id: nil, company_id: nil, pickup_id: nil)
      self.where(customer_id: customer_id).where(company_id: company_id).where(id: pickup_id).first
    end

    def find_company_pickup(company_id: nil, pickup_id: nil)
      self.where(company_id: company_id).where(id: pickup_id).first
    end

    def find_pickups_in_state(state: nil)
      self.where(state: state)
    end

    def find_company_pickups(company_id: nil)
      self.where(company_id: company_id)
    end

    def find_customer_pickups(customer_id: nil)
      self.where(customer_id: customer_id)
    end

    def find_pickups_in_states(states)
      self.where(state: states)
    end

    def find_pickups_not_in_states(states)
      self.where("state not in (?)", states)
    end

    def find_pickups_in_states_or_before_date(states: nil, before_date: nil)
      self.where("state in (?) or pickup_date < ?", states, before_date)
    end

    def find_pickups_from_date(date)
      self.where("pickup_date >= ?", date)
    end

    def find_pickups_before_date(date)
      self.where("pickup_date < ?", date)
    end

    def count_company_pickups_in_state(company_id:, state:)
      find_company_pickups(company_id: company_id).find_pickups_in_state(state: state).count
    end
  end

  def self.new_from_contact(contact)
    pickup = new
    pickup.build_contact(
      company_name:  contact.company_name,
      attention:     contact.attention,
      address_line1: contact.address_line1,
      address_line2: contact.address_line2,
      address_line3: contact.address_line3,
      zip_code:      contact.zip_code,
      city:          contact.city,
      country_code:  contact.country_code,
    )
    pickup
  end

  def show_id_from_carrier?
    case carrier_identifier
    when "ups"
      true
    else
      false
    end
  end

  def id_from_carrier_partial
    case carrier_identifier
    when "ups"
      "companies/pickups/id_from_carrier/ups"
    end
  end

  ARCHIVED_STATES = [Pickup::States::CANCELLED, Pickup::States::PICKED_UP]

  def archived?
    ARCHIVED_STATES.include?(state)
  end

  def custom?
    !auto?
  end

  def book(comment: nil)
    update_state(new_state: Pickup::States::BOOKED, event_type: Pickup::Events::BOOK, description: comment)
  end

  def book_and_set_bll(bll:, comment: nil)
    self.bll = bll
    book(comment: comment)
  end

  def pickup(comment: nil)
    update_state(new_state: Pickup::States::PICKED_UP, event_type: Pickup::Events::PICKUP, description: comment)
  end

  def cancel(comment: nil)
    update_state(new_state: Pickup::States::CANCELLED, event_type: Pickup::Events::CANCEL, description: comment)
  end

  def report_problem(comment: nil)
    update_state(new_state: Pickup::States::PROBLEM, event_type: Pickup::Events::REPORT_PROBLEM, description: comment)
  end

  def comment(comment: nil)
    create_event(event_type: Pickup::Events::COMMENT, description: comment)
  end

  def latest_event
    self.events.order(:created_at).last
  end

  private

  # Group current result set
  #
  # @param group [String] Grouping specifier
  def self.apply_group(group)
    case group.type
      when CargofluxConstants::Group::NONE
        return self.all
      when CargofluxConstants::Group::CUSTOMER
        grouped = self.all.group_by(&:customer)
        return grouped.each_pair.map {|key, val| GroupSortFilter::DataGroup.new(name: key.name, reference: key, data: val) }
      when CargofluxConstants::Group::STATE
        grouped = self.all.group_by(&:state)
        return grouped.each_pair.map {|key, val| GroupSortFilter::DataGroup.new(name: key, reference: Pickup::States, data: val) }
    end
  end

  # Sort current result set
  #
  # @param sort [String] Sorting specifier
  def self.apply_sort(sort)
    case sort
      when CargofluxConstants::Sort::DATE_ASC
        self.order("pickup_date ASC, from_time ASC, id ASC")
      when CargofluxConstants::Sort::DATE_DESC
        self.order("pickup_date DESC, from_time DESC, id DESC")
      else
        self
    end
  end

  # Applies one or more filters to the current result set
  #
  # @param filters [Array<GroupSortFilter::Filter>] An array of filters to be applied
  def self.apply_filters(filters: nil, current_company_id: nil)
    result = self
    filters.each do |filter|
      case filter.filter
        when CargofluxConstants::Filter::CUSTOMER_ID
          result = result.find_customer_pickups(customer_id: filter.filter_value)
        when CargofluxConstants::Filter::SHIPMENT_ID
          result = result.find(filter.filter_value)
        when CargofluxConstants::Filter::STATE
          result = result.find_pickups_in_state(state: filter.filter_value)
      end
    end

    return result
  end

  def update_state(new_state: nil, event_type: nil, description: nil)
    Pickup.transaction do
      # update state
      self.assign_attributes({state: new_state })
      changes = self.changes
      # log change
      create_event(event_type: event_type, event_changes: changes, description: description)
    end
  end

  def create_event(event_type: nil, event_changes: nil, description: nil)
    Pickup.transaction do
      event_data = {
          reference_id:   self.id,
          reference_type: self.class.to_s,
          event_type:     event_type,
          event_changes:  event_changes,
          description:    description,
      }
      self.events << Event.create_event(company_id:self.company_id, customer_id:self.customer_id, event_data:event_data)
      save!
    end
  end
end
