class Note < ActiveRecord::Base
  belongs_to :creator, polymorphic: true
  belongs_to :linked_object, polymorphic: true

  class << self

    def build_note(creator_id: nil, creator_type: nil, linked_object_id: nil, linked_object_type: nil, text: nil)
      note = self.new(
        creator_id:         creator_id,
        creator_type:       creator_type,
        linked_object_id:   linked_object_id,
        linked_object_type: linked_object_type,
        text:               text
      )

      return note
    end

    def create_note(creator_id: nil, creator_type: nil, linked_object_id: nil, linked_object_type: nil, text: nil)
      note = self.build_note(creator_id: creator_id, creator_type: creator_type, linked_object_id: linked_object_id, linked_object_type: linked_object_type, text: text)
      note.save!

      return note
    end

    def update_note(note_id: nil, creator_id: nil, creator_type: nil, text: nil)
      note = self.where(id: note_id, creator_id: creator_id, creator_type: creator_type).first
      note.text = text
      note.save!

      return note
    end

    def create_or_update_note(creator_id: nil, creator_type: nil, linked_object_id: nil, linked_object_type: nil, text: nil)
      note = self.where(creator_id: creator_id, creator_type: creator_type, linked_object_id: linked_object_id, linked_object_type: linked_object_type).first

      if note.present?
        note = self.update_note(note_id: note.id, creator_id: creator_id, creator_type: creator_type, text: text)
      else
        note = self.create_note(creator_id: creator_id, creator_type: creator_type, linked_object_id: linked_object_id, linked_object_type: linked_object_type, text: text)
      end

      return note
    end

    # Custom finders
    #

    def find_company_shipment_note(company_id: nil, shipment_id: nil)
      self.where(creator_id: company_id, creator_type: Company.to_s, linked_object_id: shipment_id, linked_object_type: Shipment.to_s).first
    end

    def find_customer_shipment_note(customer_id: nil, shipment_id: nil)
      self.where(creator_id: customer_id, creator_type: Customer.to_s, linked_object_id: shipment_id, linked_object_type: Shipment.to_s).first
    end

  end


end
