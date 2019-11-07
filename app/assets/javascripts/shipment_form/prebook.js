(function() {
  var formSelector = "#new_shipment"
  var carrierProductRadioSelector = "input[name='shipment[carrier_product_id]']:checked"
  var rejectPattern = /^(_method|authenticity_token)=/

  window.SubmitShipmentForm = function() {
    var selectedCarrierProductId = $(carrierProductRadioSelector).val()
    if (!selectedCarrierProductId) {
      if (window.editingShipment === "true") {
        $(formSelector).submit()
      }

      return
    }

    var carrierProductMetadataElement = $("*[data-carrier-product-metadata-for=" + selectedCarrierProductId + "]")
    if (carrierProductMetadataElement.length === 0) {
      $(formSelector).submit()
      return
    }

    var carrierProductMetadata = carrierProductMetadataElement.data("carrier-product-metadata")
    var shouldRunPrebookHook = carrierProductMetadata["prebook_step"]

    if (!shouldRunPrebookHook) {
      $(formSelector).submit()
      return
    }

    prebookHook(
      carrierProductMetadata["prebook_url"],
      function() {
        CFModal.close()
        $(formSelector).submit()
      },
      function() {
        CFModal.close()
      },
      function(jqXHR, textStatus, errorThrown) {
        console.log("Failure but we'll just continue and submit the form", errorThrown, textStatus)
        CFModal.close()
        $(formSelector).submit()
      }
    )
  }

  function prebookHook(url, successCallback, cancelCallback, errorCallback) {
    CFModal.init({ title: "Booking is in progress..." })
    CFModal.showSpinner()

    var formData = getShipmentFormData()

    var jqXHR = $.ajax({ url: url, type: "POST", data: formData })
    jqXHR.done(function(data, textStatus, jqXHR) {
      if (data.type === "confirmation") {
        CFModal.showHTMLContent(data.html_content)

        CFModal.$dialog.dialog("option", {
          title: data.title,
          buttons: [
            {
              text: "Cancel",
              class: "cf-ui-dialog-modal--cancel-btn",
              click: cancelCallback,
            },
            {
              text: "Confirm and book",
              class: "cf-ui-dialog-modal--ok-btn",
              click: successCallback,
            },
          ]
        })
      } else if (data.type === "continue") {
        successCallback()
      } else {
        console.log("Unexpected prebook response type", data.type)
        errorCallback()
      }
    })

    jqXHR.fail(errorCallback)
  }

  // Returns the shipment form data, without the _method and authenticity_token fields.
  // Also shipment_id is added (when editing shipment).
  function getShipmentFormData() {
    var formData = $(formSelector).serialize()
    var splitFormData = formData.split("&")
    var filteredFormData = splitFormData.filter(function(formData) {
      var rejectIf = formData.match(rejectPattern)
      return !rejectIf
    })

    filteredFormData.push("customer_id=" + encodeURIComponent(window.customerId))

    return filteredFormData.join("&")
  }
})()
