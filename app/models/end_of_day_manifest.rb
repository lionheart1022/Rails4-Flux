# `EndOfDayManifest` and `EODManifest` should in the future be combined as they're modelling the same thing.
# `EndOfDayManifest` is associated with a `Customer` while `EODManifest` is associated with a `Company`.
# Actually `EODManifest` can be associated with anything because the `owner` attribute is polymorphic.
#
# TODO: Migrate `EndOfDayManifest` to `EODManifest` so we end up just having `EODManifest`.
class EndOfDayManifest < ActiveRecord::Base
  attr_accessor :shipment_filter_form
  attr_accessor :raw_shipment_ids

  belongs_to :customer

  has_and_belongs_to_many :shipments

  after_create :whitelist_and_insert_shipment_ids, if: -> { raw_shipment_ids.present? }

  # PUBLIC API
  class << self

    def create_end_of_day_manifest(company_id: nil, customer_id: nil, shipment_ids: nil, id_generator: nil)
      end_of_day_manifest = nil
      EndOfDayManifest.transaction do
        end_of_day_manifest = self.new({
          company_id:             company_id,
          customer_id:            customer_id,
          end_of_day_manifest_id: id_generator.update_next_end_of_day_manifest_id,
          shipment_ids:           shipment_ids,
        })

        end_of_day_manifest.save!
      end

      return end_of_day_manifest
    end

    # Finders

    def find_customer_end_of_day_manifests(customer_id: nil)
      self.where(customer_id: customer_id)
    end

    def find_customer_end_of_day_manifest(customer_id: nil, end_of_day_manifest_id: nil)
      self.where(customer_id: customer_id).where(id: end_of_day_manifest_id).first
    end

    def find_customer_shipments_not_in_manifest(company_id: nil, customer_id: nil)
      Shipment.find_company_shipments(company_id: company_id).find_customer_shipments(customer_id: customer_id).find_shipments_not_in_manifest
    end
  end

  # INSTANCE API
  def number_of_shipments
    self.shipments.count
  end

  def number_of_packages
    self.shipments.sum(:number_of_packages)
  end

  def total_weight
    shipments.to_a.sum(&:total_weight)
  end

  def shipments_by_filter
    if shipment_filter_form
      f = shipment_filter
      f.perform!

      f
        .shipments
        .includes(:carrier_product, :customer, :recipient, :asset_awb)
        .order(shipping_date: :desc, id: :desc)
    else
      Shipment.none
    end
  end

  def shipment_filter
    filter = ShipmentFilter.new(
      current_company: customer.company,
      current_customer: customer,
      base_relation: base_shipment_relation,
    )

    filter.carrier_id = shipment_filter_form.carrier_id
    filter.state = shipment_filter_form.shipment_state
    filter.deprecated_manifest_inclusion = shipment_filter_form.manifest_inclusion

    filter
  end

  def base_shipment_relation
    if customer
      Shipment.find_company_shipments(company_id: customer.company_id).find_customer_shipments(customer_id: customer_id)
    else
      Shipment.none
    end
  end

  private

  def whitelist_and_insert_shipment_ids
    self.shipment_ids = base_shipment_relation.where(id: Array(raw_shipment_ids).reject(&:blank?)).pluck(:id)

    true
  end

  class ShipmentFilterForm
    include ActiveModel::Model

    attr_accessor :carrier_id
    attr_accessor :manifest_inclusion
    attr_accessor :shipment_state

    def initialize(params = {})
      self.manifest_inclusion = "not_in_manifest"
      self.shipment_state = CargofluxConstants::Filter::NOT_CANCELED

      super(params)
    end

    def manifest_inclusion_options
      [
        ["Shipments not in a manifest", "not_in_manifest"],
        ["All shipments", nil],
      ]
    end

    def state_options
      [
        ["Shipments booked and not cancelled", CargofluxConstants::Filter::NOT_CANCELED],
        ["Created", Shipment::States::CREATED],
        ["Booked", Shipment::States::BOOKED],
        ["In transit", Shipment::States::IN_TRANSIT],
        ["Problem", Shipment::States::PROBLEM],
        ["All states", nil],
      ]
    end
  end
end
