var DashboardSummary = createReactClass({
  wrapperClassName: function(chartType) {
    var classNames = ["summary_item_wrapper"];

    if (this.props.chartType === chartType) {
      classNames.push("active");
    }

    return classNames.join(" ");
  },

  revenueCurrencyIsSelected: function(currency) {
    return this.props.selectedRevenueCurrency === currency;
  },

  selectRevenueCurrency: function(currency) {
    this.props.selectRevenueCurrencyCallback(currency);
  },

  costCurrencyIsSelected: function(currency) {
    return this.props.selectedCostCurrency === currency;
  },

  selectCostCurrency: function(currency) {
    this.props.selectCostCurrencyCallback(currency);
  },

  render: function() {
    var component = this;

    return (
      <ul className="dashboard_summary">
        <li className={this.wrapperClassName("shipments")} onClick={this.props.changeChartCallback.bind(null, "shipments")}>
          <div className="summary_item">
            <div className="label">Shipments</div>
            <div className="value">{this.props.numberOfShipments}</div>
            <div className="unit">{this.props.numberOfShipmentsUnit}</div>
          </div>
        </li>

        <li className={this.wrapperClassName("packages")} onClick={this.props.changeChartCallback.bind(null, "packages")}>
          <div className="summary_item">
            <div className="label">Packages</div>
            <div className="value">{this.props.numberOfPackages}</div>
            <div className="unit">{this.props.numberOfPackagesUnit}</div>
          </div>
        </li>

        <li className={this.wrapperClassName("weight")} onClick={this.props.changeChartCallback.bind(null, "weight")}>
          <div className="summary_item">
            <div className="label">Weight</div>
            <div className="value">{this.props.weight}</div>
            <div className="unit">{this.props.weightUnit}</div>
          </div>
        </li>

        <li className={this.wrapperClassName("revenue")} onClick={this.props.changeChartCallback.bind(null, "revenue")}>
          <div className="summary_multi_items">
            <div className="label">Revenue</div>
            <div className="summary_multi_item_container">
              {this.props.revenues.map(function(revenue) {
                var classNames = ["summary_multi_item"]
                if (component.revenueCurrencyIsSelected(revenue.currency)) classNames.push("active");

                return (
                  <div key={revenue.currency} className={classNames.join(" ")}>
                    <div className="value">{revenue.formattedValue}</div>
                  </div>
                );
              })}
            </div>
            <div className="dots">
              {this.props.revenues.map(function(revenue) {
                var classNames = ["dot"]
                if (component.revenueCurrencyIsSelected(revenue.currency)) classNames.push("active");

                return <button key={revenue.currency} className={classNames.join(" ")} type="button" onClick={component.selectRevenueCurrency.bind(null, revenue.currency)}></button>;
              })}
            </div>
          </div>
        </li>

        <li className={this.wrapperClassName("cost")} onClick={this.props.changeChartCallback.bind(null, "cost")}>
          <div className="summary_multi_items">
            <div className="label">Cost</div>
            <div className="summary_multi_item_container">
              {this.props.costs.map(function(cost) {
                var classNames = ["summary_multi_item"]
                if (component.costCurrencyIsSelected(cost.currency)) classNames.push("active");

                return (
                  <div key={cost.currency} className={classNames.join(" ")}>
                    <div className="value">{cost.formattedValue}</div>
                  </div>
                );
              })}
            </div>
            <div className="dots">
              {this.props.costs.map(function(cost) {
                var classNames = ["dot"]
                if (component.costCurrencyIsSelected(cost.currency)) classNames.push("active");

                return <button key={cost.currency} className={classNames.join(" ")} type="button" onClick={component.selectCostCurrency.bind(null, cost.currency)}></button>;
              })}
            </div>
          </div>
        </li>
      </ul>
    );
  }
});
