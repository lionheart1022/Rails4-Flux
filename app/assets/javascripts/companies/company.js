$(function() {

  // Define namespace if non-existant
  if (typeof cargoflux === 'undefined') {
    cargoflux = new Object({});
  }

  // Init S3 Uploader (Other attachment)
  $('#s3_company_attachment_uploader').S3Uploader({
    remove_completed_progress_bar: false,
    progress_bar_target: $('#company_attachment_uploads'),
    click_submit_target: $('#upload_company_file'),
    allow_multiple_files: false
  });

  // Handle succesful S3 upload
  $('#s3_company_attachment_uploader').on('ajax:beforeSend', function(event) {
    $('#upload_company_file').hide();
    $('#upload_loading_indicator').show();
  });

  $('#s3_company_attachment_uploader').on('ajax:success', function(event, data, status, xhr) {
    location.reload();
  });

  $('#s3_company_attachment_uploader').on('ajax:error', function(event, data, status, xhr) {
    var error = data.responseJSON.error
    $('#upload_company_file').show();
    $('#upload_loading_indicator').hide();
    alert(error)
  });

  // S3 Uploader, Upload failed callback (Other attachment)
  $('#s3_company_attachment_uploader').bind('s3_upload_failed', function(e, content) {
    return alert(content.filename + ' failed to upload');
  });

  // S3 uploader interferes with the input field, causing the filename not to change. To get around this, I use another button to trigger
  // the file selection, and use the event to populate a field with the fielname manually
  $('#company_terms_choose_file').on('click', function(event) {
    $($("input[type='file']")).click()
  })

  $("input[type='file']").on('change', function(event) {
    var filename = event.target.files[0].name
    $('#company_attachment.attachment').text(filename)
  })

});
