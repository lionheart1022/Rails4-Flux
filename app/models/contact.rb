require "postgres_pattern"

class Contact < ActiveRecord::Base
  DEFAULT_ATTRIBUTES_TO_COPY = %w(
    company_name
    attention
    address_line1
    address_line2
    address_line3
    zip_code
    city
    country_name
    country_code
  )

  COUNTRIES_WITH_STATES = %(us ca)

  module Regions
    EUROPE   = 'Europe'
    ASIA     = 'Asia'
    AMERICAS = 'Americas'
    AFRICA   = 'Africa'
    OCEANIA  = 'Oceania'
  end

  belongs_to :reference, polymorphic: true

  # Testing nested_attributes through Interactor, need an error message
  # validates :address_line1, presence: true
  validate :validate_country_code

  attr_accessor :set_country_name_from_code
  alias_method :set_country_name_from_code?, :set_country_name_from_code

  before_save :set_country_name_from_code!, if: :set_country_name_from_code?
  before_save :clear_state_code_for_country_without_states

  attr_accessor :save_recipient_in_address_book, :save_sender_in_address_book

  # PUBLIC API

  def in_eu?
    Country.find_country_by_alpha2(country_code).try(:in_eu?)
  end

  class << self
    def autocomplete_search(company_name: nil)
      if company_name.present?
        where("company_name ILIKE ?", "%#{PostgresPattern.escape(company_name)}%")
      else
        all
      end
    end

    def new_contact_from_existing_contact(existing_contact: nil)
      contact = self.new({
        reference:     existing_contact.reference,
        company_name:  existing_contact.company_name,
        attention:     existing_contact.attention,
        email:         existing_contact.email,
        phone_number:  existing_contact.phone_number,
        address_line1: existing_contact.address_line1,
        address_line2: existing_contact.address_line2,
        address_line3: existing_contact.address_line3,
        zip_code:      existing_contact.zip_code,
        city:          existing_contact.city,
        country_code:  existing_contact.country_code,
        country_name:  existing_contact.country_name,
        state_code:    existing_contact.state_code,
        cvr_number:    existing_contact.cvr_number,
        note:          existing_contact.note,
      })

      return contact
    end

    def create_contact(reference: nil, contact_data: nil)

      country_code  = contact_data[:country_code]
      country_name  = contact_data[:country_name]
      country_name  = Country.find_country_by_alpha2(country_code).try(:name) if country_name.nil? && country_code.present?

      contact = self.new({
        reference:     reference,
        company_name:  contact_data[:company_name],
        attention:     contact_data[:attention],
        email:         contact_data[:email],
        phone_number:  contact_data[:phone_number],
        address_line1: contact_data[:address_line1],
        address_line2: contact_data[:address_line2],
        address_line3: contact_data[:address_line3],
        zip_code:      contact_data[:zip_code],
        city:          contact_data[:city],
        country_code:  country_code,
        country_name:  country_name,
        state_code:    contact_data[:state_code],
        cvr_number:    contact_data[:cvr_number],
        note:          contact_data[:note],
        residential:   contact_data[:residential],
      })
      contact.save!

      return contact
    rescue => e
      raise ModelError.new(e.message, contact)
    end
  end

  def full_address
    string = ''
    string << self.address_line1
    string << " #{self.address_line2}" if self.address_line2.present?
    string << " #{self.address_line3}" if self.address_line3.present?
    return string
  end

  def region
    Country.new(self.country_code).region
  end

  def country_number
    if c = Country.new(country_code)
      c.number
    end
  end

  def state_name
    if country_code.present? && state_code.present?
      country = Country.find_country_by_alpha2(self.country_code)
      state = country.states[self.state_code]
      if state
        state["name"]
      else
        # We can get into this situation if we previously had a state code (e.g. for a US address) but then the
        # country is changed to something like DK; in this case we can't get a state name so this method fails.
        # The proper solution is to not allow getting into that situation in the first place but for now we'll
        # handle the situation by returning `-`.
        "-"
      end
    end
  end

  def state_name_and_code
    if state_code.present?
      "#{state_name} (#{state_code})"
    end
  end

  def validate_country_code
    if self.country_code.present?
      unless Country.all.map {|country| country.alpha2.downcase}.include?(self.country_code.downcase)
        errors.add(:country_code, "is not a valid country code")
      end
    end
  end

  def copy_as_recipient
    Recipient.new(slice(*DEFAULT_ATTRIBUTES_TO_COPY))
  end

  def copy_as_sender
    Sender.new(slice(*DEFAULT_ATTRIBUTES_TO_COPY))
  end

  def zip_code_and_city
    [zip_code, city].reject(&:blank?).join(" ")
  end

  def as_text
    parts =
      [
        company_name,
        attention,
        address_line1,
        address_line2,
        address_line3,
        zip_code_and_city,
        country_name,
        email,
        phone_number,
      ]

    parts.reject(&:blank?).join("\n")
  end

  def set_country_name_from_code!
    if country_code.present?
      country = Country.find_country_by_alpha2(country_code)
      self.country_name = country ? country.name : nil
    end

    true
  end

  def country_with_states?
    COUNTRIES_WITH_STATES.include?(country_code.to_s.downcase)
  end

  def country_without_states?
    !country_with_states?
  end

  def as_flat_address_string
    as_address.to_flat_string
  end

  def as_address
    Address.new(country_code: country_code, state_code: state_code, city: city, zip_code: zip_code, address_line1: address_line1, address_line2: address_line2)
  end

  private

  def clear_state_code_for_country_without_states
    self.state_code = nil if country_without_states?

    true
  end
end
