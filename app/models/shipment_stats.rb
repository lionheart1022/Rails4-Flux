class ShipmentStats
  attr_accessor :company
  attr_accessor :period
  attr_accessor :carrier_type
  attr_reader :result

  def initialize(params = {})
    params.each do |key, value|
      self.public_send("#{key}=", value)
    end
  end

  def run!
    validate!

    @result = Result.new
    @result.carrier_type = carrier_type
    @result.number_of_shipments = 0
    @result.number_of_packages = 0
    @result.total_weight = BigDecimal(0.0, Float::DIG)

    matching_shipments.each do |shipment|
      @result.number_of_shipments += 1
      @result.number_of_packages += shipment.package_dimensions.number_of_packages
      @result.total_weight += shipment.package_dimensions.dimensions.sum { |dimension| BigDecimal(dimension.weight, Float::DIG) }
    end

    @result
  end

  def validate!
    raise ArgumentError, "`period` is a required property" if period.nil?
    raise ArgumentError, "`company` is a required property" if company.nil?
    raise ArgumentError, "`carrier_type` is a required property" if carrier_type.nil?
  end

  private

  def matching_shipments
    Shipment
      .joins(:carrier_product => [:carrier])
      .where(:carriers => { :type => carrier_type })
      .where(:created_at => period)
      .where(:company_id => company.id)
  end

  Result = Struct.new(:carrier_type, :number_of_shipments, :number_of_packages, :total_weight) do
    def rounded_total_weight
      total_weight ? total_weight.to_f.round(2) : nil
    end
  end
end
