class EntityRelation < ActiveRecord::Base
  belongs_to :from_reference, polymorphic: true
  belongs_to :to_reference, polymorphic: true

  module RelationTypes
    ALL                       = 'all'
    DIRECT_COMPANY            = 'direct_company'
    CARRIER_PRODUCT_CUSTOMER  = 'carrier_product_customer'
  end

  class << self

    def find_relations(from_type: nil, from_id: nil, to_type: nil, relation_type: nil)
      case relation_type
        when EntityRelation::RelationTypes::ALL
          self.where("from_reference_id = ? and from_reference_type = ?", from_id, from_type.to_s).where("to_reference_type = ?", to_type.to_s)
        else
          self.where("from_reference_id = ? and from_reference_type = ?", from_id, from_type.to_s).where("to_reference_type = ?", to_type.to_s).where("relation_type = ?", relation_type)
      end
    end

    def find_carrier_product_customer_entity_relation(from_reference_id: nil, to_reference_id: nil)
      EntityRelation.where(
        from_reference_id: from_reference_id,
        from_reference_type: Company.to_s,
        to_reference_id: to_reference_id,
        to_reference_type: Company.to_s,
        relation_type: RelationTypes::CARRIER_PRODUCT_CUSTOMER).first
    end

  end

end
