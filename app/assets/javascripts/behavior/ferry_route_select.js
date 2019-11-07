(function() {
  var routeSelectSelector = "*[data-behavior~=ferry_route_select]"
  var departureTimeSelectSelector = "*[data-behavior~=ferry_departure_time_select]"

  $(document).on("change", routeSelectSelector, function() {
    var $this = $(this)
    var behaviorConfig = $this.data("behavior-config")
    var routeDepartureTimesMap = behaviorConfig.route_departure_times_map
    var departureTimeSelect = $(departureTimeSelectSelector)
    var originalDepartureTimeValue = departureTimeSelect.val()

    departureTimeSelect.find("option:not([value=''])").remove()

    if ($this.val() !== "") {
      var routeId = Number($this.val())
      $.each(routeDepartureTimesMap[routeId], function() {
        var option = $("<option>")
        option.val(this)
        option.text(this)

        departureTimeSelect.append(option)
      })

      departureTimeSelect.val(originalDepartureTimeValue)
    }
  })

  $(function() {
    $(routeSelectSelector).trigger("change")
  })
})()
