$(function() {

  if (typeof cargoflux === 'undefined') {
    cargoflux = new Object({});
  }

  $('#check-all-carriers').change(function() {
    $(".carrier input:checkbox").prop('checked', $(this).prop("checked"));
  });

  $('#check-all-products').change(function() {
    $(".product input:checkbox").prop('checked', $(this).prop("checked"));
  });

});
