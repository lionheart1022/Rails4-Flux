(function() {
  var toggleButtonSelector = "*[data-behavior~=shipment_bulk_update__toggle_button]"
  var checkboxSelector = "*[data-behavior~=shipment_bulk_update__shipment_id_checkbox]"
  var formSelector = "*[data-behavior~=shipment_bulk_update__form]"
  var shipmentCountSelector = "*[data-behavior~=shipment_bulk_update__shipment_count]"

  function updateShipmentCount() {
    var countElement = $(shipmentCountSelector)
    var enabledCheckboxes = $(checkboxSelector).filter(":checked")
    var count = enabledCheckboxes.length

    if (count === 0) {
      countElement.html("No shipments selected")
    } else if (count === 1) {
      countElement.html("1 shipment selected")
    } else {
      countElement.html(count + " shipments selected")
    }
  }

  $(document).on("click", toggleButtonSelector, function() {
    var form = $(formSelector)
    var show = !form.is(":visible")
    form.toggle(show)
    $(checkboxSelector).toggle(show)
    updateShipmentCount()
  })

  $(document).on("submit", formSelector, function(event) {
    var form = $(formSelector)
    var hiddenFields = form.find("*[data-behavior~=shipment_bulk_update__hidden_fields]")
    var enabledCheckboxes = $(checkboxSelector).filter(":checked")

    hiddenFields.html("")

    $.each(enabledCheckboxes, function() {
      var checkbox = $(this)
      var hiddenField = $('<input type="hidden" name="bulk_update[shipment_ids][]">')
      hiddenField.val(checkbox.val())
      hiddenFields.append(hiddenField)
    })
  })

  $(document).on("change", checkboxSelector, function() {
    updateShipmentCount()
  })
})()
