(function() {
  var formSelector = "*[data-behavior~=s3_uploader_form]"

  $(function() {
    $(formSelector).each(function() {
      var $form = $(this)
      var progressBarTargetValue = $form.data("progressBarTarget")
      var progressBarTarget = progressBarTargetValue ? $(progressBarTargetValue) : null

      $form.S3Uploader({
        remove_completed_progress_bar: true,
        progress_bar_target: progressBarTarget,
      })
    })
  })
})()
