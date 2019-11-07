class AddPackageUpdateFailureData < ActiveRecord::Migration
  def change
    change_table :package_updates do |t|
      t.datetime :failed_at
      t.string :failure_reason
      t.boolean :failure_handled
    end
  end
end
