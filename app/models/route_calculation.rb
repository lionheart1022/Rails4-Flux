class RouteCalculation
  def initialize(from:, to:)
    @from = from
    @to = to
  end

  def shortest_distance_in_km(client: GoogleMapsDirections)
    shortest_distance_in_km!(client: client)
  rescue NoRouteError, NotFoundError
    nil
  rescue => e
    ExceptionMonitoring.report_exception!(e, context: { from: @from.to_flat_string, to: @to.to_flat_string })
    nil
  end

  def shortest_distance_in_km!(client: GoogleMapsDirections)
    shortest_distance_in_m!(client: client).fdiv(1000)
  end

  def shortest_distance_in_m!(client: GoogleMapsDirections)
    client.shortest_distance_in_m(from: @from, to: @to)
  end

  class BaseError < StandardError; end
  class NotFoundError < BaseError; end
  class NoRouteError < BaseError; end

  module GoogleMapsDirections
    ENDPOINT = "https://maps.googleapis.com/maps/api/directions/json"

    module_function
      def shortest_distance_in_m(from:, to:)
        uri = URI(ENDPOINT)
        uri.query = URI.encode_www_form(
          "origin" => from.to_flat_string,
          "destination" => to.to_flat_string,
          "avoid" => "ferries",
          "alternatives" => "true",
          "key" => ENV["G_MAPS_DIRECTIONS_API_KEY"],
        )

        response = Net::HTTP.get_response(uri)
        response.value # Raise if not 2xx

        json_body = JSON.parse(response.body)

        case json_body["status"]
        when "OK"
          # noop: all is good 👍
        when "NOT_FOUND"
          raise NotFoundError, "At least one of the locations specified in the request's origin, destination, or waypoints could not be geocoded"
        when "ZERO_RESULTS"
          raise NoRouteError, "No route could be found between the origin and destination"
        else
          error_message = "status was not OK as expected"
          ExceptionMonitoring.report_message(error_message, context: { from: from.to_flat_string, to: to.to_flat_string, json_body: json_body })
          raise BaseError, error_message
        end

        if json_body["routes"].size == 0
          return Float::INFINITY
        end

        json_body["routes"].map { |route| route["legs"][0]["distance"]["value"] }.min
      end
  end
end
