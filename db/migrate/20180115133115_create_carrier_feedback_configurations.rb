class CreateCarrierFeedbackConfigurations < ActiveRecord::Migration
  def change
    create_table :carrier_feedback_configurations do |t|
      t.timestamps null: false
      t.references :company, null: false
      t.string :type
      t.references :latest_file
      t.json :credentials
      t.json :account_details
      t.json :file_data
    end

    change_table :carrier_feedback_files do |t|
      t.references :configuration
    end

    create_table :ftp_directories do |t|
      t.timestamps null: false
      t.references :owner, polymorphic: true, null: false
      t.string :dirname
    end

    create_table :ftp_files do |t|
      t.timestamps null: false
      t.references :directory, null: false
      t.string :filename
    end
  end
end
