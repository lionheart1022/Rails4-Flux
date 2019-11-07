class AddRfqToEmailSettings < ActiveRecord::Migration
  def change
    add_column :email_settings, :rfq_create, :boolean, default: true
    add_column :email_settings, :rfq_propose, :boolean, default: true
    add_column :email_settings, :rfq_accept, :boolean, default: true
    add_column :email_settings, :rfq_decline, :boolean, default: true
    add_column :email_settings, :rfq_book, :boolean, default: true
  end
end
