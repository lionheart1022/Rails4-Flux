(function() {
  var selector = "*[data-behavior~=poll_and_refresh]";

  $(function() {
    $(selector).each(function() {
      var $this = $(this);
      var config = $this.data("behavior-config");
      var delay = 5000; // 5 seconds

      var interval;

      interval = window.setInterval(function () {
        $.getJSON(config.poll_url, function(data) {
          if (data.result === true) {
            window.clearInterval(interval);
            window.location.reload();
          }
        });
      }, delay);
    });
  });
})();
