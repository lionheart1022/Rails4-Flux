class AddReferenceIndexOnEvents < ActiveRecord::Migration
  def change
    add_index "events", ["reference_type", "reference_id"]
  end
end
