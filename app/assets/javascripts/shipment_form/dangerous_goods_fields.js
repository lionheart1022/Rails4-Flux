(function() {
  var enableSelector = "#new_shipment #shipment_dangerous_goods";
  var fieldsSelector = "#new_shipment .dgr_fields";
  var actualFieldsSelector = "#new_shipment .dgr_actual_fields";
  var predefinedOptionSelector = "#new_shipment select#shipment_dangerous_goods_predefined_option";

  $(document).on("change", enableSelector, function() {
    var isEnabled = $(this).is(":checked");
    $(fieldsSelector).toggle(isEnabled);
    $(fieldsSelector).find(":input").prop("disabled", !isEnabled);
  });

  $(document).on("change", predefinedOptionSelector, function() {
    var isOther = $(this).val() === "other";
    $(actualFieldsSelector).toggle(isOther);
  });

  $(function() {
    $(enableSelector).trigger("change");
    $(predefinedOptionSelector).trigger("change");
  });
})();
