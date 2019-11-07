(function() {
  var buttonSelector = "*[data-behavior~=proxy_submit_form]"

  $(document).on("click", buttonSelector, function() {
    var $this = $(this)
    $($this.data("target")).submit()
  })
})()
