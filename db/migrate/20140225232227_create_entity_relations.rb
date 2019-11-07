class CreateEntityRelations < ActiveRecord::Migration
  def change
    create_table :entity_relations do |t|
      t.integer :from_reference_id
      t.string  :from_reference_type
      t.integer :to_reference_id
      t.string  :to_reference_type
      t.string  :relation_type
      t.timestamps
    end
  end
end
