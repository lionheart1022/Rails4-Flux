(function() {
  var selector = "*[data-behavior~=margin_config_sales_price]"

  $(document).on("change", selector, function() {
    var salesPriceInput = $(this)
    var row = salesPriceInput.closest("tr")
    var marginInput = row.find("*[data-behavior~=margin_config_margin_input]")
    var baseCostPrice = parseFloat(salesPriceInput.data("base-cost-price")).toPrecision(12)

    if (!isNaN(baseCostPrice)) {
      var salesPrice = parseFloat(salesPriceInput.val().replace(",", ".")).toPrecision(12)
      var calculatedMarginValue = Math.round((salesPrice - baseCostPrice) * 100) / 100

      if (!isNaN(calculatedMarginValue)) {
        marginInput.val(calculatedMarginValue)
      }
    }
  })
})()
