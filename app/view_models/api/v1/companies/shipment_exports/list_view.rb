class API::V1::Companies::ShipmentExports::ListView < API::V1::Companies::Shipments::ListView
  attr_reader :company, :new, :updated

  def initialize(company: nil, new: nil, updated: nil)
    @company = company
    @new     = new
    @updated = updated
  end
end
