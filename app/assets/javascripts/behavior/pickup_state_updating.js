(function() {
  var linkSelector = "*[data-behavior~=pickup_state_updating]"
  var htmlDataAttr = "state-form-html"

  $(document).on("click", linkSelector, function() {
    var $this = $(this)

    $this.qtip({
      show: {
        ready: true,
        event: "click",
      },
      hide: {
        event: "unfocus"
      },
      position: {
        my: "top center",
        at: "bottom center",
        target: $this,
      },
      style: {
        classes: 'qtip-light qtip-shadow qtip-rounded'
      },
      content: {
        text: function(event, api) {
          return $this.data(htmlDataAttr)
        }
      },
      events: {
        visible: function(event, api) {
          $(this).find(":input:visible").get(0).focus()
        }
      }
    })
  })
})()
