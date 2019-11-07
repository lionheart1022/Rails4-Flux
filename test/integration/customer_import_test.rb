require "test_helper"

class CustomerImportIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "TEST-A", domain: "test-a.example.com")
    @user_password = "testingpass"
    @user = User.create!(company_id: @company.id, email: "user@example.com", password: @user_password, is_admin: true, confirmed_at: Time.now)
  end

  test "import file gets parsed" do
    sign_in

    import_file = Tempfile.new(["customer-import", ".xlsx"], Rails.root.join("tmp"))

    workbook = WriteXLSX.new(import_file.path)
    worksheet = workbook.add_worksheet
    worksheet.write_col("A1", [
      ["company_name", "email",           "address_1",  "country_code"],
      ["C-A",          "c-a@example.com", "C-A Road 1", "DK"          ],
      ["C-B",          "c-b@example.com", "C-B Road 1", "DK"          ],
      ["C-C",          "c-c@example.com", "C-C Road 1", "DK"          ],
    ])
    workbook.close

    begin
      post "/companies/customer_imports/bg", "customer_import[file]" => Rack::Test::UploadedFile.new(import_file.path)
    ensure
      import_file.close
      import_file.unlink
    end

    follow_redirect!

    customer_import_id = path.match(%r{/companies/customer_imports/(?<id>\d+)})[:id]
    customer_import = CustomerImport.find(customer_import_id)

    assert_equal 3, customer_import.rows.count

    customer_import.rows.order(:id)[0].tap do |row|
      assert_equal "C-A", row.field_data["company_name"]
      assert_equal "c-a@example.com", row.field_data["email"]
    end

    assert_equal 0, Customer.count
    assert_equal 0, UserCustomerAccess.count
  end

  test "import file gets parsed and results in customers being created" do
    sign_in

    import_file = Tempfile.new(["customer-import", ".xlsx"], Rails.root.join("tmp"))

    workbook = WriteXLSX.new(import_file.path)
    worksheet = workbook.add_worksheet
    worksheet.write_col("A1", [
      ["company_name", "email",           "address_1",  "country_code"],
      ["C-A",          "c-a@example.com", "C-A Road 1", "DK"          ],
      ["C-B",          "c-b@example.com", "C-B Road 1", "DK"          ],
      ["C-C",          "c-c@example.com", "C-C Road 1", "DK"          ],
    ])
    workbook.close

    begin
      post "/companies/customer_imports/bg", "customer_import[file]" => Rack::Test::UploadedFile.new(import_file.path)
    ensure
      import_file.close
      import_file.unlink
    end

    follow_redirect!

    customer_import_id = path.match(%r{/companies/customer_imports/(?<id>\d+)})[:id]
    customer_import = CustomerImport.find(customer_import_id)

    post "/companies/customer_imports/#{customer_import_id}/bg"

    assert_equal 3, Customer.count
    assert_equal 3, UserCustomerAccess.count
  end

  private

  def sign_in
    post "/users/sign_in", user: { email: @user.email, password: @user_password }
  end
end
