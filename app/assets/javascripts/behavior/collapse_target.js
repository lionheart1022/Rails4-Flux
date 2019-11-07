(function() {
  var checkboxSelector = "*[data-behavior~=collapse_target]"

  $(document).on("change", checkboxSelector, function() {
    var isChecked = $(this).is(":checked")
    var target = $($(this).data("target"))
    target.toggle(isChecked)
  })

  $(function() {
    $(checkboxSelector).trigger("change")
  })
})()
