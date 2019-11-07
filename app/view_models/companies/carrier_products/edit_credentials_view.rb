class Companies::CarrierProducts::EditCredentialsView
  attr_reader :main_view, :carrier, :product, :company, :account, :credentials

  def initialize(carrier: nil, product: nil, company: nil, account: nil, credentials: nil)
    @carrier      = carrier
    @product      = product
    @company      = company
    @account      = account
    @credentials  = credentials
    state_general
  end

  def live_fields
    case carrier.type
    when 'GLSCarrier'
      gls_fields_live
    when 'TNTCarrier'
      tnt_fields_live
    when 'UPSCarrier'
      ups_fields_live
    when 'DAOCarrier'
      dao_fields_live
    when 'DHLCarrier'
      dhl_fields_live
    when 'PacsoftCarrier'
      pacsoft_fields_live
    when 'BringCarrier'
      bring_fields_live
    when 'Send24Carrier'
      send24_fields_live
    when 'UnifaunCarrier'
      unifaun_fields_live
    when 'UnifaunNorwayCarrier'
      unifaun_norway_fields_live
    when 'GTXCarrier'
      gtx_fields_live
    when 'FedExCarrier'
      fed_ex_fields_live
    when 'GeodisDHLCarrier'
      geodis_dhl_fields_live
    when 'DSVCarrier'
      dsv_fields_live
    when 'KHTCarrier'
      kht_fields_live
    end
  end

  def test_fields
    case carrier.type
    when 'GLSCarrier'
      gls_fields_test
    end
  end

  def gls_fields_live
    [
      { key: :username, options: { autofocus: false, input_html: { value: credentials[:username] } }},
      { key: :password, options: { input_html: { value: credentials[:password] } }},
      { key: :customer_id, options: { label: 'Customer Id', input_html: { value: credentials[:customer_id] } }},
      { key: :contact_id, options: { label: 'Contact Id', input_html: { value: credentials[:contact_id] } }},
    ]
  end

  def gls_fields_test
    [
      { key: :test_username, options: { required: false, autofocus: false, input_html: { value: credentials[:test_username] } }},
      { key: :test_password, options: { required: false, input_html: { value: credentials[:test_password] } }},
      { key: :test_customer_id, options: { required: false, label: 'Test Customer Id', input_html: { value: credentials[:test_customer_id] } }},
      { key: :test_contact_id, options: { required: false, label: 'Test Contact Id', input_html: { value: credentials[:test_contact_id] } }},
    ]
  end

  def dao_fields_live
    [
      { key: :account, options: { autofocus: false, input_html: { value: credentials[:account] } }},
      { key: :password, options: { input_html: { value: credentials[:password] } }},
    ]
  end

  def dhl_fields_live
    [
      { key: :company, options: { autofocus: false, input_html: { value: credentials[:company] } }},
      { key: :account, options: { label: 'Site Id', input_html: { value: credentials[:account] } }},
      { key: :password, options: { input_html: { value: credentials[:password] } }},
    ]
  end

  def ups_fields_live
    [
      { key: :company, options: { autofocus: false, input_html: { value: credentials[:company] } }},
      { key: :account, options: { input_html: { value: credentials[:account] } }},
      { key: :password, options: { input_html: { value: credentials[:password] } }},
      { key: :access_token, options: { input_html: { value: credentials[:access_token] } }},
    ]
  end

  def tnt_fields_live
    [
      { key: :company, options: { autofocus: false, input_html: { value: credentials[:company] } }},
      { key: :account, options: { input_html: { value: credentials[:account] } }},
      { key: :password, options: { input_html: { value: credentials[:password] } }},
    ]
  end

  def pacsoft_fields_live
    [
      { key: :company, options: { autofocus: false, input_html: { value: credentials[:company] } }},
      { key: :account, options: { input_html: { value: credentials[:account] } }},
      { key: :password, options: { input_html: { value: credentials[:password] } }},
    ]
  end

  def bring_fields_live
    [
      { key: :user_id, options: { label: 'User Id', autofocus: false, input_html: { value: credentials[:user_id] } }},
      { key: :customer_number, options: { autofocus: false, input_html: { value: credentials[:customer_number] } }},
      { key: :api_key, options: { label: 'API Key', input_html: { value: credentials[:api_key] } }},
    ]
  end

  def send24_fields_live
    [
      { key: :consumer_key, options: { autofocus: false, input_html: { value: credentials[:consumer_key] } }},
      { key: :consumer_secret, options: { autofocus: false, input_html: { value: credentials[:consumer_secret] } }},
    ]
  end

  def unifaun_fields_live
    [
      { key: :user_id, options: { autofocus: false, input_html: { value: credentials[:user_id] } }},
      { key: :id, options: { autofocus: false, input_html: { value: credentials[:id] } }},
      { key: :secret, options: { autofocus: false, input_html: { value: credentials[:secret] } }},
    ]
  end

  def unifaun_norway_fields_live
    [
      { key: :id, options: { autofocus: false, input_html: { value: credentials[:id] } }},
      { key: :secret, options: { autofocus: false, input_html: { value: credentials[:secret] } }},
      { key: :customer_number, options: { autofocus: false, input_html: { value: credentials[:customer_number] } }},
    ]
  end

  def gtx_fields_live
    [
      { key: :username, options: { autofocus: false, input_html: { value: credentials[:username] } }},
      { key: :password, options: { autofocus: false, input_html: { value: credentials[:password] } }},
    ]
  end

  def fed_ex_fields_live
    fields(:account_number, :meter_number, :developer_key, :developer_password)
  end

  def geodis_dhl_fields_live
    [
      { key: :username, options: { autofocus: false, input_html: { value: credentials[:username] } } },
      { key: :password, options: { input_html: { value: credentials[:password] } } },
      { key: :company_id, options: { label: "Company ID", input_html: { value: credentials[:company_id] } } },
      { key: :template_with_pickup, options: { input_html: { value: credentials[:template_with_pickup] } } },
      { key: :template_without_pickup, options: { input_html: { value: credentials[:template_without_pickup] } } },
      { key: :dhl_account, options: { label: "DHL site ID", input_html: { value: credentials[:dhl_account] } } },
      { key: :dhl_password, options: { label: "DHL password", input_html: { value: credentials[:dhl_password] } } },
    ]
  end

  def dsv_fields_live
    [
      {
        key: :customer_number,
        options: { input_html: { value: credentials[:customer_number] } },
      },
    ]
  end

  def kht_fields_live
    [
      {
        key: :customer_number,
        options: { input_html: { value: credentials[:customer_number] } },
      },
      {
        key: :sender_id,
        options: { label: "Sender ID", input_html: { value: credentials[:sender_id] } },
      },
      {
        key: :ftp_user,
        options: { input_html: { value: credentials[:ftp_user] } },
      },
      {
        key: :ftp_host,
        options: { input_html: { value: credentials[:ftp_host] } },
      },
      {
        key: :ftp_password,
        options: { input_html: { value: credentials[:ftp_password] } },
      },
    ]
  end

  private

  def fields(*keys)
    keys.map {|key| field(key) }
  end

  def field(key)
    { key: key, options: { autofocus: false, input_html: { value: credentials[key] } }}
  end

  def state_general
    @main_view = "components/companies/carrier_products/edit_credentials"
  end
end
