class CreateCustomerRecordings < ActiveRecord::Migration
  def change
    create_table :customer_recordings do |t|
      t.timestamps null: false
      t.references :company, null: false
      t.integer :company_scoped_id
      t.string :type, null: false
      t.string :customer_name
      t.string :normalized_customer_name
      t.references :recordable, null: false, polymorphic: true
      t.datetime :disabled_at
    end

    add_column :customers, :dmig_crecording, :boolean
    add_column :entity_relations, :dmig_crecording, :boolean

    change_table :customer_billing_configurations do |t|
      t.references :customer_recording # Will be set to `null: false` after data migration has been performed
      t.boolean :dmig_crecording
    end
  end
end
