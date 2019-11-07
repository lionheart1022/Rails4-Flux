(function() {
  var shipmentCheckboxSelector = "*[data-behavior~=report__selected_shipment_checkbox]"
  var shipmentHiddenInputSelector = "*[data-behavior~=report__hidden_selected_shipment_input]"
  var shipmentToggleSelector = "*[data-behavior~=report__toggle_shipment_selection]"
  var loadMoreSelector = "*[data-behavior~=report__load_more_btn]"

  $(document).on("change", shipmentToggleSelector, function() {
    var $this = $(this)
    var isChecked = $this.is(":checked")
    var form = $this.closest("form")
    form.find(shipmentCheckboxSelector).prop("checked", isChecked)
    form.find(shipmentHiddenInputSelector).prop("value", isChecked ? "1" : "0")

    var loadMoreBtn = form.find(loadMoreSelector)
    if (loadMoreBtn.length > 0) {
      var dataParamsString = loadMoreBtn.attr("data-params")
      var dataParams = JSON.parse(dataParamsString)
      dataParams.report.selected = isChecked
      loadMoreBtn.attr("data-params", JSON.stringify(dataParams))
    }
  })
})()
