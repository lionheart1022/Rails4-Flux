class CreateTrackings < ActiveRecord::Migration
  def change
    create_table :trackings do |t|
      t.string :type
      t.string :status
      t.string :description
      t.date   :date

      t.timestamps
    end
  end
end
