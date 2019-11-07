require "net/ftp"

class GLSFeedbackConfiguration < CarrierFeedbackConfiguration
  DK_ACCOUNT_PREFIX = "20800"

  class << self
    def with_account_number(account_number)
      where("account_details->>'short_customer_no' = ?", account_number)
    end
  end

  def carrier_name
    "GLS"
  end

  def account_label
    "Customer ID: #{account_details['customer_id']} [#{account_details['short_customer_no']}]"
  end

  def carrier_type
    :gls
  end

  def account_no=(value)
    if value
      match = %r{\A(?<country_prefix>\d{5})?(?<short_customer_no>\d{5})\z}.match(String(value).strip)

      if match
        customer_id =
          if match[:country_prefix].present?
            value
          else
            "#{DK_ACCOUNT_PREFIX}#{match[:short_customer_no]}"
          end

        self.account_details = {
          "customer_id" => customer_id,
          "short_customer_no" => match[:short_customer_no],
        }

        return
      end
    end

    # Fall-back
    self.account_details = {}
  end

  def ftp_host
    credentials["ftp_host"]
  end

  def ftp_username
    credentials["ftp_username"]
  end

  def ftp_password
    credentials["ftp_password"]
  end

  def set_credentials_from_env!
    if ENV["GLS_DAILY_FTP_URI"].present?
      ftp_uri = URI(ENV["GLS_DAILY_FTP_URI"])

      self.credentials = {
        "ftp_host" => ftp_uri.host,
        "ftp_username" => ftp_uri.user,
        "ftp_password" => ftp_uri.password,
      }
    else
      false
    end
  end
end
