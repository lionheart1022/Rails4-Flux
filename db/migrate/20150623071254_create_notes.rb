class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.integer :creator_id
      t.string :creator_type
      t.integer :linked_object_id
      t.string :linked_object_type
      t.text :text

      t.timestamps
    end

    add_index :notes, [:linked_object_id, :linked_object_type, :creator_id, :creator_type], :unique => true, name: 'notes_index'
  end
end
