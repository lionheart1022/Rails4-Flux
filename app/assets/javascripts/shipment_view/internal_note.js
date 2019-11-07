(function() {
  var addBtnSelector = "*[data-behavior~=shipment_view__internal_note__add_btn]"
  var cancelBtnSelector = "*[data-behavior~=shipment_view__internal_note__cancel_btn]"
  var editBtnSelector = "*[data-behavior~=shipment_view__internal_note__edit_btn]"
  var formSelector = "*[data-behavior~=shipment_view__internal_note__form]"
  var displaySelector = "*[data-behavior~=shipment_view__internal_note__display]"
  var wrapperSelector = "#shipment_view__internal_note"

  $(document).on("click", addBtnSelector, function() {
    var addBtn = $(this)
    var wrapper = addBtn.closest(wrapperSelector)
    var displayView = wrapper.find(displaySelector)
    var form = wrapper.find(formSelector)

    form.show()
    form.find(":input:visible").first().focus()
    addBtn.hide()
    displayView.hide()
  })

  $(document).on("click", cancelBtnSelector, function() {
    var cancelBtn = $(this)
    var wrapper = cancelBtn.closest(wrapperSelector)
    var addBtn = wrapper.find(addBtnSelector)
    var editBtn = wrapper.find(editBtnSelector)
    var displayView = wrapper.find(displaySelector)
    var form = wrapper.find(formSelector)

    form.hide()
    addBtn.show()
    editBtn.show()
    displayView.show()
  })

  $(document).on("click", editBtnSelector, function() {
    var editBtn = $(this)
    var wrapper = editBtn.closest(wrapperSelector)
    var displayView = wrapper.find(displaySelector)
    var form = wrapper.find(formSelector)

    form.show()
    form.find(":input:visible").first().focus()
    editBtn.hide()
    displayView.hide()
  })

  $(document).on("shipment_view__internal_note:init", wrapperSelector, function() {
    var wrapper = $(this)
    var form = wrapper.find(formSelector)

    form.hide()
  })

  $(function() {
    $(wrapperSelector).trigger("shipment_view__internal_note:init")
  })
})()
