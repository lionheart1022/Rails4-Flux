var CompanyDashboard = createReactClass({
  getDefaultProps: function() {
    return {
      initialCarrierOptions: [],
      initialCustomerOptions: [],
    }
  },

  getInitialState: function() {
    var initialState = {
      periodFilterShowOptions: false,
      selectedPeriod: "all_time",
      customPeriodFrom: "",
      customPeriodTo: "",

      carrierFilterShowOptions: false,
      selectedCarrier: null,

      customerFilterShowOptions: false,
      selectedCustomer: null,

      shipments: {
        value: null,
        unit: null,
        points: [],
      },
      packages: {
        value: null,
        unit: null,
        points: [],
      },
      weight: {
        value: null,
        unit: null,
        points: [],
      },
      revenues: [],
      costs: [],

      selectedChartType: "shipments",
      selectedRevenueCurrency: null,
      selectedCostCurrency: null,
    };

    if (this.props.initialDashboard) {
      $.extend(initialState, this.buildNewStateFromJSONResponse(this.props.initialDashboard));
      this._updateChart = true;
    }

    return initialState;
  },

  queryParams: function() {
    var a = window.location.search.substr(1).split("&");

    if (a == "") return {};

    var b = {};

    for (var i = 0; i < a.length; ++i)
    {
      var p = a[i].split("=", 2);
      if (p.length == 1) {
        b[p[0]] = "";
      } else {
        b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, " "));
      }
    }

    return b;
  },

  componentWillUpdate: function(nextProps, nextState) {
    var didFiltersChange =
      this.state.selectedPeriod !== nextState.selectedPeriod ||
      this.state.customPeriodFrom !== nextState.customPeriodFrom ||
      this.state.customPeriodTo !== nextState.customPeriodTo ||
      this.state.selectedCarrier !== nextState.selectedCarrier ||
      this.state.selectedCustomer !== nextState.selectedCustomer;

    if (didFiltersChange) {
      var component = this;

      var filterParams = {
        "predefined_period": nextState.selectedPeriod,
        "carrier_id": nextState.selectedCarrier ? nextState.selectedCarrier.id : null,
      };

      if (nextState.selectedCustomer) {
        var key = nextState.selectedCustomer.type === "Company" ? "company_customer_id" : "customer_id";
        filterParams[key] = nextState.selectedCustomer.id;
      }

      if (nextState.selectedPeriod === "custom") {
        filterParams["custom_period_from"] = nextState.customPeriodFrom;
        filterParams["custom_period_to"] = nextState.customPeriodTo;
      }

      var fixedQueryParams = this.queryParams();
      if (fixedQueryParams["dummy"]) filterParams["dummy"] = fixedQueryParams["dummy"];

      $("#dashboard_chart_container .loading_indicator").show();

      var jqxhr = $.getJSON(nextProps.remoteDashboardDataURL + "?" + $.param(filterParams), function(response) { // TODO: Parameterize the URL
        component.setState(component.buildNextStateFromJSONResponse(response, nextState));
        component._resetAndUpdateChart = true;
        component.forceUpdate();
      });

      // jqxhr.fail(function() {
      // });

      jqxhr.always(function() {
        $("#dashboard_chart_container .loading_indicator").hide();
      });
    }
  },

  activeChartData: function() {
    switch (this.state.selectedChartType) {
    case "shipments":
      return [{ points: this.state.shipments.points }];
    case "packages":
      return [{ points: this.state.packages.points }];
    case "weight":
      return [{ points: this.state.weight.points }];
    case "revenue":
      return this.state.revenues.map(function(revenue) {
        return { label: revenue.currency, points: revenue.points };
      });
    case "cost":
      return this.state.costs.map(function(cost) {
        return { label: cost.currency, points: cost.points };
      });
    default:
      throw new Error("Chart type not supported (" + this.state.selectedChartType + ")");
    }
  },

  buildNextStateFromJSONResponse: function(response, nextState) {
    var parsedResponse = CompanyDashboard.parseJSONResponse(response);

    // Select the same currency as before, if possible; otherwise default to the first one
    var revenuesWithSameCurrency = parsedResponse.revenues.filter(function(revenue) { return revenue.currency === nextState.selectedRevenueCurrency; });
    var selectedRevenueCurrency = null;
    if (revenuesWithSameCurrency.length > 0) {
      selectedRevenueCurrency = revenuesWithSameCurrency[0].currency
    } else if (parsedResponse.revenues.length > 0) {
      selectedRevenueCurrency = parsedResponse.revenues[0].currency;
    }

    var costsWithSameCurrency = parsedResponse.costs.filter(function(cost) { return cost.currency === nextState.selectedCostCurrency; });
    var selectedCostCurrency = null;
    if (costsWithSameCurrency.length > 0) {
      selectedCostCurrency = costsWithSameCurrency[0].currency;
    } else if (parsedResponse.costs.length > 0) {
      selectedCostCurrency = parsedResponse.costs[0].currency;
    }

    $.extend(parsedResponse, {
      selectedRevenueCurrency: selectedRevenueCurrency,
      selectedCostCurrency: selectedCostCurrency,
    });

    return parsedResponse;
  },

  buildNewStateFromJSONResponse: function(response) {
    var parsedResponse = CompanyDashboard.parseJSONResponse(response);

    // Select the first currency as default
    $.extend(parsedResponse, {
      selectedRevenueCurrency: parsedResponse.revenues.length > 0 ? parsedResponse.revenues[0].currency : null,
      selectedCostCurrency: parsedResponse.costs.length > 0 ? parsedResponse.costs[0].currency : null,
    });

    return parsedResponse;
  },

  togglePeriodFilterOptions: function() {
    this.setState(function(prevState, props) {
      if (prevState.periodFilterShowOptions) {
        return { periodFilterShowOptions: false };
      } else {
        return {
          periodFilterShowOptions: true,
          carrierFilterShowOptions: false,
          customerFilterShowOptions: false,
        };
      }
    });
  },

  toggleCarrierFilterOptions: function() {
    this.setState(function(prevState, props) {
      if (prevState.carrierFilterShowOptions) {
        return { carrierFilterShowOptions: false };
      } else {
        return {
          periodFilterShowOptions: false,
          carrierFilterShowOptions: true,
          customerFilterShowOptions: false,
        };
      }
    });
  },

  toggleCustomerFilterOptions: function() {
    this.setState(function(prevState, props) {
      if (prevState.customerFilterShowOptions) {
        return { customerFilterShowOptions: false };
      } else {
        return {
          periodFilterShowOptions: false,
          carrierFilterShowOptions: false,
          customerFilterShowOptions: true,
        };
      }
    });
  },

  selectPredefinedPeriod: function(period) {
    this.setState({
      selectedPeriod: period,
      customPeriodFrom: "",
      customPeriodTo: "",
      periodFilterShowOptions: false,
    });
  },

  changeCustomPeriodFrom: function(event) {
    if (!event.target.value && !this.state.customPeriodTo) {
      this.setState({
        selectedPeriod: "all_time",
        customPeriodFrom: event.target.value,
      });
    } else {
      var day = moment(event.target.value);
      var firstDayInMonth = day.startOf("month").format("YYYY-MM-DD");

      this.setState({
        selectedPeriod: "custom",
        customPeriodFrom: firstDayInMonth,
      });
    }
  },

  changeCustomPeriodTo: function(event) {
    if (!event.target.value && !this.state.customPeriodFrom) {
      this.setState({
        selectedPeriod: "all_time",
        customPeriodTo: event.target.value,
      });
    } else {
      var day = moment(event.target.value);
      var lastDayInMonth = day.endOf("month").format("YYYY-MM-DD");

      this.setState({
        selectedPeriod: "custom",
        customPeriodTo: lastDayInMonth,
      });
    }
  },

  selectCarrier: function(carrier) {
    this.setState({ selectedCarrier: carrier });
    this.setState({ carrierFilterShowOptions: false });
  },

  selectCustomer: function(customer) {
    this.setState({ selectedCustomer: customer });
    this.setState({ customerFilterShowOptions: false });
  },

  changeChart: function(chartType) {
    this.setState({ selectedChartType: chartType });
    this._updateChart = true;
  },

  selectRevenueCurrency: function(currency) {
    this.setState({ selectedRevenueCurrency: currency });
  },

  selectCostCurrency: function(currency) {
    this.setState({ selectedCostCurrency: currency });
  },

  render: function() {
    if (this["_updateChart"]) {
      this._updateChart = false;
      $("#dashboard_chart").trigger("dashboard_chart:update", [this.activeChartData()]);
    }

    if (this["_resetAndUpdateChart"]) {
      this._resetAndUpdateChart = false;
      $("#dashboard_chart").trigger("dashboard_chart:reset_and_update", [this.activeChartData()]);
    }

    return (
      <div>
        <div className="dashboard_filters">
          <div className="filter_container">
            <DashboardPeriodFilter
              showOptions={this.state.periodFilterShowOptions}
              toggleOptions={this.togglePeriodFilterOptions}
              selectedPeriod={this.state.selectedPeriod}
              selectPredefinedPeriod={this.selectPredefinedPeriod}
              customPeriodFrom={this.state.customPeriodFrom}
              customPeriodTo={this.state.customPeriodTo}
              changeCustomPeriodFrom={this.changeCustomPeriodFrom}
              changeCustomPeriodTo={this.changeCustomPeriodTo}
            />
          </div>

          <div className="filter_container">
            <DashboardCarrierFilter
              showOptions={this.state.carrierFilterShowOptions}
              toggleOptions={this.toggleCarrierFilterOptions}
              selectedOption={this.state.selectedCarrier}
              selectOption={this.selectCarrier}
              initialOptions={this.props.initialCarrierOptions}
              autocompleteUrl={this.props.remoteCarrierAutocompleteURL}
            />
          </div>

          <div className="filter_container">
            <DashboardCustomerFilter
              showOptions={this.state.customerFilterShowOptions}
              toggleOptions={this.toggleCustomerFilterOptions}
              selectedOption={this.state.selectedCustomer}
              selectOption={this.selectCustomer}
              initialOptions={this.props.initialCustomerOptions}
              autocompleteUrl={this.props.remoteCustomerAutocompleteURL}
            />
          </div>
        </div>

        <DashboardSummary
          changeChartCallback={this.changeChart}
          chartType={this.state.selectedChartType}
          selectRevenueCurrencyCallback={this.selectRevenueCurrency}
          selectedRevenueCurrency={this.state.selectedRevenueCurrency}
          selectCostCurrencyCallback={this.selectCostCurrency}
          selectedCostCurrency={this.state.selectedCostCurrency}
          numberOfShipments={this.state.shipments.value}
          numberOfShipmentsUnit={this.state.shipments.unit}
          numberOfPackages={this.state.packages.value}
          numberOfPackagesUnit={this.state.packages.unit}
          weight={this.state.weight.value}
          weightUnit={this.state.weight.unit}
          revenues={this.state.revenues}
          costs={this.state.costs}
        />
      </div>
    );
  }
});

CompanyDashboard.parseJSONResponse = function(response) {
  return {
    shipments: response.shipments,
    packages: response.packages,
    weight: response.weight,
    revenues: response.revenues.map(function(revenue) {
      return {
        currency: revenue.currency,
        formattedValue: revenue.formatted_value,
        points: revenue.points,
      };
    }),
    costs: response.costs.map(function(cost) {
      return {
        currency: cost.currency,
        formattedValue: cost.formatted_value,
        points: cost.points,
      };
    }),
  };
};
