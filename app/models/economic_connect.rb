module EconomicConnect
  def request_access_uri(redirect_url:, app_public_token: ENV.fetch("ECONOMIC_APP_PUBLIC_TOKEN"))
    uri = URI("https://secure.e-conomic.com/secure/api1/requestaccess.aspx")
    uri.query = URI.encode_www_form(
      "appPublicToken" => app_public_token,
      "redirectUrl" => redirect_url,
    )
    uri
  end

  module_function :request_access_uri

  class CallbackValidation
    class BaseError < StandardError
      attr_reader :human_friendly_reason

      def intialize(message, human_friendly_reason: "Could not connect with e-conomic")
        @human_friendly_reason = human_friendly_reason
        super(message)
      end
    end

    attr_accessor :token
    attr_reader :self_response

    def initialize(token)
      self.token = token
    end

    def perform!
      uri = URI("https://restapi.e-conomic.com/self")

      req = Net::HTTP::Get.new(uri)
      req["X-AppSecretToken"] = ENV.fetch("ECONOMIC_APP_SECRET_TOKEN")
      req["X-AgreementGrantToken"] = token

      res = nil

      begin
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 15) do |http|
          http.request(req)
        end
      rescue Net::ReadTimeout => e
        raise BaseError.new("e-conomic token validation timed out", human_friendly_reason: "Could not validate token because e-conomic didn't respond within 15 seconds. Try again.")
      end

      if res.is_a?(Net::HTTPSuccess)
        @self_response = JSON.parse(res.body)
        true
      elsif res.is_a?(Net::HTTPUnauthorized)
        raise BaseError.new("Invalid e-conomic agreement token", human_friendly_reason: "Invalid e-conomic token")
      else
        raise BaseError.new("Unknown e-conomic HTTP response [#{res.code} #{res.message}]")
      end
    end
  end
end
