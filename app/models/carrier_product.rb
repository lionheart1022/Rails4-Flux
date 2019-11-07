require 'price_document_v1'
require 'tnt_price_document'
require 'dhl_price_document'
require 'ups_price_document'
require 'post_dk_price_document'

class CarrierProduct < ActiveRecord::Base
  attr_reader :basis

  belongs_to :carrier
  belongs_to :carrier_product
  belongs_to :company
  has_one    :carrier_product_price, dependent: :destroy
  has_many   :customer_carrier_products
  has_one    :sales_price, as: :reference
  has_many :rules, class_name: "CarrierProductRule"

  serialize :credentials, Hash
  serialize :options, CarrierProductOptions

  validates :name, presence: true, uniqueness: { case_sensitive: false, scope: [:company_id, :carrier_id, :carrier_product_id] }
  validates :product_code, uniqueness: { case_sensitive: false, scope: [:company_id], allow_nil: true }

  validate :custom_label_valid_does_not_override

  delegate :margin_percentage, to: :sales_price
  delegate :basis, to: :options
  delegate :weight?, to: :options
  delegate :distance?, to: :options

  delegate :volume_weight_type, to: :options
  delegate :volume_weight?, to: :options
  delegate :loading_meter?, to: :options

  accepts_nested_attributes_for :sales_price

  class QueryError < StandardError; end

  module Errors
    PARENT_NOT_FOUND_IN_CACHE = 'parent_not_found_in_cache'
  end

  module ProductTypes
    COURIER = 'courier'
    COURIER_EXPRESS = 'courier_express'
  end

  module TrackTraceMethods
    NONE      = 'none'
    TRACKLOAD = 'trackload'
    TRACKTRACE_CONTAINER = 'tracktrace_container'
  end

  module States
    UNLOCKED_FOR_CONFIGURING  = 'unlocked_for_configuring'
    LOCKED_FOR_CONFIGURING    = 'locked_for_configuring'
  end

  # PUBLIC API

  scope :for_company, ->(company_id) { where(:company_id => company_id) }

  class << self

    def build_carrier_product(company_id: nil, carrier_id: nil, name: nil, custom_label: nil, product_type: nil, product_code: nil, options: nil, volume_weight_factor: nil, custom_volume_weight_enabled: nil)
      carrier_product_options = CarrierProductOptions.new(options)

      carrier_product = self.new({
        company_id:             company_id,
        carrier_id:             carrier_id,
        name:                   name,
        custom_label:           custom_label,
        credentials:            {},
        state:                  CarrierProduct::States::UNLOCKED_FOR_CONFIGURING,
        product_type:           product_type,
        product_code:           product_code,
        volume_weight_factor: volume_weight_factor,
        custom_volume_weight_enabled: custom_volume_weight_enabled,
        options:                carrier_product_options
      })

      return carrier_product
    rescue => e
      raise ModelError.new(e.message, carrier_product)
    end

    def create_carrier_product(company_id: nil, carrier_id: nil, name: nil, custom_label: nil, product_type: nil, product_code: nil, options: nil)
      carrier_product = self.build_carrier_product(
        company_id: company_id,
        carrier_id: carrier_id,
        name: name,
        custom_label: custom_label,
        product_type: product_type,
        product_code: product_code,
        options: options
      )

      carrier_product.sales_price = SalesPrice.build_sales_price
      carrier_product.save!

      return carrier_product
    rescue => e
      raise ModelError.new(e.message, carrier_product)
    end

    def create_carrier_product_from_existing_product(company_id: nil, carrier_id: nil, existing_product_id: nil, is_locked: nil)
      existing_carrier_product = CarrierProduct.find(existing_product_id)
      company = existing_carrier_product.company
      product_code = existing_carrier_product.first_unlocked_product_in_owner_chain.product_code

      if product_code.present? && company.initials.present?
        product_code = "#{company.initials}_#{product_code}"
      else
        product_code = nil
      end

      carrier_product = self.new({
        company_id:         company_id,
        carrier_id:         carrier_id,
        carrier_product_id: existing_product_id,
        type:               existing_carrier_product.type,
        product_code:       product_code,
        credentials:        {},
        state:              is_locked ? CarrierProduct::States::LOCKED_FOR_CONFIGURING : CarrierProduct::States::UNLOCKED_FOR_CONFIGURING
      })

      carrier_product.sales_price = SalesPrice.build_sales_price
      carrier_product.save!

      return carrier_product
    end

    # Finders
    #

    # This is only to check existence - this should be scoped under customer (use 'find_enabled_customer_carrier_product_from_product_code' instead)
    #
    def find_carrier_product_from_product_code(product_code: nil)
      product_code = product_code.downcase

      self.where('carrier_products.product_code IS NOT null AND lower(carrier_products.product_code) = ?', product_code).first
    end

    def find_enabled_customer_carrier_product_from_product_code(customer_id: nil, product_code: nil)
      product_code = product_code.downcase

      self
        .joins('LEFT JOIN customer_carrier_products ccp ON ccp.carrier_product_id = carrier_products.id')
        .where('carrier_products.id IN
                  (WITH RECURSIVE tree(id, parent_id, product_code) AS (
                     SELECT cp.id, cp.carrier_product_id, cp.product_code FROM carrier_products cp
                     WHERE lower(cp.product_code) = ? AND cp.is_disabled = false
                   UNION ALL
                     SELECT cp.id, cp.carrier_product_id, cp.product_code
                     FROM carrier_products cp JOIN tree ON cp.carrier_product_id = tree.id
                     WHERE cp.is_disabled = false)
                    SELECT id FROM tree)', product_code)
        .where('ccp.customer_id = ? AND ccp.is_disabled = false', customer_id)
        .first
    end

    def find_company_carrier_product(company_id: nil, carrier_product_id: nil)
      self.where(company_id: company_id).where(id: carrier_product_id).first
    end

    def find_enabled_company_carrier_product(company_id: nil, carrier_product_id: nil)
      self.where(company_id: company_id, id: carrier_product_id, is_disabled: false).first
    end

    def find_enabled_company_carrier_products(company_id: nil, carrier_id: nil)
      self.where(company_id: company_id, carrier_id: carrier_id, is_disabled: false)
    end

    def find_company_carrier_products(company_id: nil, carrier_id: nil)
      self.where(company_id: company_id).where(carrier_id: carrier_id)
    end

    def find_all_company_carrier_products(company_id: nil)
      self.where(company_id: company_id)
    end

    def find_all_enabled_company_carrier_products(company_id: nil)
      self
        .where('carrier_products.id IN
                  (WITH RECURSIVE tree(id, parent_id) AS (
                     SELECT cp.id, cp.carrier_product_id
                     FROM carrier_products cp
                     LEFT JOIN carriers c ON cp.carrier_id = c.id
                     WHERE NOT c.disabled AND c.company_id = ?
                   UNION ALL
                     SELECT cp.id, cp.carrier_product_id
                     FROM carrier_products cp
                     LEFT JOIN carriers c ON cp.carrier_id = c.id
                     JOIN tree ON cp.carrier_product_id = tree.id
                     WHERE NOT c.disabled AND c.company_id = ?)
                    SELECT id FROM tree)', company_id, company_id)
        .where(company_id: company_id)
    end

    def find_customer_carrier_product(customer_id: nil)
      self.where(customer_id: customer_id).first
    end

    def find_carrier_products_from_ids(carrier_product_ids: nil)
      self.where(id: carrier_product_ids)
    end

    def find_carrier_products_from_carrier(company_id: nil, carrier_id: nil)
      self.where(company_id: company_id, carrier_id: carrier_id)
    end

    def find_carrier_products_sold_to_company(owner_company_id: nil, customer_company_id: nil)
      self.includes(:carrier_product).where(company_id: customer_company_id).select{ |cp| cp.carrier_product.try(:company_id) == owner_company_id }
    end

    def find_all_top_level_ancestors
      self.where('carrier_product_id IS NULL')
    end

    def find_top_level_ancestors_from_ids(carrier_product_ids: [])
      self.where('carrier_products.id IN
                  (WITH RECURSIVE tree(id, parent_id) AS (
                     SELECT cp.id, cp.carrier_product_id FROM carrier_products cp
                     WHERE cp.id IN (?)
                   UNION ALL
                     SELECT cp.id, cp.carrier_product_id FROM carrier_products cp JOIN tree ON cp.id = tree.parent_id)
                    SELECT id FROM tree)', carrier_product_ids)
    end

    def find_unlocked_top_level_ancestors_from_ids(carrier_product_ids: [])
      self.find_top_level_ancestors_from_ids(carrier_product_ids: carrier_product_ids)
    end

    def find_carrier_product_chain(carrier_product_id: nil)
      unordered_carrier_products = self.where('carrier_products.id IN
                  (WITH RECURSIVE tree(id, parent_id) AS (
                     SELECT cp.id, cp.carrier_product_id FROM carrier_products cp
                     WHERE cp.id = ?
                   UNION ALL
                     SELECT cp.id, cp.carrier_product_id FROM carrier_products cp JOIN tree ON cp.id = tree.parent_id)
                    SELECT id FROM tree)', carrier_product_id)

      # sort carrier products
      sorted_carrier_products = []

      # Find top carrier product
      unordered_carrier_products.each do |cp|
        if cp.id == carrier_product_id
          sorted_carrier_products << cp
          break
        end
      end

      # Sort the rest of the carrier products (root carrier product will be last in array)
      while sorted_carrier_products.size < unordered_carrier_products.size
        unordered_carrier_products.each do |cp|
          if cp.id == sorted_carrier_products.last.carrier_product_id
            sorted_carrier_products << cp
            break
          end
        end
      end

      sorted_carrier_products
    end

    # Retrieves the top level product from "carrier products" to avoud N + 1 queries
    #
    def top_level_ancestor(carrier_products, test_cp)
      return test_cp if test_cp.carrier_product_id.nil?

      parent = carrier_products.detect { |cp| cp.id == test_cp.carrier_product_id }
      raise QueryError.new("Carrier products parent was not found in supplied carrier products") if parent.nil?

      self.top_level_ancestor(carrier_products, parent)
    end

    def find_for_rfq(id)
      where(type: nil, carrier_product_id: nil) # Only custom and non-chain products are allowed for RFQs
        .find(id)
    end

    # Pricing type is only defined on top-level product, so we want to cache the results to avoid N + 1 queries
    #
    def product_type(carrier_products, test_cp)
      parent_cp = carrier_products.find { |cp| cp.id == test_cp.carrier_product_id }
      return test_cp.product_type if parent_cp.blank?

      self.product_type(carrier_products, parent_cp)
    end

    def get_options(carrier_products, test_cp)
      parent_cp = carrier_products.find { |cp| cp.id == test_cp.carrier_product_id }
      return test_cp.options if parent_cp.blank?

      self.get_options(carrier_products, parent_cp)
    end

    def weight_based_product?(carrier_products, test_cp)
      self.get_options(carrier_products, test_cp).weight?
    end

    def distance_based_product?(carrier_products, test_cp)
      self.get_options(carrier_products, test_cp).distance?
    end

    def product_types_values
      constants = ProductTypes.constants.map &:to_s
      constants.map { |constant| ProductTypes.const_get(constant) }
    end

  end

  # INSTANCE API

  def price_document_class
    PriceDocumentV1
  end

  def customer_price_for_shipment(customer_id: nil, **args)
    calculated_prices = calculate_price_chain_for_shipment(customer_id: customer_id, **args)
    price = calculated_prices.last

    return price if price.present? && price.buyer_id == customer_id && price.buyer_type == Customer.to_s
  end

  def calculate_price_chain_for_shipment(**args)
    ShipmentPriceCalculation.calculate(carrier_product: self, **args)
  end

  # checks if carrier product references the price document from another
  #
  def references_price_document?
    self.is_locked_for_configuring?
  end

  # recursively looks for succesful carrier product price on owner carrier products
  #
  def referenced_carrier_product_price
    parent = self.carrier_product
    until parent.nil?
      return parent.carrier_product_price if parent.carrier_product_price.try('successful?')
      parent = parent.carrier_product
    end
    return nil
  end

  # returns price document if one is specified
  #
  def price_document
    self.carrier_product_price.try(:price_document)
  end

  def name
    # if referencing a predefined carrier product then name is taken from there
    if (self.carrier_product.present? && read_attribute(:name).nil?)
      name = self.carrier_product.name
    else
      name = read_attribute(:name)
    end

    name
  end

  def transit_time
    if carrier_product.present? && read_attribute(:transit_time).nil?
      carrier_product.transit_time
    else
      read_attribute(:transit_time)
    end
  end

  def transit_time?
    transit_time.present?
  end

  def options
    # if referencing a predefined carrier product then name is taken from there
    if (self.carrier_product.present? && self.is_locked_for_configuring?)
      self.carrier_product.options
    else
      read_attribute(:options)
    end
  end

  def closest_track_trace_method
    if carrier_product.present? && read_attribute(:track_trace_method).nil?
      carrier_product.track_trace_method
    else
      read_attribute(:track_trace_method)
    end
  end

  def product_code
    # if referencing a predefined carrier product then name is taken from there
    if (self.carrier_product.present? && read_attribute(:product_code).nil?)
      self.carrier_product.product_code
    else
      read_attribute(:product_code)
    end
  end

  def custom_volume_weight_enabled
    if (self.carrier_product.present? && read_attribute(:custom_volume_weight_enabled).nil?)
      self.carrier_product.custom_volume_weight_enabled
    else
      read_attribute(:custom_volume_weight_enabled)
    end
  end

  def custom_label
    cp = self.first_unlocked_product_in_owner_chain
    cp && cp.read_attribute(:custom_label)
  end

  def volume_weight_factor
    if (self.carrier_product.present? && read_attribute(:volume_weight_factor).nil?)
      self.carrier_product.volume_weight_factor
    else
      read_attribute(:volume_weight_factor)
    end
  end

  def product_type
    # if referencing a predefined carrier product then name is taken from there
    if (self.carrier_product.present? && read_attribute(:product_type).nil?)
      self.carrier_product.product_type
    else
      read_attribute(:product_type)
    end
  end

  def weight_based_product?
    self.weight?
  end

  def distance_based_product?
    self.distance?
  end

  def is_locked_for_editing?
    # if referencing a parent carrier product then this record is locked for editing
    self.carrier_product.nil? ? false : true
  end

  def is_locked_for_configuring?
    self.state == CarrierProduct::States::LOCKED_FOR_CONFIGURING
  end

  def can_enable_tracking?
    self.supports_automatic_tracking? && !self.is_locked_for_configuring?
  end

  # Determines whether any child carrier products of this product should be marked as configured
  def should_mark_children_as_configured
    !self.credentials.blank? || (self.custom_volume_weight_enabled == true) || (!self.track_trace_method.nil? && (self.track_trace_method != CarrierProduct::TrackTraceMethods::NONE))
  end

  def owner_carrier_product
    self.carrier_product.nil? ? self : self.carrier_product
  end

  def suffixed_name
    owner = self.first_unlocked_product_in_owner_chain
    string = "#{owner.name}"
    string = "#{string} (#{owner.company.initials})" if owner.company.initials

    string
  end

  def cached_suffix_name(carrier_products: [], companies: [])
    product = self.cached_owner_carrier_product(carrier_products: carrier_products)
    company = companies.detect { |c| c.id == product.company_id }

    string = "#{product.name}"
    string = "#{string} (#{company.initials})" if company.initials
  end


  def owner_carrier_product_chain(include_self: false)
    if include_self
      self.carrier_product.nil? ? [self] : [self] + self.carrier_product.owner_carrier_product_chain(include_self: true)
    else
      self.carrier_product.nil? ? [] : self.carrier_product.owner_carrier_product_chain(include_self: true)
    end
  end

  def is_disabled?
    read_attribute(:is_disabled)
  end

  def track?
    self.automatic_tracking
  end

  # Credentials

  # Set the credentials for authenticating the carrier product
  #
  # The credentials are encrypted before setting them
  #
  # @param [Hash] credentials
  def set_credentials(credentials: nil)
    raise StandardError, 'credentials must be a hash' unless credentials.is_a?(Hash)

    password = ENV['CARRIER_PRODUCTS_ENCRYPTION_PASSWORD']
    encrypted_credentials = credentials.inject({}) do |hash, (key, value)|
      raise StandardError, "#{key.to_s.capitalize} must be specified" if value.blank? && !key.to_s.include?('test')

      hash[key] = AESCrypt.encrypt(value, password) if value.present?
      hash
    end

    self.credentials = encrypted_credentials
    self.save!
  end

  # Get the credentials for authenticating the carrier product
  #
  # If the current product is locked for configuring the credentials are sought in the owner chain.
  # The credentials are decrypted before being returned
  #
  # @return [Hash]
  def get_credentials
    password = ENV['CARRIER_PRODUCTS_ENCRYPTION_PASSWORD']

    encrypted_credentials = self.credentials
    if self.state == CarrierProduct::States::LOCKED_FOR_CONFIGURING
      configured_product = first_unlocked_product_in_owner_chain()
      if configured_product
        return configured_product.get_credentials
      else
        return {}
      end

    end

    credentials = encrypted_credentials.inject({}) do |hash, (key, value)|
      hash[key] = AESCrypt.decrypt(value, password)
      hash
    end

    return credentials
  end

  def first_unlocked_product_in_owner_chain
    owner_chain = self.owner_carrier_product_chain(include_self: true)
    configured_product = owner_chain.detect { |cp| cp.state == CarrierProduct::States::UNLOCKED_FOR_CONFIGURING }
  end

  def product_responsible
    self.first_unlocked_product_in_owner_chain.company
  end

  # Shipment country support

  # Indicates whether the carrier product can ship between the sender and destination countries specified
  #
  # @param sender_country_code [String]
  # @param destination_country_code [String]
  #
  # @return [Boolean]
  def supports_shipment_between_countries?(sender_country_code: nil, destination_country_code: nil)
    return false
  end

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    return true
  end

  def supports_test_mode?
    false
  end

  def supports_return_label?
    false
  end

  def supports_delivery_instructions?
    false
  end

  def supports_auto_pickup?
    false
  end

  def is_domestic_shipment?(sender_country_code: nil, destination_country_code: nil)
    return false if (sender_country_code.blank? || destination_country_code.blank?) # must specify both sender and destination countries
    return sender_country_code == destination_country_code # allow domestic shipments
  end

  def is_international_shipment?(sender_country_code: nil, destination_country_code: nil)
    return false if (sender_country_code.blank? || destination_country_code.blank?) # must specify both sender and destination countries
    return sender_country_code != destination_country_code # allow international shipments
  end

  def is_eu_shipment?(sender_country_code: nil, destination_country_code: nil)
    return false if sender_country_code.blank? || destination_country_code.blank?
    Country.find_country_by_alpha2(sender_country_code).try(:in_eu?) && Country.find_country_by_alpha2(destination_country_code).try(:in_eu?)
  end

  def is_non_eu_shipment?(sender_country_code: nil, destination_country_code: nil)
    return false if sender_country_code.blank? || destination_country_code.blank?
    !is_eu_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
  end

  def exchange_type_import=(value)
    self.exchange_type = value ? "import" : nil
  end

  def import?
    exchange_type == "import"
  end

  def custom_label?
    self.custom_label
  end

  protected 'is_domestic_shipment?', 'is_international_shipment?'

  def applied_volume_calculation(dimension: nil)
    case self.volume_weight_type
    when CarrierProductOptions::VolumeWeightTypes::VOLUME_WEIGHT
      self.volume_weight(dimension: dimension)
    when CarrierProductOptions::VolumeWeightTypes::LOADING_METER
      self.loading_meter(dimension: dimension)
    end
  end

  # Calculates the volume weight or loading meter for a package of certain dimensions
  #
  # @param dimension [PackageDimension] the dimensions from which to calculate the volume weight
  # @return [Float] The volume weight calculated for the specific product from the dimensions
  def volume_weight(dimension: nil)
    if self.custom_volume_weight_enabled && self.volume_weight_factor
      factor = self.volume_weight_factor
      volume_weight = Float((dimension.length * dimension.width * dimension.height)) / Float(factor)

      return volume_weight
    else
      return 0
    end
  end

  def loading_meter(dimension: nil)
    enabled = self.custom_volume_weight_enabled
    factor  = self.volume_weight_factor
    enabled && factor ? dimension.loading_meter(factor) : 0
  end

  # track and track interface

  def supports_track_and_trace?
    case closest_track_trace_method
    when CarrierProduct::TrackTraceMethods::TRACKLOAD, CarrierProduct::TrackTraceMethods::TRACKTRACE_CONTAINER
      true
    else
      false
    end
  end

  def track_and_trace_has_complex_view?
    case closest_track_trace_method
    when CarrierProduct::TrackTraceMethods::TRACKTRACE_CONTAINER
      true
    else
      false
    end
  end

  def track_and_trace_view
    case closest_track_trace_method
    when CarrierProduct::TrackTraceMethods::TRACKTRACE_CONTAINER
      "components/shared/carrier_products/track_trace_container"
    else
      nil
    end
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    case closest_track_trace_method
    when CarrierProduct::TrackTraceMethods::TRACKLOAD
      "http://www.trackload.com/cgi-bin/rapidtrk.cgi?MAWB=#{awb}"
    else
      nil
    end
  end

  # external awb asset links

  def external_awb_asset_url(external_awb_asset: nil)
    nil
  end

  # auto booking interface

  # Indicates whether the carrier product can automatically book shipments with the carrier
  #
  # @return [Boolean]
  def supports_shipment_auto_booking?
    return false
  end

  # Book shipment directly with carrier
  #
  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    nil
  end

  # Fetches new tracking information for shipment, updates state and creates event
  #
  def track_shipment(shipment: nil)
    nil
  end

  # Indicates whether the carrier product can retry getting the AWB document when it fails
  #
  # @return [Boolean]
  def supports_shipment_retry_awb_document?
    return false
  end

  # Indicates whether the carrier product can retry getting the consignment note when it fails
  #
  # @return [Boolean]
  def supports_shipment_retry_consignment_note
    return false
  end

  # Indicates whether shipments booked with the carrier product should be tracked automatically
  def supports_automatic_tracking?
    return false
  end

  # Retry fetching the awb document directly with carrier
  #
  def retry_awb_document(company_id: nil, shipment_id: nil)
    nil
  end

  # Retry fetching the consignment note directly with carrier
  #
  def retry_consignment_note(company_id: nil, shipment_id: nil)
    nil
  end

  # Indicates that the carrier product should be delivered when possible
  #
  def supports_auto_book_delivery?
    false
  end

  def supports_override_credentials?
    false
  end

  def override_credentials_class
    nil
  end

  def prebook_step?
    false
  end

  def perform_prebook_step(shipment)
    raise "Override in subclass"
  end

  # Indicates that the carrier product is custom
  #
  def custom?
    self.type.blank?
  end

  def chain?
    self.carrier_product_id.present?
  end

  def has_valid_price_document?
    carrier_product_price.try(:successful?)
  end

  def upload_carrier_product_price!(file:)
    price_document = ExcelToPriceDocumentParser.new.parse(price_document_class: price_document_class, filename: file.path)

    build_carrier_product_price unless carrier_product_price
    carrier_product_price.assign_attributes(price_document: price_document, state: price_document.state)
    carrier_product_price.save!
  end

  def bulk_update_surcharges(surcharges_attributes, current_user: nil)
    scoped_relation = SurchargeOnProduct.where(carrier_product: self)

    transaction do
      (surcharges_attributes || {}).each do |_key, surcharge_attrs|
        surcharge_id = surcharge_attrs.delete(:id)

        surcharge_for_product = scoped_relation.for_bulk_update(id: surcharge_id, parent_id: surcharge_attrs[:parent_id])
        surcharge_for_product.assign_attributes(surcharge_attrs)
        surcharge_for_product.created_by = current_user
        surcharge_for_product.carrier_product = self

        next if surcharge_for_product.invalid?

        if surcharge_for_product.like_parent?
          if surcharge_for_product.persisted?
            surcharge_for_product.destroy
          else
            true
          end
        else
          surcharge_for_product.surcharge.save!
          surcharge_for_product.save!
        end
      end
    end

    true
  end

  def list_all_surcharges
    return [] if carrier_id.nil? # A carrier product will always belong to a carrier but for some existing tests they do not, that's why we handle this special case

    carrier.list_all_surcharges
      .select do |surcharge_on_carrier|
        surcharge_on_carrier.persisted? && surcharge_on_carrier.enabled?
      end
      .map do |surcharge_on_carrier|
        surcharge_on_product = SurchargeOnProduct.find_or_initialize_by(parent: surcharge_on_carrier, carrier_product: self)
        surcharge_on_product.surcharge = surcharge_on_carrier.surcharge.dup if surcharge_on_product.new_record?
        surcharge_on_product
      end
  end

  def surcharges_to_apply
    list_all_surcharges
      .select do |surcharge_on_product|
        surcharge_on_product.enabled? && surcharge_on_product.parent.enabled?
      end
      .map do |surcharge_on_product|
        surcharge_on_product.persisted? ? surcharge_on_product.surcharge : surcharge_on_product.parent.surcharge
      end
  end

  def surcharges_to_apply_for_calculation(include_types: nil)
    surcharges_to_apply.select do |surcharge|
      if surcharge.default_surcharge?
        true
      elsif include_types.present?
        include_types.include?(surcharge.type)
      else
        false
      end
    end
  end

  def rules_with_filters_enabled?
    rules.any?(&:any_filters_enabled?)
  end

  def matches_rules?(**args)
    if rules.size > 0
      rules.any? do |rule|
        rule.match?(**args)
      end
    else
      true
    end
  end

  private

    def custom_label_valid_does_not_override
      if self.class.name != 'CarrierProduct' && self.custom_label
        errors.add(:custom_label, "You cannot override the default shipping label")
      end
    end
end
