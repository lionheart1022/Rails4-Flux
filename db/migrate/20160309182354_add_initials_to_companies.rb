class AddInitialsToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :initials, :string
    add_index :companies, :initials, unique: true
  end
end
