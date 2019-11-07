$(function () {
  $('.dashboard_tabs').on('click', '.dashboard_tab:not(.active)', function () {
    var $this = $(this),
      $activeTab = $('.dashboard_tab.active'),
      $activePanel = $('.dashboard_panel:not(.hidden)'),
      $targetPanel = $('.dashboard_panel[data-tab=' + $this[0].dataset.tab + ']');

    $this.addClass('active');
    $activeTab.removeClass('active');
    $activePanel.addClass('hidden');
    $targetPanel.removeClass('hidden');
  });
});