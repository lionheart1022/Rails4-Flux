(function() {
  var enableSelector = "*[data-behavior~=billing_configuration_enable]"
  var settingsSelector = "*[data-behavior~=billing_configuration_settings]"
  var dayIntervalInputSelector = "*[data-behavior~=billing_configuration_day_interval_input]"

  $(document).on("change", enableSelector, function(e) {
    var $this = $(this)
    var isEnabled = $this.is(":checked")
    var form = $this.closest("form")

    form.find(settingsSelector).toggle(isEnabled)

    // We check for the originalEvent because we don't want to focus on page load
    if (isEnabled && e.originalEvent) {
      form.find(dayIntervalInputSelector).focus()
    }
  })

  $(function() {
    $(enableSelector).trigger("change")
  })
})()
