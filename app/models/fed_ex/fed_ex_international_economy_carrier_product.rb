class FedExInternationalEconomyCarrierProduct < FedExGenericCarrierProduct
  def service
    FedExShipperLib::ServiceTypes::INTERNATIONAL_ECONOMY
  end
end
