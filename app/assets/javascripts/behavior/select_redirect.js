(function() {
  var inputSelector = "*[data-behavior~=select_redirect]"

  $(function() {
    $(inputSelector).each(function() {
      var select = $(this)

      select.select2({
        theme: "cargoflux",
        ajax: {
          dataType: "json",
          delay: 250,
          cache: true,
        }
      })

      select.on("select2:select", function(event) {
        var eventData = event.params.data
        window.location.href = eventData.url
      })
    })
  })
})()
