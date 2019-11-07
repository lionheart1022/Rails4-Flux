class FerryRoute < ActiveRecord::Base
  class << self
    def for_company(company)
      self
        .active
        .where(company: company)
        .order(:port_code_from, :port_code_to)
    end

    def find_for_company(company:, ferry_route_id:)
      for_company(company).find(ferry_route_id)
    end
  end

  scope :active, -> { where(disabled_at: nil) }

  belongs_to :company, required: true
  has_many :products, class_name: "FerryProduct", foreign_key: "route_id"
  has_one :destination_address, class_name: "Contact", as: :reference

  validates :name, presence: true
  validates :port_code_from, :port_code_to, presence: true
  validates :destination_address, presence: true

  before_create :set_default_name

  def ordered_products
    products.order(:time_of_departure)
  end

  def ordered_active_products
    ordered_products.active
  end

  # The products belonging to this route are expected to use the same integration record -
  # thus we should just be able to use the record from the first product.
  def integration
    if product = products.first
      product.integration || FerryProductIntegration.new(company: company)
    else
      raise "This ferry route has no products"
    end
  end

  delegate :account_number, :scandlines_id, :sftp_host, :sftp_user, :sftp_password, to: :integration

  # The products belonging to this route are expected to use the same carrier product record -
  # thus we should just be able to use the record from the first product.
  def carrier_product
    if product = products.first
      product.carrier_product
    else
      raise "This ferry route has no products"
    end
  end

  # The products belonging to this route are expected to have the same pricing schema -
  # thus we should just be able to use the record from the first product.
  def pricing_schema
    if product = products.first
      product.pricing_schema_object
    else
      raise "This ferry route has no products"
    end
  end

  def active_products?
    products.active.any?
  end

  def configuration
    FerryRouteConfiguration.new(
      current_company: company,
      account_number: account_number,
      scandlines_id: scandlines_id,
      sftp_host: sftp_host,
      sftp_user: sftp_user,
      sftp_password: sftp_password,
      carrier_product_id: carrier_product.try(:id),
    )
  end

  def build_configuration(configuration_params)
    FerryRouteConfiguration.new(configuration_params).tap do |c|
      c.current_company = company
    end
  end

  def save_configuration(configuration)
    if configuration.valid?
      integration = self.integration
      integration.assign_attributes(configuration.integration_attributes)
      integration.save!

      products.active.each do |product|
        product.update!(integration: integration, carrier_product_id: configuration.carrier_product_id)
      end

      touch

      true
    else
      false
    end
  end

  def destination_address_as_recipient
    destination_address.copy_as_recipient
  end

  private

  def set_default_name
    if name.blank? && port_code_from.present? && port_code_to.present?
      self.name = "#{port_code_from} - #{port_code_to}".upcase
    end
  end
end
