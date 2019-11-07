(function() {
  var tableHeaderSelector = "*[data-behavior~=carrier_product__credentials__th]"

  $(function() {
    $(tableHeaderSelector).each(function() {
      var $this = $(this)
      var parent = $this.closest("table")

      var withCredentials = parent.find("td[data-carrier-product-has-credentials=true]")

      if (withCredentials.length === 0) {
        $this.hide()
        parent.find("td[data-carrier-product-has-credentials]").hide()
      }
    })
  })
})()
