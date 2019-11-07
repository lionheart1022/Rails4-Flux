$(function() {
  var formSelector = "#s3_other_attachment_uploader";
  var submitButtonSelector = "#upload_other_file";
  var loadingIndicatorSelector = "#upload_loading_indicator";

  $(formSelector).S3Uploader({
    remove_completed_progress_bar: true,
    progress_bar_target: $("#other_attachment_uploads"),
    click_submit_target: $(submitButtonSelector),
    allow_multiple_files: false
  });

  $(formSelector).on("ajax:beforeSend", function(event) {
    $(submitButtonSelector).hide();
    $(loadingIndicatorSelector).show();
  });

  $(formSelector).on("ajax:success", function(event, data, status, xhr) {
    $(submitButtonSelector).show();
    $(loadingIndicatorSelector).hide();

    if (data.partial_html) {
      $(".files tr:last").before(data.partial_html);
      $("#file_description").val("");
    }
  });

  // S3 Uploader, Upload failed callback (Other attachment)
  $(formSelector).bind("s3_upload_failed", function(e, content) {
    return alert(content.filename + " failed to upload");
  });
});
