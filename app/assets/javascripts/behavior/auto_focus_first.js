(function() {
  var formSelector = "form[data-behavior~=auto_focus_first]"

  $(function() {
    $(formSelector).each(function() {
      $(this).find(":input:visible").first().focus()
    })
  })
})()
