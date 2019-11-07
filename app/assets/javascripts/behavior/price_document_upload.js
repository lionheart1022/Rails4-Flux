(function() {
  var wrapperSelector = "*[data-behavior~=price_document_upload__wrapper]"
  var formSelector = "*[data-behavior~=price_document_upload__form]"
  var showFormBtnSelector = "*[data-behavior~=price_document_upload__show_form_btn]"

  $(document).on("click", showFormBtnSelector, function() {
    var $this = $(this)
    var wrapper = $this.closest(wrapperSelector)
    var form = wrapper.find(formSelector)

    form.show()
    $this.hide()
  })

  $(function() {
    // Hide form initially
    $(formSelector).hide()
  })
})()
