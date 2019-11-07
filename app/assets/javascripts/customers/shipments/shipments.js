$(function() {

  // Define namespace if non-existant
  if (typeof cargoflux === 'undefined') {
    cargoflux = new Object();
    cargoflux._mapLoaded = false;
  }

  var digest;

  // ============================================================
  // Show page:
  // ============================================================

  // Init S3 Uploader (Invoice attachment)
  $('#body_customers #s3_invoice_attachment_uploader').S3Uploader({
    remove_completed_progress_bar: true,
    progress_bar_target: $('#body_customers #invoice_attachment_uploads')
  });

  // S3 Uploader, Upload failed callback (Invoice attachment)
  $('#body_customers #s3_invoice_attachment_uploader').bind('s3_upload_failed', function(e, content) {
    return alert(content.filename + ' failed to upload');
  });


  // Init S3 Uploader (Consignment note attachment)
  $('#body_customers #s3_consignment_note_attachment_uploader').S3Uploader({
    remove_completed_progress_bar: true,
    progress_bar_target: $('#body_customers #consignment_note_attachment_uploads')
  });

  // S3 Uploader, Upload failed callback (Consignment note attachment)
  $('#body_customers #s3_consignment_note_attachment_uploader').bind('s3_upload_failed', function(e, content) {
    return alert(content.filename + ' failed to upload');
  });

  // ============================================================
  // New page:
  // ============================================================

  // Disable new shipment submit button until carrier product is selected
  $(document).on('ready', function() {
    if (!window.editingShipment) {
      $('#create_shipment').prop('disabled', true);
    }
    $('#loading_indicator').hide();
    cargoflux.resetCalculatedFields();
  });

  $('#shipping_carrier_products').on('change', function() {
    if ($("input:radio[name='shipment[carrier_product_id]']").is(':checked')) {
      $('#create_shipment').attr('disabled', false)
    }
  });

  $('.customer.route_link').on('click', function (event) {
    var _class = $(this).attr('class').split(' ').join('.');

    event.preventDefault();
    cargoflux.toggleMapBox(_class, 400, 400);
  });

  // Listen on field input
  var fields = ["country_code", "zip_code", "address_line1", "address_line2", "address_line3", "city"];
  var selectors = _.map(fields, function(field) {
    var selector = "input[name*='" + field + "']";
    return selector;
  });

  selectors.forEach(function(selector) {
    var filteredSelector = $(selector).filter("input[name^='shipment\[recipient_attributes\]'], input[name^='shipment\[sender_attributes\]']");
    filteredSelector.on('input', _.debounce(function () {
      cargoflux.resetCalculatedFields();
      fetchAndRenderRoute();
      cargoflux.getAvailableCarrierProducts();
    }, 2000));
  });

  var fetchAndRenderRoute = function () {
    var baseSenderId = '#shipment_sender_attributes_';
    var baseRecipientId = '#shipment_recipient_attributes_';

    var parties = ['sender', 'recipient'];
    var fields = [
      { id: 'country_code', selector: ':selected' },
      { id: 'zip_code' },
      { id: 'city' },
      { id: 'address_line1' },
      { id: 'address_line2' },
      { id: 'address_line3' },
    ];

    var addresses = {
      sender: [],
      recipient: []
    };

    var baseId, inputId, value;
    parties.forEach(function(party) {
      baseId = '#shipment_' + party + '_attributes_';

      fields.forEach(function(field) {
        inputId = baseId + field.id;

        if (field.selector) {
          inputId = inputId + " " + field.selector
          value = $(inputId).text();
        } else {
          value = $(inputId).val();
        }

        if (!!value) addresses[party].push(value);
      });
    });

    sender_address = addresses.sender.join(' ');
    recipient_address = addresses.recipient.join(' ');

    if (!!sender_address && !!recipient_address) {
      cargoflux.fetchRoute(sender_address, recipient_address);
    }
  }

  cargoflux.autocompleteShipmentRecipientForm = function(contact) {
    $('#shipment_recipient_attributes_company_name').val(contact.company_name).change();
    $('#shipment_recipient_attributes_attention').val(contact.attention).change();
    $('#shipment_recipient_attributes_address_line1').val(contact.address_line1).change();
    $('#shipment_recipient_attributes_address_line2').val(contact.address_line2).change();
    $('#shipment_recipient_attributes_address_line3').val(contact.address_line3).change();
    $('#shipment_recipient_attributes_zip_code').val(contact.zip_code).change();
    $('#shipment_recipient_attributes_city').val(contact.city).change();
    $('#shipment_recipient_attributes_country_code').val(contact.country_code).change();
    $('#shipment_recipient_attributes_state_code').val(contact.state_code).change();
    $('#shipment_recipient_attributes_phone_number').val(contact.phone_number).change();
    $('#shipment_recipient_attributes_email').val(contact.email).change();
    $('#shipment_recipient_attributes_residential').prop('checked', contact.residential).change();

    cargoflux.showOrHideStateBasedOnCountry();
    cargoflux.resetCarrierProductPriceFields();
    cargoflux.getAvailableCarrierProducts();
  };

  cargoflux.autocompleteShipmentSenderForm = function(contact) {
    $('#shipment_sender_attributes_company_name').val(contact.company_name).change();
    $('#shipment_sender_attributes_attention').val(contact.attention).change();
    $('#shipment_sender_attributes_address_line1').val(contact.address_line1).change();
    $('#shipment_sender_attributes_address_line2').val(contact.address_line2).change();
    $('#shipment_sender_attributes_zip_code').val(contact.zip_code).change();
    $('#shipment_sender_attributes_city').val(contact.city).change();
    $('#shipment_sender_attributes_country_code').val(contact.country_code).change();
    $('#shipment_sender_attributes_state_code').val(contact.state_code).change();
    $('#shipment_sender_attributes_phone_number').val(contact.phone_number).change();
    $('#shipment_sender_attributes_email').val(contact.email).change();
    $('#shipment_sender_attributes_residential').prop('checked', contact.residential).change();

    cargoflux.resetCarrierProductPriceFields();
    cargoflux.getAvailableCarrierProducts();
  };

  // Toggle the state dropdown if country is selected
  cargoflux.showOrHideStateBasedOnCountry = function() {
    var country = $('#shipment_sender_attributes_country_code :selected').val()
    var options = $(states).filter("optgroup[label='" + country + "']").html()
    if (options) {
      $("#shipment_sender_attributes_state_code").parent().show();
    } else {
      $("#shipment_sender_attributes_state_code").parent().hide();
    }

    var country = $('#shipment_pickup_options_contact_attributes_country_code :selected').val()
    var options = $(states).filter("optgroup[label='" + country + "']").html()
    if (options) {
      $("#shipment_pickup_options_contact_attributes_state_code").parent().show();
    } else {
      $("#shipment_pickup_options_contact_attributes_state_code").parent().hide();
    }

    var country = $('#shipment_recipient_attributes_country_code :selected').val()
    var options = $(states).filter("optgroup[label='" + country + "']").html()
    if (options) {
      $("#shipment_recipient_attributes_state_code").parent().show();
    } else {
      $("#shipment_recipient_attributes_state_code").parent().hide();
    }

  }

  // Filters the states based on country
  cargoflux.updateStatesDropdown = function(country, stateElementId, states) {
    var options = $(states).filter("optgroup[label='" + country + "']").html()
    var $states = $(stateElementId)

    if (options) {
      var state = $(stateElementId).val()
      $states.html(options)
      $(stateElementId).val(state)
      $states.parent().show()
    } else {
      $states.empty()
      $states.parent().hide()
    }
  }

  // Stores the full list of states
  var states          = $("#shipment_sender_attributes_state_code").html()

  // Display states dropdown based on selected country
  $(document).ready(function() {
    var senderCountry    = $('#shipment_sender_attributes_country_code :selected').val()
    var recipientCountry = $('#shipment_recipient_attributes_country_code :selected').val()
    var pickupCountry    = $('#shipment_pickup_options_contact_attributes_country_code :selected').val()

    var senderState      = '#shipment_sender_attributes_state_code'
    var recipientState   = '#shipment_recipient_attributes_state_code'
    var pickupState      = '#shipment_pickup_options_contact_attributes_state_code'

    $("#shipment_sender_attributes_state_code").parent().hide()
    $("#shipment_recipient_attributes_state_code").parent().hide()
    $("#shipment_pickup_options_contact_attributes_state_code").parent().hide()

    cargoflux.updateStatesDropdown(senderCountry, senderState, states)
    cargoflux.updateStatesDropdown(recipientCountry, recipientState, states)
    cargoflux.updateStatesDropdown(pickupCountry, pickupState, states)

    cargoflux.showOrHideStateBasedOnCountry()
  })

  // Updates and filters states dropdown on import/export toggle
  $('#shipment_shipment_type').change(function() {
    var senderCountry = $('#shipment_sender_attributes_country_code :selected').val()
    var recipientCountry = $('#shipment_recipient_attributes_country_code :selected').val()

    var senderState = '#shipment_sender_attributes_state_code'
    var recipientState = '#shipment_recipient_attributes_state_code'
    var senderStateValue = $('#shipment_sender_attributes_state_code').val()
    var recipientStateValue = $('#shipment_recipient_attributes_state_code').val()

    cargoflux.updateStatesDropdown(senderCountry, senderState, states)
    cargoflux.updateStatesDropdown(recipientCountry, recipientState, states)

    $('#shipment_sender_attributes_state_code').val(recipientStateValue);
    $('#shipment_recipient_attributes_state_code').val(senderStateValue);

    cargoflux.showOrHideStateBasedOnCountry()

  })

  // The three following updates and filters the states dropdown based on selected country
  $('#shipment_sender_attributes_country_code').change(function() {
    country = $('#shipment_sender_attributes_country_code :selected').val()
    stateElementId = '#shipment_sender_attributes_state_code'
    cargoflux.updateStatesDropdown(country, stateElementId, states)
    cargoflux.showOrHideStateBasedOnCountry();

    cargoflux.resetCalculatedFields();
    fetchAndRenderRoute();
    cargoflux.getAvailableCarrierProducts();
  })

  $('#shipment_recipient_attributes_country_code').change(function() {
    country = $('#shipment_recipient_attributes_country_code :selected').val()
    stateElementId = '#shipment_recipient_attributes_state_code'

    digest = cargoflux.generateUUID();
    cargoflux.updateStatesDropdown(country, stateElementId, states)
    cargoflux.showOrHideStateBasedOnCountry()

    cargoflux.resetCalculatedFields();
    fetchAndRenderRoute();
    cargoflux.getAvailableCarrierProducts();
  })

  $('#shipment_pickup_options_contact_attributes_country_code').change(function() {
    var country = $('#shipment_pickup_options_contact_attributes_country_code :selected').val()
    var stateElementId = '#shipment_pickup_options_contact_attributes_state_code'

    cargoflux.updateStatesDropdown(country, stateElementId, states)
    cargoflux.showOrHideStateBasedOnCountry()
  })

  // Calculates wheter to add or remove rows and does it
  cargoflux.updatePackageDimensionRows = function(newRowCount) {
    digest = cargoflux.generateUUID();
    var $existingRows = $("#new_shipment .package_dimension");
    var existingRowCount = $existingRows.length;

    // Remove rows
    if (newRowCount < existingRowCount) {
      $existingRows.slice(newRowCount).remove();
    }
    // Add rows
    else if (newRowCount > existingRowCount) {
      var addRowsCount = newRowCount - existingRowCount;
      for (var i = 0 ; i < addRowsCount; i++) {
        cargoflux.addPackageDimensionRow();
      }
    }

    // Recalculate weights
    cargoflux.recalculateVolumeWeight("all");
  }

  // Clones hidden template div and appends it to the form
  cargoflux.addPackageDimensionRow = function() {
    digest = cargoflux.generateUUID();
    var newId = new Date().getTime();

    // Ensure we never get elements with a duplicate id
    var searchForId = "#package_dimension_" + newId;

    while ($(searchForId).length > 0) {
      newId = new Date().getTime();
      searchForId = "#package_dimension_" + newId;
    }

    var $selector     = $("#new_shipment .package_dimensions .dimensions")
    var $templateHtml = $("#package_dimension_template_form .package_dimension").clone().wrap('<div/>').parent().html().replace(/REPLACE_ME/g, newId);
    $selector.append($templateHtml);
    $selector.children().last().find('.amount').focus().val(1);
  }

  $("#shipment_carrier_product_id").on("change", function() {
    cargoflux.recalculateVolumeWeight("all");
  });

  $("#shipment_shipment_type").on("change", function() {
    digest = cargoflux.generateUUID();
    cargoflux.resetCalculatedFields();
    cargoflux.getAvailableCarrierProducts();
  });

  // Observe volume weight fields, recalculate total when changed
  $("#new_shipment .package_dimensions").on("change", ".observe_volume_weight", function() {
    var total = parseFloat(0);
    var val;

    $.each($("#new_shipment .package_dimensions .observe_volume_weight"), function() {
      val = $(this).val();
      if (val != '') {
        total += parseFloat($(this).val());
      }
    });

    $("#total_volume_weight").val(total.toFixed(2));
  });

  // Disable customs fields on-load and listen for changes to "Dutiable"
  // checkbox to enable/disable them
  cargoflux.shipment_customs_fields = $("#shipment_customs_amount, #shipment_customs_currency, #shipment_customs_code");

  $("#shipment_dutiable").on("change", function() {
    var $this = $(this);
    if ($this.is(':checked')) {
      $.each(cargoflux.shipment_customs_fields, function() {
        $(this).removeAttr("disabled");
      });
    }
    else {
      $.each(cargoflux.shipment_customs_fields, function() {
        $(this).attr("disabled", "disabled");
      });
    }
  });

  // Disable customs fields
  $("#shipment_dutiable").change();

  cargoflux.shipment_pickup_fields = $(".pickup.form_pane .pickup_fields");

  $("#shipment_request_pickup").on("change", function() {
    var requestPickupIsChecked = $(this).is(":checked");
    cargoflux.shipment_pickup_fields.toggle(requestPickupIsChecked);
  });

  $("#shipment_request_pickup").trigger("change");

  // Recalculates weight and updates form field
  cargoflux.recalculateRegularWeight = function() {
    var total  = parseFloat(0);
    var failed = false
    var val;
    var formatted_val;

    $.each($("#new_shipment .package_dimensions .package_dimension"), function() {
      var amount           = $(this).find('.amount').val()
      var weight           = $(this).find('.weight').val()

      formatted_weight = weight.replace(',', '.');
      if (cargoflux.isNumeric(weight) && cargoflux.isNumeric(amount)) {
        var total_row_weight = formatted_weight * amount
        total += parseFloat(total_row_weight);
        $(this).find('.total_row_weight').val(total_row_weight.toFixed(2));
      } else {
        $(this).find('.total_row_weight').val('N/A');
        $("#total_weight").val('N/A');
        failed = true
      }
    });

    if (!failed) {
      $("#total_weight").val(total.toFixed(2));
    }
  }

  function isBlank(str) {
    return (!str || /^\s*$/.test(str));
  }

  cargoflux.missingFields = function() {
    var packageDimensionsJSONElement = document.getElementById("shipment_form__package_dimensions_as_json")
    if (packageDimensionsJSONElement === null) {
      return true
    }

    var packageDimensions = JSON.parse(packageDimensionsJSONElement.dataset.dimensions)
    if (packageDimensions === null) {
      return true
    }

    var missing = false;
    $('.package_dimensions .price_required, .recipient .price_required, .customer_id .price_required').each(function() {
      var val = $(this).val()
      if (isBlank(val)) {
        missing = true;
      }
    });
    return missing;
  };

  cargoflux.invalidInput = function() {
    var invalid = false;
    $('.package_dimensions .price_observe').each(function() {
      var val = $(this).val()
      if (!cargoflux.isNumeric(val)) {
        invalid = true;
      }
    });
    return invalid;
  }

  cargoflux.validInput = function() {
    return !cargoflux.invalidInput() && !cargoflux.missingFields();
  }

  $("#new_shipment").on('click', 'p.add', function(event) {
    event.preventDefault();
    digest = cargoflux.generateUUID();

    var currentNumberOfRows = $('.package_dimensions').length
    cargoflux.addPackageDimensionRow();
    cargoflux.resetCalculatedFields()
  });

  $("#new_shipment").on("click", "button.add_package_row", function(event) {
    digest = cargoflux.generateUUID()

    var $packageSizeSelect = $("#new_shipment select.predefined_package_size")
    var $selectedOption = $packageSizeSelect.find("option:selected")
    var packageDimensions = $selectedOption.data("predefined-package-dimensions")

    var $selector = $("#new_shipment .package_dimensions .dimensions")
    var fillInDimensions = null;

    // Initially we want to fill in the first package line item, if it has not been altered.
    if (packageDimensions && $selector.children().length == 1) {
      var $lastDimensions = $selector.children().last()

      var dimAmount = $lastDimensions.find('input.amount').val()
      var dimLength = $lastDimensions.find('input.length').val()
      var dimWidth = $lastDimensions.find('input.width').val()

      if (dimAmount === "1" && dimLength === "" && dimWidth === "") {
        fillInDimensions = $lastDimensions;
      }
    }

    if (fillInDimensions === null) {
      cargoflux.addPackageDimensionRow()
      fillInDimensions = $selector.children().last()
    }

    if (packageDimensions) {
      fillInDimensions.find('input.length').val(packageDimensions["length"])
      fillInDimensions.find('input.width').val(packageDimensions["width"])
    }

    cargoflux.resetCalculatedFields()
  });

  $('#new_shipment').on('click', 'p.remove_package_row', function(event) {
    event.preventDefault();
    digest = cargoflux.generateUUID();

    var row = $(event.currentTarget).parent();
    row.remove();
    cargoflux.resetCalculatedFields()
    cargoflux.getAvailableCarrierProducts();
  });

  cargoflux.resetCalculatedFields = function() {
    $('#loading_indicator').show();
    $('#incomplete_information').hide();
    $('#shipping_carrier_products').html('');

    if (cargoflux.missingFields()) {
      $('#incomplete_information').show();
      $('#invalid_information').hide();
      $('#loading_indicator').hide();
    } else if (cargoflux.invalidInput()) {
      $('#incomplete_information').hide();
      $('#invalid_information').show();
      $('#loading_indicator').hide();
    } else {
      $('#incomplete_information').hide();
      $('#loading_indicator').show();
      $('#invalid_information').hide();
    }

    cargoflux.resetCarrierProductPriceFields();
    cargoflux.recalculateRegularWeight();
    cargoflux.recalculateVolumeWeight("all");
  };

  // Do visual price calculation immediately
  $('#new_shipment').on('keyup', '.price_observe', function() {
    digest = cargoflux.generateUUID();
    cargoflux.resetCalculatedFields();
  })

  $(document).on("shipment_form_goods_lines:price_related_change", function() {
    digest = cargoflux.generateUUID();
    cargoflux.resetCalculatedFields();
  })

  $('#new_shipment').on('change', 'input[type=checkbox].price_observe', function() {
    digest = cargoflux.generateUUID();
    cargoflux.resetCalculatedFields();
  })

  $('#new_shipment').on('change', '.shipment_shipping_date.input select.price_observe', function() {
    digest = cargoflux.generateUUID();
    cargoflux.resetCalculatedFields();
  })

  // Delay actual ajax request
  var timeOut = 0;
  $('#new_shipment').on('keyup', '.price_observe', function() {
    clearTimeout(timeOut);
    timeOut = setTimeout(function() {
      if (cargoflux.validInput()) {
        cargoflux.resetCalculatedFields();
        cargoflux.getAvailableCarrierProducts();
      }
    }, 1500);
  })

  $(document).on("shipment_form_goods_lines:price_related_change", function() {
    clearTimeout(timeOut);
    timeOut = setTimeout(function() {
      if (cargoflux.validInput()) {
        cargoflux.resetCalculatedFields();
        cargoflux.getAvailableCarrierProducts();
      }
    }, 1500);
  })

  $('#new_shipment').on('change', 'input[type=checkbox].price_observe', function() {
    clearTimeout(timeOut);
    timeOut = setTimeout(function() {
      if (cargoflux.validInput()) {
        cargoflux.resetCalculatedFields();
        cargoflux.getAvailableCarrierProducts();
      }
    }, 1500);
  })

  $('#new_shipment').on('change', '.shipment_shipping_date.input select.price_observe', function() {
    clearTimeout(timeOut);
    timeOut = setTimeout(function() {
      if (cargoflux.validInput()) {
        cargoflux.resetCalculatedFields();
        cargoflux.getAvailableCarrierProducts();
      }
    }, 1500);
  })

  // Gets available carrier products
  cargoflux.getAvailableCarrierProducts = function() {
    var sender_country_code  = $('.sender #shipment_sender_attributes_country_code').val();
    var sender_zip_code      = $('.sender #shipment_sender_attributes_zip_code').val();
    var sender_city          = $('.sender #shipment_sender_attributes_city').val();
    var sender_address_line1 = $('.sender #shipment_sender_attributes_address_line1').val();
    var sender_address_line2 = $('.sender #shipment_sender_attributes_address_line2').val();

    var recipient_country_code  = $('.recipient #shipment_recipient_attributes_country_code').val();
    var recipient_zip_code      = $('.recipient #shipment_recipient_attributes_zip_code').val();
    var recipient_city          = $('.recipient #shipment_recipient_attributes_city').val();
    var recipient_address_line1 = $('.recipient #shipment_recipient_attributes_address_line1').val();
    var recipient_address_line2 = $('.recipient #shipment_recipient_attributes_address_line2').val();

    var selected_carrier_product_id = $('#shipping_carrier_products input[type=radio]:checked').val();
    var shipment_type               = $('#shipment_shipment_type').val();
    var dangerous_goods             = $('#shipment_dangerous_goods').is(':checked');
    var residential                 = $('#shipment_recipient_attributes_residential').is(':checked');

    var shipping_date = moment({
      year: parseInt($("#shipment_shipping_date_1i").val()),
      month: parseInt($("#shipment_shipping_date_2i").val()) - 1,
      date: parseInt($("#shipment_shipping_date_3i").val()),
    })

    var packageDimensionsJSONElement = document.getElementById("shipment_form__package_dimensions_as_json")
    var packageDimensions = {}
    if (packageDimensionsJSONElement) {
      packageDimensions = JSON.parse(packageDimensionsJSONElement.dataset.dimensions)
    }

    var goodsLinesJSONElement = document.getElementById("shipment_form__goods_lines_as_json")
    var goodsLines = []
    if (goodsLinesJSONElement) {
      goodsLines = JSON.parse(goodsLinesJSONElement.dataset.dimensions)
    }

    var data = {
      selected_carrier_product_id: selected_carrier_product_id,
      package_dimensions:          packageDimensions,
      goods_lines:                 goodsLines,
      shipment_type:               shipment_type,
      shipping_date:               shipping_date.format("YYYY-MM-DD"),
      dangerous_goods:             dangerous_goods,
      residential:                 residential,
      digest:                      digest,

      sender: {
        country_code:  sender_country_code,
        city:          sender_city,
        zip_code:      sender_zip_code,
        address_line1: sender_address_line1,
        address_line2: sender_address_line2
      },
      recipient: {
        country_code:  recipient_country_code,
        city:          recipient_city,
        zip_code:      recipient_zip_code,
        address_line1: recipient_address_line1,
        address_line2: recipient_address_line2
      }
    }

    cargoflux.performGetCarriersAndPrices(data);
  }

  // Recalcuates volume weight and updates form field
  cargoflux.recalculateVolumeWeight = function(what) {
    clearTimeout(cargoflux.calculateVolumeWeightTimer);
    var carrierProductId = $("#shipment_carrier_product_id").val();

    if (carrierProductId === undefined || carrierProductId.length < 1) {
      return;
    }

    var data = {
      "carrier_product_id": carrierProductId,
      "package_dimensions": {}
    };

    // Calculate for all or single row
    var rows = (what === "all") ? $("#new_shipment .package_dimension") : $(what);

    $.each(rows, function(index, value) {
      var $row   = $(value);
      var rowId  = $row.data("row-id");
      var length = $row.find("input.length").val();
      var width  = $row.find("input.width").val();
      var height = $row.find("input.height").val();
      var amount = $row.find('input.amount').val();

      if (cargoflux.isNumeric(length) && cargoflux.isNumeric(width) && cargoflux.isNumeric(height) && cargoflux.isNumeric(amount)) {
        data["package_dimensions"][rowId] = {
          "id":     rowId,
          "length": length,
          "width":  width,
          "height": height,
          "amount": amount
        };
      }
    });

    if ($.isEmptyObject(data["package_dimensions"])) {
      return;
    }

    // Perform ajax request in 1 second unless reset before then
    cargoflux.calculateVolumeWeightTimer = setTimeout(function() {
      cargoflux.performVolumeWeightAjax(data);
    }, 1000);
  }

  // Call backend and get calculated volument weight
  cargoflux.performVolumeWeightAjax = function(data) {
    var endpoint = window.priceEndpoint + '.json'

    var jqxhr = $.ajax({
      url:      endpoint,
      type:     "POST",
      dataType: "json",
      data:     data
    })
    .done(function(data, textStatus, jqXHR) {
      $.each(data.data.volume_weights, function(index, value) {
        var volumeWeightField = $("#shipment_package_dimensions_" + value.id + "_volume_weight");
        volumeWeightField.val(parseFloat(value.volume_weight).toFixed(2)).change();
      });
    })
    .fail(function(jqXHR, textStatus, errorThrown) {
      //console.log("Request failed: " + errorThrown);
    });
  }

  // Call backend and get carriers and prices
  cargoflux.performGetCarriersAndPrices = function(data) {
    cargoflux.resetCarrierProductPriceFields();
    var endpoint

    if (window.shipmentPriceURL) {
      endpoint = window.shipmentPriceURL
    } else {
      endpoint = window.priceEndpoint + '.json'
    }

    var customerId = window.customerId
    data.customer_id = customerId

    if (!cargoflux.validInput()) { return }

    var jqxhr = $.ajax({
      url:      endpoint,
      type:     "POST",
      dataType: "json",
      data:     data
    })
      .done(function(data, textStatus, jqXHR) {
        var shouldShowRoute = data.should_show_route;

        if (data.digest != digest)
          // reset digest here
          return;

        if (shouldShowRoute) {
          cargoflux.showMapSection();
        }

        $('#incomplete_information').hide();
        $('#shipping_carrier_products').html(data['html']);
        $('#loading_indicator').hide();
      })
      .fail(function(jqXHR, textStatus, errorThrown) {
        $('#shipping_carrier_products').html('An error occured');
        $('#loading_indicator').hide();
        console.log("Get Carriers and Prices Request failed: " + errorThrown);
      });
  }

  cargoflux.getRandomInt = function(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

  cargoflux.isNumeric = function(string) {
    string = string.replace(/,/, '.');
    return !isNaN(string) && string !== null && string !== '';
  }

  // UUID for price calculation
  cargoflux.generateUUID = function(){
    var d = new Date().getTime();
    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = (d + Math.random()*16)%16 | 0;
        d = Math.floor(d/16);
        return (c=='x' ? r : (r&0x7|0x8)).toString(16);
    });
    return uuid;
  };

  cargoflux.resetCarrierProductPriceFields = function() {
    cargoflux.resetMap();
    cargoflux.hideMapSection();

    $('.carrier_product_price').each(function(){
      var price = $(this);
      price.html('N/A');
    })
  }

  // Calculate onload in case we have existing data (create from existing)
  cargoflux.recalculateVolumeWeight("all");
  cargoflux.recalculateRegularWeight();
  if ($('#create_shipment').val() && cargoflux.validInput()) {
    cargoflux.getAvailableCarrierProducts();
  }

  cargoflux.waitFor('google', function() {
    fetchAndRenderRoute();
  });
});
