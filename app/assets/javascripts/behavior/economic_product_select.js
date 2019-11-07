(function() {
  var productSelectSelector = "*[data-behavior~=economic_product_select]";
  var refreshSelector = "*[data-behavior~=economic_product_select_refresh]";
  var maxTimeElapsed = 5*1000; // 5 minutes

  var checkStatus;

  checkStatus = function(url, doneCallback, startedAt) {
    startedAt = startedAt || Date.now();

    $.getJSON(url, function(payload) {
      if (payload["done"] === true) {
        doneCallback();
      } else {
        var timeElapsed = Date.now() - startedAt;
        if (timeElapsed > maxTimeElapsed) {
          alert("It took too long to fetch the latest e-conomic products");
        } else {
          setTimeout(function() {
            checkStatus(url, doneCallback, startedAt);
          }, 20*1000); // Wait 20 seconds and check again
        }
      }
    });
  };

  window.App = window.App || {};
  window.App.fetchLatestEconomicProducts = function(params) {
    $(refreshSelector).addClass("loading_products")

    checkStatus(params.pollUrl, function() {
      $.getJSON(params.listUrl, function(selectElementResponse) {
        var replacementSelect = $(selectElementResponse.html);
        var replacementSelectInnerHTML = replacementSelect.html();

        $(productSelectSelector).each(function() {
          var $this = $(this);

          // Cache selected value
          var selectedValue = $this.val();

          $this.html(replacementSelectInnerHTML);

          // Re-select after having replaced <option>s
          if (selectedValue !== null) {
            $this.val(selectedValue);
          }
        });

        $(refreshSelector).removeClass("loading_products");
      });
    });
  };
})();
