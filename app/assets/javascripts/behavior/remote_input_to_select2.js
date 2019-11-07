(function() {
  var inputSelector = "*[data-behavior~=remote_input_to_select2]"
  var initEvent = "remote_input_to_select2:init"

  $(document).on(initEvent, inputSelector, function() {
    var input = $(this)
    var select = $("<select>")

    var value = input.val()
    if (value !== "") {
      var optionText = input.data("selected-option-text")

      var option = $("<option>")
      option.prop("value", value)
      option.text(optionText)
      select.append(option)

      select.val(value)
    }

    $.each(input.prop("attributes"), function() {
      if (this.name === "data-behavior") {
        // Ignore
        return
      } else if (this.name === "placeholder") {
        // Set placeholder as select2 expects
        return select.attr("data-placeholder", this.value)
      } else {
        // Copy the remaining attributes to the select-node
        return select.attr(this.name, this.value)
      }
    })

    input.replaceWith(select)

    select.select2({
      ajax: {
        dataType: "json",
        delay: 250,
        cache: true,
      }
    })
  })

  $(function() {
    $(inputSelector).trigger(initEvent)
  })
})()
