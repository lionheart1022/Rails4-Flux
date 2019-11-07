(function() {
  var truckSelector = "*[data-behavior~=shipment_form_truck_select]"
  var driverSelector = "*[data-behavior~=shipment_form_driver_select]"
  $(document).on("change", truckSelector, function(){
    var $this = $(this)
    var behaviorConfig = $this.data("behavior-config")
    var truckDefaultDrivers = behaviorConfig.default_drivers
    var driverInput = $(driverSelector)
    driverInput.val(truckDefaultDrivers[$this.val()])
  })
})()
