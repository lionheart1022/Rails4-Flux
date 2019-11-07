(function() {
  var rowSelector = "*[data-behavior~=customer_product__row]"
  var enableSelector = "*[data-behavior~=customer_product__input_enable]"
  var enableAutobookingSelector = "*[data-behavior~=customer_product__input_enable_autobooking]"
  var autobookSelector = "*[data-behavior~=customer_product__input_autobook]"
  var marginStateSelector = "*[data-behavior~=customer_product__margin_state]"
  var marginPercentageSelector = "*[data-behavior~=customer_product__input_margin_percentage]"
  var marginTypeSelector = "*[data-behavior~=customer_product__margin_type_select]"

  $(document).on("change", enableSelector, function(event) {
    var enableNode = $(this)
    var isEnabled = enableNode.is(":checked")
    var row = $(this).closest(rowSelector)
    var marginStateNode = row.find(marginStateSelector)
    var marginTypeSelect = row.find(marginTypeSelector)

    if (isEnabled) {
      marginTypeSelect.trigger("change")
    } else {
      if (enableNode.prop("defaultChecked")) {
        marginStateNode.attr("class", "customer_product__margin_state__not_disabled_yet")
      } else {
        marginStateNode.attr("class", "customer_product__margin_state__disabled")
      }
    }

    if (isEnabled) {
      row.find("input[type=checkbox]:disabled").prop("disabled", false)
      row.find("*[readonly]:input").prop("readonly", false)

      // We check for the originalEvent because we don't want to focus on page load or perform auto-checking
      if (event.originalEvent) {
        row.find(enableAutobookingSelector).prop("checked", true).trigger("change")
        row.find(autobookSelector).prop("checked", true).trigger("change")
        row.find(marginPercentageSelector).focus()
      }
    } else {
      row.find("input[type=checkbox]").not(enableSelector).prop("checked", false).prop("disabled", true).trigger("change")
      row.find(":not(input[type=checkbox]):input").prop("readonly", true)
    }
  })

  $(document).on("change", marginTypeSelector, function() {
    var marginTypeSelect = $(this)
    var marginType = marginTypeSelect.val()
    var row = marginTypeSelect.closest(rowSelector)
    var marginStateNode = row.find(marginStateSelector)

    if (marginType == "percentage") {
      marginStateNode.attr("class", "customer_product__margin_state__enabled__percentage")
    } else if (marginType == "intervals") {
      marginStateNode.attr("class", "customer_product__margin_state__enabled__intervals")
    }
  })

  $(document).on("change", enableAutobookingSelector, function() {
    var isAutobookingEnabled = $(this).is(":checked")
    var row = $(this).closest(rowSelector)

    if (!isAutobookingEnabled) {
      row.find(autobookSelector).prop("checked", false)
    }
  })

  $(function() {
    $(enableSelector).trigger("change")
  })
})()
