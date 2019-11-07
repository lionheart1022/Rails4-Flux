(function() {
  var deleteLinkSelector = ".shipment_view_other_asset a[data-remote]";

  $(document).on("ajax:send", deleteLinkSelector, function() {
    var $link_div = $(this).parent();
    var $loading_indicator = $link_div.find(".loading_indicator");
    $(this).hide();
    $loading_indicator.show();
  });

  $(document).on("ajax:complete", deleteLinkSelector, function() {
    var $link_div = $(this).parent();
    var $loading_indicator = $link_div.find(".loading_indicator");
    $(this).show();
    $loading_indicator.hide();
  });
})();
