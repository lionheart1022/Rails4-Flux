require "csv"

class Customers::CreateAddressImport
  CONTACT_ATTRIBUTE_TO_FILE_COLUMN_MAPPING = {
    "company_name" => "company",
    "attention" => "attention",
    "address_line1" => "address_1",
    "address_line2" => "address_2",
    "address_line3" => "address_3",
    "zip_code" => "zip",
    "city" => "city",
    "country_code" => "country_iso",
    "state_code" => "state_code",
    "phone_number" => "phone",
    "email" => "email",
  }

  FILE_COLUMN_TO_CONTACT_ATTRIBUTE_MAPPING = CONTACT_ATTRIBUTE_TO_FILE_COLUMN_MAPPING.invert

  attr_accessor :current_customer
  attr_accessor :file

  def initialize(current_customer:)
    self.current_customer = current_customer
  end

  def run!
    @contact_success_count = 0
    @contact_failure_count = 0

    ActiveRecord::Base.transaction do
      import_from_csv!
    end

    Result.new(
      contact_success_count: @contact_success_count,
      contact_failure_count: @contact_failure_count,
    )
  end

  private

  def import_from_csv!
    options = {
      headers: true,
      col_sep: ";",
      skip_blanks: true,
    }

    file_contents = file.read

    CSV.parse(file_contents, options) do |row|
      contact_attributes = {}

      FILE_COLUMN_TO_CONTACT_ATTRIBUTE_MAPPING.each do |file_column_name, attribute_name|
        value = row[file_column_name].to_s.strip
        contact_attributes[attribute_name] = value unless value.nil?
      end

      next if contact_attributes.blank?

      begin
        address_book = find_or_create_address_book!

        contact = address_book.contacts.new(contact_attributes)
        contact.country_code = contact.country_code.downcase if contact.country_code
        contact.country_name = Country.find_country_by_alpha2(contact.country_code).try(:name) if contact.country_code
        contact.save!

        register_contact_success!
      rescue => e
        ExceptionMonitoring.report!(e, context: { customer_id: current_customer.id, file_contents: file_contents, csv_row: row.to_hash })
        register_contact_failure!
      end
    end
  end

  def find_or_create_address_book!
    @address_book ||= ::AddressBook.find_or_create_by!(customer_id: current_customer.id)
  end

  def register_contact_success!
    @contact_success_count += 1
  end

  def register_contact_failure!
    @contact_failure_count += 1
  end

  class Result
    attr_accessor :contact_success_count
    attr_accessor :contact_failure_count

    def initialize(params = {})
      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def json_response
      {
        message: "Succesfully imported #{contact_success_count} #{'contact'.pluralize(contact_success_count)} (#{contact_failure_count} failed)",
        success: true,
      }
    end

    def http_status
      :ok
    end
  end

  private_constant :Result
end
