class GLSSearchNearestParcelshop
  API_URI = URI("http://www.gls.dk/webservices_v4/wsShopFinder.asmx/SearchNearestParcelShops")
  NUMBER_OF_SHOPS_TO_RETURN = 1

  attr_accessor :street
  attr_accessor :zip_code
  attr_accessor :country_code

  def initialize(params = {})
    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def get_result!
    response = Net::HTTP.post_form(API_URI, post_form_parameters)

    unless response.is_a?(Net::HTTPSuccess)
      raise UnsuccessfulResponseError.new("Did not receive 2xx response as expected", response: response)
    end

    doc = Nokogiri::XML.parse(response.body)
    accuracy_level = doc.at_xpath("//xmlns:accuracylevel").text

    if accuracy_level == "UNKNOWN"
      raise UnknownAccuracyError.new("Accuracy of parcelshop is unknown", response: response)
    end

    OpenStruct.new(number: doc.at_xpath("//xmlns:PakkeshopData/xmlns:Number").text)
  end

  private

  def post_form_parameters
    {
      "street" => street,
      "zipcode" => zip_code,
      "countryIso3166A2" => country_code,
      "Amount" => NUMBER_OF_SHOPS_TO_RETURN,
    }
  end

  class BaseError < StandardError
  end

  class UnsuccessfulResponseError < BaseError
    attr_reader :response

    def initialize(msg, response:)
      @response = response
      super(msg)
    end
  end

  class UnknownAccuracyError < BaseError
    attr_reader :response

    def initialize(msg, response:)
      @response = response
      super(msg)
    end
  end
end
