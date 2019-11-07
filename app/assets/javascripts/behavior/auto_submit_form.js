(function() {
  var inputSelector = "form[data-behavior~=auto_submit_on_change] :input";

  $(document).on("change", inputSelector, function() {
    $(this).closest("form").submit();
  });
})();
