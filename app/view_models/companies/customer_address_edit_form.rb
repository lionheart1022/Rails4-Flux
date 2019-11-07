class Companies::CustomerAddressEditForm
  include ActiveModel::Model

  CUSTOMER_ATTRIBUTES = [
    :email,
    :attention,
    :address_line1,
    :address_line2,
    :address_line3,
    :zip_code,
    :city,
    :country_code,
    :state_code,
    :phone_number,
    :cvr_number,
    :note,
  ]

  attr_internal_accessor :customer_record

  attr_accessor :name
  attr_accessor :email
  attr_accessor :attention
  attr_accessor :address_line1
  attr_accessor :address_line2
  attr_accessor :address_line3
  attr_accessor :zip_code
  attr_accessor :city
  attr_accessor :country_code
  attr_accessor :state_code
  attr_accessor :phone_number
  attr_accessor :cvr_number
  attr_accessor :note
  attr_accessor :external_accounting_number

  validates! :customer_record, presence: true
  validates :name, presence: true
  validates :address_line1, presence: true
  validates :country_code, presence: true

  def initialize(params = {})
    self.customer_record = params.delete(:customer_record)
    assign_attributes_from_customer_record!

    super
  end

  def assign_attributes(params = {})
    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end if params
  end

  def save
    if valid?
      Customer.transaction do
        customer_record.update!(
          name: name,
          external_accounting_number: external_accounting_number,
        )

        customer_record.build_address if customer_record.address.nil?

        CUSTOMER_ATTRIBUTES.each do |attr|
          customer_record.address.public_send("#{attr}=", self.public_send(attr))
        end

        customer_record.address.set_country_name_from_code = true
        customer_record.address.company_name = name
        customer_record.address.save!
      end

      true
    else
      false
    end
  end

  private

  def assign_attributes_from_customer_record!
    if customer_record.nil?
      raise ArgumentError, "`customer_record` is required"
    end

    self.name = customer_record.name
    self.external_accounting_number = customer_record.external_accounting_number

    if customer_record.address
      CUSTOMER_ATTRIBUTES.each do |attr|
        self.public_send("#{attr}=", customer_record.address.public_send(attr))
      end

      country_code.downcase! if country_code
    end
  end
end
