var DateRangePicker = createReactClass({
  getDefaultProps: function() {
    return {
      value: null,
      onChange: function(value) { },
      config: {},
    }
  },

  componentDidMount: function() {
    var parent = ReactDOM.findDOMNode(this);

    if ($(parent).find("input").length == 0) {
      $(parent).append('<input type="text">');
    }

    var component = this;
    var input = $(parent).find("input");
    input
    .dateRangePicker(this.props.config)
    .bind("datepicker-change", function(event, obj) {
      var fakeInputEvent = { target: { value: obj.value } };
      component.props.onChange(fakeInputEvent);
    })
  },

  componentWillReceiveProps: function(nextProps) {
    if (this.props.value === nextProps.value) {
      // Nothing changed, so do nothing.
      return;
    }

    var parent = ReactDOM.findDOMNode(this);
    var input = $(parent).find("input");

    if (nextProps.value) {
      // This limits this component to only single date use which is fine for now.
      input.data("dateRangePicker").setDateRange(nextProps.value, nextProps.value);
    } else {
      input.data("dateRangePicker").clear();
    }
  },

  componentWillUnmount: function() {
    var parent = ReactDOM.findDOMNode(this);
    var input = $(parent).find("input");

    input.data("dateRangePicker").destroy();
  },

  shouldComponentUpdate: function() {
    return false;
  },

  render: function() {
    return <span className="date_range_picker_wrapper"></span>;
  }
});
