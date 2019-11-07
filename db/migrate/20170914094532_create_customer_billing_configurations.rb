class CreateCustomerBillingConfigurations < ActiveRecord::Migration
  def change
    create_table :customer_billing_configurations do |t|
      t.timestamps null: false
      t.datetime :disabled_at
      t.references :customer, null: false
      t.string :schedule_type, null: false
      t.json :schedule_params
      t.boolean :with_detailed_pricing, null: false, default: false
    end

    create_table :automated_report_requests do |t|
      t.timestamps null: false
      t.datetime :handled_at
      t.datetime :run_at
      t.references :parent, polymorphic: true, null: false
      t.json :parent_params
      t.references :report
    end
  end
end
