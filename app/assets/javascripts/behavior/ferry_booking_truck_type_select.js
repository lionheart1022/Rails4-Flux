(function() {
  var truckTypeSelectSelector = "*[data-behavior~=ferry_booking_truck_type_select]"
  var truckLengthSelector = "*[data-behavior~=ferry_booking_truck_length]"

  $(document).on("change", truckTypeSelectSelector, function() {
    var $this = $(this)
    var behaviorConfig = $this.data("behavior-config")
    var truckTypeDefaultLengths = behaviorConfig.truck_type_default_lengths

    if ($this.val() !== "") {
      var truckLengthInput = $(truckLengthSelector)
      truckLengthInput.val(truckTypeDefaultLengths[$this.val()])
    }
  })
})()
