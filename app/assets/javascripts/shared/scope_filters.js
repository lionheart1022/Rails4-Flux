$(function() {

  // ============================================================
  // Scope filters for index pages
  // ============================================================

  // Submit form when any scope dropdown changes
  $('#body .page_actions .scopes select, #body .page_actions .scopes input').change(function() {
    $(this).closest('form').submit();
  });

});
