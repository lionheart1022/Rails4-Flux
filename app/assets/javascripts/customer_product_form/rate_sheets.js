(function() {
  var rowSelector = "*[data-behavior~=customer_product__row]"
  var marginPercentageSelector = "*[data-behavior~=customer_product__input_margin_percentage]"
  var marginTypeSelector = "*[data-behavior~=customer_product__margin_type_select]"
  var rateSheetBtnSelector = "*[data-behavior~=customer_product__rate_sheet_btn]"

  $(document).on("input", marginPercentageSelector, function(event) {
    var marginPercentageInput = $(this)
    var row = $(this).closest(rowSelector)
    var rateSheetBtn = row.find(rateSheetBtnSelector)

    var marginChanged = marginPercentageInput.prop("defaultValue") !== marginPercentageInput.val()
    var showRateSheetBtn = !marginChanged

    if (showRateSheetBtn) {
      rateSheetBtn.css("visibility", "visible")
    } else {
      rateSheetBtn.css("visibility", "hidden")
    }
  })

  $(document).on("change", marginTypeSelector, function(event) {
    var marginTypeSelect = $(this)
    var row = $(this).closest(rowSelector)
    var rateSheetBtn = row.find(rateSheetBtnSelector)

    var defaultSelectedOptions = marginTypeSelect.find("option").toArray().filter(function(option) { return option.defaultSelected })
    var defaultValue = defaultSelectedOptions.length == 1 ? defaultSelectedOptions[0].value : null

    var marginTypeChanged = defaultValue !== marginTypeSelect.val()
    var showRateSheetBtn = !marginTypeChanged

    if (showRateSheetBtn) {
      rateSheetBtn.css("visibility", "visible")
    } else {
      rateSheetBtn.css("visibility", "hidden")
    }
  })
})()
