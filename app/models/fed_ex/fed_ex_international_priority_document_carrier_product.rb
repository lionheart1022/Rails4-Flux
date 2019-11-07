class FedExInternationalPriorityDocumentCarrierProduct < FedExGenericCarrierProduct
  def fed_ex_international_document?
    true
  end

  def service
    FedExShipperLib::ServiceTypes::INTERNATIONAL_PRIORITY
  end
end
