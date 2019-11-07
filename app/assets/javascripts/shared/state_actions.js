$(function() {

  // Define namespace if non-existant
  if (typeof cargoflux === 'undefined') {
    cargoflux = new Object();
  }

  // ============================================================
  // State actions overlay popup for index and show pages
  // ============================================================

  cargoflux.clicked_state_span = null;

  $('#body table.shipments td.state span.state, #body table.pickups td.state span.state').qtip({
    show: 'click',
    hide: 'unfocus',
    events: {
      render: function(event, api) {
        cargoflux.clicked_state_span = $(api.target);
      }
    },
    content: {
      text: function(api){
        return $(this).next('div.state_actions').html();
      }
    },
    position: {
      my: 'top center',
      at: 'bottom center',
      target: 'event'
    },
    style: {
      classes: 'qtip-light qtip-shadow qtip-rounded'
    }
  });

  // ============================================================
  // Handle ajax responses for shipment/pickup state-change:
  // ============================================================

  $("body").on("ajax:success", "form.edit_shipment, form.edit_pickup", function(event, data, status, xhr) {
    if (cargoflux.clicked_state_span) {
      cargoflux.clicked_state_span.text(data.state_text);
      cargoflux.clicked_state_span.closest("td").attr("class", ("state " + data.state_class));
      $('div.qtip:visible').qtip('hide');
    }
  });

  $("body").on("ajax:error", "form.edit_shipment, form.edit_pickup", function(event, xhr, status, error) {
    if (xhr.responseText) {
      alert(xhr.responseText);
    } else {
      alert("Unable to change state.");
    }
  });

});
