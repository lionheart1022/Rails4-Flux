(function() {
  window.ShipmentFormGoodsLines = createReactClass({
    getDefaultProps: function() {
      return {
        goodsIdentifierOptions: [],
        initialLines: [{ goods_identifier: "CLL", amount: 1 }],
      }
    },

    getInitialState: function() {
      var linesWithIds = this.props.initialLines.map(function(line) {
        return $.extend({}, line, { _id: uuidv4() })
      })

      return {
        lines: linesWithIds,
        addedLine: false,
        selectedGoodsIdentifier: "CLL",
      }
    },

    addLine: function() {
      var goodsIdentifier = this.state.selectedGoodsIdentifier
      var newLine = {
        _id: uuidv4(),
        goods_identifier: goodsIdentifier,
        amount: 1,
      }

      var matchingGoodsIdentifierOptions = this.props.goodsIdentifierOptions.filter(function(option) {
        return option.value === goodsIdentifier
      })

      if (matchingGoodsIdentifierOptions.length === 1) {
        $.extend(newLine, matchingGoodsIdentifierOptions[0].predefined_dimensions)
      }

      var newLines = this.state.lines.slice()
      newLines.push(newLine)

      this.setState({ lines: newLines, addedLine: true })
    },

    removeLine: function(idOfTarget) {
      var newLines = this.state.lines.filter(function(line) {
        return line._id !== idOfTarget
      })

      if (newLines.length === 0) {
        newLines = [{ _id: uuidv4(), goods_identifier: "CLL", amount: 1 }]
      }

      this.setState({ lines: newLines })
    },

    changeLineValue: function(idOfTarget, field, event) {
      var newLines = this.state.lines.slice()

      $.each(newLines, function() {
        if (this._id === idOfTarget) {
          this[field] = event.target.value
        }
      })

      this.setState({ lines: newLines })
    },

    changeLineIntegerValue: function(idOfTarget, field, event) {
      var newLines = this.state.lines.slice()

      $.each(newLines, function() {
        if (this._id === idOfTarget) {
          this[field] = event.target.value
        }
      })

      this.setState({ lines: newLines })
    },

    changeLineFloatValue: function(idOfTarget, field, event) {
      var newLines = this.state.lines.slice()

      $.each(newLines, function() {
        if (this._id === idOfTarget) {
          this[field] = event.target.value.replace(",", ".")
        }
      })

      this.setState({ lines: newLines })
    },

    changeLineCheckboxValue: function(idOfTarget, field, event) {
      var newLines = this.state.lines.slice()

      $.each(newLines, function() {
        if (this._id === idOfTarget) {
          this[field] = event.target.checked
        }
      })

      this.setState({ lines: newLines })
    },

    changeSelectedGoodsIdentifier: function(event) {
      this.setState({ selectedGoodsIdentifier: event.target.value })
    },

    getTotalWeight: function() {
      var total = 0.0

      for (var i = 0; i < this.state.lines.length; i++) {
        var line = this.state.lines[i]
        var amount = $.trim(line.amount)
        var weight = $.trim(line.weight)

        if (amount === "" || weight === "") {
          return null
        } else {
          total += Number(amount) * Number(weight)
        }
      }

      return total
    },

    getFormattedTotalWeight: function() {
      var totalWeight = this.getTotalWeight()

      if (totalWeight === null || isNaN(totalWeight)) {
        return "N/A"
      } else {
        return totalWeight
      }
    },

    asPackageDimensions: function() {
      var packageDimensions = {}

      for (var i = 0; i < this.state.lines.length; i++) {
        var line = this.state.lines[i]
        var isValid = this.isLineValid(line)

        if (!isValid) {
          return null
        }

        packageDimensions[i] = {
          id: i,
          amount: line.amount,
          length: line.length,
          width:  line.width,
          height: line.height,
          weight: line.weight,
        }
      }

      return packageDimensions
    },

    isLineValid: function(line) {
      var pAmount = parseInt(line.amount)
      var pLength = parseInt(line.length)
      var pWidth = parseInt(line.width)
      var pHeight = parseInt(line.height)
      var pWeight = parseFloat(line.weight)

      return !isNaN(pAmount) && !isNaN(pLength) && !isNaN(pWidth) && !isNaN(pHeight) && !isNaN(pWeight)
    },

    componentDidMount: function() {
      $(document).trigger("shipment_form_goods_lines:price_related_change")
    },

    componentDidUpdate: function(prevProps, prevState) {
      var isChangeUnrelatedToPrice = this.state.selectedGoodsIdentifier !== prevState.selectedGoodsIdentifier
      var isChangeRelatedToPrice = !isChangeUnrelatedToPrice

      if (isChangeRelatedToPrice) {
        $(document).trigger("shipment_form_goods_lines:price_related_change")
      }

      if (this.state.addedLine) {
        this.lastAmountInputElement.select()
        this.setState({ addedLine: false })
      }
    },

    render: function() {
      var component = this

      return (
        <div>
          <div className="shipment_form_goods_lines__container">
            <table className="shipment_form_goods_lines__table">
              <thead>
                <tr>
                  <th colSpan="2">Amount</th>
                  <th></th>
                  <th colSpan="2">
                    <span>Length&nbsp;</span>
                    <span className="shipment_form_goods_line_header__unit">(cm)</span>
                  </th>
                  <th colSpan="2">
                    <span>Width&nbsp;</span>
                    <span className="shipment_form_goods_line_header__unit">(cm)</span>
                  </th>
                  <th colSpan="2">
                    <span>Height&nbsp;</span>
                    <span className="shipment_form_goods_line_header__unit">(cm)</span>
                  </th>
                  <th colSpan="2">
                    <span>Weight&nbsp;</span>
                    <span className="shipment_form_goods_line_header__unit">(kg)</span>
                  </th>
                  <th colSpan="3">
                    <span>Total weight&nbsp;</span>
                    <span className="shipment_form_goods_line_header__unit">(kg)</span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {this.state.lines.map(function(lineData, lineIndex) {
                  var amountInputRef

                  if (lineIndex + 1 === component.state.lines.length) {
                    amountInputRef = function(input) { component.lastAmountInputElement = input }
                  } else {
                    amountInputRef = function(input) {}
                  }

                  return (
                    <GoodsLine
                      key={lineIndex}
                      {...lineData}
                      goodsIdentifierOptions={component.props.goodsIdentifierOptions}
                      index={lineIndex}
                      amountInputRef={amountInputRef}
                      removeCallback={component.removeLine.bind(null, lineData._id)}
                      valueChangeCallback={component.changeLineValue.bind(null, lineData._id)}
                      integerValueChangeCallback={component.changeLineIntegerValue.bind(null, lineData._id)}
                      floatValueChangeCallback={component.changeLineFloatValue.bind(null, lineData._id)}
                      checkboxChangeCallback={component.changeLineCheckboxValue.bind(null, lineData._id)}
                    />
                  )
                })}

                <tr className="shipment_form_goods_lines__total_weight_row">
                  <td className="shipment_form_goods_lines__total_weight_label" colSpan="10"></td>
                  <td className="shipment_form_goods_line__equals">=</td>
                  <td><input type="text" value={this.getFormattedTotalWeight()} className="cf_input" disabled={true} /></td>
                  <td colSpan="2"></td>
                </tr>
              </tbody>
            </table>
          </div>

          <div>
            <select className="shipment_form_goods_line__new_line_select" value={this.state.selectedGoodsIdentifier} onChange={this.changeSelectedGoodsIdentifier}>
              {this.props.goodsIdentifierOptions.map(function(option) {
                return <option key={option.value} value={option.value}>{option.name}</option>
              })}
            </select>
            <button type="button" className="shipment_form_goods_line__new_line_btn" onClick={this.addLine}>Add</button>
          </div>

          <div id="shipment_form__package_dimensions_as_json" data-dimensions={JSON.stringify(this.asPackageDimensions())}></div>
          <div id="shipment_form__goods_lines_as_json" data-dimensions={JSON.stringify(this.state.lines)}></div>
        </div>
      )
    }
  })

  var GoodsLine = createReactClass({
    getDefaultProps: function() {
      return {
        index: null,
        _id: null,
        amount: "",
        goods_identifier: "",
        length: "",
        width: "",
        height: "",
        weight: "",
        non_stackable: false,
      }
    },

    getTotalWeight: function() {
      var amount = $.trim(this.props.amount)
      var weight = $.trim(this.props.weight)

      if (amount === "" || weight === "") {
        return null
      } else {
        return Number(amount) * Number(weight)
      }
    },

    getFormattedTotalWeight: function() {
      var totalWeight = this.getTotalWeight()

      if (totalWeight === null || isNaN(totalWeight)) {
        return "N/A"
      } else {
        return totalWeight
      }
    },

    getInputNameFor: function(field) {
      return "shipment[package_dimensions][" + this.props.index + "][" + field + "]"
    },

    render: function() {
      return (
        <tr>
          <td className="shipment_form_goods_line__amount_cell">
            <input
              type="text"
              className="cf_input shipment_form_goods_line__amount_input"
              name={this.getInputNameFor("amount")}
              value={this.props.amount}
              onChange={this.props.integerValueChangeCallback.bind(null, "amount")}
              ref={this.props.amountInputRef} />
          </td>
          <td>
            <select className="cf_input shipment_form_goods_line__unit_input" name={this.getInputNameFor("goods_identifier")} value={this.props.goods_identifier} onChange={this.props.valueChangeCallback.bind(null, "goods_identifier")}>
              {this.props.goodsIdentifierOptions.map(function(option) {
                return <option key={option.value} value={option.value}>{option.value}</option>
              })}
            </select>
          </td>
          <td className="shipment_form_goods_line__multiplier"> ×</td>
          <td>
            <input type="text" className="cf_input" value={this.props.length} name={this.getInputNameFor("length")} onChange={this.props.integerValueChangeCallback.bind(null, "length")} />
          </td>
          <td className="shipment_form_goods_line__multiplier"> ×</td>
          <td>
            <input type="text" className="cf_input" value={this.props.width} name={this.getInputNameFor("width")} onChange={this.props.integerValueChangeCallback.bind(null, "width")} />
          </td>
          <td className="shipment_form_goods_line__multiplier"> ×</td>
          <td>
            <input type="text" className="cf_input" value={this.props.height} name={this.getInputNameFor("height")} onChange={this.props.integerValueChangeCallback.bind(null, "height")} />
          </td>
          <td className="shipment_form_goods_line__spacer"></td>
          <td>
            <input type="text" className="cf_input" value={this.props.weight} name={this.getInputNameFor("weight")} onChange={this.props.floatValueChangeCallback.bind(null, "weight")} />
          </td>
          <td className="shipment_form_goods_line__equals">=</td>
          <td>
            <input type="text" value={this.getFormattedTotalWeight()} className="cf_input" disabled={true} />
          </td>
          <td className="shipment_form_goods_line__non_stackable_cell">
            <label className="shipment_form_goods_line__checkbox_wrapped_in_label">
              <input type="checkbox" value="1" checked={this.props.non_stackable} name={this.getInputNameFor("non_stackable")} onChange={this.props.checkboxChangeCallback.bind(null, "non_stackable")} />
              <span>Do not stack</span>
            </label>
          </td>
          <td className="shipment_form_goods_line__remove_cell">
            <button type="button" className="shipment_form_goods_line__remove_btn" onClick={this.props.removeCallback}>Remove</button>
          </td>
        </tr>
      )
    }
  })

  function uuidv4() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }
})();
