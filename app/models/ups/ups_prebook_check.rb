class UPSPrebookCheck
  TESTING_URI = URI("https://wwwcie.ups.com/rest/Rate")
  PRODUCTION_URI = URI("https://onlinetools.ups.com/rest/Rate")

  DELIVERY_SURCHARGE_CODE = "112081"

  class << self
    def run(shipment)
      new(shipment).run
    end
  end

  attr_reader :shipment
  attr_reader :uri

  def initialize(shipment, uri: nil)
    @shipment = shipment
    @uri = uri || begin
      if Rails.env.production?
        PRODUCTION_URI
      else
        TESTING_URI
      end
    end
  end

  def run
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" })
    request.body = to_json

    response = http.request(request)
    response.value

    json_response = JSON.parse(response.body)
    if json_response["RateResponse"]
      # If there's 1 alert, we get a JSON object. If there's more than 1 alert, we get a JSON array of objects 😑
      alerts = Array.wrap(json_response["RateResponse"]["Response"]["Alert"])
      delivery_surcharge_alert = alerts.find { |alert| alert["Code"] == DELIVERY_SURCHARGE_CODE }

      result =
        if delivery_surcharge_alert
          ShipmentPrebook::SurchargeWarningResult.new([
            ShipmentPrebook::Surcharge.new(
              type: "UPSSurcharges::AreaDelivery",
              description: "A delivery area surcharge has been added",
            )
          ])
        else
          ShipmentPrebook::OKResult.new
        end

      result.estimated_arrival_date = Date.parse(json_response["RateResponse"]["RatedShipment"]["TimeInTransit"]["ServiceSummary"]["EstimatedArrival"]["Arrival"]["Date"])

      return result
    elsif json_response["Fault"]
      raise "Unexpected UPS Rates Fault response"
    else
      # TODO
    end

    ShipmentPrebook::OKResult.new
  rescue => e
    context = {}

    if defined?(request) && request
      context[:request_body] = request.body
    end

    if defined?(response) && response
      context[:response_code] = response.code
      context[:response_body] = response.body
    end

    ExceptionMonitoring.report!(e, context: context)

    ShipmentPrebook::ErrorResult.new("Unexpected UPS-prebook-check error")
  end

  def to_json
    to_builder.target!
  end

  def to_builder
    credentials = shipment.carrier_product.get_credentials

    Jbuilder.new do |json|
      json.UPSSecurity do
        json.UsernameToken do
          json.Username credentials[:company]
          json.Password credentials[:password]
        end

        json.ServiceAccessToken do
          json.AccessLicenseNumber credentials[:access_token]
        end
      end

      json.RateRequest do
        json.Request do
          json.RequestOption "Ratetimeintransit"
          json.SubVersion "1801"
        end

        json.Shipment do
          json.Shipper do
            json.ShipperNumber credentials[:account]
            build_contact_json(json, shipper)
          end

          json.ShipTo do
            build_contact_json(json, shipment.recipient)
          end

          json.ShipFrom do
            build_contact_json(json, shipment.sender)
          end

          json.Service do
            json.Code shipment.carrier_product.service
            json.Description shipment.description
          end

          if shipment.carrier_product.ups_documents_only?
            json.DocumentsOnlyIndicator ""
          end

          json.Package shipment.package_dimensions.dimensions do |package_dimension|
            json.PackagingType do
              json.Code shipment.carrier_product.packaging_code
            end

            if include_dimensions?
              json.Dimensions do
                json.UnitOfMeasurement do
                  json.Code "CM"
                end

                json.Length package_dimension.length.to_s
                json.Width package_dimension.width.to_s
                json.Height package_dimension.height.to_s
              end
            end

            json.PackageWeight do
              json.UnitOfMeasurement do
                json.Code "KGS"
              end

              if shipment.carrier_product.ups_letter?
                json.Weight "0"
              else
                json.Weight package_dimension.weight.to_s
              end
            end
          end

          json.ShipmentTotalWeight do
            json.UnitOfMeasurement do
              json.Code "KGS"
            end
            json.Weight shipment.package_dimensions.total_weight.to_s
          end

          json.InvoiceLineTotal do
            json.CurrencyCode invoice_line_total_currency_code
            json.MonetaryValue invoice_line_total_value
          end

          json.DeliveryTimeInformation do
            json.PackageBillType package_bill_type
            json.Pickup do
              json.Date shipment.shipping_date.strftime('%Y%m%d')
            end
          end
        end
      end
    end
  end

  def include_dimensions?
    !shipment.carrier_product.ups_letter?
  end

  def shipper
    if shipment.carrier_product.import?
      shipment.recipient
    else
      shipment.sender
    end
  end

  def package_bill_type
    case
    when shipment.carrier_product.ups_documents_only?
      "02" # 02=Document only
    else
      "03" # 03=Non-Document
    end
  end

  def invoice_line_total_currency_code
    shipment.customs_currency.presence || "EUR"
  end

  def invoice_line_total_value
    (shipment.customs_amount.presence || 1).to_s
  end

  def build_contact_json(json, contact)
    json.Name contact.company_name
    json.Address do
      json.AddressLine([
        contact.address_line1,
        contact.address_line2,
        contact.address_line3,
      ])
      json.City contact.city
      json.StateProvinceCode contact.state_code
      json.PostalCode contact.zip_code
      json.CountryCode contact.country_code
    end
  end
end
