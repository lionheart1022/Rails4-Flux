class CompaniesAddInfoEmail < ActiveRecord::Migration
  def change
    add_column(:companies, :info_email, :string)
  end
end
