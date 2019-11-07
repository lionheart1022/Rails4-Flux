(function() {
  window.CFModal = {
    $dialog: null,
    $dialogContent: null,

    init: function(jqDialogOptions) {
      var defaults = {
        modal: true,
        resizable: false,
        draggable: false,
        dialogClass: "cf-ui-dialog-modal no-close",
        minWidth: 500,
        buttons: [],
      }

      var jqDialogOptionsMerged = $.extend(defaults, jqDialogOptions)

      if (!CFModal.$dialog) {
        CFModal.$dialogElement = $("<div></div>")
        $(document.body).append(CFModal.$dialogElement)
        CFModal.$dialog = CFModal.$dialogElement.dialog(jqDialogOptionsMerged)
      } else {
        CFModal.$dialog.dialog("option", jqDialogOptionsMerged)
        CFModal.$dialog.dialog("open")
      }
    },

    showSpinner: function() {
      CFModal.showHTMLContent('<div class="cf-modal-show-spinner"><div class="spinner--wrapper-size60"><div class="spinner"></div></div></div>')
    },

    showHTMLContent: function(htmlContent) {
      CFModal.$dialogElement.html(htmlContent)
    },

    close: function() {
      CFModal.$dialog.dialog("close")
    }
  }
})()
