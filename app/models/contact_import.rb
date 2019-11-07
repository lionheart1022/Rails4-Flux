module ContactImport
  PERMITTED_COLUMN_NAMES = %w(
    company_name
    attention
    address_1
    address_2
    address_3
    zip_code
    city
    country_code
    state_code
    state
    phone
    email
  )

  PERMITTED_DB_COLUMN_NAMES = %w(
    created_at
    updated_at
    reference_id
    reference_type
    company_name
    attention
    address_line1
    address_line2
    address_line3
    zip_code
    city
    country_code
    country_name
    state_code
    phone_number
    email
  )

  class << self
    def from_xlsx_file(io)
      ExcelParser.new(io)
    end

    def bulk_create(import_params, company: nil, customer: nil)
      return if import_params[:rows].blank?

      now = Time.zone.now
      inserted_ids = nil

      ActiveRecord::Base.transaction do
        address_book =
          if company
            AddressBook.find_or_create_by!(owner: company)
          elsif customer
            AddressBook.find_or_create_by!(customer: customer)
          else
            raise "One of company or customer must be specified"
          end

        rows = import_params[:rows].map do |_, row_attributes|
          Row.new(row_attributes)
        end

        rows.reject!(&:invalid?)

        rows_attributes = rows.map do |row|
          {
            # Inferred fields
            created_at: now,
            updated_at: now,
            reference_id: address_book.id,
            reference_type: "AddressBook",

            # Fields from actual import
            company_name: row.company_name,
            attention: row.attention,
            address_line1: row.address_1,
            address_line2: row.address_2,
            address_line3: row.address_3,
            zip_code: row.zip_code,
            city: row.city,
            country_code: row.downcased_country_code,
            country_name: row.country_name,
            state_code: row.state_code,
            phone_number: row.phone,
            email: row.email,
          }
        end

        bulk_insertion = BulkInsertion.new(rows_attributes, column_names: PERMITTED_DB_COLUMN_NAMES.map(&:to_sym), model_class: ::Contact)
        bulk_insertion.perform!
        inserted_ids = bulk_insertion.inserted_ids
      end

      inserted_ids
    end
  end

  class BaseParser
    def rows
    end

    def perform!
      raise "define in subclass"
    end
  end

  class ExcelParser < BaseParser
    attr_reader :io, :workbook
    attr_reader :rows

    def initialize(io)
      @io = io
      @workbook = Creek::Book.new(io.path)
    end

    def perform!
      @rows = []

      workbook.sheets.each do |sheet|
        # First row in the file is the header row
        header = sheet.rows.first

        # The others are the actual rows with values
        next_rows = sheet.rows.drop(1)

        next_parsed_rows = next_rows.map do |row|
          Row.build(row: row, header: header)
        end

        @rows += next_parsed_rows
      end

      rows.reject!(&:blank_row?)
      rows.each(&:validate)

      rows
    end
  end

  class Row
    include ActiveModel::Model

    class << self
      def build(row:, header:)
        i = new

        header.values.each_with_index do |name, column_index|
          attr_name = name.to_s.downcase

          if PERMITTED_COLUMN_NAMES.include?(attr_name)
            i.public_send("#{attr_name}=", row.values[column_index])
          end
        end

        i
      end
    end

    PERMITTED_COLUMN_NAMES.each do |field|
      attr_accessor :"#{field}"
    end

    validates :company_name, presence: true
    validates :address_1, presence: true
    validates :country_code, presence: true

    validate :country_code_must_be_valid
    validate :state_code_must_be_valid, if: :should_validate_state_code?

    alias_method :state_name, :state

    def normalized_email
      email.downcase.strip if email
    end

    def blank_row?
      PERMITTED_COLUMN_NAMES.all? { |field| self.public_send(field).blank? }
    end

    def country_name
      Country.find_country_by_alpha2(country_code).try(:name) if country_code.present?
    end

    def downcased_country_code
      country_code.downcase if country_code
    end

    def state_code
      return @state_code if @state_code.present?

      if state_name.present?
        state_mapping_for_country.each do |code, state_struct|
          if state_struct.name.casecmp(state_name) == 0
            return code
          end
        end
      end

      nil
    end

    private

    def country_code_must_be_valid
      if country_code.present? && country_name.nil?
        errors.add(:country_code, "is not valid")
      end
    end

    def state_code_must_be_valid
      state_result = state_mapping_for_country.find do |code, _state_struct|
        code.casecmp(state_code) == 0
      end

      if state_result.nil?
        errors.add(:state_code, "is not valid")
      end

      true
    end

    def state_mapping_for_country
      if country_code.blank?
        {}
      else
        country_result = Country.find_country_by_alpha2(downcased_country_code)

        if country_result
          country_result.states
        else
          {}
        end
      end
    end

    def should_validate_state_code?
      state_code.present? && StatesPerCountry::COUNTRY_CODES.include?(downcased_country_code)
    end
  end
end
