$(function() {
  var DELAY = 10000;

  var pollReportStatus = $('#poll_report_status').val()

  if (pollReportStatus === 'true') {
    setTimeout(function () {
      window.location.reload();
    }, DELAY);
  }

  var options = {
    separator : ' to ',
    setValue: function(s,s1,s2) {
      $('#scope_filter_range_start').val(s1);
      $('#scope_filter_range_end').val(s2);
    }
  }

  var $filter = $('#scope_filter_range_start')
  if ($filter.length) {
    $filter
    .dateRangePicker(options)
    .bind('datepicker-change', function(event, object) {
      $(this).closest('form').submit()
      $(this).close()
    })
  }

});
