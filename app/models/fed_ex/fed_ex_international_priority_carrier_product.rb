class FedExInternationalPriorityCarrierProduct < FedExGenericCarrierProduct
  def service
    FedExShipperLib::ServiceTypes::INTERNATIONAL_PRIORITY
  end
end
