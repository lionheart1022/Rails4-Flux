class FedExInternationalPriorityFreightCarrierProduct < FedExGenericCarrierProduct
  def service
    FedExShipperLib::ServiceTypes::INTERNATIONAL_PRIORITY_FREIGHT
  end
end
