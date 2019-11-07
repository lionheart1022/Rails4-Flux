class Companies::DashboardView
  attr_accessor :current_company

  attr_accessor :number_of_shipments
  attr_accessor :number_of_packages
  attr_accessor :weight
  attr_accessor :revenues
  attr_accessor :costs

  attr_accessor :shipment_points
  attr_accessor :package_points
  attr_accessor :weight_points

  def self.new_from_filter(filter)
    o = new

    o.number_of_shipments = filter.total_no_of_shipments
    o.number_of_packages = filter.total_no_of_packages
    o.weight = filter.total_weight
    o.revenues = filter.sorted_total_revenue
    o.costs = filter.sorted_total_cost
    o.shipment_points = filter.shipment_points
    o.package_points = filter.package_points
    o.weight_points = filter.weight_points

    o
  end

  def initialize()
  end

  def company_shipments
    Shipment
      .includes(:customer, :sender, :recipient, :carrier_product, :asset_awb, :company)
      .find_company_shipments(company_id: current_company.id)
  end

  def problem_shipments
    company_shipments.find_shipments_in_states([Shipment::States::PROBLEM])
  end

  def created_shipments
    company_shipments.find_shipments_in_states([Shipment::States::CREATED])
  end

  def rfq_shipments
    ShipmentRequest
      .includes(shipment: [:customer, :recipient, :carrier_product])
      .find_company_shipment_requests(company_id: current_company.id)
      .find_company_actionable_states
  end

  def pickup_requests
    Pickup.
      find_company_pickups(company_id: current_company.id)
      .find_pickups_in_states([Pickup::States::CREATED, Pickup::States::PROBLEM])
  end

  def number_of_shipments_unit
    "Amount"
  end

  def number_of_packages_unit
    "Amount"
  end

  def weight_label
    "Weight"
  end

  def weight_unit
    return "-" if weight.nil?

    if weight < 1000
      "KG"
    else
      "Ton"
    end
  end

  def formatted_weight
    return if weight.nil?

    if weight < 1000
      weight
    else
      (weight / 1000).round
    end
  end

  def to_builder
    Jbuilder.new do |json|
      json.shipments do
        json.unit number_of_shipments_unit
        json.value number_of_shipments

        json.points shipment_points do |point|
          json.timestamp point.timestamp
          json.value point.value
        end
      end

      json.packages do
        json.unit number_of_packages_unit
        json.value number_of_packages

        json.points package_points do |point|
          json.timestamp point.timestamp
          json.value point.value
        end
      end

      json.weight do
        json.unit weight_unit
        json.value formatted_weight

        json.points weight_points do |point|
          json.timestamp point.timestamp
          json.value point.value.round(3).to_f
        end
      end

      json.revenues revenues do |revenue|
        json.currency revenue.currency
        json.formatted_value ActiveSupport::NumberHelper.number_to_currency(revenue.value, precision: 0, unit: revenue.currency, format: "%n %u", delimiter: ".")

        json.points revenue.points do |point|
          json.timestamp point.timestamp
          json.value point.value.round(2).to_f
        end
      end

      json.costs costs do |cost|
        json.currency cost.currency
        json.formatted_value ActiveSupport::NumberHelper.number_to_currency(cost.value, precision: 0, unit: cost.currency, format: "%n %u", delimiter: ".")

        json.points cost.points do |point|
          json.timestamp point.timestamp
          json.value point.value.round(2).to_f
        end
      end
    end
  end

  Revenue = Struct.new(:currency, :value, :points)
  Cost = Struct.new(:currency, :value, :points)
  ChartPoint = Struct.new(:timestamp, :value)
end
