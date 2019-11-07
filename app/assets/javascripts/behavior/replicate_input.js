(function() {
  var selector = "*[data-behavior~=replicate_on_input]"

  $(document).on("input", selector, function() {
    var $this = $(this)
    var target = $this.data("replicate-value-to")
    $(target).val($this.val())
  })
})();

(function() {
  var selector = "*[data-behavior~=replicate_on_change]"

  $(document).on("change", selector, function() {
    var $this = $(this)
    var target = $this.data("replicate-value-to")
    $(target).val($this.val())
  })
})();
