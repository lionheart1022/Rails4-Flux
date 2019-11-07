class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.belongs_to  :company
      t.belongs_to  :customer
      t.string      :reference_type
      t.integer     :reference_id
      t.string      :event_type
      t.text        :description
      t.timestamps
    end
  end
end
