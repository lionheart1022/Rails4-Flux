$(function() {
    // ============================================================
    // Edit page:
    // ============================================================

    // Init S3 Uploader (AWB attachment)
    $('#body_companies #s3_logo_attachment_uploader').S3Uploader({
        remove_completed_progress_bar: true,
        progress_bar_target: $('#body_companies #logo_attachment_uploads')
    });

    // S3 Uploader, Upload failed callback (AWB attachment)
    $('#body_companies #s3_logo_attachment_uploader').bind('s3_upload_failed', function(e, content) {
        alert(content.filename + ' failed to upload');
    });

});
