(function() {
  var btnSelector = "*[data-behavior~=scroll_to_and_highlight]";

  $(document).on("click", btnSelector, function() {
    var targetSelector = $(this).data("target");
    var target = $(targetSelector);

    $("html, body").animate(
      { scrollTop: target.offset().top },
      {
        duration: 1000,
        complete: function() {
          target.effect("highlight");
        }
      }
    );
  });
})();
