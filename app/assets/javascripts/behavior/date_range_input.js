(function() {
  var mainSelector = "*[data-behavior~=date_range_input]";
  var startDateSelector = "*[data-behavior~=date_range_input__start]";
  var endDateSelector = "*[data-behavior~=date_range_input__end]";

  $(function() {
    $(mainSelector).each(function() {
      var $this = $(this);
      var startDateNode = $this.find(startDateSelector);
      var endDateNode = $this.find(endDateSelector);

      var dateRangePickerOptions = {
        separator : " to ",
        getValue: function() {
          if (startDateNode.val() && endDateNode.val()) {
            return startDateNode.val() + " to " + endDateNode.val();
          } else {
            return ",";
          }
        },
        setValue: function(s, s1, s2) {
          startDateNode.val(s1);
          endDateNode.val(s2);
        }
      }

      $this.dateRangePicker(dateRangePickerOptions);
    });
  });
})();
