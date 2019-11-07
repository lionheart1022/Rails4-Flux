xml.instruct!
xml.ShipmentList do
  xml.NewShipments do
    @view_model.new.each do |shipment|
      render(partial: 'api/v1/companies/partials/shipment', locals: {
        builder: xml,
        shipment: shipment,
        customer_external_accounting_number: @view_model.customer_external_accounting_number(shipment: shipment),
        advanced_price: @view_model.company_advanced_price(shipment: shipment)
      })
    end
  end

  xml.UpdatedShipments do
    @view_model.updated.each do |shipment|
      render(partial: 'api/v1/companies/partials/shipment', locals: {
        builder: xml,
        shipment: shipment,
        customer_external_accounting_number: @view_model.customer_external_accounting_number(shipment: shipment),
        advanced_price: @view_model.company_advanced_price(shipment: shipment)
      })
    end
  end
end