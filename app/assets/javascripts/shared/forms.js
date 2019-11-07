$(function() {
  
  // ============================================================
  // Disable all submit buttons when their form is submitted
  // to avoid multiple submits
  // ============================================================
  
  $("#body form").submit(function() {
    $(this).find('input[type=submit]').attr('disabled', 'disabled');
  })
  
});
