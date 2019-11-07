class ChangeNullSettingsForBillingConfiguration < ActiveRecord::Migration
  def change
    change_column_null :customer_billing_configurations, :customer_id, true
    change_column_null :customer_billing_configurations, :customer_recording_id, false
  end
end
