class FerryRouteConfiguration
  include ActiveModel::Model

  attr_accessor :current_company
  attr_accessor :account_number
  attr_accessor :scandlines_id
  attr_accessor :sftp_host, :sftp_user, :sftp_password
  attr_accessor :carrier_product_id

  validates! :current_company, presence: true
  validates :account_number, presence: true
  validates :scandlines_id, presence: true
  validates :sftp_host, :sftp_user, :sftp_password, presence: true
  validates :carrier_product_id, presence: true

  def available_carrier_products
    CarrierProduct
      .find_all_enabled_company_carrier_products(company_id: current_company.id)
      .where(type: "ScandlinesCarrierProduct")
      .sort_by { |cp| cp.name.downcase }
  end

  def integration_attributes
    {
      account_number: account_number,
      scandlines_id: scandlines_id,
      sftp_host: sftp_host,
      sftp_user: sftp_user,
      sftp_password: sftp_password,
    }
  end
end
