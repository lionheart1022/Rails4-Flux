class MigrateOldShipmentNotes < ActiveRecord::Migration
  def up
    shipments = Shipment.where('shipments.note IS NOT NULL')
    shipments.each do |shipment|
      text = shipment.note

      Note.create_note(creator_id: shipment.product_responsible.id, creator_type: Company.to_s, linked_object_id: shipment.id, linked_object_type: Shipment.to_s, text: text)
    end

    remove_column :shipments, :note
  end

  def down
    add_column :shipments, :note, :text

    Note.all.each do |note|
      shipment = Shipment.where(company_id: note.creator_id).first
      next unless shipment.present?

      shipment.note = note.text
      shipment.save!
    end

    Note.destroy_all
  end
end
