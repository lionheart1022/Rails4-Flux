module ShipmentFormHelper
  def shipment_form_goods_lines_react_component(shipment:)
    react_component(
      "ShipmentFormGoodsLines",
      goodsIdentifierOptions: shipment_goods_identifier_options,
      initialLines: shipment.as_goods.ordered_lines.map do |line|
        {
          amount: line.quantity.to_s,
          goods_identifier: line.goods_identifier,
          length: line.length.to_s,
          width: line.width.to_s,
          height: line.height.to_s,
          weight: line.weight.to_s,
          non_stackable: line.non_stackable,
        }
      end
    )
  end

  def shipment_goods_identifier_options
    predefined_dimensions = {
      "PLL" => { length: "120", width: "80" },
      "HPL" => { length: "80", width: "60" },
      "QPL" => { length: "60", width: "40" },
    }

    predefined_identifiers = {
      "CLL" => "Custom size",
      "PLL" => "EUR-pallet",
      "HPL" => "Half pallet",
      "QPL" => "Quarter pallet",
    }

    predefined_identifiers.map do |identifier, name|
      {
        name: name,
        value: identifier,
        predefined_dimensions: predefined_dimensions.fetch(identifier, {}),
      }
    end
  end
end
