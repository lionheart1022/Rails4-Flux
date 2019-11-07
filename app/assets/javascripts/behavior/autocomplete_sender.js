(function() {
  var inputSelector = "*[data-behavior~=autocomplete_sender]";

  $(function() {
    $(inputSelector).each(function() {
      var $this = $(this);
      var config = $this.data("behavior-config");

      $this.autocomplete({
        source: config["remote_url"],
        minLength: 2,
        focus: function(event, ui) {
          event.preventDefault();
          if (ui.item) {
            cargoflux.autocompleteShipmentSenderForm(ui.item.value);
          }
        },
        select: function(event, ui) {
          event.preventDefault();
          if (ui.item) {
            cargoflux.autocompleteShipmentSenderForm(ui.item.value);
          }
        }
      })
    });
  });
})();
