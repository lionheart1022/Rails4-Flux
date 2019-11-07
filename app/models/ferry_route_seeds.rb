class FerryRouteSeeds
  attr_reader :company

  PUTTGARDEN_ADDRESS_ATTRIBUTES    = { company_name: "Puttgarden Scandlines",  attention: "-", address_line1: "Fährhafenstrasse",   zip_code: "23769", city: "Puttgarden",  country_name: "Germany", country_code: "DE" }
  RODBY_ADDRESS_ATTRIBUTES         = { company_name: "Rødby Scandlines",       attention: "-", address_line1: "Færgestationsvej 5", zip_code: "4970",  city: "Rødby",       country_name: "Denmark", country_code: "DK" }
  ROSTOCK_ADDRESS_ATTRIBUTES       = { company_name: "Rostock Scandlines",     attention: "-", address_line1: "Ost-West-Straße 32", zip_code: "18147", city: "Rostock",     country_name: "Germany", country_code: "DE" }
  GEDSER_ADDRESS_ATTRIBUTES        = { company_name: "Gedser Scandlines",      attention: "-", address_line1: "Jernbanevejen 1",    zip_code: "4874",  city: "Gedser",      country_name: "Denmark", country_code: "DK" }
  HELSINGBORG_ADDRESS_ATTRIBUTES   = { company_name: "Helsingborg Scandlines", attention: "-", address_line1: "Bredgatan",          zip_code: "25278", city: "Helsingborg", country_name: "Sweden",  country_code: "SE" }
  HELSINGOR_ADDRESS_ATTRIBUTES     = { company_name: "Helsingør Scandlines",   attention: "-", address_line1: "Færgevej 8",         zip_code: "3000",  city: "Helsingør",   country_name: "Denmark", country_code: "DK" }
  ORESUNDSBRON_ADDRESS_ATTRIBUTES  = { company_name: "Øresundsbroen",          attention: "-", address_line1: "Öresundsbron",       zip_code: "",      city: "Malmö",       country_name: "Sweden",  country_code: "SE" }

  PORT_CODE_TO_ADDRESS_ATTRIBUTES = {
    "PUT" => PUTTGARDEN_ADDRESS_ATTRIBUTES,
    "ROD" => RODBY_ADDRESS_ATTRIBUTES,
    "ROS" => ROSTOCK_ADDRESS_ATTRIBUTES,
    "GED" => GEDSER_ADDRESS_ATTRIBUTES,
    "HEG" => HELSINGBORG_ADDRESS_ATTRIBUTES,
    "HER" => HELSINGOR_ADDRESS_ATTRIBUTES,
    "MAL" => ORESUNDSBRON_ADDRESS_ATTRIBUTES,
  }

  PORT_CODES_TO_DEPARTURE_TIMES = {
    ["PUT", "ROD"] => [
      "00:15",
      "00:45",
      "01:15",
      "01:45",
      "02:15",
      "02:45",
      "03:15",
      "03:45",
      "04:15",
      "04:45",
      "05:15",
      "05:45",
      "06:15",
      "06:45",
      "07:15",
      "07:45",
      "08:15",
      "08:45",
      "09:15",
      "09:45",
      "10:15",
      "10:45",
      "11:15",
      "11:45",
      "12:15",
      "12:45",
      "13:15",
      "13:45",
      "14:15",
      "14:45",
      "15:15",
      "15:45",
      "16:15",
      "16:45",
      "17:15",
      "17:45",
      "18:15",
      "18:45",
      "19:15",
      "19:45",
      "20:15",
      "20:45",
      "21:15",
      "22:15",
      "22:45",
      "23:15",
    ],
    ["ROD", "PUT"] => [
      "00:15",
      "00:45",
      "01:15",
      "01:45",
      "02:15",
      "02:45",
      "03:15",
      "03:45",
      "04:15",
      "04:45",
      "05:15",
      "05:45",
      "06:15",
      "06:45",
      "07:15",
      "07:45",
      "08:15",
      "08:45",
      "09:15",
      "09:45",
      "10:15",
      "10:45",
      "11:15",
      "11:45",
      "12:15",
      "12:45",
      "13:15",
      "13:45",
      "14:15",
      "14:45",
      "15:15",
      "15:45",
      "16:15",
      "16:45",
      "17:15",
      "17:45",
      "18:15",
      "18:45",
      "19:15",
      "19:45",
      "20:15",
      "20:45",
      "21:15",
      "21:45",
      "22:15",
      "23:15",
      "23:45",
    ],
    ["GED", "ROS"] => [
      "02:30",
      "07:00",
      "09:00",
      "11:00",
      "13:00",
      "15:00",
      "17:00",
      "19:00",
      "21:00",
      "23:45",
    ],
    ["ROS", "GED"] => [
      "04:00",
      "06:00",
      "09:00",
      "11:00",
      "13:00",
      "15:00",
      "17:00",
      "19:00",
      "21:00",
      "23:45",
    ],
    ["HEG", "HER"] => [
      "04:00",
      "06:00",
      "09:00",
      "11:00",
      "13:00",
      "15:00",
      "17:00",
      "19:00",
      "21:00",
      "23:45",
    ],
  }

  def initialize(company)
    @company = company
  end

  def perform!
    FerryRoute.transaction do
      setup_route_put_rod!
      setup_route_put_rod_with_oresundsbron!
      setup_route_rod_put!
      setup_route_rod_put_with_oresundsbron!
      setup_route_ros_ged!
      setup_route_ros_ged_with_oresundsbron!
      setup_route_ged_ros!
      setup_route_ged_ros_with_oresundsbron!
      setup_route_put_rod_her_heg!
      setup_route_heg_her_rod_put!
      setup_route_ros_ged_her_heg!
      setup_route_heg_her_ged_ros!
      setup_route_heg_her!
      setup_route_her_heg!
    end
  end

  private

  def setup_route_put_rod!
    route_attributes = {
      name: "Puttgarden-Rodby",
      port_code_from: "PUT",
      port_code_to: "ROD",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
    upsert_ferry_products!(ferry_route: ferry_route, departure_times: PORT_CODES_TO_DEPARTURE_TIMES.fetch(["PUT", "ROD"]))
  end

  def setup_route_put_rod_with_oresundsbron!
    route_attributes = {
      name: "Puttgarden-Rodby-Oresundsbron",
      port_code_from: "PUT",
      port_code_to: "MAL",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
    upsert_ferry_products!(ferry_route: ferry_route, departure_times: PORT_CODES_TO_DEPARTURE_TIMES.fetch(["PUT", "ROD"]))
  end

  def setup_route_rod_put!
    route_attributes = {
      name: "Rodby-Puttgarden",
      port_code_from: "ROD",
      port_code_to: "PUT",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
    upsert_ferry_products!(ferry_route: ferry_route, departure_times: PORT_CODES_TO_DEPARTURE_TIMES.fetch(["ROD", "PUT"]))
  end

  def setup_route_rod_put_with_oresundsbron!
    route_attributes = {
      name: "Oresundsbron-Rodby-Puttgarden",
      port_code_from: "MAL",
      port_code_to: "PUT",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
    upsert_ferry_products!(ferry_route: ferry_route, departure_times: PORT_CODES_TO_DEPARTURE_TIMES.fetch(["ROD", "PUT"]))
  end

  def setup_route_ros_ged!
    route_attributes = {
      name: "Rostock-Gedser",
      port_code_from: "ROS",
      port_code_to: "GED",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
    upsert_ferry_products!(ferry_route: ferry_route, departure_times: PORT_CODES_TO_DEPARTURE_TIMES.fetch(["ROS", "GED"]))
  end

  def setup_route_ros_ged_with_oresundsbron!
    route_attributes = {
      name: "Rostock-Gedser-Oresundsbron",
      port_code_from: "ROS",
      port_code_to: "MAL",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
    upsert_ferry_products!(ferry_route: ferry_route, departure_times: PORT_CODES_TO_DEPARTURE_TIMES.fetch(["ROS", "GED"]))
  end

  def setup_route_ged_ros!
    route_attributes = {
      name: "Gedser-Rostock",
      port_code_from: "GED",
      port_code_to: "ROS",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
    upsert_ferry_products!(ferry_route: ferry_route, departure_times: PORT_CODES_TO_DEPARTURE_TIMES.fetch(["GED", "ROS"]))
  end

  def setup_route_ged_ros_with_oresundsbron!
    route_attributes = {
      name: "Oresundsbron-Gedser-Rostock",
      port_code_from: "MAL",
      port_code_to: "ROS",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
    upsert_ferry_products!(ferry_route: ferry_route, departure_times: PORT_CODES_TO_DEPARTURE_TIMES.fetch(["GED", "ROS"]))
  end

  def setup_route_put_rod_her_heg!
    route_attributes = {
      name: "Puttgarden-Rodby + Helsingor-Helsingborg",
      port_code_from: "PUT",
      port_code_to: "HEG",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
    upsert_ferry_products!(ferry_route: ferry_route, departure_times: PORT_CODES_TO_DEPARTURE_TIMES.fetch(["PUT", "ROD"]))
  end

  def setup_route_heg_her_rod_put!
    route_attributes = {
      name: "Helsingborg-Helsingor + Rodby-Puttgarden",
      port_code_from: "HEG",
      port_code_to: "PUT",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
    upsert_ferry_products!(ferry_route: ferry_route, departure_times: PORT_CODES_TO_DEPARTURE_TIMES.fetch(["HEG", "HER"]))
  end

  def setup_route_ros_ged_her_heg!
    route_attributes = {
      name: "Rostock-Gedser + Helsingor-Helsingborg",
      port_code_from: "ROS",
      port_code_to: "HEG",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
    upsert_ferry_products!(ferry_route: ferry_route, departure_times: PORT_CODES_TO_DEPARTURE_TIMES.fetch(["ROS", "GED"]))
  end

  def setup_route_heg_her_ged_ros!
    route_attributes = {
      name: "Helsingborg-Helsingor + Gedser-Rostock",
      port_code_from: "HEG",
      port_code_to: "ROS",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
    upsert_ferry_products!(ferry_route: ferry_route, departure_times: PORT_CODES_TO_DEPARTURE_TIMES.fetch(["HEG", "HER"]))
  end

  def setup_route_heg_her!
    route_attributes = {
      name: "Helsingborg-Helsingor",
      port_code_from: "HEG",
      port_code_to: "HER",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
  end

  def setup_route_her_heg!
    route_attributes = {
      name: "Helsingor-Helsingborg",
      port_code_from: "HER",
      port_code_to: "HEG",
    }

    ferry_route = upsert_ferry_route_by!(route_attributes)
  end

  def upsert_ferry_route_by!(route_attributes)
    ferry_route = company_ferry_routes.find_by(route_attributes.slice(:port_code_from, :port_code_to))
    ferry_route ||= company_ferry_routes.new(route_attributes)

    ferry_route.build_destination_address unless ferry_route.destination_address
    ferry_route.destination_address.assign_attributes(PORT_CODE_TO_ADDRESS_ATTRIBUTES.fetch(ferry_route.port_code_to))
    ferry_route.save!

    ferry_route
  end

  def upsert_ferry_products!(ferry_route:, departure_times: [])
    departure_times.each do |time_of_departure|
      ferry_route.products.find_or_create_by!(time_of_departure: time_of_departure)
    end
  end

  def company_ferry_routes
    FerryRoute.where(company: company)
  end
end
