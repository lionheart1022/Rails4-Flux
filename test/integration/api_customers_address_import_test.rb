require "test_helper"

class APICustomersAddressImportTest < ActionDispatch::IntegrationTest
  test "create a regular address import" do
    company = setup_company!
    customer = setup_customer!(company: company)
    access_token = AccessToken.create!(owner: customer, value: SecureRandom.hex)

    csv_headers = [
      "company",
      "attention",
      "address_1",
      "address_2",
      "address_3",
      "zip",
      "city",
      "country_iso",
      "state_code",
      "phone",
      "email",
    ]
    csv = CSV.new("", col_sep: ";", write_headers: true, headers: csv_headers)
    csv << {
      "company" => "Test Customer",
      "attention" => nil,
      "address_1" => "Njalsgade 17A",
      "address_2" => nil,
      "address_3" => nil,
      "zip" => "2300",
      "city" => "Copenhagen",
      "country_iso" => "dk",
      "state_code" => nil,
      "phone" => nil,
      "email" => "test@example.com",
    }

    csv_file = Tempfile.new(["address-import", ".csv"], Rails.root.join("tmp"))
    begin
      csv_file.write(csv.string)
      csv_file.rewind

      assert_equal 0, AddressBook.where(customer: customer).count

      post "/api/v1/customers/address/import", access_token: access_token.value, file: Rack::Test::UploadedFile.new(csv_file.path)

      assert_equal 200, status

      json_response = JSON.parse(response.body)
      assert_equal true, json_response["success"]
      assert_equal "Succesfully imported 1 contact (0 failed)", json_response["message"]

      assert_equal 1, AddressBook.where(customer: customer).count
      assert_equal 1, AddressBook.where(customer: customer).first.contacts.count

      contacts = AddressBook.where(customer: customer).first.contacts
      assert_equal "test@example.com", contacts[0].email
    ensure
      csv_file.close
      csv_file.unlink
    end
  end

  private

  def setup_company!
    Company.create_cargoflux_company!(name: "CargoFlux ApS", current_customer_id: 0, current_report_id: 0)
    Company.create_direct_company!(name: "Company A", current_customer_id: 0, current_report_id: 0)
  end

  def setup_customer!(company:)
    customer = Customer.new(name: "Test Customer 1", company: company, customer_id: company.update_next_customer_id)
    customer.build_address(company_name: "Test Customer A", attention: "Test Person", address_line1: "Njalsgade 17A", zip_code: "2300", city: "København S", country_code: "dk", country_name: "Denmark")
    customer.save!

    customer
  end
end
