var DashboardCarrierFilter = createReactClass({
  getDefaultProps: function() {
    return {
      selectedOption: null,
    }
  },

  renderLabel: function() {
    if (this.props.selectedOption !== null) {
      return (
        <span>
          <strong className="option_label">Carrier:</strong>
          <span className="option_value">{this.props.selectedOption.text}</span>
        </span>
      );
    } else {
      return <span>Carrier</span>;
    }
  },

  render: function() {
    return (
      <DashboardAutocompletion
        label={this.renderLabel()}
        toggleOptions={this.props.toggleOptions}
        showOptions={this.props.showOptions}
        selectOption={this.props.selectOption}
        selectedOption={this.props.selectedOption}
        initialOptions={this.props.initialOptions}
        autocompleteUrl={this.props.autocompleteUrl} />
    );
  }
});
