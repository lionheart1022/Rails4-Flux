class CustomersMigrateScopedCompanyId < ActiveRecord::Migration
  def up
    Company.all.each do |company|
      company.customers.order(:id).each_with_index do |customer, idx|
        customer.customer_id = idx+1
        customer.save!
      end
      company.current_customer_id = company.customers.count
      company.save!
    end
  end
end
