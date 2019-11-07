class RemoveCustomerRecordingMigrationFlags < ActiveRecord::Migration
  def change
    remove_column :customers, :dmig_crecording, :boolean
    remove_column :entity_relations, :dmig_crecording, :boolean
    remove_column :customer_billing_configurations, :dmig_crecording, :boolean
  end
end
