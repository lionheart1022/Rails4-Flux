class CreatePackageFeedback < ActiveRecord::Migration
  def change
    create_table :carrier_feedback_files do |t|
      t.datetime :created_at, null: false
      t.references :company, null: false
      t.string :type
      t.binary :file_contents
      t.references :file_uploaded_by
      t.string :original_filename
      t.string :s3_object_key
      t.datetime :parsed_at
    end

    add_column :packages, :type, :string

    create_table :package_updates do |t|
      t.datetime :created_at, null: false
      t.references :feedback_file
      t.references :package
      t.references :package_recording
      t.json :metadata
    end
  end
end
