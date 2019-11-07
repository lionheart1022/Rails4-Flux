class SetCompanyIdNullSettingInCustomerImport < ActiveRecord::Migration
  def change
    change_column_null :customer_imports, :company_id, false
  end
end
