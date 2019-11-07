require 'package_dimension'
require 'booking_lib'
require 'price_document_v1'
require 'tnt_price_document'
require 'gls_price_document'
require 'dhl_price_document'
require 'ups_price_document'
require 'post_dk_price_document'
require 'price_document_v1'

class Shipment < ActiveRecord::Base
  attr_accessor :rfq
  attr_accessor :request_pickup, :pickup_options
  attr_accessor :select_truck_and_driver, :truck_id, :driver_id

	module ShipmentTypes
		EXPORT = 'export'
		IMPORT = 'import'
	end

  module States
    CREATED                             = 'created'
    WAITING_FOR_BOOKING                 = 'waiting_for_booking'
    BOOKING_INITIATED                   = 'booking_initiated'
    BOOKED_WAITING_AWB_DOCUMENT         = 'booked_waiting_awb_document'
    BOOKED_AWB_IN_PROGRESS              = 'booked_awb_in_progress'
    BOOKED_WAITING_CONSIGNMENT_NOTE     = 'booked_waiting_consignment_note'
    BOOKED_CONSIGNMENT_NOTE_IN_PROGRESS = 'booked_consignment_note_in_progress'
    BOOKED                              = 'booked'
    IN_TRANSIT                          = 'in_transit'
    DELIVERED_AT_DESTINATION            = 'delivered_at_destination'
    PROBLEM                             = 'problem'
    CANCELLED                           = 'cancelled'
    BOOKING_FAILED                      = 'booking_failed'
    REQUEST                             = 'request'
  end

  module Events
    CREATE                                    = 'events_shipments_create'
    WAITING_FOR_BOOKING                       = 'events_shipments_waiting_for_booking'
    BOOKING_INITIATED                         = 'events_shipments_booking_initiated'
    AUTOBOOK                                  = 'events_shipments_autobook'
    AUTOBOOK_WITH_WARNINGS                    = 'events_shipments_autobook_with_warnings'
    BOOK_WITHOUT_AWB_DOCUMENT                 = 'events_shipments_book_without_awb'
    FETCHING_AWB_DOCUMENT                     = 'events_shipments_fetching_awb_document'
    BOOK_WITHOUT_CONSIGNMENT_NOTE             = 'events_shipments_book_without_consignment_note'
    FETCHING_CONSIGNMENT_NOTE                 = 'events_shipments_fetching_consignment_note'
    BOOK                                      = 'events_shipments_book'
    SHIP                                      = 'events_shipments_ship'
    REPORT_PROBLEM                            = 'events_shipments_report_problem'
    REPORT_AUTOBOOK_PROBLEM                   = 'events_shipments_report_autobook_problem'
    REPORT_AUTOBOOK_AWB_PROBLEM               = 'events_shipments_report_autobook_awb_problem'
    REPORT_AUTOBOOK_CONSIGNMENT_NOTE_PROBLEM  = 'events_shipments_report_autobook_consignment_note_problem'
    DELIVERED_AT_DESTINATION                  = 'events_shipments_delivered_at_destination'
    CANCEL                                    = 'events_shipments_cancel'
    BOOKING_FAIL                              = 'events_shipments_booking_fail'
    RETRY                                     = 'events_shipments_retry'
    RETRY_AWB_DOCUMENT                        = 'events_shipments_retry_awb_document'
    RETRY_CONSIGNMENT_NOTE                    = 'events_shipments_retry_consignment_note'
    COMMENT                                   = 'events_shipments_comment'
    INFO                                      = 'events_shipments_info'
    ASSET_OTHER_UPLOADED                      = 'events_shipments_asset_other_uploaded'
    ASSET_AWB_UPLOADED                        = 'events_shipments_asset_awb_uploaded'
    ASSET_INVOICE_UPLOADED                    = 'events_shipments_asset_invoice_uploaded'
    ASSET_CONSIGNMENT_NOTE_UPLOADED           = 'events_shipments_asset_consignment_note_uploaded'

    ADD_PRICE                                 = "events_shipments_add_price"
    SET_SALES_PRICE                           = "events_shipments_set_sales_price"
    UPDATE_SHIPMENT_PRICE                     = "events_shipments_update_shipment_price"
    CREATE_OR_UPDATE_SHIPMENT_NOTE            = "events_shipments_create_or_update_shipment_note"
  end

  module ContextEvents
    CREATE_AND_AUTOBOOK = "context_events_shipments_create_and_autobook"
    RETRY_AND_AUTOBOOK = "context_events_shipments_retry_and_autobook"
    COMPANY_UPDATE = "context_events_shipments_company_update"
    CUSTOMER_CANCEL = "context_events_shipments_customer_cancel"
  end

  module Errors
    class IllegalActionException < StandardError
      attr_reader :action, :reason
      def initialize(action, reason)
        @action = action
        @reason = reason
      end
    end

    class AssetError < StandardError
    end

    class CreateAwbAssetException < AssetError
    end

    class CreateInvoiceAssetException < AssetError
    end

    class CreateConsignmentNoteAssetException < AssetError
    end

    class GenericError
      attr_reader :code, :description

      def initialize(code: nil, description: nil)
        @code         = code
        @description  = description
      end

      def to_s
        "#{@code}: #{@description}"
      end
    end
  end

  include GroupSortFilter

  include S3Callback

  has_one                 :shipment_request, dependent: :destroy
  has_one                 :recipient,               as: :reference, dependent: :destroy
  has_one                 :sender,                  as: :reference, dependent: :destroy
  has_one                 :asset_awb,               as: :assetable, dependent: :destroy
  has_many                :asset_other,             as: :assetable, dependent: :destroy
  has_one                 :asset_invoice,           as: :assetable, dependent: :destroy
  has_one                 :asset_consignment_note,  as: :assetable, dependent: :destroy
  belongs_to              :company
  belongs_to              :customer
  belongs_to              :carrier_product
  belongs_to              :pickup_relation, class_name: "Pickup", foreign_key: "pickup_id", required: false
  has_many                :events, as: :reference
  has_many                :notes, as: :linked_object
  has_and_belongs_to_many :end_of_day_manifests
  has_and_belongs_to_many :reports
  has_and_belongs_to_many :deliveries
  has_many                :advanced_prices, -> { includes(:advanced_price_line_items) }, dependent: :destroy
  has_many                :api_requests
  has_one                 :truck_driver_association, class_name: "ShipmentTruckDriver"
  has_one                 :truck_driver, through: :truck_driver_association
  # has_one                 :customer_carrier_product

  has_many :additional_surcharges, class_name: "ShipmentAdditionalSurcharge", dependent: :destroy

  has_many :eod_manifest_associations, class_name: "EODManifest::ShipmentAssociation"
  has_many :eod_manifests, through: :eod_manifest_associations, source: :manifest

  belongs_to :goods, class_name: "ShipmentGoods"

  accepts_nested_attributes_for :recipient, :sender

  serialize :package_dimensions, PackageDimensions
  serialize :shipment_errors, Array
  serialize :shipment_warnings, Array

  validates :shipping_date,      presence: true
  validates :number_of_packages, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :package_dimensions, presence: true
  validates :carrier_product,    presence: true

  # PUBLIC API

  scope :for_company, -> (company_id) { where(:company_id => company_id) }
  scope :for_customer, -> (customer_id) { where(:customer_id => customer_id) }
  scope :sorted_by_date_desc, -> { order("shipping_date DESC") }
  scope :sorted_by_date_asc, -> { order("shipping_date ASC") }
  scope :invoiceable, -> {
    where(state: [
      Shipment::States::BOOKING_INITIATED, Shipment::States::BOOKED_WAITING_AWB_DOCUMENT, Shipment::States::BOOKED_AWB_IN_PROGRESS,
      Shipment::States::BOOKED_WAITING_CONSIGNMENT_NOTE, Shipment::States::BOOKED_CONSIGNMENT_NOTE_IN_PROGRESS, Shipment::States::BOOKED,
      Shipment::States::IN_TRANSIT, Shipment::States::DELIVERED_AT_DESTINATION, Shipment::States::PROBLEM
    ])
  }

  delegate :name, to: :customer, prefix: true
  delegate :name, to: :carrier_product, prefix: true
  delegate :company_name, to: :sender, prefix: true
  delegate :company_name, to: :recipient, prefix: true
  delegate :service, :supports_auto_book_delivery?, to: :carrier_product, prefix: true

  class << self

    def create_shipment(company_id: nil, customer_id: nil, scoped_customer_id: nil, shipment_data: nil, sender_data: nil, recipient_data: nil, id_generator: nil, advanced_prices: nil)
      shipment = nil
      Shipment.transaction do
        shipment_id = id_generator.try(:update_next_shipment_id)
        shipment = self.new({
          company_id:            company_id,
          customer_id:           customer_id,
          shipment_id:           shipment_id,
          unique_shipment_id: "#{customer_id}-#{scoped_customer_id}-#{shipment_id}",
          state:                 shipment_data[:state] || Shipment::States::CREATED,
          shipping_date:         shipment_data[:shipping_date],
          number_of_packages:    shipment_data[:number_of_packages],
          number_of_pallets:     shipment_data[:number_of_pallets],
          package_dimensions:    shipment_data[:package_dimensions],
          dutiable:              shipment_data[:dutiable],
          customs_amount:        shipment_data[:customs_amount],
          customs_currency:      shipment_data[:customs_currency],
          customs_code:          shipment_data[:customs_code],
          description:           shipment_data[:description],
          carrier_product_id:    shipment_data[:carrier_product_id],
          reference:             shipment_data[:reference],
          shipment_type:         shipment_data[:shipment_type],
          parcelshop_id:         shipment_data[:parcelshop_id],
          return_label:          shipment_data[:return_label],
          remarks:               shipment_data[:remarks],
          delivery_instructions: shipment_data[:delivery_instructions],
          dangerous_goods:       shipment_data[:dangerous_goods],
          dangerous_goods_predefined_option: shipment_data[:dangerous_goods_predefined_option],
          dangerous_goods_description: shipment_data[:dangerous_goods_description],
          un_number:             shipment_data[:un_number],
          dangerous_goods_class: shipment_data[:dangerous_goods_class],
          un_packing_group:      shipment_data[:un_packing_group],
          packing_instruction:   shipment_data[:packing_instruction],
        })

        shipment.sender          = Sender.create_contact(reference: shipment, contact_data: sender_data)
        shipment.recipient       = Recipient.create_contact(reference: shipment, contact_data: recipient_data)
        shipment.advanced_prices = advanced_prices
        shipment.save!

        if sender_data[:save_sender_in_address_book] && sender_data[:save_sender_in_address_book] == "1"
          AddressBook.create_contact(customer_id: customer_id, contact_data: sender_data)
        end

        if recipient_data[:save_recipient_in_address_book] && recipient_data[:save_recipient_in_address_book] == "1"
          AddressBook.create_contact(customer_id: customer_id, contact_data: recipient_data)
        end

        # log change
        event_data = {
          reference_id:   shipment.id,
          reference_type: shipment.class.to_s,
          event_type:     Shipment::Events::CREATE,
        }
        shipment.events << Event.create_event(company_id: company_id, customer_id: customer_id, event_data: event_data)
      end

      return shipment
    rescue => e
      Rails.logger.error "\ncreate_shipment failed #{e.inspect}"
      raise ModelError.new(e.message, shipment)
    end

    # Find methods
    #

    def find_shipments_eligible_for_tracking
      only  = TrackingLib.tracked_shipment_states
      state = CarrierProduct::States::UNLOCKED_FOR_CONFIGURING
      self.where('shipments.state in (?)', only)
          .where('shipments.carrier_product_id IN
                  (WITH RECURSIVE tree(id) AS (
                     SELECT cp.id FROM carrier_products cp
                     WHERE cp.state = ? AND cp.automatic_tracking = true
                   UNION ALL
                     SELECT cp.id FROM carrier_products cp JOIN tree ON cp.carrier_product_id = tree.id)
                    SELECT id FROM tree)', state)
    end

    def find_company_shipments(company_id: nil)
      carrier_products = CarrierProduct.find_all_company_carrier_products(company_id: company_id)
      carrier_product_ids = carrier_products.map {|cp| cp.id }

      company_relations = EntityRelation.find_relations(from_type: Company, from_id: company_id, to_type: Company, relation_type: EntityRelation::RelationTypes::DIRECT_COMPANY).includes(:to_reference)
      related_company_ids = company_relations.map {|er| er.to_reference.id }
      self.where("shipments.carrier_product_id IN
                 (WITH RECURSIVE tree(id) AS (
                    SELECT cp.id, cp.name FROM carrier_products cp
                    WHERE cp.id IN (?)
                    UNION ALL
                      SELECT cp.id, cp.name FROM carrier_products cp JOIN tree ON cp.carrier_product_id = tree.id)
                  SELECT id FROM tree) OR shipments.company_id IN (?)", carrier_product_ids, related_company_ids)
    end

    def count_company_shipments_in_state(company_id:, state:)
      find_company_shipments(company_id: company_id).find_shipments_in_state(state: state).count
    end

    def find_shipments_sold_to_company(company_id: nil, customer_company_id: nil)
      carrier_products = CarrierProduct.find_all_company_carrier_products(company_id: company_id)
      carrier_product_ids = carrier_products.map {|cp| cp.id }
      self.where("shipments.carrier_product_id IN
                 (WITH RECURSIVE tree(id) AS (
                    SELECT cp.id, cp.name FROM carrier_products cp
                    WHERE cp.carrier_product_id IN (?) AND cp.company_id = ?
                    UNION ALL
                      SELECT cp.id, cp.name FROM carrier_products cp JOIN tree ON cp.carrier_product_id = tree.id)
                  SELECT id FROM tree)", carrier_product_ids, customer_company_id)
    end

    def find_company_shipment(company_id: nil, shipment_id: nil)
      self.find_company_shipments(company_id: company_id).where(id: shipment_id).first
    end

    def find_shipments_in_state(state: nil)
      self.where("shipments.state = ?", state)
    end

    def find_customer_shipments(customer_id: nil)
      self.where(customer_id: customer_id)
    end

    def find_customer_shipments_with_ids(customer_id: nil, shipment_ids: nil)
      self.where(customer_id: customer_id).where(id: shipment_ids)
    end

    # @return [Shipment]
    def find_customer_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
      self.where(company_id:company_id).where(customer_id: customer_id).where(id: shipment_id).first
    end

    def find_customer_shipment_from_unique_shipment_id(company_id: nil, customer_id: nil, unique_shipment_id: nil)
      self.where(company_id:company_id).where(customer_id: customer_id).where(unique_shipment_id: unique_shipment_id).first
    end

    def find_company_shipment_from_unique_shipment_id(company_id: nil, unique_shipment_id: nil)
      self.where(company_id:company_id).where(unique_shipment_id: unique_shipment_id).first
    end

    def find_company_shipments_with_awb_or_unique_shipment_id(company_id: nil, query: nil)
      return self.none if query.blank?

      self
        .find_company_shipments(company_id: company_id)
        .wildcard_search_awb_or_reference_or_unique_shipment_id(query)
    end

    def find_customer_shipments_with_awb_or_unique_shipment_id(company_id: nil, customer_id: nil, query: nil)
      return self.none if query.blank?

      self
        .where(company_id: company_id, customer_id: customer_id)
        .wildcard_search_awb_or_reference_or_unique_shipment_id(query)
        .where("state <> ?", States::REQUEST)
    end

    def wildcard_search_awb_or_reference_or_unique_shipment_id(query)
      where("awb ILIKE :query_pattern OR unique_shipment_id ILIKE :query_pattern OR reference ILIKE :query_pattern", query_pattern: "%#{query}%")
    end

    def find_shipment(shipment_id: nil)
      self.where(id: shipment_id).first
    end

    # returns the customer or company buying/forwarding product from company
    def find_buyer_from_shipment_and_company(company_id: nil, shipment_id: nil)
      shipment = self.find_company_shipment(company_id: company_id, shipment_id: shipment_id)
      cp = shipment.carrier_product
      parent = cp.carrier_product

      # is selling directly to customer
      if cp.company_id == company_id
        return shipment.customer
      end

      # is selling to company
      while cp.carrier_product.present?
        if parent.company_id == company_id
          return cp.company
        end

        cp = parent
        parent = cp.carrier_product
      end
    end

    def find_shipments_in_states(states)
      self.where("shipments.state in (?)", states)
    end

    def find_shipments_not_in_states(states)
      self.where("shipments.state not in (?)", states)
    end

    def find_shipments_not_canceled
      self.find_shipments_not_in_states([Shipment::States::CANCELLED, Shipment::States::PROBLEM, Shipment::States::BOOKING_FAILED])
    end

    def find_shipments_not_requested
      self.find_shipments_not_in_states([Shipment::States::REQUEST])
    end

    def find_shipments_with_carrier_id(carrier_id: nil)
      self.joins("left join carrier_products on carrier_products.id=shipments.carrier_product_id").joins("left join carriers on carriers.id=carrier_products.carrier_id").where("carriers.id = ?", carrier_id)
    end

    def find_shipments_not_in_manifest
      self.joins("left join end_of_day_manifests_shipments on shipments.id=end_of_day_manifests_shipments.shipment_id").where("end_of_day_manifests_shipments.shipment_id is null")
    end

    def find_not_exported_company_shipments(company_id: nil)
      self
        .joins('LEFT JOIN shipment_exports se ON shipments.id = se.shipment_id')
        .where('se.owner_id = ? AND se.owner_type = ? AND exported = false AND updated = false', company_id, Company.to_s)
    end

    def find_updated_and_exported_company_shipments(company_id: nil)
      self
        .joins('LEFT JOIN shipment_exports se ON shipments.id = se.shipment_id')
        .where('se.owner_id = ? AND se.owner_type = ? AND updated = true', company_id, Company.to_s)
    end

    # Selects shipments that are not currently in a report within a company
    #
    # The search has to be scoped by company because several companies can access the same shipment. The search is performed by finding the ids of all reports within the company,
    # then using those to lookup all shipment ids within those reports, and then using the shipment ids to filter out shipments already in a report
    def find_shipments_not_in_report_in_company(company_id: nil)
      reports_ids = Report.find_company_reports(company_id: company_id).map {|r| r.id }
      reports_ids = reports_ids.empty? ? [-1] : reports_ids
      self.distinct.joins("left join reports_shipments on shipments.id=reports_shipments.shipment_id").where("shipments.id not in (select reports_shipments.shipment_id from reports_shipments where reports_shipments.report_id in (?))", reports_ids)
    end

    # Finds shipments that at one point in their history have been booked, and are not currently cancelled
    def find_shipments_that_have_been_booked
      accepted_events = [Shipment::Events::BOOK, Shipment::Events::SHIP, Shipment::Events::DELIVERED_AT_DESTINATION]
      self.find_shipments_not_in_states([Shipment::States::CANCELLED]).select("shipments.id").distinct.select("shipments.*").joins("left join events on shipments.id = events.reference_id").where("events.reference_type = ?", Shipment.to_s).where("events.event_type IN (?)", accepted_events)
    end

    def find_shipments_with_customer_type(company_id: nil, customer_type: nil)
      carrier_products = CarrierProduct.find_all_company_carrier_products(company_id: company_id)
      carrier_product_ids = carrier_products.map {|cp| cp.id }
      carrier_product_ids = carrier_product_ids.empty? ? [-1] : carrier_product_ids # if empty set then we use -1 so that we can still use "in ()" sql query

      entity_relations = EntityRelation.find_relations(from_type: Company, from_id: company_id, to_type: Company, relation_type: EntityRelation::RelationTypes::DIRECT_COMPANY)
      company_ids = entity_relations.map {|er| er.to_reference_id }
      company_ids = company_ids.empty? ? [-1] : company_ids # if empty set then we use -1 so that we can still use "in ()" sql query

      case customer_type
        when CargofluxConstants::CustomerTypes::DIRECT_CUSTOMERS
          self.where("shipments.carrier_product_id in (#{carrier_product_ids.join(',')})")
        when CargofluxConstants::CustomerTypes::CARRIER_PRODUCT_CUSTOMERS
          self.where("shipments.carrier_product_id not in (#{carrier_product_ids.join(',')})").where("shipments.company_id not in (#{company_ids.join(',')})")
        when CargofluxConstants::CustomerTypes::COMPANY_CUSTOMERS
          self.where("shipments.company_id in (#{company_ids.join(',')})")
      end
    end

    def find_shipments_with_company_id(company_id: nil)
      self.where(company_id: company_id)
    end

    def shipped_after(date)
      where(arel_table[:shipping_date].gteq(date))
    end

    def shipped_before(date)
      where(arel_table[:shipping_date].lteq(date))
    end

    def find_shipments_after_date(date: nil)
      self.where("shipments.created_at >= ?", date)
    end

    def find_shipments_before_date(date: nil)
      self.where("shipments.created_at <= ?", date)
    end

    def find_shipments_with_carrier(carrier_id:)
      self.joins(:carrier_product).where(carrier_products: { carrier_id: carrier_id })
    end

    def shipment_types
  		Shipment::ShipmentTypes.constants.map{ |c| c.to_s.downcase.titleize }
  	end

    # Returns true if the customer can retry the booking process
    #
    # @return [Boolean]
    def customer_can_retry_booking?(customer_id: nil, shipment_id: nil)
      shipment = Shipment.where(customer_id: customer_id, id: shipment_id).first
      shipment.state == Shipment::States::BOOKING_FAILED
    end

    # Find the entitiy responsible for paying for the shipment.
    # This changes based on who is looking. Used to group shipments when creating invoices.
    def find_company_or_customer_payer(current_company_id: nil, shipment_id: nil)
      shipment = Shipment.find(shipment_id)
      carrier_product_chain = CarrierProduct.find_carrier_product_chain(carrier_product_id: shipment.carrier_product.id)

      # Find array index for carrier_product matching the current company
      match_index = carrier_product_chain.index(carrier_product_chain.find { |l| l.company_id == current_company_id })

      if match_index == 0
        # If first in carrier_product_chain then invoice the shipments customer
        Customer.find_customer(customer_id: shipment.customer.id)
      else
        # Otherwise invoice the company right below the current one in the chain
        Company.find_company(company_id: carrier_product_chain[match_index - 1].company_id)
      end
    end

  end

  # PUBLIC INSTANCE API
  #

  def dangerous_goods_predefined_option_used?
    un_number_from_dangerous_goods_predefined_option.present?
  end

  def description_from_dangerous_goods_predefined_option
    case dangerous_goods_predefined_option
    when "dry_ice" then "Dry Ice UN1845"
    when "lithium_ion_UN3481_PI966" then "Ion PI966 Section I (LiBa with equipment)"
    when "lithium_ion_UN3481_PI967" then "Ion PI967 Section I (LiBa in equipment)"
    when "lithium_metal_UN3091_PI969" then "Metal PI969 Section I (LiBa with equipment)"
    when "lithium_metal_UN3091_PI970" then "Metal PI970 Section I (LiBa in equipment)"
    end
  end

  def prefixed_un_number_from_dangerous_goods_predefined_option(prefix: "UN")
    if un_number = un_number_from_dangerous_goods_predefined_option
      "#{prefix}#{un_number}"
    end
  end

  def un_number_from_dangerous_goods_predefined_option
    case dangerous_goods_predefined_option
    when "dry_ice" then 1845
    when "lithium_ion_UN3481_PI966" then 3481
    when "lithium_ion_UN3481_PI967" then 3481
    when "lithium_metal_UN3091_PI969" then 3091
    when "lithium_metal_UN3091_PI970" then 3091
    end
  end

  def latest_api_request
    self.api_requests.order(created_at: :desc).first
  end

  def request
    self.shipment_request
  end


  def destroy_asset(company_id: nil, shipment_id: nil, asset_id: nil)

  end

  def create_or_update_awb_asset_from_local_file(file_path: nil, linked_object: nil)
    asset = asset_awb || AssetAwb.new(assetable: self)

    Asset.transaction do
      File.open(file_path) do |file|
        asset.attachment = file
        asset.save!
      end
      create_event(event_type: Shipment::Events::ASSET_AWB_UPLOADED, description: asset.attachment_file_name, linked_object: linked_object)
    end
  rescue => e
    raise Shipment::Errors::CreateAwbAssetException.new(e.message)
  end

  def create_or_update_awb_asset(filepath: nil, filename: nil, filetype: nil, linked_object: nil)
    asset = asset_awb || AssetAwb.new(assetable: self)

    Asset.transaction do
      s3_copy_file_between_buckets(asset: asset, filepath: filepath, filename: filename)
      create_event(event_type: Shipment::Events::ASSET_AWB_UPLOADED, description: asset.attachment_file_name, linked_object: linked_object)
    end

    return asset
  rescue => e
    raise Shipment::Errors::CreateAwbAssetException.new(e.message)
  end

  def create_or_update_invoice_asset(filepath: nil, filename: nil, filetype: nil, linked_object: nil)
    asset = asset_invoice || AssetInvoice.new(assetable: self)

    Asset.transaction do
      s3_copy_file_between_buckets(asset: asset, filepath: filepath, filename: filename)
      create_event(event_type:Shipment::Events::ASSET_INVOICE_UPLOADED, description: asset.attachment_file_name, linked_object: linked_object)
    end

    return asset
  rescue => e
    msg = "#{e.message}, name: #{filename}, type: #{filetype}, content_type: #{asset.attachment_content_type}"
    ExceptionMonitoring.report_message(msg)
    raise Shipment::Errors::CreateInvoiceAssetException.new(e.message)
  end

  def create_or_update_consignment_note_asset(filepath: nil, filename: nil, filetype: nil, linked_object: nil)
    asset = asset_consignment_note || AssetConsignmentNote.new(assetable: self)

    Asset.transaction do
      s3_copy_file_between_buckets(asset: asset, filepath: filepath, filename: filename)
      create_event(event_type:Shipment::Events::ASSET_CONSIGNMENT_NOTE_UPLOADED, description: asset.attachment_file_name, linked_object: linked_object)
    end

    return asset
  rescue => e
    msg = "#{e.message}, name: #{filename}, type: #{filetype}, content_type: #{asset.attachment_content_type}"
    ExceptionMonitoring.report_message(msg)
    raise Shipment::Errors::CreateConsignmentNoteAssetException.new(e.message)
  end

  def create_or_update_consignment_note_asset_from_local_file(file_path: nil, linked_object: nil)
    asset = asset_consignment_note || AssetConsignmentNote.new(assetable: self)

    Asset.transaction do
      File.open(file_path) do |file|
        asset.attachment = file
        asset.save!
      end
      create_event(event_type: Shipment::Events::ASSET_CONSIGNMENT_NOTE_UPLOADED, description: asset.attachment_file_name, linked_object: linked_object)
    end
  rescue => e
    raise Shipment::Errors::CreateConsignmentNoteAssetException.new(e.message)
  end

  def waiting_for_booking(comment: nil, linked_object: nil)
    update_state(new_state: Shipment::States::WAITING_FOR_BOOKING, event_type: Shipment::Events::WAITING_FOR_BOOKING, description: comment, linked_object: linked_object)
  end

  def booking_initiated(comment: nil, linked_object: nil)
    update_state(new_state: Shipment::States::BOOKING_INITIATED, event_type: Shipment::Events::BOOKING_INITIATED, description: comment, linked_object: linked_object)
  end

  def book(awb: nil, external_awb_asset: nil, comment: nil, warnings: nil, linked_object: nil)
    self.assign_attributes({ awb: awb }) unless awb.nil?
    self.assign_attributes({ external_awb_asset: external_awb_asset }) unless external_awb_asset.nil?
    self.assign_attributes({ shipment_warnings: warnings }) unless warnings.nil?
    update_state(new_state: Shipment::States::BOOKED, event_type: Shipment::Events::BOOK, description: comment, linked_object: linked_object)
  end

  def book_without_awb_document(awb: nil, comment: nil, linked_object: nil)
    self.assign_attributes({awb: awb}) unless awb.nil?
    update_state(new_state: Shipment::States::BOOKED_WAITING_AWB_DOCUMENT, event_type: Shipment::Events::BOOK_WITHOUT_AWB_DOCUMENT, description: comment, linked_object: linked_object)
  end

  def fetching_awb_document(comment: nil, linked_object: nil)
    update_state(new_state: Shipment::States::BOOKED_AWB_IN_PROGRESS, event_type: Shipment::Events::FETCHING_AWB_DOCUMENT, description: comment, linked_object: linked_object)
  end

  def book_without_consignment_note(awb: nil, comment: nil, linked_object: nil)
    self.assign_attributes({awb: awb}) unless awb.nil?
    update_state(new_state: Shipment::States::BOOKED_WAITING_CONSIGNMENT_NOTE, event_type: Shipment::Events::BOOK_WITHOUT_CONSIGNMENT_NOTE, description: comment, linked_object: linked_object)
  end

  def fetching_consignment_note(comment: nil, linked_object: nil)
    update_state(new_state: Shipment::States::BOOKED_CONSIGNMENT_NOTE_IN_PROGRESS, event_type: Shipment::Events::FETCHING_CONSIGNMENT_NOTE, description: comment, linked_object: linked_object)
  end

  def ship(comment: nil, linked_object: nil)
    update_state(new_state: Shipment::States::IN_TRANSIT, event_type: Shipment::Events::SHIP, description: comment, linked_object: linked_object)
  end

  def delivered_at_destination(comment: nil, linked_object: nil)
    update_state(new_state: Shipment::States::DELIVERED_AT_DESTINATION, event_type: Shipment::Events::DELIVERED_AT_DESTINATION, description: comment, linked_object: linked_object)
  end

  def cancel(comment: nil, linked_object: nil)
    update_state(new_state: Shipment::States::CANCELLED, event_type: Shipment::Events::CANCEL, description: comment, linked_object: linked_object)
  end

  def booking_fail(comment: nil, errors: [], linked_object: nil)
    update_state(new_state: Shipment::States::BOOKING_FAILED, event_type: Shipment::Events::BOOKING_FAIL, description: comment, errors: errors, linked_object: linked_object)
  end

  def report_problem(comment: nil, errors: [], linked_object: nil)
    update_state(new_state: Shipment::States::PROBLEM, event_type: Shipment::Events::REPORT_PROBLEM, description: comment, errors: errors, linked_object: linked_object)
  end

  def comment(comment: nil, linked_object: nil)
    create_event(event_type:Shipment::Events::COMMENT, description: comment, linked_object: linked_object)
  end

  def info(description: nil, linked_object: nil)
    create_event(event_type: Shipment::Events::INFO, description: description, linked_object: linked_object)
  end

  def pickup
    create_event(event_type: Shipment::Events::PICKUP, description: comment, linked_object: linked_object)
  end

  def manifest_pickup
    create_event(event_type: Shipment::Events::MANIFEST_PICKUP, description: comment, linked_object: linked_object)
  end

  def comment_without_state_change(comment: nil, linked_object: nil)
    create_event(description: comment, linked_object: linked_object)
  end

  def latest_event
    self.events.order(:created_at).last
  end

  def done_deliveries
    deliveries.where(state: Delivery::States::EMPTY)
  end

  def event_already_reported?(event_type: nil)
    event = self.events.where(event_type: event_type).first
    event.present?
  end

  # returns true if shipment is new as has not been retried
  def booking_failed?
    self.state == Shipment::States::BOOKING_FAILED
  end

  # returns the associated carrier's name if present
  def carrier
    self.carrier_product.carrier.name
  end

  # To avoid querying the database multiple times to get the name (it is only defined on top level ancestor), we preload carrier products with 'CarrierProduct.find_top_level_ancestors_from_ids()'
  # and pass them here
  #
  def cached_carrier_product_name(carrier_products: nil)
    self.cached_owner_carrier_product(carrier_products: carrier_products).name
  end

  def cached_owner_carrier_product(carrier_products: nil)
    current = carrier_products.detect{ |cp| cp.id == self.carrier_product_id }

    while current.present?
      match = carrier_products.detect{ |cp| cp.id == current.carrier_product_id }
      return current if match.nil?
      current = match
    end

    return current
  end

  def customer_name_for_company(company_id:)
    if customer.company_id == company_id
      customer_name
    else
      current = carrier_product

      loop do
        break if current.carrier_product.nil?
        return current.company.name if current.carrier_product.company_id == company_id

        current = current.carrier_product
      end

      nil
    end
  end

  # responsible companies

  # The technical responsible is the company responsible for technical errors in the booking process
  #
  # It is defined as the original owner of a carrier product. For auto-booking product this will most likely be CargoFlux.
  # For company defined products, they will also be the technical responsible.
  #
  # WARNING! Until the CargoFlux organization is ready to assume responsibility for technical errors, the technical responsible
  # has been redefined as the product responsible
  def technical_responsible
    # WARNING! Reinstate when CargoFlux is ready to handle technical errors
    #self.carrier_product.owner_carrier_product_chain(include_self: true).last.company
    self.product_responsible
  end

  # The product responsible is the company who is responsible for booking the shipment.
  #
  # It is not necessarily the carrier product linked to the shipment, but might be a parent to that carrier product, by tracing up the owner chain.
  # It is defined as the first unlocked product in the owner chain.
  def product_responsible
    self.carrier_product.first_unlocked_product_in_owner_chain.company
  end

  def logo_url_of_product_responsible
    responsible_company = product_responsible

    if responsible_company && responsible_company.asset_logo
      responsible_company.asset_logo.attachment.url
    end
  end

  # The customer responsible is the company responsible for servicing the customer creating the shipment
  #
  # It is defined as the company that owns the carrier product linked to the shipment, so it will always be the company of which
  # the customer is a direct customer
  def customer_responsible
    self.carrier_product.company
  end

  def requested?
    self.state == States::REQUEST
  end

  # Returns true if the specified company is responsible for servicing the customer creating the shipment
  #
  # @return [Boolean]
  def company_responsible_for_customer?(company_id: nil)
    self.carrier_product.company_id == company_id
  end

  def company_responsible_for_product?(company_id: nil)
    product_responsible.id == company_id
  end

  # Returns true if the customer can retry the booking process
  #
  # @return [Boolean]
  def customer_can_retry_booking?(customer_id: nil)
    self.state == Shipment::States::BOOKING_FAILED
  end

  def customer_carrier_product
    CustomerCarrierProduct.where(customer_id: self.customer_id, carrier_product_id: self.carrier_product_id).first
  end

  def regular_shipment?
    !ferry_booking_shipment?
  end

  def customs_amount_from_user_input=(value)
    self.customs_amount =
      if value.is_a?(String)
         value.gsub(',', '.')
       else
         value
       end
  end

  # Set shipping date to today for past shipping dates
  def adjust_past_shipping_date
    self.shipping_date = [shipping_date, Date.today].max if shipping_date
  end

  def upsert_note!(creator, *args)
    note = nil

    transaction do
      note = Note.find_or_initialize_by(creator: creator, linked_object: self)
      note.assign_attributes(*args)
      note.save!

      EventManager.handle_event(event: ::Shipment::Events::CREATE_OR_UPDATE_SHIPMENT_NOTE, event_arguments: { shipment_id: id })
    end

    note
  end

  def total_weight
    package_dimensions.total_weight
  end

  def as_goods
    if goods_id?
      goods
    else
      as_goods_struct
    end
  end

  def goods_lines
    goods.lines if goods
  end

  private

  def as_goods_struct
    goods_attrs = {
      volume_type: package_dimensions.volume_type,
      dimension_unit: "cm",
      weight_unit: "kg",
      lines: as_goods_line_structs,
    }

    ShipmentGoodsStruct.new(*goods_attrs.values_at(*ShipmentGoodsStruct.members))
  end

  def as_goods_line_structs
    grouped_dimensions = package_dimensions.dimensions.group_by(&:equality_key)

    grouped_dimensions.map do |_, dims|
      line_attrs = {
        quantity: dims.count,
        goods_identifier: "CLL",
        length: dims[0].length,
        width: dims[0].width,
        height: dims[0].height,
        weight: dims[0].weight,
        volume_weight: dims[0].volume_weight,
        non_stackable: false,
      }

      GoodsLineStruct.new(*line_attrs.values_at(*GoodsLineStruct.members))
    end
  end

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
        return grouped.each_pair.map {|key, val| GroupSortFilter::DataGroup.new(name: key, reference: Shipment::States, data: val) }
      when CargofluxConstants::Group::CUSTOMER_TYPE
        # company id - used for finding carrier products
        company_id = group.data

        # company carrier products - i.e. direct customers book on these
        carrier_products = CarrierProduct.find_all_company_carrier_products(company_id: company_id)
        carrier_product_ids = carrier_products.map {|cp| cp.id }
        shipments_direct_customers = carrier_product_ids.size > 0 ? self.where("shipments.carrier_product_id in (#{carrier_product_ids.join(',')})") : []

        # company ids for direct company customers
        entity_relations = EntityRelation.find_relations(from_type: Company, from_id: company_id, to_type: Company, relation_type: EntityRelation::RelationTypes::DIRECT_COMPANY)
        company_ids = entity_relations.map {|er| er.to_reference_id }
        shipments_direct_companies = company_ids.size > 0 ? self.where("shipments.company_id in (#{company_ids.join(',')})") : []

        # carrier product shipments - it's the rest minus the two other groups
        shipments_carrier_product_customers = self
        shipments_carrier_product_customers = shipments_carrier_product_customers.where("shipments.carrier_product_id not in (#{carrier_product_ids.join(',')})") if carrier_product_ids.size > 0
        shipments_carrier_product_customers = shipments_carrier_product_customers.where("shipments.company_id not in (#{company_ids.join(',')})") if company_ids.size > 0

        groups = []
        groups << GroupSortFilter::DataGroup.new(name: "Direct customers", reference: "Direct customers", data: shipments_direct_customers) if shipments_direct_customers.size > 0
        groups << GroupSortFilter::DataGroup.new(name: "Direct companies", reference: "Direct companies", data: shipments_direct_companies) if shipments_direct_companies.size > 0
        groups << GroupSortFilter::DataGroup.new(name: "Carrier product customers", reference: "Carrier product customers", data: shipments_carrier_product_customers) if shipments_carrier_product_customers.size > 0

        return groups
      when CargofluxConstants::Group::COMPANY
        grouped = self.all.group_by {|s| s.company }
        groups = grouped.each_pair.map {|key, val| GroupSortFilter::DataGroup.new(name: key.name, reference: key, data: val) }
        sorted_groups = groups.sort {|g1, g2| g1.name <=> g2.name }
        return sorted_groups
    end
  end

  # Sort current result set
  #
  # @param sort [String] Sorting specifier
  def self.apply_sort(sort)
    case sort
      when CargofluxConstants::Sort::DATE_ASC
        self.order("shipments.shipping_date ASC, shipments.id ASC")
      when CargofluxConstants::Sort::DATE_DESC
        self.order("shipments.shipping_date DESC, shipments.id DESC")
      else
        self
    end
  end

  # Applies one or more filters to the current result set
  #
  # @param filters [Array<GroupSortFilter::Filter>] An array of filters to be applied
  def self.apply_filters(filters: nil, current_company_id: nil)
    result = self
    Rails.logger.debug filters

    filters.each do |filter|
      case filter.filter
        when CargofluxConstants::Filter::CUSTOMER_ID
          result = result.find_customer_shipments(customer_id: filter.filter_value)
        when CargofluxConstants::Filter::SHIPMENT_ID
          result = result.find(filter.filter_value)
        when CargofluxConstants::Filter::STATE
          result = result.find_shipments_in_state(state: filter.filter_value)
        when CargofluxConstants::Filter::CARRIER_ID
          result = result.find_shipments_with_carrier_id(carrier_id: filter.filter_value)
        when CargofluxConstants::Filter::NOT_IN_MANIFEST
          result = result.find_shipments_not_in_manifest
        when CargofluxConstants::Filter::NOT_IN_REPORT
          result = result.find_shipments_not_in_report_in_company(company_id: filter.filter_value)
        when CargofluxConstants::Filter::HAS_BEEN_BOOKED
          result = result.find_shipments_that_have_been_booked
        when CargofluxConstants::Filter::HAS_BEEN_BOOKED_OR_IN_STATE
          if filter.filter_value == CargofluxConstants::Filter::NOT_CANCELED
            result = result.find_shipments_that_have_been_booked
          else
            result = result.find_shipments_in_state(state: filter.filter_value)
          end
        when CargofluxConstants::Filter::NOT_CANCELED
          result = result.find_shipments_not_canceled
        when CargofluxConstants::Filter::CUSTOMER_TYPE
          company_id    = filter.filter_value[:company_id]
          customer_type = filter.filter_value[:customer_type]
          result = result.find_shipments_with_customer_type(company_id: company_id, customer_type: customer_type)
        when CargofluxConstants::Filter::COMPANY_ID
          company_id  = filter.filter_value
          result      = result.find_shipments_sold_to_company(company_id: current_company_id, customer_company_id: company_id)

        when CargofluxConstants::Filter::RANGE_START
          date   = filter.filter_value

          Rails.logger.debug date
          result = result.find_shipments_after_date(date: date)

        when CargofluxConstants::Filter::RANGE_END
          date   = filter.filter_value

          Rails.logger.debug date
          result = result.find_shipments_before_date(date: date)
      end
    end

    return result
  end

  def update_state(new_state: nil, event_type: nil, description: nil, errors: [], linked_object: nil)
    should_clear_errors = self.state == Shipment::States::PROBLEM && new_state != Shipment::States::CANCELLED

    Shipment.transaction do
      self.assign_attributes(state: new_state)
      self.assign_attributes(shipment_errors: errors) if errors.present?
      self.assign_attributes(shipment_errors: []) if should_clear_errors

      changes = self.changes
      create_event(event_type: event_type, event_changes: changes, description: description, linked_object: linked_object)
      self.save!
    end
  end

  def create_event(event_type: nil, event_changes: nil, description: nil, linked_object: nil)
    Shipment.transaction do
      event_data = {
        reference_id:   self.id,
        reference_type: self.class.to_s,
        event_type:     event_type,
        event_changes:  event_changes,
        description:    description,
      }

      if !linked_object.nil?
        event_data[:linked_object_id]   = linked_object.id
        event_data[:linked_object_type] = linked_object.class.to_s
      end

      logger.debug("EVENT CHANGES: " + event_changes.inspect)
      self.events << Event.create_event(company_id: self.company_id, customer_id: self.customer_id, event_data: event_data)
      save!
    end
  end

end
