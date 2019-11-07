(function() {
  var inputSelector = "input[data-behavior~=select_or_type_other]";
  var blankOptionIdentifier = "blankOption";
  var otherOptionIdentifier = "otherOption";
  var regularOptionIdentifier = "regularOption";

  $(function() {
    $(inputSelector).each(function() {
      var input = $(this);
      var collection = input.data("collection");

      var select = buildSelect(collection, input.val());
      select.insertAfter(input);

      var bringBackSelectButton = $("<button>");
      bringBackSelectButton.prop("type", "button");
      bringBackSelectButton.addClass("bring_back_select");
      bringBackSelectButton.text("Show list");
      bringBackSelectButton.insertAfter(select);

      bringBackSelectButton.on("click", function() {
        select.find("option")
          .filter(function() { return $(this).data(blankOptionIdentifier); })
          .prop("selected", true);

        select.trigger("change");
      });

      select.on("change", function() {
        var selectedOption = $(this).find("option:selected");

        if (selectedOption.data(otherOptionIdentifier)) {
          input.show();
          select.hide();
          bringBackSelectButton.show();
        } else if (selectedOption.data(blankOptionIdentifier)) {
          input.val(null);
          input.hide();
          select.show();
          bringBackSelectButton.hide();
        } else if (typeof selectedOption.data(regularOptionIdentifier) === "number") {
          input.val(selectedOption.prop("value"));
          input.hide();
          select.show();
          bringBackSelectButton.hide();
        }
      });

      select.trigger("change");
    });
  });

  function buildSelect(collection, initialValue) {
    var initiallySelectedIndex = typeof initialValue === "string" ? collection.indexOf(initialValue) : -1;
    var select = $("<select>");

    var blankOption = $("<option>");
    blankOption.data(blankOptionIdentifier, true);
    select.append(blankOption);

    $.each(collection, function(index) {
      var selectOption = $("<option>");
      selectOption.prop("value", this);
      selectOption.html(this);
      selectOption.data(regularOptionIdentifier, index);

      if (index === initiallySelectedIndex) {
        selectOption.prop("selected", true);
      }

      select.append(selectOption);
    });

    var otherOption = $("<option>");
    otherOption.html("Other...");
    otherOption.data(otherOptionIdentifier, true);

    if (initiallySelectedIndex === -1 && initialValue) {
      otherOption.prop("selected", true);
    }

    select.append(otherOption);

    return select;
  }
})();
