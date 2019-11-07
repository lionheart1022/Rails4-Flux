(function() {
  var toggleCheckboxSelector = "*[data-behavior~=toggle_all_notifications]"
  var notificationSettingSelector = "*[data-behavior~=notification_setting]"

  var allNotificationSettingsAreChecked = function(form) {
    var notificationSettings = form.find(notificationSettingSelector)
    return notificationSettings.length === notificationSettings.filter(":checked").length
  }

  $(document).on("change", toggleCheckboxSelector, function() {
    var $this = $(this)
    var form = $this.closest("form")
    form.find(notificationSettingSelector).prop("checked", $this.prop("checked"))
  })

  $(document).on("change", notificationSettingSelector, function() {
    var $this = $(this)
    var form = $this.closest("form")
    var toggleCheckbox = form.find(toggleCheckboxSelector)
    toggleCheckbox.prop("checked", allNotificationSettingsAreChecked(form))
  })

  $(function() {
    $(toggleCheckboxSelector).each(function() {
      var toggleCheckbox = $(this)
      toggleCheckbox.show()

      // Trigger a change event on the first notification setting to set the state of the toggle check box
      var form = toggleCheckbox.closest("form")
      form.find(notificationSettingSelector).first().trigger("change")
    })
  })
})()
