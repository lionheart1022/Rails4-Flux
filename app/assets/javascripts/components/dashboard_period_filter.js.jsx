var DashboardPeriodFilter = createReactClass({
  getDefaultProps: function() {
    return {
      showOptions: false,
    }
  },

  selectedLabel: function() {
    var component = this;

    var filteredPeriods = DashboardPeriodFilter.predefinedPeriods.filter(function(period) {
      return period.value === component.props.selectedPeriod;
    });

    if (filteredPeriods.length > 0) {
      return filteredPeriods[0].label;
    } else {
      return "Custom period";
    }
  },

  labelForPeriod: function(period) {
    var filteredPeriods = DashboardPeriodFilter.predefinedPeriods.filter(function(p) {
      return p.value === period;
    });

    if (filteredPeriods.length > 0) {
      return filteredPeriods[0].label;
    } else {
      return null;
    }
  },

  filterOptionsClassName: function() {
    return this.props.showOptions ? "filter period_filter active" : "filter period_filter";
  },

  render: function() {
    return (
      <div className={this.filterOptionsClassName()}>
        <div className="filter_label" onClick={this.props.toggleOptions}>
          <span className="text">{this.selectedLabel()}</span>
          <span className="arrow"></span>
        </div>

        <div className="filter_options">
          <ul className="predefined_periods">
            {this.props.selectedPeriod !== "all_time" ? <li onClick={this.props.selectPredefinedPeriod.bind(null, "all_time")}>{this.labelForPeriod("all_time")}</li> : null}
            <li onClick={this.props.selectPredefinedPeriod.bind(null, "last_quarter")}>{this.labelForPeriod("last_quarter")}</li>
            <li onClick={this.props.selectPredefinedPeriod.bind(null, "last_six_months")}>{this.labelForPeriod("last_six_months")}</li>
            <li onClick={this.props.selectPredefinedPeriod.bind(null, "last_year")}>{this.labelForPeriod("last_year")}</li>
            <li onClick={this.props.selectPredefinedPeriod.bind(null, "last_two_years")}>{this.labelForPeriod("last_two_years")}</li>
          </ul>

          <div className="custom_period">
            <div className="explanation">Or pick interval</div>

            <div className="date_field">
              <label>
                <span className="date_field_label">From</span>
                <span className="date_field_input_container">
                  <DateRangePicker value={this.props.customPeriodFrom} onChange={this.props.changeCustomPeriodFrom} config={DashboardPeriodFilter.dateRangePickerConfig} />
                </span>
              </label>
            </div>

            <div className="date_field">
              <label>
                <span className="date_field_label">To</span>
                <span className="date_field_input_container">
                  <DateRangePicker value={this.props.customPeriodTo} onChange={this.props.changeCustomPeriodTo} config={DashboardPeriodFilter.dateRangePickerConfig} />
                </span>
              </label>
            </div>
          </div>
        </div>
      </div>
    );
  }
});

DashboardPeriodFilter.predefinedPeriods = [
  { value: "all_time", label: "All time" },
  { value: "last_quarter", label: "Last quarter" },
  { value: "last_six_months", label: "Last 6 months" },
  { value: "last_year", label: "Last year" },
  { value: "last_two_years", label: "Last 2 years" },
];

DashboardPeriodFilter.dateRangePickerConfig = {
  autoClose: true,
  singleDate: true,
  showShortcuts: false,
  singleMonth: true,
}
