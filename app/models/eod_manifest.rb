class EODManifest < ActiveRecord::Base
  belongs_to :owner, polymorphic: true, required: true
  belongs_to :created_by, class_name: "User"

  has_many :shipment_associations, foreign_key: "manifest_id"
  has_many :shipments, through: :shipment_associations

  attr_accessor :bulk_insert_shipment_ids

  validates :owner_scoped_id, presence: true

  after_create :insert_shipment_ids_in_bulk

  def number_of_shipments
    shipments.count
  end

  def number_of_packages
    shipments.sum(:number_of_packages)
  end

  def total_weight
    shipments.to_a.sum(&:total_weight)
  end

  private

  def insert_shipment_ids_in_bulk
    rows =
      Array(bulk_insert_shipment_ids)
      .reject(&:blank?)
      .map { |shipment_id| { manifest_id: id, shipment_id: shipment_id } }

    bulk_insertion = BulkInsertion.new(rows, column_names: [:manifest_id, :shipment_id], model_class: ShipmentAssociation, returning: false)
    bulk_insertion.perform!
  end

  class ShipmentAssociation < ActiveRecord::Base
    self.table_name = "eod_manifest_shipments"

    belongs_to :manifest, required: true, class_name: "EODManifest"
    belongs_to :shipment, required: true
  end
end
