class AddPickupNotificationsToEmailSettings < ActiveRecord::Migration
  def change
    add_column :email_settings, :pickup_create, :boolean, default: true
    add_column :email_settings, :pickup_book, :boolean, default: true
    add_column :email_settings, :pickup_pickup, :boolean, default: true
    add_column :email_settings, :pickup_problem, :boolean, default: true
    add_column :email_settings, :pickup_cancel, :boolean, default: true
    add_column :email_settings, :pickup_comment, :boolean, default: true
  end
end
