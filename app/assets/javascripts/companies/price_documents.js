$(function () {

	// shows upload button if file selected
	$('.submit').attr('hidden',true);
  $('input:file').change(function(){
  	var id = $(this).attr('id');
    var fileId = "#" + id;
    var submitId = "#s" + id;

    if ($(this).val()) {
      $(submitId).removeAttr('hidden'); 
    }
    else {
      $(fileId).attr('hidden', true);
    }
  });

});