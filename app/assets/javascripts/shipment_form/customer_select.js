(function() {
  var inputSelector = "#shipment_customer_id_select";

  var autocompletePickupContactFields = function(contact) {
    $("#shipment_pickup_options_contact_attributes_company_name").val(contact.company_name).change();
    $("#shipment_pickup_options_contact_attributes_attention").val(contact.attention).change();
    $("#shipment_pickup_options_contact_attributes_address_line1").val(contact.address_line1).change();
    $("#shipment_pickup_options_contact_attributes_address_line2").val(contact.address_line2).change();
    $("#shipment_pickup_options_contact_attributes_zip_code").val(contact.zip_code).change();
    $("#shipment_pickup_options_contact_attributes_city").val(contact.city).change();
    $("#shipment_pickup_options_contact_attributes_country_code").val(contact.country_code).change();
    $("#shipment_pickup_options_contact_attributes_state_code").val(contact.state_code).change();
    $("#shipment_pickup_options_contact_attributes_phone_number").val(contact.phone_number).change();
    $("#shipment_pickup_options_contact_attributes_email").val(contact.email).change();
  };

  $(document).on("select2:select", inputSelector, function(event) {
    var shipmentFormConfigElement = $("#shipment_form_config");
    var shipmentFormConfig = shipmentFormConfigElement.length === 1 ? shipmentFormConfigElement.data("shipment-form-config") : {};

    var data = event.params.data;
    var customerId = data.id;
    window.customerId = customerId;

    if (shipmentFormConfig && shipmentFormConfig.shipmentPriceURLKey) {
      window.shipmentPriceURL = data[shipmentFormConfig.shipmentPriceURLKey]
    }

    cargoflux.autocompleteShipmentSenderForm(data.address);
    autocompletePickupContactFields(data.address);
  });

  $(function() {
    $(inputSelector).each(function() {
      $(this).select2({
        theme: "cargoflux",
        ajax: {
          dataType: "json",
          delay: 250,
          cache: true,
        },
        containerCssClass: "input string",
      });
    });
  });
})();
