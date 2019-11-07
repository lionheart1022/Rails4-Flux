class CreateEventsV2 < ActiveRecord::Migration
  def change
    create_table :events_v2 do |t|
      t.datetime :created_at, null: false
      t.string :type, null: false
      t.string :label, null: false
      t.references :eventable, polymorphic: true, null: false, index: true
      t.references :initiator, polymorphic: true
      t.string :custom_initiator_label
      t.text :description
    end

    create_table :ferry_booking_snapshots do |t|
      t.references :event, null: false
      t.boolean :initial_state, null: false, default: false
      t.json :current_state
      t.json :diff
    end
  end
end
