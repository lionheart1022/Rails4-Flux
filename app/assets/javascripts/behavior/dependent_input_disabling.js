(function() {
  var inputSelector = "*[data-behavior~=dependent-input-disabling]";
  var groupSelector = "*[data-dependent-input-disabling-group~=true]";
  var dependentInputSelector = "*[data-input-to-disable~=true]";

  $(document).on("change", inputSelector, function() {
    var isEnabled = $(this).is(":checked");
    $(this).closest(groupSelector).find(dependentInputSelector).prop("disabled", !isEnabled);
  });

  $(function() {
    $(inputSelector).trigger("change");
  });
})();
