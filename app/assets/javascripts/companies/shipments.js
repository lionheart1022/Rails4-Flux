$(function() {

  // ============================================================
  // Show page:
  // ============================================================

  // Pricing
  $('.pricing.form .reset_new_price_line').hide()
  $('.advanced_pricing .edit_shipment_price_line').on('click', function (event) {
    var row = $(this).closest('tr')

    var shipmentId  = $(row).find('.shipment_id').val()
    var id          = $(row).find('.id').val()
    var costPrice   = $(row).find('.cost_price_amount').val()
    var salesPrice  = $(row).find('.sales_price_amount').val()
    var description = $(row).find('.description').val()

    var pricingForm = $('.pricing.form')
    $(pricingForm).find('.new_price_line_description').val(description)
    $(pricingForm).find('.new_price_line_cost_price').val(costPrice)
    $(pricingForm).find('.new_price_line_sales_price').val(salesPrice)
    $(pricingForm).find('.submit_new_price_line').val('Update Price')
    // $(pricingForm).find('.new_price_line_description').parents('td').hide();
    $('.pricing.form .reset_new_price_line').show()

    var updateUrl = $(this).data("update-url")

    console.log(window.rfq)
    if (window.rfq) { updateUrl = updateUrl + '?rfq=true'}

    $('.simple_form.new_advanced_price').attr('action', updateUrl)
  })

  $('.pricing.form .reset_new_price_line').on('click', function (event) {
    event.preventDefault()

    var pricingForm = $('.pricing.form')
    $(pricingForm).find('.new_price_line_description').val('')
    $(pricingForm).find('.new_price_line_cost_price').val('')
    $(pricingForm).find('.new_price_line_sales_price').val('')
    $(pricingForm).find('.submit_new_price_line').val('Add')
    $('.pricing.form .reset_new_price_line').hide()
    // $(pricingForm).find('.new_price_line_description').parents('td').show();

    var createUrl = $(this).data("create-url")
    $('.simple_form.new_advanced_price').attr('action', createUrl)

  })

  cargoflux.waitFor('google', function() {
    fetchAndRenderRoute();
  });

  $('.company.route_link').on('click', function (event) {
    var _class = $(this).attr('class').split(' ').join('.');

    event.preventDefault();
    cargoflux.toggleMapBox(_class, 630, 50);
  });

  // Init S3 Uploader (AWB attachment)
  $('#body_companies #s3_awb_attachment_uploader').S3Uploader({
    remove_completed_progress_bar: true,
    progress_bar_target: $('#body_companies #awb_attachment_uploads')
  });

  // S3 Uploader, Upload failed callback (AWB attachment)
  $('#body_companies #s3_awb_attachment_uploader').bind('s3_upload_failed', function(e, content) {
    return alert(content.filename + ' failed to upload');
  });


  // Init S3 Uploader (Consignment note attachment)
  $('#body_companies #s3_consignment_note_attachment_uploader').S3Uploader({
    remove_completed_progress_bar: true,
    progress_bar_target: $('#body_companies #consignment_note_attachment_uploads')
  });

  // S3 Uploader, Upload failed callback (Consignment note attachment)
  $('#body_companies #s3_consignment_note_attachment_uploader').bind('s3_upload_failed', function(e, content) {
    return alert(content.filename + ' failed to upload');
  });


  // Init S3 Uploader (Invoice attachment)
  $('#body_companies #s3_invoice_attachment_uploader').S3Uploader({
    remove_completed_progress_bar: true,
    progress_bar_target: $('#invoice_attachment_uploads')
  });

  // S3 Uploader, Upload failed callback (Invoice attachment)
  $('#body_companies #s3_invoice_attachment_uploader').bind('s3_upload_failed', function(e, content) {
    return alert(content.filename + ' failed to upload');
  });

  var checked = $('#carrier_product_custom_volume_weight_enabled').prop('checked')
  if (!checked) {
    $('#carrier_product_volume_weight_factor').prop('disabled', true)
  }

  $('#carrier_product_custom_volume_weight_enabled').on('change', function (event) {
    $('#carrier_product_volume_weight_factor').prop('disabled', !event.target.checked)
  })

});

var fetchAndRenderRoute = function () {
  var sender_address = $('.full_sender_address').attr('value');
  var recipient_address = $('.full_recipient_address').attr('value');

  if (!!sender_address && !!recipient_address) {
    cargoflux.fetchRoute(sender_address, recipient_address);
  }
}
