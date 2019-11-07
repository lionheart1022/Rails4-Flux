class AddCompanyColorTheme < ActiveRecord::Migration
  def change
    add_column :companies, :primary_brand_color, :string
  end
end
