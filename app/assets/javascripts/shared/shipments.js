$(function() {

  // Define namespace if non-existant
  if (typeof cargoflux === 'undefined') {
    cargoflux = new Object();
  }

  // Update filename/filelink in attachment headline when file upload finishes
  cargoflux.updateFilelink = function(parentId, linkHtml) {
    $filename = $(parentId).find(".filename .filename_inner p");
    $filename.html(linkHtml);
    $filename.effect( "highlight", { color: "#1384e4"}, 1500 );
  }

  // Add/update link icon url for AWB document when file upload finishes
  cargoflux.updateAwbFilelink = function(parentId, linkHtml) {
    $span = $(parentId).find(".awb_document_link");

    // Span for link not found, add it
    if ($span.length < 1) {
      $(parentId).find(".filename_inner").append('<span class="awb_document_link"></span>');
      $span = $(parentId).find(".awb_document_link");
    }

    $span.html(linkHtml);
    $span.effect( "highlight", { color: "#1384e4"}, 1500 );
  }

  // Sets the shipment type to that of the shipment the form is based on
  var existing = $('#shipment_type').attr('data-shipment-type');
  if (existing)
    $("#shipment_shipment_type").val(existing);

  $("#shipment_shipment_type").change(function () {
  	var selected = $(this).find(':selected').val().toLowerCase();

  	if (selected == 'import' || selected == 'export') {
  		switch_fields();
  	}
  });

  // Switch sender and recipient data in new shipment form
  switch_fields = function() {
    sender = $('#shipment_sender_attributes_company_name').val();
    recipient = $('#shipment_recipient_attributes_company_name').val();
    $('#shipment_sender_attributes_company_name').val(recipient);
    $('#shipment_recipient_attributes_company_name').val(sender);

    sender = $('#shipment_sender_attributes_attention').val();
    recipient = $('#shipment_recipient_attributes_attention').val();
    $('#shipment_sender_attributes_attention').val(recipient);
    $('#shipment_recipient_attributes_attention').val(sender);

    sender = $('#shipment_sender_attributes_address_line1').val();
    recipient = $('#shipment_recipient_attributes_address_line1').val();
    $('#shipment_sender_attributes_address_line1').val(recipient);
    $('#shipment_recipient_attributes_address_line1').val(sender);

    sender = $('#shipment_sender_attributes_address_line2').val();
    recipient = $('#shipment_recipient_attributes_address_line2').val();
    $('#shipment_sender_attributes_address_line2').val(recipient);
    $('#shipment_recipient_attributes_address_line2').val(sender);

    sender = $('#shipment_sender_attributes_address_line3').val();
    recipient = $('#shipment_recipient_attributes_address_line3').val();
    $('#shipment_sender_attributes_address_line3').val(recipient);
    $('#shipment_recipient_attributes_address_line3').val(sender);

    sender = $('#shipment_sender_attributes_zip_code').val();
    recipient = $('#shipment_recipient_attributes_zip_code').val();
    $('#shipment_sender_attributes_zip_code').val(recipient);
    $('#shipment_recipient_attributes_zip_code').val(sender);

    sender = $('#shipment_sender_attributes_city').val();
    recipient = $('#shipment_recipient_attributes_city').val();
    $('#shipment_sender_attributes_city').val(recipient);
    $('#shipment_recipient_attributes_city').val(sender);

    sender = $('#shipment_sender_attributes_country_code').val();
    recipient = $('#shipment_recipient_attributes_country_code').val();
    $('#shipment_sender_attributes_country_code').val(recipient);
    $('#shipment_recipient_attributes_country_code').val(sender);

    sender = $('#shipment_sender_attributes_phone_number').val();
    recipient = $('#shipment_recipient_attributes_phone_number').val();
    $('#shipment_sender_attributes_phone_number').val(recipient);
    $('#shipment_recipient_attributes_phone_number').val(sender);

    sender = $('#shipment_sender_attributes_email').val();
    recipient = $('#shipment_recipient_attributes_email').val();
    $('#shipment_sender_attributes_email').val(recipient);
    $('#shipment_recipient_attributes_email').val(sender);

    sender = $('#shipment_sender_attributes_residential').is(":checked");
    recipient = $('#shipment_recipient_attributes_residential').is(":checked");
    $('#shipment_sender_attributes_residential').prop("checked", recipient);
    $('#shipment_recipient_attributes_residential').prop("checked", sender);

    return false;
  };

});
