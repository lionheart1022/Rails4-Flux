$(function() {

  if (typeof cargoflux === 'undefined') {
    cargoflux = new Object({});
  }

  $('#check-all').change(function() {
    $("input:checkbox").prop('checked', $(this).prop("checked"));
  });



});
