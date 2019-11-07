$(function() {

  // Define namespace if non-existant
  if (typeof cargoflux === 'undefined') {
    cargoflux = new Object();
  }

  // ============================================================
  // Show page:
  // ============================================================

  // Enable checkbox
  cargoflux.enable_autobook_checkbox = function(checkbox) {
    checkbox.removeAttr("disabled");
    checkbox.closest("td").removeClass("disabled");
  }

  // Disable checkbox
  cargoflux.disable_autobook_checkbox = function(checkbox) {
    checkbox.attr('checked', false);
    checkbox.attr("disabled", true);
    checkbox.closest("td").addClass("disabled");
  }

  // Disable dependent checkboxes onload
  $.each($("#body_companies table.carrier_products tr"), function(index, value) {
    var $row = $(value);
    var $product_checkbox = $row.find("td.carrier_product input");
    var $enable_checkbox = $row.find("td.enable_autobooking input.boolean");
    var $autobook_checkbox = $row.find("td.autobook input.boolean");
    var $allow_auto_pickup_checkbox = $row.find("td.allow_auto_pickup input.boolean");
    var $test_checkbox = $row.find("td.test input[type=checkbox]");

    // Onload checks
    if (!$product_checkbox.is(":checked")) {
      cargoflux.disable_autobook_checkbox($enable_checkbox);
      cargoflux.disable_autobook_checkbox($allow_auto_pickup_checkbox);
      cargoflux.disable_autobook_checkbox($test_checkbox);
    }

    if (!$enable_checkbox.is(":checked")) {
      cargoflux.disable_autobook_checkbox($autobook_checkbox);
    }

    // Click on carrier product name
    $product_checkbox.click(function() {
      if ($(this).is(":checked")) {
        cargoflux.enable_autobook_checkbox($enable_checkbox);
        cargoflux.enable_autobook_checkbox($autobook_checkbox);
        cargoflux.enable_autobook_checkbox($allow_auto_pickup_checkbox);
        cargoflux.enable_autobook_checkbox($test_checkbox);

        $enable_checkbox.prop("checked", true);
        $autobook_checkbox.prop("checked", true);
      }
      else {
        cargoflux.disable_autobook_checkbox($enable_checkbox);
        cargoflux.disable_autobook_checkbox($allow_auto_pickup_checkbox);
        cargoflux.disable_autobook_checkbox($autobook_checkbox);
        cargoflux.disable_autobook_checkbox($test_checkbox);
      }
    });

    // Click on "Enable auto-booking"
    $enable_checkbox.click(function() {
      if ($(this).is(":checked")) {
        cargoflux.enable_autobook_checkbox($autobook_checkbox);
      }
      else {
        cargoflux.disable_autobook_checkbox($autobook_checkbox);
      }
    });

  });

});
