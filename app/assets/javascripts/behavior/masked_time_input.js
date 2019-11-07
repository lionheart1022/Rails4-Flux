(function() {
  var dataBehaviorPattern = /\bmasked_time_input\b/;

  var applyBehavior = function(node) {
    $(node).mask("99:99");
  };

  var observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.type === "childList") {
        mutation.addedNodes.forEach(function(addedNode) {
          if (addedNode.nodeName === "INPUT") {
            var behaviorValue = addedNode.dataset.behavior;

            if (behaviorValue && dataBehaviorPattern.test(behaviorValue)) {
              applyBehavior(addedNode);
            }
          }
        });
      }
    });
  });

  observer.observe(document.documentElement, { childList: true, subtree: true });
})();
