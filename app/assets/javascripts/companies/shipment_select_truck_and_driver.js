$(function() {
  var shipmentTruckAndDriverFields = $(".truck_and_driver.form_pane .truck_and_driver_fields");

  $("#shipment_select_truck_and_driver").on("change", function() {
    var selectTruckAndDriverIsChecked = $(this).is(":checked");
    shipmentTruckAndDriverFields.toggle(selectTruckAndDriverIsChecked);
  });

  $("#shipment_select_truck_and_driver").trigger("change");
});
