require "test_helper"

class CustomerImportPerformJobTest < ActiveJob::TestCase
  test "importing with invalid rows present" do
    customer_import = CustomerImport.new
    customer_import.build_company(name: "Test Company")
    customer_import.rows.build(field_data: { "company_name" => "C-A", "email" => nil, "address_1" => "C-A Road 1", "country_code" => "DK" })
    customer_import.save!

    perform_enqueued_jobs do
      CustomerImportPerformJob.perform_later(customer_import.id)
    end

    assert_performed_jobs 1
  end
end
