(function() {
  var checkboxSelector = "input[data-behavior~=carrier_product__automatic_tracking_checkbox]"
  var checkboxCellSelector = "td[data-behavior~=carrier_product__automatic_tracking_checkbox__cell]"
  var checkboxAllSelector = "input[data-behavior~=carrier_product__automatic_tracking_checkbox__all]"
  var tableHeaderSelector = "th[data-behavior~=carrier_product__automatic_tracking_checkbox__th]"
  var bulkUpdateRowSelector = "tr[data-behavior~=carrier_product__bulk_update__tr]"

  $(document).on("change", checkboxSelector, function() {
    var parent = $(this).closest("table")
    var checkboxes = parent.find(checkboxSelector)
    var checkedCheckboxes = checkboxes.filter(":checked")
    var checkboxAll = parent.find(checkboxAllSelector)

    if (checkedCheckboxes.length === checkboxes.length) {
      checkboxAll.prop("checked", true)
      checkboxAll.prop("indeterminate", false)
    } else if (checkedCheckboxes.length === 0) {
      checkboxAll.prop("checked", false)
      checkboxAll.prop("indeterminate", false)
    } else {
      checkboxAll.prop("indeterminate", true)
    }
  })

  $(document).on("change", checkboxAllSelector, function() {
    var parent = $(this).closest("table")
    var checkboxes = parent.find(checkboxSelector)
    var allIsChecked = $(this).is(":checked")

    checkboxes.prop("checked", allIsChecked)
  })

  $(function() {
    $(checkboxSelector).first().trigger("change")

    if ($(bulkUpdateRowSelector).length > 0) {
      var parent = $(bulkUpdateRowSelector).closest("table")

      if (parent.find(checkboxSelector).length === 0) {
        parent.find(bulkUpdateRowSelector).hide()
        parent.find(checkboxCellSelector).hide()
        parent.find(tableHeaderSelector).hide()
      }
    }
  })
})()
