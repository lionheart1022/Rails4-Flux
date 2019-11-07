class ShipmentExport < ActiveRecord::Base
  belongs_to :shipment
  belongs_to :owner, :polymorphic => true

  class << self
    def mark_for_export!(owner:, shipment_id: nil)
      existing_record = find_by(owner: owner, shipment_id: shipment_id)

      if existing_record
        existing_record.update_attributes!(updated: true) if existing_record.exported?
        return existing_record
      end

      create!(owner: owner, shipment_id: shipment_id, exported: false, updated: false)
    end

    def set_company_exported(company_id: nil, shipment_ids: nil)
      self
        .where(owner_id: company_id, owner_type: Company.to_s, shipment_id: shipment_ids)
        .update_all(exported: true, updated: false)
    end
  end
end
