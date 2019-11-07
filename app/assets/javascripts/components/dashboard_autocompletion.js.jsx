var DashboardAutocompletion = createReactClass({
  getDefaultProps: function() {
    return {
      showOptions: false,
    }
  },

  getInitialState: function() {
    return {
      searchTerm: "",
      options: this.props.initialOptions || null,
    };
  },

  componentDidUpdate: function() {
    if (this.props.showOptions) {
      this.textInput.focus();
    }
  },

  componentWillUpdate: function(nextProps, nextState) {
    var component = this;

    if (this.state.searchTerm !== nextState.searchTerm) {
      var urlWithQuery = nextProps.autocompleteUrl + "?term=" + encodeURIComponent(nextState.searchTerm);
      $.getJSON(urlWithQuery, function(data) {
        component.setState({ options: data });
      });
    }
  },

  filterClassName: function() {
    return this.props.showOptions ? "filter autocomplete_filter active" : "filter autocomplete_filter";
  },

  handleSearchTermChange: function(event) {
    this.setState({ searchTerm: event.target.value });
  },

  render: function() {
    var component = this;

    var optionsContent = null;
    if (this.state.options !== null) {
      optionsContent = (
        <ul className="autocomplete_options">
          {this.props.selectedOption !== null ? <li key="_all_" onClick={component.props.selectOption.bind(null, null)}>All</li> : null }
          {this.state.options.map(function(option) {
            return <li key={option.key} onClick={component.props.selectOption.bind(null, option)}>{option.text}</li>
          })}
        </ul>
      );
    }

    return (
      <div className={this.filterClassName()}>
        <div className="filter_label" onClick={this.props.toggleOptions}>
          <span className="text">{this.props.label}</span>
          <span className="arrow"></span>
        </div>

        <div className="filter_options">
          <div className="search_field">
            <input type="text" value={this.state.searchTerm} onChange={this.handleSearchTermChange} ref={function(input) { component.textInput = input; }} />
          </div>

          {optionsContent}
        </div>
      </div>
    );
  }
});
