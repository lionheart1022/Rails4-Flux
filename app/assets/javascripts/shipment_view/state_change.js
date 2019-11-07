// In the shipment view
(function() {
  var formSelector = "form#shipment_state_change";
  var stateSelectSelector = formSelector + " select#shipment_state";
  var awbInputSelector = formSelector + " #shipment_awb";

  $(document).on("change", stateSelectSelector, function() {
    var stateValue = $(this).val();

    if (stateValue === "booked") {
      $(awbInputSelector).prop("disabled", false);
    } else {
      $(awbInputSelector).prop("disabled", true);
    }
  });

  $(function() {
    $(stateSelectSelector).trigger("change");
  });
})();

// In the list view (shown with the qtip-plugin)
(function() {
  var formSelector = "*[data-shipment-state-change-form=true]";
  var stateSelectSelector = ".input.shipment_state select";
  var awbInputSelector = ".input.shipment_awb input";

  $(document).on("change", formSelector + " " + stateSelectSelector, function() {
    var $this = $(this);
    var stateValue = $this.val();

    var form = $this.closest("form");
    var awbInput = form.find(awbInputSelector);

    if (stateValue === "booked") {
      awbInput.prop("disabled", false);
    } else {
      awbInput.prop("disabled", true);
    }
  });

  $(document).on("shipment_state_change_form:init", formSelector, function() {
    $(this).find(stateSelectSelector).trigger("change");
  });
})();
