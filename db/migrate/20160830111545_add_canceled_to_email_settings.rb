class AddCanceledToEmailSettings < ActiveRecord::Migration
  def change
    add_column :email_settings, :rfq_cancel, :boolean, default: true
  end
end
