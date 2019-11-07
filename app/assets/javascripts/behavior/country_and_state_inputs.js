(function() {
  var wrapperSelector = "*[data-behavior~=country_and_state_inputs__container]"
  var countrySelector = "*[data-behavior~=country_and_state_inputs__country]"
  var stateSelector = "*[data-behavior~=country_and_state_inputs__state]"

  $(function() {
    $(stateSelector).each(function() {
      var stateSelect = $(this)
      var wrapper = stateSelect.closest(wrapperSelector)
      var countrySelect = wrapper.find(countrySelector)

      var originalStateCode = stateSelect.val()
      var countryToOptionsHTMLMapping = {}

      stateSelect.find("optgroup").each(function() {
        var optgroup = this
        var countryCode = optgroup.getAttribute("label")

        countryToOptionsHTMLMapping[countryCode] = optgroup.innerHTML
      })

      var updateStateOptions = function(stateCode) {
        var optionsHTML = countryToOptionsHTMLMapping[countrySelect.val()]
        var countryWithStates = typeof optionsHTML !== "undefined"

        stateSelect.html('<option value=""></option>' + (countryWithStates ? optionsHTML : ''))
        stateSelect.val(stateCode)

        stateSelect.closest("div.input").toggle(countryWithStates)
      }

      updateStateOptions(originalStateCode)

      countrySelect.on("change", function() {
        updateStateOptions(null)
      })
    })
  })
})()
